-- Loads the Sourcegraph endpoint + access token from a JSON file. The path is
-- deliberately fixed per-machine (see config.credentials_path) so the same
-- Neovim config can be copied across machines while each keeps its own secret.
--
-- Fails hard on any problem: no fallbacks, no defaults.

local config = require("sourcegraph.config")

local M = {}

local function fail(msg)
  error("sourcegraph: " .. msg, 0)
end

local function read_file(path)
  local fd = io.open(path, "r")
  if not fd then
    fail("credentials file not found at " .. path)
  end
  local content = fd:read("*a")
  fd:close()
  if not content or content == "" then
    fail("credentials file is empty at " .. path)
  end
  return content
end

local function decode(content)
  local ok, decoded = pcall(vim.json.decode, content)
  if not ok then
    fail("credentials file is not valid JSON: " .. decoded)
  end
  if type(decoded) ~= "table" then
    fail("credentials file must be a JSON object")
  end
  return decoded
end

local function require_string(decoded, key)
  local value = decoded[key]
  if type(value) ~= "string" then
    fail("credentials field '" .. key .. "' must be a string")
  end
  if value == "" then
    fail("credentials field '" .. key .. "' must not be empty")
  end
  return value
end

---Load `{ endpoint, token }` from the configured credentials file. The endpoint
---has any trailing slashes stripped.
---@return { endpoint: string, token: string }
function M.load()
  local path = vim.fn.expand(config.get().credentials_path)
  local decoded = decode(read_file(path))
  return {
    endpoint = require_string(decoded, "endpoint"):gsub("/+$", ""),
    token = require_string(decoded, "token"),
  }
end

return M
