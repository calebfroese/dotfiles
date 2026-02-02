require("keymaps")
require("configuration")
require("packages")

if vim.loop.os_uname().sysname == "Linux" then
  vim.g.clipboard = {
    name = 'OSC 52',
    copy = {
      ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
      ['"'] = require('vim.ui.clipboard.osc52').copy('"'),
      ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
    },
    paste = {
      ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
      ['"'] = require('vim.ui.clipboard.osc52').paste('"'),
      ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
    },
  }
end


-- Function to open help in the current buffer
local function open_help_in_current_buffer()
  if vim.bo.filetype == "help" and vim.b.already_opened == nil then
    vim.b.already_opened = true

    -- close the original window
    local original_win = vim.fn.win_getid(vim.fn.winnr("#"))
    local help_win = vim.api.nvim_get_current_win()
    if original_win ~= help_win then
      vim.api.nvim_win_close(original_win, false)
    end

    -- put the help buffer in the buffer list
    vim.bo.buflisted = true
  end
end

-- Open help in current buffer instead of horizontal split
vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("HelpReplaceWindow", { clear = false }),
  callback = open_help_in_current_buffer,
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
