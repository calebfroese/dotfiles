return {
  {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",
    enabled = false,
    config = function()
      require("dashboard").setup({
        theme = "hyper",
        config = {
          header = {
            "",
          },
          footer = {
            "",
          },
          center = {},
          shortcut = {},
          packages = { enable = false },
          project = {
            enable = true,
            limit = 8,
            action = function(arg)
              vim.cmd('cd ' .. arg)
              vim.cmd('Oil')
            end,
          },
        }
      })
    end,
},
}
