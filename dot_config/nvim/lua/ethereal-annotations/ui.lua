local M = {}

local ns = vim.api.nvim_create_namespace("ethereal")
local hl_bg, hl_fg

function M.setup(opts)
  hl_bg = opts.highlight_bg or "#3d2800"
  hl_fg = opts.comment_fg or "#ff8800"
  vim.api.nvim_set_hl(0, "EtherealHighlight", { bg = hl_bg })
  vim.api.nvim_set_hl(0, "EtherealComment", { fg = hl_fg, bg = hl_bg, italic = true })
end

function M.clear(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr or 0, ns, 0, -1)
end

function M.render(bufnr, annotations)
  bufnr = bufnr or 0
  M.clear(bufnr)
  for _, a in ipairs(annotations) do
    for line = a.start_line - 1, a.end_line - 1 do
      vim.api.nvim_buf_add_highlight(bufnr, ns, "EtherealHighlight", line, 0, -1)
    end
    vim.api.nvim_buf_set_extmark(bufnr, ns, a.start_line - 1, 0, {
      virt_lines_above = true,
      virt_lines = { { { a.comment, "EtherealComment" } } },
    })
  end
end

function M.has_overlap(annotations, start_line, end_line)
  for _, a in ipairs(annotations) do
    if not (end_line < a.start_line or start_line > a.end_line) then return true end
  end
  return false
end

function M.prompt(callback)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype, vim.bo[buf].bufhidden = "nofile", "wipe"

  local width = vim.api.nvim_win_get_width(0)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "cursor", width = width, height = 1, row = 1, col = 0,
    style = "minimal", border = "rounded",
  })

  vim.cmd("startinsert")

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    buffer = buf,
    callback = function()
      vim.api.nvim_win_set_height(win, math.max(1, vim.api.nvim_buf_line_count(buf)))
    end,
  })

  local function close()
    vim.api.nvim_win_close(win, true)
    vim.cmd("stopinsert")
  end

  local function submit()
    local text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), " "):gsub("^%s+", ""):gsub("%s+$", "")
    close()
    if text ~= "" then callback(text) end
  end

  vim.keymap.set("n", "<Esc>", close, { buffer = buf })
  vim.keymap.set("n", "q", close, { buffer = buf })
  vim.keymap.set({ "n", "i" }, "<CR>", submit, { buffer = buf })
  vim.keymap.set("i", "<C-j>", "<CR>", { buffer = buf, remap = false })
end

return M
