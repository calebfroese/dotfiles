-- lua/plugins/fzflua.lua

require("fzf-lua").setup({
  fzf_colors = true,
  winopts = {
    height = 1,
    width = 1,
    preview = {
      delay = 0,
    },
  },
  keymap = {
    builtin = {
      false, -- do not inherit defaults
      ["<M-Esc>"] = "hide",
      ["?"] = "toggle-help",
      -- more often want to page through the preview than the results, so assign pagination motions to that instead
      ["<C-d>"] = "preview-page-down",
      ["<C-u>"] = "preview-page-up",
    },
  },
  grep = {
    prompt = "Grep ❯ ",
  },
})

-- Keys mappings
local map = vim.keymap.set

map("n", "<leader><leader>", "<cmd>FzfLua resume<cr>", { desc = "Resume search" })
map("n", "<leader>f", function()
  require("fzf-lua-zoxide").open({
    callback = function(dir)
      vim.cmd("e " .. dir)
    end,
    setcwd = false,
  })
end, { desc = "Open Directory" })

map("n", "<leader>F", function()
  require("fzf-lua-zoxide").open({
    callback = function(_)
      vim.cmd("e .")
    end,
  })
end, { desc = "Change Directory" })

map("n", "<leader>s:", "<cmd>FzfLua command_history<cr>", { desc = "Command History" })
map("n", "<leader>sb", "<cmd>FzfLua buffers<cr>", { desc = "Buffers" })
map("n", "<leader>sB", "<cmd>FzfLua lines<cr>", { desc = "Buffers Contents" })
map("n", "<leader>sg", "<cmd>FzfLua grep_project<cr>", { desc = "Grep Project" })
map("n", "<leader>sf", "<cmd>FzfLua files<cr>", { desc = "File (cwd)" })
map("n", "<leader>sr", "<cmd>FzfLua oldfiles<cr>", { desc = "File (recent)" })
map("n", "<leader>sx", "<cmd>FzfLua diagnostics_document<cr>", { desc = "Diagnostics (buffer)" })
map("n", "<leader>sX", "<cmd>FzfLua diagnostics_workspace<cr>", { desc = "Diagnostics (cwd)" })
map("n", "<leader>sl", "<cmd>FzfLua lsp_references<cr>", { desc = "References" })

-- fzf-lua-zoxide setup
require("fzf-lua-zoxide").setup()
