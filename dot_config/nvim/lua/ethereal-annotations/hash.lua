local M = {}

function M.compute(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr or 0, 0, -1, false)
  return M.compute_lines(lines)
end

function M.compute_lines(lines)
  return vim.fn.sha256(table.concat(lines, "\n"))
end

return M
