local M = { src = "https://github.com/neovim/nvim-lspconfig" }

function M.setup()
	vim.lsp.config("terraformls", {
		filetypes = { "terraform", "terraform-vars", "tf" },
		root_markers = { "*.tfvars" },
		settings = {
			terraform = { ignoreSingleFileWarning = true },
		},
	})
	vim.lsp.enable("terraformls")
	vim.lsp.enable("gopls")

	-- Python
	vim.lsp.enable("pyright")
	vim.lsp.config("efm", {
		filetypes = { "python" },
		init_options = { documentFormatting = true, documentRangeFormatting = true },
		settings = {
			rootMarkers = { ".git/" },
			languages = {
				python = {
					{ formatCommand = "black --quiet -", formatStdin = true },
				},
			},
		},
	})
	vim.lsp.enable("efm")

	-- Lua
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

	-- TypeScript/JavaScript
	vim.lsp.enable("ts_ls")
end

if ... then
	return M
else
	M.setup()
end
