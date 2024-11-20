require("keymaps")
require("configuration")

-- Bootstrap LazyVim
require("config.lazy")

vim.wo.number = true
vim.wo.relativenumber = true

vim.o.tabstop = 2
vim.o.softtabstop = 2
vim.o.shiftwidth = 2
-- Setup copy/paste with iTerm. Requires "brew install reattach-to-user-namespace" on the MacOS host and relevant setup for iTerm
vim.o.clipboard = "unnamedplus"

vim.g.clipboard = {
  name = 'OSC 52',
  copy = {
    ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
    ['"'] = require('vim.ui.clipboard.osc52').copy('"'),
    ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
  },
  paste = {
    ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
    ['"'] = require('vim.ui.clipboard.osc52').paste('"'),
    ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
  },
}

-- Open help in current buffer instead of horizontal split
vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("HelpReplaceWindow", { clear = false }),
  callback = function()
    if vim.bo.filetype == "help" and vim.b.already_opened == nil then
      vim.b.already_opened = true

      -- close the original window
      local original_win = vim.fn.win_getid(vim.fn.winnr("#"))
      local help_win = vim.api.nvim_get_current_win()
      if original_win ~= help_win then
        vim.api.nvim_win_close(original_win, false)
      end

      -- put the help buffer in the buffer list
      vim.bo.buflisted = true
    end
  end,
})
