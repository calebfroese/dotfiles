-- lua/plugins/cmp.lua
local vim = vim

-- Opts generation
local function get_opts()
  vim.api.nvim_set_hl(0, "CmpGhostText", { link = "Comment", default = true })
  local cmp = require("cmp")
  local defaults = require("cmp.config.default")()
  return {
    auto_brackets = {},
    snippet = {
      expand = function(args)
        require("luasnip").lsp_expand(args.body)
      end,
    },
    completion = defaults.completion,
    mapping = cmp.mapping.preset.insert({
      ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
      ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
      ["<C-b>"] = cmp.mapping.scroll_docs(-4),
      ["<C-f>"] = cmp.mapping.scroll_docs(4),
      ["<C-Space>"] = cmp.mapping.complete(),
      ["<C-e>"] = cmp.mapping.abort(),
      ["<CR>"] = cmp.mapping.confirm({ select = true }),
      ["<S-CR>"] = cmp.mapping.confirm({
        behavior = cmp.ConfirmBehavior.Replace,
        select = true,
      }),
      ["<C-CR>"] = function(fallback)
        cmp.abort()
        fallback()
      end,
    }),
    sources = cmp.config.sources({
      { name = "nvim_lsp" },
      { name = "path" },
    }, {
      { name = "buffer" },
    }),
    formatting = defaults.formatting,
    experimental = {
      ghost_text = {
        hl_group = "CmpGhostText",
      },
    },
    sorting = defaults.sorting,
  }
end

local opts = get_opts()

-- Config logic
for _, source in ipairs(opts.sources) do
  source.group_index = source.group_index or 1
end
local cmp = require("cmp")
local Kind = cmp.lsp.CompletionItemKind
cmp.setup(opts)
cmp.event:on("confirm_done", function(event)
  if not vim.tbl_contains(opts.auto_brackets or {}, vim.bo.filetype) then
    return
  end
  local entry = event.entry
  local item = entry:get_completion_item()
  if vim.tbl_contains({ Kind.Function, Kind.Method }, item.kind) then
    local keys = vim.api.nvim_replace_termcodes("()<left>", false, false, true)
    vim.api.nvim_feedkeys(keys, "i", true)
  end
end)
