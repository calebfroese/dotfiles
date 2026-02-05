function _G.custom_statusline()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  local lsp_indicator
  if #clients > 0 then
    lsp_indicator = '%#LspActive#■%*'
  else
    lsp_indicator = '%#LspInactive#■%*'
  end
  return '%f %m%r%h%w%= ' .. lsp_indicator .. ' %l,%c '
end

vim.o.statusline = '%!v:lua.custom_statusline()'

local function set_lsp_highlights()
  vim.api.nvim_set_hl(0, 'LspActive', { fg = '#61afef' })
  vim.api.nvim_set_hl(0, 'LspInactive', { fg = '#5c6370' })
end

set_lsp_highlights()

vim.api.nvim_create_autocmd('ColorScheme', {
  callback = set_lsp_highlights,
})
