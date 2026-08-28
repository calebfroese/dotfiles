-- Thin GraphQL transport over `curl`. Provides blocking and non-blocking POSTs;
-- higher-level API modules build queries on top of these.

local credentials = require("sourcegraph.credentials")

local M = {}

local function fail(msg)
  error("sourcegraph.api: " .. msg, 0)
end

---@param creds { endpoint: string, token: string }
---@param query string
---@param variables table
---@return string[]
local function curl_args(creds, query, variables)
  return {
    "curl",
    "--silent",
    "--show-error",
    "--fail-with-body",
    "--max-time",
    "30",
    "-X",
    "POST",
    "-H",
    "Authorization: token " .. creds.token,
    "-H",
    "Content-Type: application/json",
    "--data",
    vim.json.encode({ query = query, variables = variables }),
    creds.endpoint .. "/.api/graphql",
  }
end

---Joined `message` fields from a GraphQL `errors` array, or the raw JSON if the
---shape is unexpected.
---@param errors table
---@return string
local function errors_message(errors)
  local messages = {}
  for _, e in ipairs(errors) do
    if type(e) == "table" and type(e.message) == "string" then
      messages[#messages + 1] = e.message
    end
  end
  if #messages == 0 then
    return vim.json.encode(errors)
  end
  return table.concat(messages, "; ")
end

---Interpret a completed curl result. Never raises.
---@param result { code: integer, stdout: string, stderr: string }
---@return boolean ok
---@return table|string data_or_error
local function parse(result)
  if result.code ~= 0 then
    return false, "request failed (curl exit " .. result.code .. "): " .. (result.stderr or "")
  end
  local ok, decoded = pcall(vim.json.decode, result.stdout)
  if not ok then
    return false, "response is not valid JSON: " .. decoded
  end
  if type(decoded) ~= "table" then
    return false, "response is not a JSON object"
  end
  -- GraphQL may return `errors` alongside partial `data` (e.g. a single file
  -- exceeding a size limit). Prefer usable data; only fail without it.
  if type(decoded.data) == "table" then
    return true, decoded.data
  end
  if decoded.errors then
    return false, "GraphQL error: " .. errors_message(decoded.errors)
  end
  return false, "response is missing 'data'"
end

---Blocking GraphQL POST. Fails hard on any error. For one-off calls (e.g. the
---healthcheck), never the UI hot path.
---@param query string
---@param variables table
---@return table data
function M.graphql(query, variables)
  local result = vim.system(curl_args(credentials.load(), query, variables), { text = true }):wait()
  local ok, data = parse(result)
  if not ok then
    fail(data)
  end
  return data
end

---Non-blocking GraphQL POST. `cb` runs on the main loop with `(true, data)` or
---`(false, message)`.
---@param query string
---@param variables table
---@param cb fun(ok: boolean, data_or_error: table|string)
function M.graphql_async(query, variables, cb)
  vim.system(curl_args(credentials.load(), query, variables), { text = true }, function(result)
    local ok, data = parse(result)
    vim.schedule(function()
      cb(ok, data)
    end)
  end)
end

return M
