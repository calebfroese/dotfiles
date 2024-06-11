return {
  { "echasnovski/mini.pairs",
  event = "VeryLazy",
  config = function()
    require('mini.pairs').setup()
  end
},

{
  "folke/which-key.nvim",
  event = "VeryLazy",
  config = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 0
    require('which-key').register({
      ["<leader>"] = {
        name = "Leader",
        ["<leader>"] = { "<cmd>FzfLua buffers<cr>", "Open buffers" },
        ["/"] = {  require('Comment.api').toggle.linewise.current, "Comment" },
        [":"] = { "<cmd>FzfLua command_history<cr>", "Command history" },
      },
      ["<leader>s"] = {
        name = "Search",
        f = { "<cmd>FzfLua grep_project<cr>", "Quick Search" },
        s = { function() require("spectre").toggle() end, "Toggle Search" },
        w = { function() require("spectre").open_visual({select_word=true}) end, "Search Current Word" },
      },
        ["<leader>o"] = {
          name = "Code Actions",
          o = { function() vim.lsp.buf.code_action() end, "Organize / Add Missing Imports" },
          d = { function() vim.diagnostic.open_float() end, "LSP Diagnostic Window" },
        },
        ["<leader>p"] = {
          name = "Pane",
          o = { "<cmd>Neotree reveal<cr>", "Reveal" },
          s = {
            function()
              vim.api.nvim_command('vsplit')
              vim.api.nvim_command('bn')
          end, "Split (cur right)" },
          v = {
            function()
              vim.api.nvim_command('vsplit')
              vim.api.nvim_command('wincmd l')
              vim.api.nvim_command('bn')
              vim.api.nvim_command('wincmd h')
          end, "Split (cur left)" },
        },
      ["<leader>g"] = {
        name = "Git",
        b = { "<cmd>BlameToggle<cr>", "Blame" },
      },
      ["<leader>f"] = {
        name = "Find",
        f = { "<cmd>FzfLua files<cr>", "Find files (cwd)" },
        r = { "<cmd>FzfLua oldfiles<cr>", "Recent files" },
        n = { "<cmd>enew<cr>", "New File" },
      },
    })
  end,
  opts = {
    plugins = {
      marks = true, -- shows a list of your marks on ' and `
      registers = true, -- shows your registers on " in NORMAL or <C-r> in INSERT mode
      -- the presets plugin, adds help for a bunch of default keybindings in Neovim
      -- No actual key bindings are created
      spelling = {
        enabled = true, -- enabling this will show WhichKey when pressing z= to select spelling suggestions
        suggestions = 20, -- how many suggestions should be shown in the list?
      },
      presets = {
        operators = true, -- adds help for operators like d, y, ...
        motions = true, -- adds help for motions
        text_objects = true, -- help for text objects triggered after entering an operator
        windows = true, -- default bindings on <c-w>
        nav = true, -- misc bindings to work with windows
        z = true, -- bindings for folds, spelling and others prefixed with z
        g = true, -- bindings for prefixed with g
      },
    },
    -- add operators that will trigger motion and text object completion
    -- to enable all native operators, set the preset / operators plugin above
    operators = { gc = "Comments" },
    key_labels = {
      -- override the label used to display some keys. It doesn't effect WK in any other way.
      -- For example:
      -- ["<space>"] = "SPC",
      -- ["<cr>"] = "RET",
      -- ["<tab>"] = "TAB",
    },
    motions = {
      count = true,
    },
    icons = {
      breadcrumb = "»", -- symbol used in the command line area that shows your active key combo
      separator = "➜", -- symbol used between a key and it's label
      group = "+", -- symbol prepended to a group
    },
    popup_mappings = {
      scroll_down = "<c-d>", -- binding to scroll down inside the popup
      scroll_up = "<c-u>", -- binding to scroll up inside the popup
    },
    window = {
      border = "none", -- none, single, double, shadow
      position = "bottom", -- bottom, top
      margin = { 1, 0, 1, 0 }, -- extra window margin [top, right, bottom, left]. When between 0 and 1, will be treated as a percentage of the screen size.
      padding = { 1, 2, 1, 2 }, -- extra window padding [top, right, bottom, left]
      winblend = 0, -- value between 0-100 0 for fully opaque and 100 for fully transparent
      zindex = 1000, -- positive value to position WhichKey above other floating windows.
    },
    layout = {
      height = { min = 4, max = 25 }, -- min and max height of the columns
      width = { min = 20, max = 50 }, -- min and max width of the columns
      spacing = 3, -- spacing between columns
      align = "left", -- align columns left, center or right
    },
    ignore_missing = false, -- enable this to hide mappings for which you didn't specify a label
    hidden = { "<silent>", "<cmd>", "<Cmd>", "<CR>", "^:", "^ ", "^call ", "^lua " }, -- hide mapping boilerplate
    show_help = true, -- show a help message in the command line for using WhichKey
    show_keys = true, -- show the currently pressed key and its label as a message in the command line
    --  triggers = {"<leader>"}, -- automatically setup triggers
    -- triggers = {"<leader>"} -- or specifiy a list manually
    -- list of triggers, where WhichKey should not wait for timeoutlen and show immediately
    triggers_nowait = {
      -- marks
      "<leader>",
      "`",
      "'",
      "g`",
      "g'",
      -- registers
      '"',
      "<c-r>",
      -- spelling
      "z=",
    },
    triggers_blacklist = {
      -- list of mode / prefixes that should never be hooked by WhichKey
      -- this is mostly relevant for keymaps that start with a native binding
      i = { "j", "k" },
      v = { "j", "k" },
    },
    -- disable the WhichKey popup for certain buf types and file types.
    -- Disabled by default for Telescope
    disable = {
      buftypes = {},
      filetypes = {},
    },
  }
},
{
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function ()
    local configs = require("nvim-treesitter.configs")

    configs.setup({
      sync_install = false,
      highlight = { enable = true },
      indent = { enable = true },  
      ensure_installed = {
        "bash",
        "go",
        "html",
        "javascript",
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
  end
},
{
  "nvim-lualine/lualine.nvim",
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  event = "VeryLazy",
  opts = function()
    return {
      options = {
        theme = 'auto'
      },
      sections = {
        lualine_a = {'mode'},
        lualine_c = {
          {
            'filename',
            path = 1,
          },
        },
        lualine_y = {'progress'},
        lualine_z = {'location'}

      },
    }
  end,
},
{
  "williamboman/mason.nvim",
  event = "VeryLazy",
  dependencies = {
    "neovim/nvim-lspconfig",
    "williamboman/mason-lspconfig",
    "folke/neodev.nvim",
  },
  config = function()
    require("neodev").setup()
    require("mason").setup()
    require("mason-lspconfig").setup({
      ensure_installed = {
        "lua_ls",
        "gopls",
        "tsserver",
        "pyright",
        "terraformls",
      },
    })

    require("mason-lspconfig").setup_handlers {
      -- The first entry (without a key) will be the default handler
      -- and will be called for each installed server that doesn't have
      -- a dedicated handler.
      function (server_name) -- default handler (optional)
        require("lspconfig")[server_name].setup {}
      end,
      -- Next, you can provide a dedicated handler for specific servers.
      -- For example, a handler override for the `rust_analyzer`:
    }
  end
},
{
  "tpope/vim-sleuth",
  event = "VeryLazy",
},
{
  "Mofiqul/vscode.nvim",
  opts = function()
    vim.cmd.colorscheme("vscode")
  end,
},
{
  "stevearc/conform.nvim",
  event = "VeryLazy",
  config = function()
    require("conform").setup({})
  end
},
{
  "FabijanZulj/blame.nvim",
  event = "VeryLazy",
  config = function()
    require("blame").setup()
  end
},
{
  'nvim-pack/nvim-spectre',
  event = "VeryLazy",
  dependencies = {
    'nvim-lua/plenary.nvim'
  },
},
  {
    'L3MON4D3/LuaSnip',
    event = "VeryLazy",
  },
  {
    'mfussenegger/nvim-lint',
    event = "VeryLazy",
    config = function()
      require('lint').linters_by_ft = {
        typescript = {'eslint_d',}
      }
    end
  },
  {
    'mhartington/formatter.nvim',
    event = "VeryLazy",
  },
  {
    "numToStr/Comment.nvim",
config = function()
        require('Comment').setup()
    end
  },
}

