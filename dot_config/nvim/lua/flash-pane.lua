-- Flash current window with orange overlay
local M = {}

function M.flash_current_window()
  -- Define orange highlight group
  vim.api.nvim_set_hl(0, 'FlashOrange', { bg = '#d75f00' })
  
  -- Get current window dimensions
  local win = vim.api.nvim_get_current_win()
  local width = vim.api.nvim_win_get_width(win)
  local height = vim.api.nvim_win_get_height(win)
  
  -- Create temporary buffer filled with spaces
  local buf = vim.api.nvim_create_buf(false, true)
  local lines = {}
  for i = 1, height do
    lines[i] = string.rep(' ', width)
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Create floating window overlay covering the current window
  local flash_win = vim.api.nvim_open_win(buf, false, {
    relative = 'win',
    win = win,
    row = 0,
    col = 0,
    width = width,
    height = height,
    style = 'minimal',
    focusable = false
  })
  
  -- Apply orange background to the overlay
  vim.wo[flash_win].winhl = 'Normal:FlashOrange'
  vim.cmd('redraw')
  
  -- Remove overlay after 100ms
  vim.defer_fn(function()
    if vim.api.nvim_win_is_valid(flash_win) then
      vim.api.nvim_win_close(flash_win, true)
    end
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end, 100)
end

-- Set up keybindings
vim.keymap.set('n', '<C-v>', M.flash_current_window, { 
  desc = 'Flash current window orange'
})

vim.keymap.set('n', '<leader>k', M.flash_current_window, { 
  desc = 'Flash current window orange'
})

return M
