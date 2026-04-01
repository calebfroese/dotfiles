local M = { src = "https://github.com/nvim-mini/mini.icons" }

function M.setup()
	require('mini.icons').setup()
	MiniIcons.mock_nvim_web_devicons()
end

if ... then
	return M
else
	M.setup()
end
