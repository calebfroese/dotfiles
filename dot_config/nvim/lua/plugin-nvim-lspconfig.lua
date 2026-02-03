local M = { src = "https://github.com/neovim/nvim-lspconfig" }

function M.setup()
	vim.lsp.enable("terraformls")
	vim.lsp.config("terraformls", {
		root_dir = function(fname)
			if type(fname) == "number" then
				fname = vim.api.nvim_buf_get_name(fname)
			end
			local root_files = vim.fs.find({ "BUILD.bazel" }, { path = fname, upward = true, limit = 1 })
			if root_files[1] then
				return vim.fs.dirname(root_files[1])
			end
			print("nope")
			-- local git_root = vim.fs.find(".git", { path = fname, upward = true, limit = 1 })
			-- if git_root[1] then
			-- 	return vim.fs.dirname(git_root[1])
			-- end
		end,
	})
	vim.lsp.enable("gopls")

	-- Python
	vim.lsp.enable({ "pyright", "efm" })
	vim.lsp.config("efm", {
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
end

if ... then
	return M
else
	M.setup()
end
