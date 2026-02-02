local M = { src = "https://github.com/nvim-treesitter/nvim-treesitter" }

function M.setup()
	require('nvim-treesitter').setup()
	require('nvim-treesitter').install({
		"bash", "go", "html", "javascript", "java", "json", "lua", "markdown",
		"markdown_inline", "python", "query", "regex", "tsx", "terraform",
		"typescript", "vim", "yaml",
	})

	local ignore_filetype = {
		"checkhealth",
		"oil",
	}

	local group = vim.api.nvim_create_augroup("TreesitterSetup", { clear = true })

	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		desc = "Enable TreeSitter highlighting and indentation",
		callback = function(ev)
			local ft = ev.match

			if vim.tbl_contains(ignore_filetype, ft) then
				return
			end

			local lang = vim.treesitter.language.get_lang(ft) or ft
			local buf = ev.buf
			pcall(vim.treesitter.start, buf, lang)

			vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
			vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
		end,
	})
end

if ... then
	return M
else
	M.setup()
end
