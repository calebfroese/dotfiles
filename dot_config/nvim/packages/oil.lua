local M = {
  src = "https://github.com/stevearc/oil.nvim"
}

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

return M
