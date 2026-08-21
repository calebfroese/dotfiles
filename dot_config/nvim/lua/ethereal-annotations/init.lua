local store = require("ethereal-annotations.store")
local ui = require("ethereal-annotations.ui")
local resolver = require("ethereal-annotations.resolver")

local M = {}

-- Last-seen content hash per plain buffer, so on_change can tell a real edit
-- (hash changed -> annotations stale) from a no-op event.
local last_hash = {}

-- Combined-view buffers register their row map through here.
M.register_combined = resolver.register_combined

local function current_buf(bufnr)
  return (bufnr == nil or bufnr == 0) and vim.api.nvim_get_current_buf() or bufnr
end

---Repaint a buffer from stored annotations. Works for real files, single-file
---diff panes, and the combined Full Diff view alike, via its resolver.
function M.refresh(bufnr)
  bufnr = current_buf(bufnr)
  local r = resolver.for_buffer(bufnr)
  if not r then return end
  local items = {}
  for _, file in ipairs(r.files()) do
    for _, a in ipairs(store.get(file.path, file.hash)) do
      local rows = r.rows(file, a.start_line, a.end_line)
      if #rows > 0 then
        items[#items + 1] = { rows = rows, comment = a.comment }
      end
    end
  end
  ui.render(bufnr, items)
end

---Annotate the selected rows (1-based, inclusive).
function M.add(start_line, end_line)
  local bufnr = vim.api.nvim_get_current_buf()
  local r = resolver.for_buffer(bufnr)
  if not r then return vim.notify("Cannot annotate unsaved buffer", vim.log.levels.WARN) end

  local target, err = r.span(start_line - 1, end_line - 1)
  if not target then return vim.notify(err, vim.log.levels.WARN) end

  if ui.has_overlap(store.get(target.path, target.hash), target.start_line, target.end_line) then
    return vim.notify("Overlapping annotations not allowed", vim.log.levels.WARN)
  end

  ui.prompt(function(comment)
    store.add(target.path, target.hash, {
      start_line = target.start_line,
      end_line = target.end_line,
      comment = comment,
    })
    M.refresh(bufnr)
  end)
end

---Delete the annotation covering the given row (1-based).
function M.delete(line)
  local bufnr = vim.api.nvim_get_current_buf()
  local r = resolver.for_buffer(bufnr)
  if not r then return end

  local target = r.point(line - 1)
  if not target then return vim.notify("No annotation at cursor", vim.log.levels.WARN) end

  local kept, deleted = {}, false
  for _, a in ipairs(store.get(target.path, target.hash)) do
    if target.start_line >= a.start_line and target.start_line <= a.end_line then
      deleted = true
    else
      table.insert(kept, a)
    end
  end

  if deleted then
    store.set(target.path, target.hash, kept)
    M.refresh(bufnr)
  else
    vim.notify("No annotation at cursor", vim.log.levels.WARN)
  end
end

---Clear annotations for the file(s) backing the current buffer. In the combined
---Full Diff view this clears every file shown there.
function M.clear_file()
  local bufnr = vim.api.nvim_get_current_buf()
  local r = resolver.for_buffer(bufnr)
  if not r then return end
  for _, file in ipairs(r.files()) do
    store.clear(file.hash)
  end
  ui.clear(bufnr)
end

function M.clear_all()
  store.clear_all()
  ui.clear(0)
end

---React to a live edit: if the buffer's content hash changed, its old
---annotations no longer apply, so drop them. Diff panes are static snapshots
---and never invalidate.
function M.on_change(bufnr)
  bufnr = current_buf(bufnr)
  if resolver.is_snapshot(bufnr) then return end
  local r = resolver.for_buffer(bufnr)
  if not r then return end
  -- A plain buffer has exactly one backing file; its hash tracks the content.
  local file = r.files()[1]
  local previous = last_hash[bufnr]
  if previous and previous ~= file.hash then
    store.clear(previous)
    ui.clear(bufnr)
  end
  last_hash[bufnr] = file.hash
  M.refresh(bufnr)
end

return M
