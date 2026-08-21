require("statusline")

vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

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

-- Blank diff filler rows instead of the noisy "----" fill.
vim.o.fillchars = "diff: "

-- Softer, greyer diff backgrounds (the theme's defaults are too strong).
-- Reapplied on colorscheme change since themes set these on load.
local function soften_diff_colors()
  vim.api.nvim_set_hl(0, "DiffAdd", { bg = "#1f2a1c" })
  vim.api.nvim_set_hl(0, "DiffChange", { bg = "#291d1d" })
  vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#291d1d" })
  vim.api.nvim_set_hl(0, "DiffText", { bg = "#3a2624" })
end
soften_diff_colors()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("SoftDiffColors", { clear = true }),
  callback = soften_diff_colors,
})
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
