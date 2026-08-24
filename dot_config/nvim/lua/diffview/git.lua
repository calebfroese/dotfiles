-- Git plumbing for diffview. Pure data access; no UI.

local constants = require("diffview.constants")

local M = {}

-- Sentinel for a filler (absent) line on one side of the alignment.
M.FILLER = "\0"

local function git(cwd, args)
  return vim.fn.systemlist(vim.list_extend({ "git", "-C", cwd }, args)), vim.v.shell_error
end

local function to_lines(s)
  local lines = vim.split(s or "", "\n", { plain = true })
  if lines[#lines] == "" then
    table.remove(lines)
  end
  return lines
end

-- Cached snapshot, so the file list and the combined Full Diff (built moments
-- apart) share one parallel git batch. Invalidated when the base changes.
local snapshot_cache = {}

function M.invalidate()
  snapshot_cache = {}
end

-- Diff base ref per root: what the working tree is compared against. Defaults
-- to HEAD (uncommitted changes only); the branch view sets it to the merge-base
-- so the diff spans the whole branch plus uncommitted work.
local base_ref = {}

---@param root string
---@return string
local function base_of(root)
  return base_ref[root] or "HEAD"
end

---Set the diff base for `root` (e.g. "HEAD" or a merge-base sha). Invalidates
---the cached snapshot so the next read reflects the new base.
---@param root string
---@param ref string
function M.set_base(root, ref)
  base_ref[root] = ref
  M.invalidate()
end

-- Candidate base branches, best first. An explicit `branch` wins. Otherwise the
-- local default branch — all comparison is against local refs, never the
-- remote.
---@param root string
---@param branch string|nil
---@return string[]
local function base_candidates(root, branch)
  if branch then
    return { branch }
  end
  return { "origin/main", "origin/master", "main", "master" }
end

---Merge-base of HEAD and the local branch it forked from — where this branch's
---own work begins.
---@param root string
---@param branch string|nil
---@return string|nil
function M.merge_base(root, branch)
  for _, b in ipairs(base_candidates(root, branch)) do
    local out, code = git(root, { "merge-base", b, "HEAD" })
    if code == 0 and out[1] and out[1] ~= "" then
      return out[1]
    end
  end
  return nil
end

-- The slow, independent queries that make up a snapshot, built per base.
-- name-status vs the base gives the authoritative changed-file set + kind
-- (works when base is a merge-base, where committed-on-branch files are clean
-- vs HEAD and so absent from `git status`). status is still needed for
-- untracked files. numstat supplies +/- line counts. diff is the hunk text.
local function snapshot_args(base)
  return {
    { "status", "--porcelain=v1" },
    { "diff", "--numstat", base },
    { "diff", base },
    { "diff", "--name-status", base },
  }
end

---@param lines string[]
local function parse_numstat(lines)
  local counts = {}
  for _, line in ipairs(lines) do
    local add, del, path = line:match("^(%S+)%s+(%S+)%s+(.+)$")
    if path then
      counts[path] = { add = tonumber(add) or 0, del = tonumber(del) or 0 }
    end
  end
  return counts
end

-- Map `git diff --name-status` letters to the index/worktree marker pair that
-- constants.classify understands. The base-side diff is a single axis, so the
-- letter is placed in `index` and `worktree` is blank.
---@param lines string[]
local function parse_name_status(lines)
  local changes = {}
  for _, line in ipairs(lines) do
    local letter, rest = line:match("^(%a)%d*%s+(.+)$")
    if letter and rest then
      -- Renames/copies are "old\tnew"; keep the new path.
      local arrow = rest:find("\t")
      local path = arrow and rest:sub(arrow + 1) or rest
      table.insert(changes, { path = path, index = letter, worktree = " " })
    end
  end
  return changes
end

-- Complete changed-file set for the snapshot: every file differing from the
-- base (name-status), plus untracked files from `git status` (which the base
-- diff cannot see because they are not tracked).
local function build_changes(status_lines, name_status_lines)
  local changes = parse_name_status(name_status_lines)
  local seen = {}
  for _, c in ipairs(changes) do
    seen[c.path] = true
  end
  for _, line in ipairs(status_lines) do
    if #line >= 4 then
      local rest = line:sub(4)
      local arrow = rest:find(" %-> ")
      if arrow then
        rest = rest:sub(arrow + 4)
      end
      local index, worktree = line:sub(1, 1), line:sub(2, 2)
      -- Untracked (or otherwise unseen) files are not in the base diff.
      if (index == "?" or worktree == "?") and not seen[rest] then
        seen[rest] = true
        table.insert(changes, { path = rest, index = index, worktree = worktree })
      end
    end
  end
  return changes
end

local function build_snapshot(out)
  return {
    changes = build_changes(out[1], out[4]),
    counts = parse_numstat(out[2]),
    difftext = out[3],
  }
end

---@param path string|nil
---@return string|nil
function M.repo_root(path)
  local dir = path and vim.fn.fnamemodify(path, ":p:h") or vim.fn.getcwd()
  local out, code = git(dir, { "rev-parse", "--show-toplevel" })
  return code == 0 and out[1] or nil
end

---@class diffview.Snapshot
---@field changes { path: string, index: string, worktree: string }[]
---@field counts table<string, { add: integer, del: integer }>
---@field difftext string[]

---Snapshot (status+numstat+diff), cached per root. Runs the batch in parallel.
---@param root string
---@return diffview.Snapshot
function M.snapshot(root)
  if snapshot_cache[root] then
    return snapshot_cache[root]
  end
  local args = snapshot_args(base_of(root))
  local procs = {}
  for i, a in ipairs(args) do
    procs[i] = vim.system(vim.list_extend({ "git", "-C", root }, a), { text = true })
  end
  local out = {}
  for i, p in ipairs(procs) do
    out[i] = to_lines(p:wait().stdout)
  end
  snapshot_cache[root] = build_snapshot(out)
  return snapshot_cache[root]
end

---Async snapshot: serves cache warm, else runs the batch and calls cb when ready.
---@param root string
---@param cb fun(snap: diffview.Snapshot)
function M.snapshot_async(root, cb)
  if snapshot_cache[root] then
    return cb(snapshot_cache[root])
  end
  local args = snapshot_args(base_of(root))
  local out, remaining = {}, #args
  for i, a in ipairs(args) do
    vim.system(vim.list_extend({ "git", "-C", root }, a), { text = true }, function(res)
      out[i] = to_lines(res.stdout)
      remaining = remaining - 1
      if remaining == 0 then
        vim.schedule(function()
          snapshot_cache[root] = build_snapshot(out)
          cb(snapshot_cache[root])
        end)
      end
    end)
  end
end

---Base-side blob for `path`, or nil if absent at the base.
---@return string[]|nil
function M.base_lines(root, path)
  local lines, code = git(root, { "show", base_of(root) .. ":" .. path })
  return code == 0 and lines or nil
end

---Working-tree file at `path`, or nil if it does not exist.
---@return string[]|nil
function M.worktree_lines(root, path)
  local full = root .. "/" .. path
  return vim.fn.filereadable(full) == 1 and vim.fn.readfile(full) or nil
end

---Binary if any line has a NUL or embedded newline (readfile splits text on \n).
---@param lines string[]|nil
function M.is_binary(lines)
  for _, l in ipairs(lines or {}) do
    if l:find("\0", 1, true) or l:find("\n", 1, true) then
      return true
    end
  end
  return false
end

---@class diffview.FileDiff
---@field path string
---@field left string[]   Old-side lines (context + deletions), filler-padded
---@field right string[]  New-side lines (context + additions), filler-padded
---@field right_lines integer[]  Real worktree line per right entry; 0 for filler/hunk rows
---@field filetype string
---@field kind string     "new"|"deleted"|"modified"
---@field add integer
---@field del integer

---Parse the base diff into per-file side-by-side aligned hunks, then append
---untracked files (all-additions). Matches the oil list's file set.
---@param root string
---@return diffview.FileDiff[]
function M.diff_hunks(root)
  local snap = M.snapshot(root)
  local files, cur = {}, nil
  -- Next real worktree line for the current file's right side; advanced by the
  -- @@ header and by every context/added line.
  local right_line = 0

  -- Pad the shorter side with fillers so the two sides stay row-aligned. Filler
  -- rows on the right have no real worktree line, recorded as 0.
  local function balance()
    while cur and #cur.left < #cur.right do
      table.insert(cur.left, M.FILLER)
    end
    while cur and #cur.right < #cur.left do
      table.insert(cur.right, M.FILLER)
      table.insert(cur.right_lines, 0)
    end
  end

  for _, line in ipairs(snap.difftext) do
    if line:match("^diff %-%-git ") then
      balance()
      cur = { path = nil, left = {}, right = {}, right_lines = {}, filetype = "" }
      right_line = 0
      table.insert(files, cur)
    elseif cur and (line:match("^%+%+%+ ") or line:match("^%-%-%- ")) then
      -- New side is /dev/null for deletions, so fall back to the old path.
      local p = line:match("^%+%+%+ b/(.*)$") or line:match("^%-%-%- a/(.*)$")
      if p and p ~= "/dev/null" and not cur.path then
        cur.path = p
        cur.filetype = vim.filetype.match({ filename = p }) or ""
      end
    elseif cur and line:match("^@@") then
      balance()
      -- @@ -a,b +c,d @@ : c is the first worktree line of this hunk's right side.
      local c = line:match("^@@ %-%d+,?%d* %+(%d+)")
      right_line = tonumber(c) or right_line
      table.insert(cur.left, line)
      table.insert(cur.right, line)
      table.insert(cur.right_lines, 0)
    elseif cur and cur.path then
      local tag = line:sub(1, 1)
      if tag == " " then
        balance()
        table.insert(cur.left, line:sub(2))
        table.insert(cur.right, line:sub(2))
        table.insert(cur.right_lines, right_line)
        right_line = right_line + 1
      elseif tag == "-" then
        table.insert(cur.left, line:sub(2))
      elseif tag == "+" then
        table.insert(cur.right, line:sub(2))
        table.insert(cur.right_lines, right_line)
        right_line = right_line + 1
      end
    end
  end
  balance()

  local status_by_path = {}
  for _, c in ipairs(snap.changes) do
    status_by_path[c.path] = c
  end
  local result = {}
  for _, f in ipairs(files) do
    if f.path then
      f.kind = constants.classify(status_by_path[f.path])
      local n = snap.counts[f.path] or { add = 0, del = 0 }
      f.add, f.del = n.add, n.del
      table.insert(result, f)
    end
  end

  -- Untracked files show as "??" in status; render them as all-additions.
  for _, c in ipairs(snap.changes) do
    if c.index == "?" or c.worktree == "?" then
      local content = M.worktree_lines(root, c.path) or {}
      if M.is_binary(content) then
        content = { "Binary file" }
      end
      local left, right, right_lines = {}, {}, {}
      for i, l in ipairs(content) do
        table.insert(left, M.FILLER)
        table.insert(right, l)
        table.insert(right_lines, i)
      end
      table.insert(result, {
        path = c.path,
        left = left,
        right = right,
        right_lines = right_lines,
        filetype = vim.filetype.match({ filename = c.path }) or "",
        kind = "new",
        add = #content,
        del = 0,
      })
    end
  end

  return result
end

return M
