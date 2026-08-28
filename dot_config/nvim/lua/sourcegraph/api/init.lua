-- Public surface of the Sourcegraph API layer.

local M = {}

M.search = require("sourcegraph.api.search").search
M.search_async = require("sourcegraph.api.search").search_async
M.current_username = require("sourcegraph.api.user").current_username

return M
