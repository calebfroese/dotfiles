-- Setup copy/paste with iTerm. Requires "brew install reattach-to-user-namespace"
vim.o.clipboard = "unnamedplus"
-- Various keybindings
vim.g.mapleader = " "
vim.g.maplocalleader = " "
-- Tab and shift tab indent/unindent capability
vim.keymap.set("i", "<S-Tab>", "<C-\\><C-N><<<C-\\><C-N>^i")
vim.keymap.set("v", "<S-Tab>", "<gv")
vim.keymap.set("v", "<Tab>", ">gv")



