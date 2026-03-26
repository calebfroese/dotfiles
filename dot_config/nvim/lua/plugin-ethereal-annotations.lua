local M = {}

--- Default configuration for ethereal-annotations plugin
local config = {
  keymap_add = '"',
  keymap_delete = '<leader>d"',
  highlight_bg = "#3d2800",
  comment_fg = "#ff8800",
}

function M.setup(opts)
  opts = opts or {}
  for k, v in pairs(opts) do config[k] = v end

  local ethereal = require("ethereal-annotations")
  local ui = require("ethereal-annotations.ui")
  local store = require("ethereal-annotations.store")

  if opts.storage_path then store.set_storage_path(opts.storage_path) end
  ui.setup({ highlight_bg = config.highlight_bg, comment_fg = config.comment_fg })

  vim.keymap.set("x", config.keymap_add, function()
    local s, e = vim.fn.line("v"), vim.fn.line(".")
    if s > e then s, e = e, s end
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
    vim.schedule(function() ethereal.add(s, e) end)
  end, { desc = "Add annotation" })

  vim.keymap.set("n", config.keymap_delete, function()
    ethereal.delete(vim.fn.line("."))
  end, { desc = "Delete annotation" })

  vim.api.nvim_create_user_command("EtherealClear", ethereal.clear_file, {})
  vim.api.nvim_create_user_command("EtherealClearAll", ethereal.clear_all, {})

  local group = vim.api.nvim_create_augroup("Ethereal", { clear = true })
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function() vim.schedule(ethereal.refresh) end,
  })
  vim.api.nvim_create_autocmd({ "BufWritePost", "TextChanged", "TextChangedI" }, {
    group = group,
    callback = function() vim.schedule(ethereal.on_change) end,
  })
end

return M
