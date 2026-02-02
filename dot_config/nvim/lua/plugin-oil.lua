local M = { src = "https://github.com/stevearc/oil.nvim" }

function M.setup()
	require("oil").setup({
		columns = {
			"icon",
		},
		keymaps = {
			["`"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
		},
	})
end

if ... then
	return M
else
	M.setup()
end
