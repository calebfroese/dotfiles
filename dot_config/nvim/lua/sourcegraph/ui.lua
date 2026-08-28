-- Live Sourcegraph code search in an fzf-lua picker.
--
-- The fzf prompt *is* the Sourcegraph query. Each keystroke (debounced) reruns
-- the search asynchronously and streams results styled like fzf-lua's grep:
-- file icon, magenta path, green line number, treesitter-highlighted code with
-- the matched span in red. <CR> opens the file locally, <C-o> opens the
-- Sourcegraph URL, <C-y> yanks it, <C-e> raises the query's result cap.

local api = require("sourcegraph.api")
local config = require("sourcegraph.config")
local credentials = require("sourcegraph.credentials")

local M = {}

local function fail(msg)
  error("sourcegraph.ui: " .. msg, 0)
end

local function fzf()
  local ok, mod = pcall(require, "fzf-lua")
  if not ok then
    fail("fzf-lua is required")
  end
  return mod
end

--- Entry formatting -------------------------------------------------------

---Nerd-font file icon for a path, ANSI-coloured like fzf-lua's file pickers.
---@param path string
---@return string
local function devicon(path)
  local devicons = require("fzf-lua.devicons")
  devicons.load()
  local icon, color = devicons.get_devicon(path)
  if icon == "" then
    return ""
  end
  return color and fzf().utils.ansi_from_rgb(color, icon) or icon
end

---Strip ANSI so lookups match what fzf returns (it drops colour from --ansi
---output when reporting the selected entry).
---@param entry string
---@return string
local function strip(entry)
  return fzf().utils.strip_ansi_coloring(entry)
end

---Wrap the matched byte spans of `preview` in red-bold ANSI, like ripgrep's
---default match highlight. `spans` are Sourcegraph's offsetAndLengths: 0-based
---byte offset + length pairs, assumed sorted and non-overlapping.
---@param preview string
---@param spans integer[][]
---@return string
local function highlight_matches(preview, spans)
  local ansi = fzf().utils.ansi_codes
  local out, cursor = {}, 0
  for _, span in ipairs(spans) do
    local off, len = span[1], span[2]
    if off and len and off >= cursor and off + len <= #preview then
      out[#out + 1] = preview:sub(cursor + 1, off)
      out[#out + 1] = ansi.red(ansi.bold(preview:sub(off + 1, off + len)))
      cursor = off + len
    end
  end
  out[#out + 1] = preview:sub(cursor + 1)
  return table.concat(out)
end

---Format one line match as `<icon><nbsp><path>:<line>: <preview>`, matching
---fzf-lua's grep entries.
---@param icon string Pre-rendered coloured icon (may be empty)
---@param path string
---@param lm sourcegraph.LineMatch
---@return string
local function format_entry(icon, path, lm)
  local ansi = fzf().utils.ansi_codes
  local preview = (lm.preview or ""):gsub("%s+$", "")
  return string.format(
    "%s%s%s:%s: %s",
    icon,
    fzf().utils.nbsp,
    ansi.magenta(path),
    ansi.green(tostring(lm.lineNumber + 1)),
    highlight_matches(preview, lm.offsetAndLengths or {})
  )
end

---Format a path-only match (no line matches, e.g. from a `file:` filter) as
---`<icon><nbsp><path>`, mirroring the web UI showing filename hits.
---@param icon string
---@param path string
---@return string
local function format_path_entry(icon, path)
  return icon .. fzf().utils.nbsp .. fzf().utils.ansi_codes.magenta(path)
end

---Parse a rendered entry into `path, lnum, text, filetype` for fzf-lua's in-list
---treesitter highlighter. The icon/nbsp prefix is optional.
---@param line string
---@return string?, string?, string?, string?
local function ts_line_parser(line)
  local rest = line:match(fzf().utils.nbsp .. "(.*)") or line
  local filepath, lnum, text = rest:match("^(.-):(%d+): (.*)$")
  if not filepath then
    return nil
  end
  local ft = vim.filetype.match({ filename = require("fzf-lua.path").tail(filepath) })
  return filepath, lnum, text, ft
end

--- Query helpers ----------------------------------------------------------

-- Filters that are part of the default scaffold; a query containing only these
-- is not worth searching for on its own.
local SCAFFOLD_FILTERS = { count = true, repo = true }

---Whether a query is worth sending: it has either enough free-text (non-filter)
---content, or a filter the user added beyond the default `count:`/`repo:` scope
---(e.g. `file:`, `lang:`). This lets `file:foo` search on its own while a bare
---scope does not.
---@param query string
---@param min_len integer Minimum free-text length to trigger on content alone.
---@return boolean
local function should_search(query, min_len)
  local free_text = {}
  local has_extra_filter = false
  for token in query:gmatch("%S+") do
    local key = token:match("^%-?(%w[%w_]*):")
    if key then
      if not SCAFFOLD_FILTERS[key] then
        has_extra_filter = true
      end
    else
      free_text[#free_text + 1] = token
    end
  end
  return has_extra_filter or #table.concat(free_text, " ") >= min_len
end

---The `count:` value in a query, or 0 if absent.
---@param query string
---@return integer
local function count_of(query)
  return tonumber(query:match("%f[%w]count:(%d+)")) or 0
end

---`query` with its `count:` raised by `increment` (prepended if absent).
---@param query string
---@param increment integer
---@return string
local function raise_count(query, increment)
  local raised = count_of(query) + increment
  if query:match("%f[%w]count:%d+") then
    return (query:gsub("%f[%w]count:%d+", "count:" .. raised, 1))
  end
  return "count:" .. raised .. " " .. query
end

--- Actions ----------------------------------------------------------------

---Open a match at its matched line, using the local checkout resolved by
---`config.repo_local_path`. Notifies (rather than errors) when unavailable.
---@param match sourcegraph.FileMatch
---@param line integer 1-based
local function open_local(match, line)
  local path = config.get().repo_local_path(match.repository, match.path)
  if not path then
    return vim.notify("sourcegraph: no local checkout for " .. match.repository, vim.log.levels.WARN)
  end
  if vim.fn.filereadable(path) ~= 1 then
    return vim.notify("sourcegraph: file not found locally: " .. path, vim.log.levels.WARN)
  end
  vim.cmd.edit(vim.fn.fnameescape(path))
  pcall(vim.api.nvim_win_set_cursor, 0, { line, 0 })
  vim.cmd("normal! zz")
end

--- Previewer --------------------------------------------------------------

---Builtin previewer rendering a match's file content (fetched with the search)
---centred on the matched line, syntax-highlighted. `index`/`lineno` are shared
---upvalues, keyed by the stripped entry and refreshed on every query.
---@param index table<string, sourcegraph.FileMatch>
---@param lineno table<string, integer>
local function make_previewer(index, lineno)
  local Previewer = require("fzf-lua.previewer.builtin").base:extend()

  function Previewer:new(o, opts, fzf_win)
    Previewer.super.new(self, o, opts, fzf_win)
    setmetatable(self, Previewer)
    return self
  end

  function Previewer:populate_preview_buf(entry_str)
    local key = strip(entry_str)
    local match = index[key]
    local buf = self:get_tmp_buffer()
    if match then
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(match.content, "\n", { plain = true }))
      local ft = vim.filetype.match({ filename = match.path }) or ""
      if ft ~= "" then
        vim.bo[buf].filetype = ft
      end
    end
    self:set_preview_buf(buf)
    self.win:update_preview_title(" " .. (match and match.path or "") .. " ")
    self.win:update_preview_scrollbar()
    pcall(vim.api.nvim_win_set_cursor, self.win.preview_winid, { lineno[key] or 1, 0 })
    vim.api.nvim_win_call(self.win.preview_winid, function()
      vim.cmd("normal! zz")
    end)
  end

  return Previewer
end

--- Picker -----------------------------------------------------------------

---Open the live search picker.
---@param seed string|nil Initial query text (defaults to config.default_query)
function M.search(seed)
  local cfg = config.get()
  local endpoint = credentials.load().endpoint
  local ansi = fzf().utils.ansi_codes

  -- Entry -> match / line / url, rebuilt on every query and read by the
  -- previewer and actions. Cleared in place so the previewer's captured
  -- references stay valid.
  local index, lineno, url_of = {}, {}, {}
  local function reset()
    for _, tbl in ipairs({ index, lineno, url_of }) do
      for k in pairs(tbl) do
        tbl[k] = nil
      end
    end
  end

  -- fzf-lua live contents: return a producer `fn(cb)` that streams lines. We
  -- run the request off the event loop and emit from its callback, so Neovim
  -- never blocks; `cb(nil)` closes the stream.
  local contents = function(args)
    local query = args[1] or ""
    reset()
    return function(cb)
      if not should_search(query, cfg.min_pattern_len) then
        return cb(nil)
      end
      api.search_async(query, function(ok, result)
        if not ok then
          local msg = tostring(result):gsub("^.-sourcegraph[%w%.]*:%s*", "")
          cb(ansi.red("!! error: " .. msg))
          return cb(nil)
        end
        if result.limitHit then
          cb(
            ansi.yellow(
              string.format("-- results capped (<C-e> to raise to %d) --", count_of(query) + cfg.count.increment)
            )
          )
        end
        local emitted = 0
        for _, m in ipairs(result.matches) do
          local url = endpoint .. m.url
          local icon = devicon(m.path)
          if #m.lineMatches == 0 then
            -- Path-only match (e.g. a `file:` filter): show the filename alone.
            local display = format_path_entry(icon, m.path)
            local key = strip(display)
            index[key], lineno[key], url_of[key] = m, 1, url
            cb(display)
            emitted = emitted + 1
          end
          for _, lm in ipairs(m.lineMatches) do
            local display = format_entry(icon, m.path, lm)
            local key = strip(display)
            index[key], lineno[key], url_of[key] = m, lm.lineNumber + 1, url
            cb(display)
            emitted = emitted + 1
          end
        end
        if emitted == 0 then
          cb(ansi.grey("-- no matches --"))
        end
        cb(nil)
      end)
    end
  end

  fzf().fzf_live(contents, {
    prompt = "Sourcegraph> ",
    query = seed or cfg.default_query,
    query_delay = cfg.query_delay_ms,
    exec_empty_query = false,
    winopts = {
      treesitter = { enabled = true },
      preview = { layout = "horizontal", horizontal = "right:50%", wrap = true },
    },
    _treesitter = ts_line_parser,
    previewer = make_previewer(index, lineno),
    actions = {
      ["default"] = function(selected)
        local key = selected[1] and strip(selected[1])
        if key and index[key] then
          open_local(index[key], lineno[key] or 1)
        end
      end,
      ["ctrl-e"] = function(_, opts)
        local query = opts.last_query or ""
        if query ~= "" then
          M.search(raise_count(query, cfg.count.increment))
        end
      end,
      ["ctrl-o"] = function(selected)
        local url = selected[1] and url_of[strip(selected[1])]
        if url then
          vim.ui.open(url)
        end
      end,
      ["ctrl-y"] = function(selected)
        local url = selected[1] and url_of[strip(selected[1])]
        if url then
          vim.fn.setreg("+", url)
          vim.notify("sourcegraph: yanked " .. url)
        end
      end,
    },
  })
end

return M
