vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.wo.number = true
vim.wo.relativenumber = true
vim.wo.cursorline = true
vim.o.tabstop = 2
vim.o.softtabstop = 2
vim.o.shiftwidth = 2
vim.o.viminfo = "!,'1000,<50,s10,h"

vim.diagnostic.config({ virtual_text = true })

-- Setup copy/paste with iTerm. Requires "brew install reattach-to-user-namespace" on the MacOS host and relevant setup for iTerm
vim.o.clipboard = "unnamedplus"
vim.o.winborder = "rounded"
if vim.loop.os_uname().sysname == "Linux" then
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
end
