-- lua/plugins/copilot.lua

-- avante.nvim
require("avante").setup({
  provider = "copilot",
  mappings = {
    ask = "<C-a>",
    edit = "<C-e>",
  },
})

-- img-clip.nvim
require("img-clip").setup({})

-- render-markdown.nvim
require("render-markdown").setup({
  file_types = { "markdown", "Avante" },
})

-- copilot.vim loads automatically
