vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.wo.number = true
vim.wo.relativenumber = true
vim.wo.cursorline = true
vim.o.tabstop = 2
vim.o.softtabstop = 2
vim.o.shiftwidth = 2
vim.o.viminfo = "!,'1000,<50,s10,h"

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

vim.keymap.set("n", "<leader><leader>", "<cmd>FzfLua resume<cr>", { desc = "Resume search" })
vim.keymap.set("n", "<leader>D", function()
	require("fzf-lua-zoxide").open({
		callback = function(dir)
			vim.cmd("e " .. dir)
		end,
		setcwd = false,
	})
end, { desc = "Open Directory" })

vim.keymap.set("n", "<leader>F", function()
	require("fzf-lua-zoxide").open({
		callback = function(_)
			vim.cmd("e .")
		end,
	})
end, { desc = "Change Directory" })

vim.keymap.set("n", "<leader>s:", "<cmd>FzfLua command_history<cr>", { desc = "Command History" })
vim.keymap.set("n", "<leader>sb", "<cmd>FzfLua buffers<cr>", { desc = "Buffers" })
vim.keymap.set("n", "<leader>sB", "<cmd>FzfLua lines<cr>", { desc = "Buffers Contents" })
vim.keymap.set("n", "<leader>sg", "<cmd>FzfLua grep_project<cr>", { desc = "Grep Project" })
vim.keymap.set("n", "<leader>sf", "<cmd>FzfLua files<cr>", { desc = "File (cwd)" })
vim.keymap.set("n", "<leader>sr", "<cmd>FzfLua oldfiles<cr>", { desc = "File (recent)" })
vim.keymap.set("n", "<leader>sx", "<cmd>FzfLua diagnostics_document<cr>", { desc = "Diagnostics (buffer)" })
vim.keymap.set("n", "<leader>sX", "<cmd>FzfLua diagnostics_workspace<cr>", { desc = "Diagnostics (cwd)" })
vim.keymap.set("n", "<leader>sl", "<cmd>FzfLua lsp_references<cr>", { desc = "References" })
