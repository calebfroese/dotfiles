-- Rendering for diffview: scratch diff buffers, side-by-side layout, the
-- status-marker column, change-count virtual text, and highlights.

local constants = require("diffview.constants")

local M = {}

local counts_ns = vim.api.nvim_create_namespace("diffview_counts")
local combined_ns = vim.api.nvim_create_namespace("diffview_combined")
local syntax_ns = vim.api.nvim_create_namespace("diffview_combined_syntax")

local ICONS = constants.ICONS
local HL = constants.HL

-- Windows of the most recent preview / transient skeleton, so each can be
-- replaced in place.
local preview_wins = {}
local skeleton_wins = {}

-- Overridable via setup(); reapplied on colorscheme change.
local colors = vim.deepcopy(constants.DEFAULT_COLORS)

---Right-aligned "+A -D" chunks, shared by list rows and combined-view headers.
local function count_virt_text(add, del)
  return {
    { string.format("+%d", add), HL.new },
    { " ", "Normal" },
    { string.format("-%d", del), HL.deleted },
  }
end

local function ensure_highlights()
  vim.api.nvim_set_hl(0, HL.new, { fg = colors.new })
  vim.api.nvim_set_hl(0, HL.deleted, { fg = colors.deleted })
  vim.api.nvim_set_hl(0, HL.modified, { fg = colors.modified })
  vim.api.nvim_set_hl(0, HL.header, { fg = colors.header, bold = true })
  vim.api.nvim_set_hl(0, HL.filler, { link = "Comment" })
  vim.api.nvim_set_hl(0, HL.full, { fg = colors.modified, italic = true })
end

function M.setup(opts)
  if opts and opts.colors then
    colors = vim.tbl_extend("force", colors, opts.colors)
  end
  ensure_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("DiffviewHighlights", { clear = true }),
    callback = ensure_highlights,
  })
end

---@param path string
function M.filetype_for(path)
  return vim.filetype.match({ filename = path }) or ""
end

---The oil status-marker column: `≡` for Full Diff, else the +/-/~ change icon.
---@return oil.ColumnDefinition
function M.status_column()
  local FIELD_META = require("oil.constants").FIELD_META
  return {
    render = function(entry)
      local meta = entry[FIELD_META]
      if meta and meta.full then
        return { "≡", HL.full }
      end
      local kind = constants.classify(meta and meta.git)
      return { ICONS[kind] .. " ", HL[kind] }
    end,
    parse = function(line)
      return line:match("^(%S+)%s+(.*)$")
    end,
  }
end

---Right-aligned "+A -D" counts on every file row; italicise the Full Diff name.
---@param buf integer
function M.render_counts(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local oil = require("oil")
  vim.api.nvim_buf_clear_namespace(buf, counts_ns, 0, -1)
  for lnum = 1, vim.api.nvim_buf_line_count(buf) do
    local meta = (oil.get_entry_on_line(buf, lnum) or {}).meta
    if meta and meta.stat then
      vim.api.nvim_buf_set_extmark(buf, counts_ns, lnum - 1, 0, {
        virt_text = count_virt_text(meta.stat.add, meta.stat.del),
        virt_text_pos = "right_align",
        hl_mode = "combine",
      })
    end
    if meta and meta.full then
      vim.api.nvim_buf_set_extmark(buf, counts_ns, lnum - 1, 0, {
        end_row = lnum,
        end_col = 0,
        hl_group = HL.full,
        hl_mode = "combine",
      })
    end
  end
end

---Read-only scratch buffer holding `lines`. Setting filetype fires the FileType
---autocmd (vim.treesitter.start). Splits embedded newlines (binary bytes) so
---nvim_buf_set_lines never errors.
---@return integer bufnr
local function make_scratch(lines, name, filetype)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  local safe = {}
  for _, l in ipairs(lines or {}) do
    if l:find("\n", 1, true) then
      vim.list_extend(safe, vim.split(l, "\n", { plain = true }))
    else
      safe[#safe + 1] = l
    end
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, safe)
  vim.bo[buf].modifiable = false
  pcall(vim.api.nvim_buf_set_name, buf, name)
  if filetype and filetype ~= "" then
    vim.bo[buf].filetype = filetype
  end
  return buf
end

---@class diffview.Pair
---@field label string
---@field left string[]|nil     Lines for old side, nil if absent
---@field right string[]|nil    Lines for new side, nil if absent
---@field left_name string|nil
---@field right_name string|nil
---@field right_real_path string|nil  Real worktree path the right pane mirrors (single-file view)
---@field filetype string|nil
---@field files diffview.FileDiff[]|nil  If set, build the combined all-files view
---@field diff_root string|nil  Git root the combined view's paths resolve against
---@field on_return fun()|nil   Called on \ (go back)
---@field on_preview fun()|nil  Called on <C-p> (go to list + preview)

---Build one side of the combined view: files' aligned lines, each under a
---header, blank-padded. Returns the lines plus header/filler/region metadata.
---For the right side, also returns line_map[row0] = { path, line } mapping each
---real content row (0-based) back to its worktree file and line number.
local function combined_side(files, side)
  local git = require("diffview.git")
  local lines, headers, fillers, regions, line_map = {}, {}, {}, {}, {}
  for i, f in ipairs(files) do
    if i > 1 then
      table.insert(lines, "")
      table.insert(lines, "")
    end
    local icon = ICONS[f.kind] or ICONS.unknown
    table.insert(headers, { row = #lines, file = f, icon = icon })
    table.insert(lines, string.format("%s %s", icon, f.path))
    table.insert(lines, "")
    table.insert(lines, "")
    local lang = f.filetype ~= "" and vim.treesitter.language.get_lang(f.filetype) or nil
    local body_start, body = #lines, {}
    for idx, l in ipairs(f[side]) do
      if l == git.FILLER then
        table.insert(fillers, #lines)
        table.insert(lines, "")
        table.insert(body, "")
      elseif l:match("^@@") then
        -- Hunk marker: keep the row but blank it in the parse region.
        table.insert(lines, l)
        table.insert(body, "")
      else
        local rl = side == "right" and f.right_lines and f.right_lines[idx] or 0
        if rl and rl > 0 then
          line_map[#lines] = { path = f.path, line = rl }
        end
        table.insert(lines, l)
        table.insert(body, l)
      end
    end
    if lang then
      table.insert(regions, { start_row = body_start, lang = lang, body = body })
    end
  end
  return lines, headers, fillers, regions, line_map
end

---Icon coloured by kind, path in header hl, +A/-D counts as right-aligned virt.
local function style_combined(buf, headers, fillers)
  for _, h in ipairs(headers) do
    vim.api.nvim_buf_set_extmark(buf, combined_ns, h.row, 0, {
      end_col = #h.icon,
      hl_group = HL[h.file.kind] or HL.modified,
    })
    vim.api.nvim_buf_set_extmark(buf, combined_ns, h.row, #h.icon, {
      end_row = h.row + 1,
      end_col = 0,
      hl_group = HL.header,
    })
    vim.api.nvim_buf_set_extmark(buf, combined_ns, h.row, 0, {
      virt_text = count_virt_text(h.file.add, h.file.del),
      virt_text_pos = "right_align",
      hl_mode = "combine",
    })
  end
  for _, row in ipairs(fillers) do
    vim.api.nvim_buf_set_extmark(buf, combined_ns, row, 0, { line_hl_group = HL.filler })
  end
end

---Per-file syntax for the combined view: parse each file's body with its own
---language parser and paint the highlights offset into the buffer. Hunk
---fragments are not whole programs, so this is best-effort.
local function syntax_combined(buf, regions)
  for _, r in ipairs(regions) do
    local text = table.concat(r.body, "\n")
    local ok, parser = pcall(vim.treesitter.get_string_parser, text, r.lang)
    local query = ok and parser and vim.treesitter.query.get(r.lang, "highlights")
    if query then
      for id, node in query:iter_captures(parser:parse()[1]:root(), text) do
        local sr, sc, er, ec = node:range()
        local hl = "@" .. query.captures[id] .. "." .. r.lang
        for row = sr, er do
          pcall(vim.api.nvim_buf_set_extmark, buf, syntax_ns, r.start_row + row, row == sr and sc or 0, {
            end_row = row == er and (r.start_row + row) or (r.start_row + row + 1),
            end_col = row == er and ec or 0,
            hl_group = hl,
            priority = 90,
          })
        end
      end
    end
  end
end

---Build the two diff buffers for a pair: a single file's old/new, or — when
---pair.files is set — the combined all-files view.
---@param pair diffview.Pair
---@return integer left, integer right
local function build_buffers(pair)
  if pair.files then
    local lc, lh, lf, lr = combined_side(pair.files, "left")
    local rc, rh, rf, rr, rmap = combined_side(pair.files, "right")
    local left = make_scratch(lc, "git diff [HEAD]", nil)
    local right = make_scratch(rc, "git diff [working]", nil)
    syntax_combined(left, lr)
    syntax_combined(right, rr)
    style_combined(left, lh, lf)
    style_combined(right, rh, rf)
    -- Row→(path,line) map lets ethereal-annotations target the real worktree
    -- file from the combined right side. Registered Lua-side (a buffer var
    -- would mangle the sparse integer-keyed table via vimscript).
    if pair.diff_root then
      pcall(function()
        require("ethereal-annotations").register_combined(right, rmap, pair.diff_root)
      end)
    end
    return left, right
  end
  local ft = pair.filetype or M.filetype_for(pair.label)
  local left = make_scratch(pair.left, pair.left_name or (pair.label .. " [old]"), ft)
  local right = make_scratch(pair.right, pair.right_name or (pair.label .. " [new]"), ft)
  -- The right pane is a verbatim copy of the worktree file, so it hashes and
  -- line-aligns 1:1 with it. Tag it so ethereal-annotations targets the real
  -- file (path + content hash), not this scratch buffer's cosmetic name.
  if pair.right_real_path then
    vim.b[right].ethereal_real_path = pair.right_real_path
  end
  return left, right
end

---Enter diff mode on the current window; disable cursorline, which Vim renders
---as a full-width underline in diff windows.
local function diffthis()
  vim.cmd("diffthis")
  vim.wo.cursorline = false
end

local function close_wins(wins)
  for _, w in ipairs(wins) do
    if vim.api.nvim_win_is_valid(w) then
      pcall(vim.api.nvim_win_close, w, true)
    end
  end
end

---Open a pair side-by-side, replacing the current window's layout.
---@param pair diffview.Pair
function M.open_pair(pair)
  local left, right = build_buffers(pair)
  vim.api.nvim_win_set_buf(0, left)
  diffthis()
  vim.cmd("rightbelow vsplit")
  vim.api.nvim_win_set_buf(0, right)
  diffthis()
  pcall(vim.cmd, "normal! gg]c")

  -- Surface any stored annotations for the real file on its diff pane.
  if pair.right_real_path or pair.files then
    pcall(function()
      require("ethereal-annotations").refresh(right)
    end)
  end

  -- \ and <C-p> tear down these buffers, then hand off to the caller.
  local function exit_to(cb)
    return function()
      for _, b in ipairs({ left, right }) do
        pcall(vim.api.nvim_buf_delete, b, { force = true })
      end
      cb()
    end
  end
  for _, b in ipairs({ left, right }) do
    if pair.on_return then
      vim.keymap.set("n", "\\", exit_to(pair.on_return), { buffer = b, desc = "Back to diff list" })
    end
    if pair.on_preview then
      vim.keymap.set("n", "<C-p>", exit_to(pair.on_preview), { buffer = b, desc = "Back to list preview" })
    end
  end
end

function M.close_preview()
  close_wins(preview_wins)
  preview_wins = {}
end

function M.close_skeleton()
  close_wins(skeleton_wins)
  skeleton_wins = {}
end

---Three empty panes immediately (equal thirds) so the layout appears instantly
---while data loads. Focus stays on the rightmost (future list) pane.
function M.open_skeleton()
  M.close_skeleton()
  local function blank()
    local b = vim.api.nvim_create_buf(false, true)
    vim.bo[b].bufhidden = "wipe"
    return b
  end
  vim.api.nvim_win_set_buf(0, blank())
  local list_win = vim.api.nvim_get_current_win()
  vim.cmd("leftabove vsplit")
  local new_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(new_win, blank())
  vim.cmd("leftabove vsplit")
  local old_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(old_win, blank())
  vim.api.nvim_set_current_win(list_win)
  vim.cmd("wincmd =")
  skeleton_wins = { old_win, new_win }
end

---Preview a pair as [ old | new | list ] equal thirds, to the left of the
---current (list) window, keeping focus on the list. Replaces any prior preview.
---@param pair diffview.Pair
function M.preview_pair(pair)
  local list_win = vim.api.nvim_get_current_win()
  M.close_preview()
  local left, right = build_buffers(pair)

  vim.api.nvim_set_current_win(list_win)
  vim.cmd("leftabove vsplit")
  local new_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(new_win, right)
  diffthis()
  vim.cmd("leftabove vsplit")
  local old_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(old_win, left)
  diffthis()
  pcall(vim.cmd, "normal! gg]c")

  preview_wins = { old_win, new_win }
  if vim.api.nvim_win_is_valid(list_win) then
    vim.api.nvim_set_current_win(list_win)
    vim.cmd("wincmd =")
  end

  -- Surface stored annotations on the freshly built right pane. The list keeps
  -- focus, so without this they would only appear once the pane is entered.
  if pair.right_real_path or pair.files then
    pcall(function()
      require("ethereal-annotations").refresh(right)
    end)
  end
end

return M
