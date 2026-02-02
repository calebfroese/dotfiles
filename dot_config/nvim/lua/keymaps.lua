vim.diagnostic.config({
	virtual_text = true
})
vim.keymap.set("n", "<leader>d", function()
	vim.diagnostic.open_float({ focus = true })
end)
-- Tab/shift+tab to indent/unindent
vim.keymap.set("i", "<S-Tab>", "<C-\\><C-N><<<C-\\><C-N>^i")
vim.keymap.set("v", "<S-Tab>", "<gv")
vim.keymap.set("v", "<Tab>", ">gv")

-- Backslash to open netrw
vim.keymap.set("n", "\\", function()
	vim.cmd("Oil")
end)

-- Toggle between cpp .h and .cpp files
vim.keymap.set("n", "<C-c>", function()
	local file = vim.fn.expand("%:r")
	local ext = vim.fn.expand("%:e")
	if ext == "cpp" then
		vim.cmd("e " .. file .. ".h")
	elseif ext == "h" then
		vim.cmd("e " .. file .. ".cpp")
	end
end)

-- Map tab navigation keys (works both inside and outside tmux)
vim.keymap.set("n", "<Tab>", ":tabnext<CR>")
vim.keymap.set("n", "<S-Tab>", ":tabprevious<CR>")
vim.keymap.set("n", "<C-Tab>", ":tabnext<CR>")
vim.keymap.set("n", "<C-S-Tab>", ":tabprevious<CR>")

-- Map Ctrl+n to create new tab
vim.keymap.set("n", "<C-n>", ":tabnew<CR>")

vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)
vim.keymap.set("n", "<leader>q", ":q<CR>")
vim.keymap.set("n", "<C-X>", ":update<CR> :source<CR>")
