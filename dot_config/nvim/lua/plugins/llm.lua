-- lua/plugins/llm.lua

require("codecompanion").setup({
  strategies = {
    chat = {
      adapter = "copilot",
    },
    inline = {
      adapter = "copilot",
    },
  },
  opts = {
    log_level = "DEBUG",
  },
})
