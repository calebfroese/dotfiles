-- lua/plugins/oil.lua

require("oil").setup({
  columns = {
    "icon",
  },
  keymaps = {
    ["`"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
  },
})
