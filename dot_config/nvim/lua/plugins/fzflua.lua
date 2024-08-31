return {
  {
    "ibhagwan/fzf-lua",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("fzf-lua").setup({})
    end,
  },
  {
    "calebfroese/fzf-lua-zoxide",
    dependencies = { "ibhagwan/fzf-lua" },
    config = function()
      require("fzf-lua-zoxide").setup()
    end,
  },
}
