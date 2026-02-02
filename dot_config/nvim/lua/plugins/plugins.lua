-- lua/plugins/plugins.lua

-- undotree
vim.cmd("source ~/.config/nvim/lua/plugins/undotree.vim")

-- nvim-autopairs
require("nvim-autopairs").setup({})

-- nvim-treesitter
require("nvim-treesitter.configs").setup({
  sync_install = false,
  highlight = { enable = true },
  indent = { enable = true },
  auto_install = true,
  ignore_install = {},
  modules = {},
  ensure_installed = {
    "bash", "go", "html", "javascript", "java", "json", "lua", "markdown",
    "markdown_inline", "python", "query", "regex", "tsx", "terraform",
    "typescript", "vim", "yaml",
  },
})

-- mason and deps
require("neodev").setup()
require("mason").setup()
require("mason-nvim-dap").setup()
require("mason-lspconfig").setup()

-- Auto install mason packages
local packages = {
  -- LSP
  "lua-language-server",
  "pyright",
  "terraform-ls",
  "typescript-language-server",
  "rust-analyzer",
  -- DAP
  "js-debug-adapter",
  -- Formatter
  "stylua",
  "prettier",
  "golines",
  "buf",
  "shfmt",
}
local str = ""
for _, v in pairs(packages) do
  if not require("mason-registry").is_installed(v) then
    str = str .. " " .. v
  end
end
if string.len(str) > 0 then
  vim.cmd("MasonInstall " .. str)
end

-- vscode.nvim (Theme)
require("vscode").setup({
  color_overrides = {
    vscBack = 'NONE',
  },
})
vim.cmd.colorscheme("vscode")

-- Custom theme overrides
local hl = vim.api.nvim_set_hl
hl(0, "CursorLineNr", { fg = "#ff8000", bold = true })
hl(0, 'CursorLine', { bg = "#202020" })

-- blame.nvim
require("blame").setup()

-- nvim-lint
require("lint").linters_by_ft = {
  typescript = { "eslint_d" },
}

-- Comment.nvim
require("Comment").setup()
