-- Plugin options, with a `setup(opts)` deep-merge over the defaults below.
-- Every value is overridable, but the defaults are chosen so the plugin works
-- with no configuration.

local M = {}

---@class sourcegraph.Config
---@field credentials_path string  Path to the JSON file holding { endpoint, token }.
---@field default_query string     Prefilled query when the picker opens.
---@field query_delay_ms integer   Debounce before a live query is sent.
---@field min_pattern_len integer  Minimum non-filter query length before searching.
---@field count { initial: integer, increment: integer }  Result cap and <C-e> step.
---@field repo_local_path fun(repo: string, path: string): string?  Map a match to a
---  local file path to open, or nil to open the Sourcegraph URL instead.

---@type sourcegraph.Config
local defaults = {
  credentials_path = "~/.config/sourcegraph-nvim/credentials.json",
  default_query = [[count:150 repo:^github\.com/Canva/.*$ ]],
  query_delay_ms = 500,
  min_pattern_len = 2,
  count = {
    initial = 150,
    increment = 500,
  },
  -- Canva repos live at github.com/Canva/<repo> and are checked out under
  -- ~/work/<repo>; other repos have no local checkout.
  repo_local_path = function(repo, path)
    local name = repo:match("^github%.com/Canva/(.+)$")
    if not name then
      return nil
    end
    return vim.fn.expand("~/work/" .. name .. "/" .. path)
  end,
}

---@type sourcegraph.Config
local options = vim.deepcopy(defaults)

---Merge `opts` over the defaults.
---@param opts sourcegraph.Config|table|nil
function M.setup(opts)
  options = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
end

---The active configuration.
---@return sourcegraph.Config
function M.get()
  return options
end

return M
