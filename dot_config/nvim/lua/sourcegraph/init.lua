-- Public entry point for the sourcegraph plugin.

local M = {}

---Apply user options (see sourcegraph.config for the schema and defaults).
---@param opts sourcegraph.Config|table|nil
function M.setup(opts)
  require("sourcegraph.config").setup(opts)
end

---Open the live search picker.
---@param seed string|nil Initial query text
function M.search(seed)
  require("sourcegraph.ui").search(seed)
end

return M
