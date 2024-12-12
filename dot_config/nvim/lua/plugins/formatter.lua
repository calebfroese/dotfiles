local function buildifier()
  local util = require("formatter.util")
  return {
    exe = "buildifier",
    args = { "-mode", "fix" },
    stdin = true,
  }
end

return {
  {
    "mhartington/formatter.nvim",
    event = "VeryLazy",
    cmd = { "Format", "FormatWrite" },
    config = function()
      require("formatter").setup({
        logging = true,
        log_level = vim.log.levels.WARN,
        filetype = {
          -- Keep in sync with installed plugins/plugins.lua
          -- https://github.com/mhartington/formatter.nvim/tree/master/lua/formatter/filetypes
          go = require("formatter.filetypes.go").golines,
          lua = require("formatter.filetypes.lua").stylua,
          css = require("formatter.filetypes.css").prettier,
          typescript = require("formatter.filetypes.typescript").prettier,
          typescriptreact = require("formatter.filetypes.typescriptreact").prettier,
          javascript = require("formatter.filetypes.javascript").prettier,
          javascriptreact = require("formatter.filetypes.javascriptreact").prettier,
          html = require("formatter.filetypes.html").prettier,
          yaml = require("formatter.filetypes.yaml").prettier,
          json = require("formatter.filetypes.json").prettier,
          rust = require("formatter.filetypes.rust").rustfmt,
          proto = require("formatter.filetypes.proto").buf_format,
          sh = require("formatter.filetypes.sh").shfmt,
          cpp = require("formatter.filetypes.cpp").clangformat,
          bzl = buildifier,
        },
      })
    end,
  },
}
