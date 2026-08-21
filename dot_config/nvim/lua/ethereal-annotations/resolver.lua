-- A resolver maps a buffer's rows to real files and lines, so the rest of the
-- plugin treats every buffer uniformly regardless of whether it is a real file,
-- a single-file diff pane (a verbatim worktree copy), or the combined Full Diff
-- view (many files concatenated, rows not linear in file lines).
--
-- Coordinates: rows are 0-based (extmark space); lines are 1-based (file space).
-- A "target" is a storage key plus a line range: { path, hash, start_line,
-- end_line }. Every resolver answers:
--   * span(lo0, hi0)              -> target | nil, err   (for add)
--   * point(row0)                 -> target | nil        (for delete; 1 line)
--   * files()                     -> { path, hash }[]    (for render)
--   * rows(path, start_line, end) -> row0[]              (for render)

local hash = require("ethereal-annotations.hash")

local M = {}

-- Combined (Full Diff) buffers register a row->(path,line) map here, keyed by
-- bufnr. Kept Lua-side (not a buffer var) so the sparse integer-keyed table is
-- not mangled by vimscript serialization.
local combined_maps = {}

---Register a combined-view buffer. `map[row0] = { path = relpath, line = n }`.
---@param bufnr integer
---@param map table<integer, { path: string, line: integer }>
---@param root string  git root the relative paths resolve against
function M.register_combined(bufnr, map, root)
  combined_maps[bufnr] = { map = map, root = root }
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = bufnr,
    once = true,
    callback = function() combined_maps[bufnr] = nil end,
  })
end

---True while a buffer should be treated as a static snapshot of other files
---(diff panes), so content-change events never invalidate stored annotations.
---@param bufnr integer
function M.is_snapshot(bufnr)
  return combined_maps[bufnr] ~= nil or vim.b[bufnr].ethereal_real_path ~= nil
end

-- Worktree hash for `abspath`, matching the hash a loaded buffer of that file
-- would produce (readfile lines == buffer lines).
local function worktree_hash(abspath)
  if vim.fn.filereadable(abspath) == 0 then return nil end
  return hash.compute_lines(vim.fn.readfile(abspath))
end

-- Identity resolver: row N is line N+1 of a single file. Backs both real-file
-- buffers and single-file diff panes; they differ only in where the path comes
-- from (a diff pane overrides it via b:ethereal_real_path).
local function identity_resolver(bufnr)
  local path = vim.b[bufnr].ethereal_real_path or vim.fn.expand("%:p")
  if path == "" then return nil end
  local h = hash.compute(bufnr)

  return {
    span = function(lo0, hi0)
      return { path = path, hash = h, start_line = lo0 + 1, end_line = hi0 + 1 }
    end,
    point = function(row0)
      return { path = path, hash = h, start_line = row0 + 1, end_line = row0 + 1 }
    end,
    files = function()
      return { { path = path, hash = h } }
    end,
    rows = function(_, sl, el)
      local out = {}
      for line = sl, el do out[#out + 1] = line - 1 end
      return out
    end,
  }
end

-- Combined resolver: each row maps to a specific (path, line) via the map.
-- Filler/header/hunk rows are absent from the map.
local function combined_resolver(c)
  local map, root = c.map, c.root
  local function abs(relpath) return root .. "/" .. relpath end

  return {
    span = function(lo0, hi0)
      local relpath, lo, hi
      for row0 = lo0, hi0 do
        local m = map[row0]
        if m then
          if relpath and m.path ~= relpath then
            return nil, "Annotation cannot span multiple files"
          end
          relpath = m.path
          lo = (not lo or m.line < lo) and m.line or lo
          hi = (not hi or m.line > hi) and m.line or hi
        end
      end
      if not relpath then return nil, "No annotatable lines in selection" end
      local h = worktree_hash(abs(relpath))
      if not h then return nil, "File is not readable" end
      return { path = abs(relpath), hash = h, start_line = lo, end_line = hi }
    end,
    point = function(row0)
      local m = map[row0]
      if not m then return nil end
      local h = worktree_hash(abs(m.path))
      if not h then return nil end
      return { path = abs(m.path), hash = h, start_line = m.line, end_line = m.line }
    end,
    files = function()
      local seen, out = {}, {}
      for _, m in pairs(map) do
        if not seen[m.path] then
          seen[m.path] = true
          local h = worktree_hash(abs(m.path))
          if h then out[#out + 1] = { path = abs(m.path), hash = h, rel = m.path } end
        end
      end
      return out
    end,
    rows = function(file, sl, el)
      local out = {}
      for row0, m in pairs(map) do
        if m.path == file.rel and m.line >= sl and m.line <= el then
          out[#out + 1] = row0
        end
      end
      table.sort(out)
      return out
    end,
  }
end

---The resolver for a buffer, or nil when a plain buffer has no file path.
---@param bufnr integer
function M.for_buffer(bufnr)
  local c = combined_maps[bufnr]
  if c then return combined_resolver(c) end
  return identity_resolver(bufnr)
end

return M
