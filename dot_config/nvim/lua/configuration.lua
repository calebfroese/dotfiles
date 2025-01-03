vim.o.number = true
vim.o.relativenumber = true

-- This only works for Go. Should expand this to other langs and make a plugin out of it.
function RemoveUnusedImports()
  local diagnostics = vim.diagnostic.get(0)
  local lines_removed = 0
  for _, diagnostic in ipairs(diagnostics) do
    if diagnostic.code == "UnusedImport" then
      local start_line = diagnostic.lnum - lines_removed
      local end_line = diagnostic.end_lnum - lines_removed + 1
      vim.api.nvim_buf_set_lines(0, start_line, end_line, false, {})
      lines_removed = lines_removed + end_line - start_line
    end
  end
end

function OpenDiagnosticPopup()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  if vim.diagnostic.get(0, {lnum = lnum}) then
    vim.diagnostic.open_float()
  end
end

-- The nvim default lsp shows diagnostics in virtual text, but when those diagnostics
-- are long they are truncated. This opens a floating window after a brief delay.
vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
    OpenDiagnosticPopup()
  end,
})

-- Add a binding to leader + d to open diagnostics
vim.api.nvim_set_keymap("n", "<leader>d", ":lua OpenDiagnosticPopup()<CR>", {noremap = true, silent = true})
