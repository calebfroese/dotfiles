require("configuration")
require("keymaps")

local plugins = {
  require("plugin-nvim-treesitter"),
  require("plugin-oil"),
  require("plugin-fzf-lua"),
  require("plugin-fzf-lua-zoxide"),
  require("plugin-nvim-lspconfig"),
  require("plugin-vscode"),
  require("plugin-mini-completion"),
}

vim.pack.add(plugins)

for _, pkg in ipairs(plugins) do
  pkg.setup()
end


-- Absolutely hate that :help screws up whatever split panes I have
-- This treats :help similar to :e, opening in the active pane
vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("HelpInCurrentBuffer", { clear = true }),
  callback = function()
    if vim.bo.filetype ~= "help" or vim.b.help_opened then
      return
    end
    vim.b.help_opened = true
    vim.bo.buflisted = true

    local prev_win = vim.fn.win_getid(vim.fn.winnr("#"))
    local curr_win = vim.api.nvim_get_current_win()
    if prev_win ~= curr_win and vim.api.nvim_win_is_valid(prev_win) then
      vim.api.nvim_win_close(prev_win, false)
    end
  end,
})

-- Custom function to show tab pwd in tab labels
function _G.custom_tablabel()
  local s = ''
  for i = 1, vim.fn.tabpagenr('$') do
    local cwd = vim.fn.getcwd(-1, i)
    local fullpath = vim.fn.fnamemodify(cwd, ':~')  -- Full path from home
    s = s .. '%' .. i .. 'T'
    if i == vim.fn.tabpagenr() then
      s = s .. '%#TabLineSel#'
    else
      s = s .. '%#TabLine#'
    end
    s = s .. ' ' .. fullpath .. ' '
  end
  s = s .. '%#TabLineFill#%T'
  return s
end

-- Force custom tabline after all plugins load
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.opt.tabline = "%!v:lua.custom_tablabel()"
    vim.opt.showtabline = 2  -- Always show tabline

    -- Style active tab orange
    vim.api.nvim_set_hl(0, 'TabLineSel', { fg = '#ffffff', bg = '#ff8000', bold = true })
    vim.api.nvim_set_hl(0, 'TabLine', { fg = '#ffffff', bg = '#3c3c3c' })
    vim.api.nvim_set_hl(0, 'TabLineFill', { bg = '#1c1c1c' })
  end,
})
