return {
  {
    "mbbill/undotree",
    config = function()
      vim.cmd("source ~/.config/nvim/lua/plugins/undotree.vim")
    end,
  },
  {
    "mfussenegger/nvim-jdtls",
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = true,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      local configs = require("nvim-treesitter.configs")

      configs.setup({
        sync_install = false,
        highlight = { enable = true },
        indent = { enable = true },
        auto_install = true,
        ignore_install = {},
        modules = {},
        ensure_installed = {
          "bash",
          "go",
          "html",
          "javascript",
          "java",
          "json",
          "lua",
          "markdown",
          "markdown_inline",
          "python",
          "query",
          "regex",
          "tsx",
          "terraform",
          "typescript",
          "vim",
          "yaml",
        },
      })
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    config = function()
      require("lualine").setup({
        options = {
          theme = "auto",
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = {},
          lualine_c = {
            {
              "filename",
              path = 1,
            },
          },
          lualine_x = {},
          lualine_y = { "searchcount" },
          lualine_z = { "progress" },
        },
        inactive_sessions = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { "filename" },
          lualine_x = {},
          lualine_y = {},
          lualine_z = {},
        },
      })
    end,
  },
  {
    "williamboman/mason.nvim",
    event = "VeryLazy",
    dependencies = {
      "neovim/nvim-lspconfig",
      "williamboman/mason-lspconfig",
      "jay-babu/mason-nvim-dap.nvim",
      "folke/neodev.nvim",
    },
    config = function()
      require("neodev").setup()
      require("mason").setup()
      require("mason-nvim-dap").setup()
      require("mason-lspconfig").setup()
      require("mason-lspconfig").setup_handlers({
        function(server_name)
          require("lspconfig")[server_name].setup({})
        end,
      })

      -- These will be automatically installed, keep in sync with expected formatters/lsp/dap etc
      local packages = {
        -- LSP
        "lua-language-server",
        "pyright",
        "terraform-ls",
        "typescript-language-server",
        -- DAP
        "js-debug-adapter",
        -- Formatter
        "stylua",
        "prettier",
        "golines",
        "buf",
      }
      local str = ""
      for _, v in pairs(packages) do
        if not require("mason-registry").is_installed(v) then
          str = str .. " " .. v
        end
      end
      if string.len(str) > 0 then
        vim.cmd("MasonInstall " .. str)
      end
    end,
  },
  {
    "tpope/vim-sleuth",
    event = "VeryLazy",
  },
  {
    "Mofiqul/vscode.nvim",
    opts = function()
      require("vscode").setup()
      vim.cmd.colorscheme("vscode")
    end,
  },
  {
    "stevearc/conform.nvim",
    event = "VeryLazy",
    config = function()
      require("conform").setup({})
    end,
  },
  {
    "FabijanZulj/blame.nvim",
    event = "VeryLazy",
    config = function()
      require("blame").setup()
    end,
  },
  {
    "nvim-pack/nvim-spectre",
    event = "VeryLazy",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },
  {
    "L3MON4D3/LuaSnip",
    event = "VeryLazy",
  },
  {
    "mfussenegger/nvim-lint",
    event = "VeryLazy",
    config = function()
      require("lint").linters_by_ft = {
        typescript = { "eslint_d" },
      }
    end,
  },
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup()
    end,
  },
}
