-- oil adapter: browse a repo's working-tree changes as a directory.
-- URL: oil-diff://<repo-root>/  — read-only for now.

local git = require("diffview.git")
local ui = require("diffview.ui")

local M = {}

M.name = "diff"

-- Leading space sorts this synthetic entry before any real filename.
M.FULL_DIFF = " Full Diff"

M.normalize_url = function(url, callback)
  callback(require("oil.util").addslash(url))
end

M.list = function(url, column_defs, cb)
  local cache = require("oil.cache")
  local FIELD_META = require("oil.constants").FIELD_META
  local _, root = require("oil.util").parse_url(url)
  root = root:gsub("/$", "")

  -- Display paths relative to :tcd; keep the git-root path in meta for reads.
  local tcd = vim.fn.getcwd(-1, 0)
  -- Snapshot is cached (M.open primes it async), so this read is warm.
  local snap = git.snapshot(root)

  local entries = {}
  local total = { add = 0, del = 0 }
  for _, change in ipairs(snap.changes) do
    local stat = snap.counts[change.path]
    if not stat then
      -- Untracked files are absent from numstat; count every line as added.
      local wt = git.worktree_lines(root, change.path)
      stat = { add = wt and #wt or 0, del = 0 }
    end
    total.add = total.add + stat.add
    total.del = total.del + stat.del
    local display = vim.fs.relpath(tcd, root .. "/" .. change.path) or change.path
    local entry = cache.create_entry(url, display, "file")
    entry[FIELD_META] = { git = change, stat = stat }
    table.insert(entries, entry)
  end

  local full = cache.create_entry(url, M.FULL_DIFF, "file")
  full[FIELD_META] = { full = true, root = root, stat = total }
  table.insert(entries, 1, full)

  cb(nil, entries)
end

M.get_column = function(name)
  return name == "git_status" and ui.status_column() or nil
end

-- Read-only until mutations map onto git ops (unstage/checkout/rm).
M.is_modifiable = function()
  return false
end

M.render_action = function(action)
  return string.format("%s %s", action.type:upper(), action.url or action.src_url)
end

M.perform_action = function(_, cb)
  cb("diffview: mutations not implemented yet")
end

return M
