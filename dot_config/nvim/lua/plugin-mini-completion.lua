local M = { src = "https://github.com/nvim-mini/mini.completion" }

function M.setup()
	require('mini.completion').setup()
end

if ... then
	return M
else
	M.setup()
end
