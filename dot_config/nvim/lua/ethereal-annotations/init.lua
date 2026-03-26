local hash = require("ethereal-annotations.hash")
local store = require("ethereal-annotations.store")
local ui = require("ethereal-annotations.ui")

local M = {}
local buffer_hashes = {}

local function file_path() return vim.fn.expand("%:p") end
local function file_hash(bufnr) return hash.compute(bufnr or 0) end

function M.refresh(bufnr)
  bufnr = bufnr or 0
  local path = file_path()
  if path == "" then return end
  local h = file_hash(bufnr)
  buffer_hashes[bufnr] = h
  ui.render(bufnr, store.get(path, h))
end

function M.add(start_line, end_line)
  local path = file_path()
  if path == "" then return vim.notify("Cannot annotate unsaved buffer", vim.log.levels.WARN) end

  local h = file_hash(0)
  if ui.has_overlap(store.get(path, h), start_line, end_line) then
    return vim.notify("Overlapping annotations not allowed", vim.log.levels.WARN)
  end

  ui.prompt(function(comment)
    store.add(path, h, { start_line = start_line, end_line = end_line, comment = comment })
    buffer_hashes[0] = h
    M.refresh(0)
  end)
end

function M.delete(line)
  local path = file_path()
  if path == "" then return end

  local h = file_hash(0)
  local annotations, new, deleted = store.get(path, h), {}, false
  for _, a in ipairs(annotations) do
    if line >= a.start_line and line <= a.end_line then
      deleted = true
    else
      table.insert(new, a)
    end
  end

  if deleted then
    store.set(path, h, new)
    M.refresh(0)
  else
    vim.notify("No annotation at cursor", vim.log.levels.WARN)
  end
end

function M.clear_file()
  local path = file_path()
  if path == "" then return end
  store.clear(file_hash(0))
  buffer_hashes[0] = nil
  ui.clear(0)
end

function M.clear_all()
  store.clear_all()
  buffer_hashes = {}
  ui.clear(0)
end

function M.on_change(bufnr)
  bufnr = bufnr or 0
  local path = file_path()
  if path == "" then return end

  local current, previous = file_hash(bufnr), buffer_hashes[bufnr]
  if previous and previous ~= current then
    store.clear(previous)
    ui.clear(bufnr)
  end
  buffer_hashes[bufnr] = current
  M.refresh(bufnr)
end

return M
