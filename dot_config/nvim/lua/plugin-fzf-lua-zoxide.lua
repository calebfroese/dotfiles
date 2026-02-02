local M = { src = "https://github.com/calebfroese/fzf-lua-zoxide" }

function M.setup()
	require('fzf-lua-zoxide').setup()
end

if ... then
	return M
else
	M.setup()
end
