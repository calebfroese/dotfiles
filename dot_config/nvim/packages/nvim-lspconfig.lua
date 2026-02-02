local M = {
  src = "https://github.com/neovim/nvim-lspconfig"
}

function M.setup()
	vim.lsp.enable("lua_ls")
end

return M
