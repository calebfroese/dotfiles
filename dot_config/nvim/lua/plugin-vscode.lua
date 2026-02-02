local M = { src = "https://github.com/Mofiqul/vscode.nvim" }

function M.setup()
	require("vscode").setup({ color_overrides = { vscBack = 'NONE' }})
	vim.cmd.colorscheme "vscode"
end

if ... then
	return M
else
	M.setup()
end
