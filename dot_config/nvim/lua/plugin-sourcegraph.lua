local M = {}

function M.setup(opts)
  require("sourcegraph").setup(opts)

  vim.api.nvim_create_user_command("SourcegraphSearch", function()
    require("sourcegraph").search()
  end, { desc = "Live Sourcegraph code search" })
end

return M
