local M = { src = "https://github.com/neovim/nvim-lspconfig" }

function M.setup()
	vim.lsp.enable("lua_ls")
	vim.lsp.config("lua_ls", {
		settings = {
    Lua = {
      diagnostics = {
        globals = { 'vim', 'require' },
      },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
      },
      telemetry = { enable = false },
    },
    },
	})
end

if ... then
	return M
else
	M.setup()
end
