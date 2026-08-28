-- Sourcegraph code search.

local client = require("sourcegraph.api.client")

local M = {}

local function fail(msg)
  error("sourcegraph.api.search: " .. msg, 0)
end

-- KEYWORD patternType mirrors the Sourcegraph web UI: unquoted terms are AND'd,
-- "quoted text" is an exact phrase. Passed as a variable (the server rejects the
-- inline enum literal).
local QUERY = [[
query Search($query: String!, $patternType: SearchPatternType!) {
  search(query: $query, version: V3, patternType: $patternType) {
    results {
      matchCount
      limitHit
      results {
        __typename
        ... on FileMatch {
          repository { name }
          file { path url content }
          lineMatches { preview lineNumber offsetAndLengths }
        }
      }
    }
  }
}
]]

---@class sourcegraph.LineMatch
---@field preview string
---@field lineNumber integer
---@field offsetAndLengths integer[][]

---@class sourcegraph.FileMatch
---@field repository string
---@field path string
---@field url string
---@field content string
---@field lineMatches sourcegraph.LineMatch[]

---@class sourcegraph.SearchResult
---@field matchCount integer
---@field limitHit boolean
---@field matches sourcegraph.FileMatch[]

---Shape the GraphQL `data` into a SearchResult, or an error message.
---@param data table
---@return boolean ok
---@return sourcegraph.SearchResult|string result_or_error
local function transform(data)
  -- Nested fields may be JSON `null` (decoded as vim.NIL, a truthy userdata)
  -- when the server returns partial data alongside an error; guard with types.
  local search = type(data.search) == "table" and data.search or nil
  local results = search and type(search.results) == "table" and search.results or nil
  if not results then
    return false, "no search results (the server may have returned only errors)"
  end

  local matches = {}
  for _, r in ipairs(results.results or {}) do
    if r.__typename == "FileMatch" then
      matches[#matches + 1] = {
        repository = r.repository.name,
        path = r.file.path,
        url = r.file.url,
        content = r.file.content or "",
        lineMatches = r.lineMatches or {},
      }
    end
  end

  return true, {
    matchCount = results.matchCount,
    limitHit = results.limitHit,
    matches = matches,
  }
end

---Search synchronously. Blocks; fails hard on any error.
---@param query string A Sourcegraph search query string
---@return sourcegraph.SearchResult
function M.search(query)
  if type(query) ~= "string" or query == "" then
    fail("query must be a non-empty string")
  end
  local ok, result = transform(client.graphql(QUERY, { query = query, patternType = "keyword" }))
  if not ok then
    fail(result)
  end
  return result
end

---Search asynchronously; never blocks the event loop. `cb` runs on the main loop
---with `(true, SearchResult)` or `(false, message)`.
---@param query string
---@param cb fun(ok: boolean, result_or_error: sourcegraph.SearchResult|string)
function M.search_async(query, cb)
  if type(query) ~= "string" or query == "" then
    return cb(false, "query must be a non-empty string")
  end
  client.graphql_async(QUERY, { query = query, patternType = "keyword" }, function(ok, data)
    if not ok then
      return cb(false, data)
    end
    cb(transform(data))
  end)
end

return M
