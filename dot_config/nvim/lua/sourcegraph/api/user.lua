-- Authenticated user, used by the healthcheck to verify credentials.

local client = require("sourcegraph.api.client")

local M = {}

local QUERY = [[
query CurrentUser {
  currentUser {
    username
  }
}
]]

---The authenticated user's username. Fails hard if unauthenticated or malformed.
---@return string username
function M.current_username()
  local data = client.graphql(QUERY, vim.empty_dict())
  local user = data.currentUser
  if type(user) ~= "table" or type(user.username) ~= "string" or user.username == "" then
    error("sourcegraph.api.user: not authenticated (no current user)", 0)
  end
  return user.username
end

return M
