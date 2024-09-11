return {
  {
    "ibhagwan/fzf-lua",
    event = "VimEnter",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("fzf-lua").setup({
        fzf_colors = true,
        winopts = {
          fullscreen = true,
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
          prompt = "Grep ❯ "
        },
      })
    end,
    keys = {
      { "<leader>s", group = "Search" },
      { "<leader><leader>", "<cmd>FzfLua resume<cr>", desc = "Resume search" },
      {
        "<leader>F",
        function()
          require("fzf-lua-zoxide").open({
            callback = function(_)
              vim.cmd("e .")
            end,
          })
        end,
        desc = "Open Directory",
      },
      { "<leader>s:", "<cmd>FzfLua command_history<cr>", desc = "Command History" },
      { "<leader>sb", "<cmd>FzfLua buffers<cr>", desc = "Buffers" },
      { "<leader>sg", "<cmd>FzfLua grep_project<cr>", desc = "Grep Project" },
      { "<leader>sf", "<cmd>FzfLua files<cr>", desc = "File (cwd)" },
      { "<leader>sr", "<cmd>FzfLua oldfiles<cr>", desc = "File (recent)" },
      { "<leader>sx", "<cmd>FzfLua diagnostics_document<cr>", desc = "Diagnostics (buffer)" },
      { "<leader>sX", "<cmd>FzfLua diagnostics_workspace<cr>", desc = "Diagnostics (cwd)" },
      { "<leader>sl", "<cmd>FzfLua lsp_references<cr>", desc = "References" },
    },
  },
  {
    "calebfroese/fzf-lua-zoxide",
    dependencies = { "ibhagwan/fzf-lua" },
    config = function()
      require("fzf-lua-zoxide").setup()
    end,
  },
}
