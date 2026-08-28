-- `:checkhealth sourcegraph` — verifies credentials load and actually work.

local M = {}

function M.check()
  vim.health.start("sourcegraph")

  local config = require("sourcegraph.config")
  local ok, creds = pcall(require("sourcegraph.credentials").load)
  if not ok then
    vim.health.error(tostring(creds), {
      "Create " .. config.get().credentials_path,
      'It must contain: { "endpoint": "https://...", "token": "..." }',
    })
    return
  end
  vim.health.ok("credentials loaded (endpoint: " .. creds.endpoint .. ")")

  local ping_ok, username = pcall(require("sourcegraph.api").current_username)
  if not ping_ok then
    vim.health.error(tostring(username), {
      "Verify the endpoint is reachable and the token is valid",
    })
    return
  end
  vim.health.ok("authenticated as " .. username)
end

return M
