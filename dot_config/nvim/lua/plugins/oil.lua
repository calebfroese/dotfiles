return {
  {
    "stevearc/oil.nvim",
    opts = {
      columns = {
        "icon",
      },
      keymaps = {
        ["`"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
      },
    },
    dependencies = { "nvim-tree/nvim-web-devicons" },
  },
}
