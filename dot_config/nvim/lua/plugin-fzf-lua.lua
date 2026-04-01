local M = { src = "https://github.com/ibhagwan/fzf-lua" }

function M.setup()
	require('fzf-lua').setup({
		fzf_colors = true,
		previewers = {
			builtin = {
				extensions = {
					["png"] = { "chafa", "{file}", "--format=symbols" },
					["jpg"] = { "chafa", "{file}", "--format=symbols" },
					["jpeg"] = { "chafa", "{file}", "--format=symbols" },
					["gif"] = { "chafa", "{file}", "--format=symbols" },
					["webp"] = { "chafa", "{file}", "--format=symbols" },
					["svg"] = { "chafa", "{file}", "--format=symbols" },
				},
			},
		},
		winopts = {
			height = 1,
			width = 1,
			preview = {
				delay = 0,
			},
		},
		map = {
			builtin = {
				false, -- do not inherit defaults
				["<M-Esc>"] = "hide",
				["?"] = "toggle-help",
				-- more often want to page through the preview than the results, so assign pagination motions to that instead
				["<C-d>"] = "preview-page-down",
				["<C-u>"] = "preview-page-up",
			},
		},
		grep = {
			prompt = "Grep ❯ ",
		},
	})
end

if ... then
	return M
else
	M.setup()
end
