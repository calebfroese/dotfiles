local packages = {
	require("packages/vscode"),
	require("packages/oil"),
	require("packages/fzf-lua"),
	require("packages/fzf-lua-zoxide"),
	require("packages/nvim-lspconfig"),
}
vim.pack.add(packages)
for _, pkg in ipairs(packages) do
	pkg.setup()
end

