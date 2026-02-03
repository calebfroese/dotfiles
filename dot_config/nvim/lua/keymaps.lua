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
