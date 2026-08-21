-- Shared vocabulary for change kinds: markers, highlight group names, and the
-- default colors. Single source of truth for git.lua (classify) and ui.lua
-- (rendering).

local M = {}

-- Highlight group names owned by this plugin.
M.HL = {
  new = "DiffviewNew",
  deleted = "DiffviewDeleted",
  modified = "DiffviewModified",
  unknown = "DiffviewModified",
  header = "DiffviewHeader",
  filler = "DiffviewFiller",
  full = "DiffviewFull",
}

-- ASCII status markers per change kind.
M.ICONS = {
  new = "+",
  deleted = "-",
  modified = "~",
  unknown = "?",
}

-- Default colors per kind; overridable via setup().
M.DEFAULT_COLORS = {
  new = "#2ea043",
  deleted = "#da3633",
  modified = "#8b949e",
  header = "#e5c07b", -- combined-view file header (bold yellow)
}

---Classify a porcelain change record into a kind key.
---@param st { index: string, worktree: string }|nil
---@return "new"|"deleted"|"modified"|"unknown"
function M.classify(st)
  if not st then
    return "unknown"
  end
  local x, y = st.index, st.worktree
  if x == "?" or y == "?" or x == "A" then
    return "new"
  end
  if x == "D" or y == "D" then
    return "deleted"
  end
  return "modified"
end

return M
