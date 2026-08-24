-- diffview orchestration: wires oil (frontend), git (plumbing) and ui
-- (rendering) together and exposes the verbs the plugin binds. See
-- plugin-diffview.lua for setup.

local git = require("diffview.git")
local ui = require("diffview.ui")

local M = {}

local config = { keymap_open = "<CR>", keymap_preview = "<C-p>" }

-- Per-list-buffer CursorMoved autocmd id; nil when live preview is off.
local live_preview_autocmd = {}

local function is_diff_buffer(buf)
  return vim.api.nvim_buf_get_name(buf):match("^oil%-diff://") ~= nil
end

---Build a diffview pair from the oil entry under the cursor. The "Full Diff"
---row yields the combined pair; any other row yields that single file's pair.
---@return diffview.Pair|nil
local function pair_for_cursor_entry()
  local entry = require("oil").get_cursor_entry()
  if not entry or entry.type ~= "file" then
    return nil
  end
  local _, root = require("oil.util").parse_url(vim.api.nvim_buf_get_name(0))
  root = root:gsub("/$", "")

  if entry.meta and entry.meta.full then
    return { label = "Full Diff", files = git.diff_hunks(entry.meta.root), diff_root = entry.meta.root }
  end

  -- entry.name is display-only (:tcd-relative); use meta.git.path for reads.
  local path = (entry.meta and entry.meta.git and entry.meta.git.path) or entry.name
  local left = git.head_lines(root, path)
  local right = git.worktree_lines(root, path)
  local left_name = string.format("oil-diff://%s [base]", path)
  local right_name = string.format("%s/%s", root, path)
  local right_real_path = root .. "/" .. path
  if git.is_binary(left) or git.is_binary(right) then
    return {
      label = path,
      left = left and { "Binary file" } or nil,
      right = right and { "Binary file" } or nil,
      left_name = left_name,
      right_name = right_name,
    }
  end
  return {
    label = path,
    left = left,
    right = right,
    left_name = left_name,
    right_name = right_name,
    right_real_path = right_real_path,
    filetype = ui.filetype_for(path),
  }
end

---@param buf integer
function M.stop_live_preview(buf)
  if live_preview_autocmd[buf] then
    pcall(vim.api.nvim_del_autocmd, live_preview_autocmd[buf])
    live_preview_autocmd[buf] = nil
  end
  ui.close_preview()
end

---Preview the diff for the entry under the cursor, beside the list.
function M.preview_diff()
  local pair = pair_for_cursor_entry()
  if pair then
    ui.preview_pair(pair)
  end
end

---Toggle live preview: while on, moving the cursor updates the diff panes.
---@param buf integer
function M.toggle_live_preview(buf)
  if live_preview_autocmd[buf] then
    M.stop_live_preview(buf)
    return
  end
  M.preview_diff()
  live_preview_autocmd[buf] = vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = buf,
    desc = "Live diff preview follows cursor",
    callback = M.preview_diff,
  })
end

---Open the oil list. First row is the "Full Diff" aggregate; the rest are files.
function M.open_list()
  local root = git.repo_root()
  if not root then
    return vim.notify("diffview: not inside a git repository", vim.log.levels.ERROR)
  end
  -- Set our column before the first render so oil does not switch columns
  -- afterwards and trigger a redundant second list() refetch.
  if (require("oil.config").columns[1] or "") ~= "git_status" then
    require("oil").set_columns({ "git_status" })
  end
  vim.cmd.edit("oil-diff://" .. root .. "/")
end

---Move the cursor to the first list row whose entry satisfies `pred`.
---@param buf integer
---@param pred fun(entry: table): boolean
---@return boolean moved
local function seek_entry(buf, pred)
  local oil = require("oil")
  for lnum = 1, vim.api.nvim_buf_line_count(buf) do
    local entry = oil.get_entry_on_line(buf, lnum)
    if entry and pred(entry) then
      vim.api.nvim_win_set_cursor(0, { lnum, 0 })
      return true
    end
  end
  return false
end

---Identify the entry under the cursor so we can return to it after the list is
---rebuilt. Files are keyed by their git path; the aggregate row by `full`.
---@return fun(entry: table): boolean
local function cursor_entry_matcher()
  local entry = require("oil").get_cursor_entry()
  if entry and entry.meta and entry.meta.full then
    return function(e)
      return e.meta and e.meta.full or false
    end
  end
  local path = entry and entry.meta and entry.meta.git and entry.meta.git.path
  if not path then
    return function()
      return false
    end
  end
  return function(e)
    return e.meta and e.meta.git and e.meta.git.path == path or false
  end
end

---Move to the Full Diff row and start live preview. Buffer must be a rendered list.
---@param buf integer
local function start_full_preview(buf)
  seek_entry(buf, function(entry)
    return entry.meta and entry.meta.full or false
  end)
  M.toggle_live_preview(buf)
end

---:GitDiff entry point. Shows three empty panes instantly, primes the git
---snapshot asynchronously, then replaces the skeleton with the real list + live
---Full Diff preview. Invalidates the snapshot so it reflects current state.
---@param opts { branch?: boolean, base?: string }|nil  Diff against the branch's
---merge-base (whole-branch diff incl. uncommitted) instead of HEAD.
function M.open(opts)
  opts = opts or {}
  local root = git.repo_root()
  if not root then
    return vim.notify("diffview: not inside a git repository", vim.log.levels.ERROR)
  end
  if opts.branch then
    local mb = git.merge_base(root, opts.base)
    if not mb then
      return vim.notify("diffview: could not find a branch merge-base", vim.log.levels.ERROR)
    end
    git.set_base(root, mb)
  else
    git.set_base(root, "HEAD")
  end
  git.invalidate()
  ui.open_skeleton()
  local list_win = vim.api.nvim_get_current_win()

  git.snapshot_async(root, function()
    ui.close_skeleton()
    if not vim.api.nvim_win_is_valid(list_win) then
      return -- user navigated away before git returned
    end
    vim.api.nvim_set_current_win(list_win)
    M.open_list()
    vim.schedule(function()
      local buf = vim.api.nvim_get_current_buf()
      if is_diff_buffer(buf) then
        start_full_preview(buf)
      end
    end)
  end)
end

---Open the full 2-pane diff for the entry under the cursor.
function M.open_diff()
  local pair = pair_for_cursor_entry()
  if not pair then
    return
  end
  -- Remember which row we opened from so \ / <C-p> land back on it instead of
  -- the top of the freshly-rebuilt list.
  local matcher = cursor_entry_matcher()
  -- Both \ and <C-p> return to the 3-pane list+preview (never a bare list).
  local back = function()
    M.open_list()
    vim.schedule(function()
      local buf = vim.api.nvim_get_current_buf()
      seek_entry(buf, matcher)
      M.toggle_live_preview(buf)
    end)
  end
  pair.on_return = back
  pair.on_preview = back
  local oil_buf = vim.api.nvim_get_current_buf()
  M.stop_live_preview(oil_buf)
  ui.open_pair(pair)
  pcall(vim.api.nvim_buf_delete, oil_buf, { force = true })
end

---Wire everything up. Called from plugin-diffview.lua after oil is available.
function M.setup(opts)
  config = vim.tbl_extend("force", config, opts)
  local oil = require("oil")

  -- Register the adapter under oil's expected module name.
  package.preload["oil.adapters.diff"] = function()
    return require("diffview.oil")
  end

  -- oil.setup() wires BufReadCmd/BufWriteCmd + the filetype pattern from the
  -- schemes present then. We add ours afterwards, so replicate that here.
  require("oil.config").adapters["oil-diff://"] = "diff"
  vim.filetype.add({ pattern = { ["oil%-diff://.*"] = { "oil", { priority = 10 } } } })

  local scheme = vim.api.nvim_create_augroup("DiffviewScheme", { clear = true })
  vim.api.nvim_create_autocmd("BufReadCmd", {
    group = scheme,
    pattern = "oil-diff://*",
    nested = true,
    callback = function(p)
      oil.load_oil_buffer(p.buf)
    end,
  })
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    group = scheme,
    pattern = "oil-diff://*",
    nested = true,
    callback = function()
      oil.save()
    end,
  })

  ui.setup({ colors = config.colors })

  local group = vim.api.nvim_create_augroup("Diffview", { clear = true })
  local oil_config = require("oil.config")
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "OilEnter",
    callback = function(ev)
      local buf = ev.data and ev.data.buf or ev.buf
      local diff = is_diff_buffer(buf)
      -- set_columns forces a refetch, so only call it when it must change.
      local want = diff and "git_status" or "icon"
      if (oil_config.columns[1] or "") ~= want then
        oil.set_columns({ want })
      end
      if not diff then
        return
      end
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(buf) then
          return
        end
        vim.keymap.set("n", config.keymap_open, M.open_diff, { buffer = buf, desc = "Open side-by-side diff" })
        vim.keymap.set("n", config.keymap_preview, function()
          M.toggle_live_preview(buf)
        end, { buffer = buf, desc = "Toggle live diff preview" })
        ui.render_counts(buf)
      end)
    end,
  })

  -- Tear down the preview when the list window closes. BufWinLeave (not
  -- BufLeave) so moving into the preview panes does not kill them.
  vim.api.nvim_create_autocmd("BufWinLeave", {
    group = group,
    callback = function(ev)
      if is_diff_buffer(ev.buf) then
        M.stop_live_preview(ev.buf)
      end
    end,
  })
end

return M
