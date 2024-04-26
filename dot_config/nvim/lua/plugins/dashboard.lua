return {
  {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",
    enabled = true,
    config = function()
      require("dashboard").setup({
        theme = "hyper",
        config = {
          header = {
            "",
          },
          center = {},
        },
      })
    end,
  },
}
