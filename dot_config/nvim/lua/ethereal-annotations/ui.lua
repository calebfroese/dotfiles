local M = {}

local ns = vim.api.nvim_create_namespace("ethereal")
local hl_bg, hl_fg

function M.setup(opts)
  hl_bg = opts.highlight_bg or "#3d2800"
  hl_fg = opts.comment_fg or "#ff8800"
  vim.api.nvim_set_hl(0, "EtherealHighlight", { bg = hl_bg })
  vim.api.nvim_set_hl(0, "EtherealComment", { fg = hl_fg, bg = hl_bg, italic = true })
  vim.api.nvim_set_hl(0, "EtherealSign", { fg = hl_fg })
end

function M.clear(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr or 0, ns, 0, -1)
end

-- Full-line highlight on a single 0-based row. line_hl_group paints the line
-- when focused; the sign stays visible even in non-current diff windows.
local function highlight_row(bufnr, row0)
  vim.api.nvim_buf_set_extmark(bufnr, ns, row0, 0, {
    line_hl_group = "EtherealHighlight",
    sign_text = "▌",
    sign_hl_group = "EtherealSign",
    hl_eol = true,
    priority = 200,
  })
end

local function comment_above(bufnr, row0, comment)
  vim.api.nvim_buf_set_extmark(bufnr, ns, row0, 0, {
    virt_lines_above = true,
    virt_lines = { { { comment, "EtherealComment" } } },
    priority = 200,
  })
end

---Repaint all annotations. Each item is a set of 0-based buffer rows to
---highlight plus the comment shown above the first row. Callers translate file
---lines to rows, so this is uniform across real files and diff views.
---@param items { rows: integer[], comment: string }[]
function M.render(bufnr, items)
  bufnr = bufnr or 0
  M.clear(bufnr)
  for _, it in ipairs(items) do
    for _, row0 in ipairs(it.rows) do
      highlight_row(bufnr, row0)
    end
    if it.rows[1] then
      comment_above(bufnr, it.rows[1], it.comment)
    end
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
