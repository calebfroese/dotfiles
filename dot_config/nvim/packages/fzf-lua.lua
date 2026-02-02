local M = {
	src = "https://github.com/ibhagwan/fzf-lua"
}

function M.setup()
	require('fzf-lua').setup({
		fzf_colors = true,
		winopts = {
			height = 1,
			width = 1,
			preview = {
				delay = 0,
			},
		},
		map = {
			builtin = {
				false, -- do not inherit defaults
				["<M-Esc>"] = "hide",
				["?"] = "toggle-help",
				-- more often want to page through the preview than the results, so assign pagination motions to that instead
				["<C-d>"] = "preview-page-down",
				["<C-u>"] = "preview-page-up",
			},
		},
		grep = {
			prompt = "Grep ❯ ",
		},
	})

	vim.keymap.set("n", "<leader><leader>", "<cmd>FzfLua resume<cr>", { desc = "Resume search" })
	vim.keymap.set("n", "<leader>f", function()
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

end

return M
