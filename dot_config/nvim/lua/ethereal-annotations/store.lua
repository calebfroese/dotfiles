local M = {}

local storage_path

function M.get_storage_path()
  storage_path = storage_path or vim.fn.stdpath("data") .. "/ethereal-annotations"
  return storage_path
end

function M.set_storage_path(path)
  storage_path = path
end

local function annotation_path(hash)
  return M.get_storage_path() .. "/" .. hash .. ".txt"
end

local function parse_file(path)
  if vim.fn.filereadable(path) == 0 then return nil, {} end
  local lines = vim.fn.readfile(path)
  if #lines == 0 then return nil, {} end

  local source, annotations = lines[1], {}
  for i = 2, #lines do
    local range, comment = lines[i]:match("^([^:]+):(.*)$")
    if range then
      local s, e = range:match("^(%d+)-(%d+)$")
      if not s then s, e = range:match("^(%d+)$"), range:match("^(%d+)$") end
      if s then
        table.insert(annotations, { start_line = tonumber(s), end_line = tonumber(e), comment = comment })
      end
    end
  end
  return source, annotations
end

local function write_file(hash, source, annotations)
  local dir = M.get_storage_path()
  if vim.fn.isdirectory(dir) == 0 then vim.fn.mkdir(dir, "p") end

  local lines = { source }
  for _, a in ipairs(annotations) do
    local range = a.start_line == a.end_line and tostring(a.start_line) or (a.start_line .. "-" .. a.end_line)
    table.insert(lines, range .. ":" .. a.comment)
  end
  vim.fn.writefile(lines, annotation_path(hash))
end

function M.get(file_path, hash)
  local source, annotations = parse_file(annotation_path(hash))
  return source == file_path and annotations or {}
end

function M.set(file_path, hash, annotations)
  local path = annotation_path(hash)
  if #annotations == 0 then
    if vim.fn.filereadable(path) == 1 then vim.fn.delete(path) end
  else
    write_file(hash, file_path, annotations)
  end
end

function M.add(file_path, hash, annotation)
  local annotations = M.get(file_path, hash)
  table.insert(annotations, annotation)
  M.set(file_path, hash, annotations)
end

function M.clear(hash)
  local path = annotation_path(hash)
  if vim.fn.filereadable(path) == 1 then vim.fn.delete(path) end
end

function M.clear_all()
  for _, f in ipairs(vim.fn.glob(M.get_storage_path() .. "/*.txt", false, true)) do
    vim.fn.delete(f)
  end
end

return M
