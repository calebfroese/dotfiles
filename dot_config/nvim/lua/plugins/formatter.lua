return {
  {
    "mhartington/formatter.nvim",
    event = "VeryLazy",
    cmd = { "Format", "FormatWrite" },
    config = function()
      require('formatter').setup({
        logging = true,
        log_level = vim.log.levels.WARN,
        filetype = {
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
        },
      })
    end,
  },
}
