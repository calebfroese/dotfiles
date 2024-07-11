local function is_neotree_open()
  -- Get the list of windows in the current tab
  local windows = vim.api.nvim_tabpage_list_wins(0)

  -- Iterate over the windows and check the buffer names
  for _, win in ipairs(windows) do
    local buf = vim.api.nvim_win_get_buf(win)
    local buf_name = vim.api.nvim_buf_get_name(buf)
    local buf_ft = vim.api.nvim_buf_get_option(buf, "filetype")

    -- Check if the buffer name or filetype matches NeoTree
    if buf_name:match("NeoTree") or buf_ft == "neo-tree" then
      return true
    end
  end

  return false
end

return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 0
      require("which-key").register({
        ["<leader>"] = {
          name = "Leader",
          ["<leader>"] = { "<cmd>FzfLua buffers<cr>", "Open buffers" },
          ["/"] = { require("Comment.api").toggle.linewise.current, "Comment" },
          [":"] = { "<cmd>FzfLua command_history<cr>", "Command history" },
          ["q"] = {
            function()
              local pane_count = #vim.api.nvim_tabpage_list_wins(0)

              local is_open = is_neotree_open()
              if is_open then
                pane_count = pane_count - 1
              end

              if pane_count > 1 then
                local current_win = vim.api.nvim_get_current_win()
                vim.api.nvim_win_close(current_win, true)
              else
                vim.cmd("Dashboard")
              end
            end,
            "Quit",
          },
        },
        ["<leader>s"] = {
          name = "Search",
          f = { "<cmd>FzfLua grep_project<cr>", "Quick Search" },
          s = {
            function()
              require("spectre").toggle()
            end,
            "Toggle Search",
          },
          w = {
            function()
              require("spectre").open_visual({ select_word = true })
            end,
            "Search Current Word",
          },
        },
        ["<leader>d"] = {
          name = "Debugger",
          t = {
            function()
              require("dapui").toggle()
            end,
            "Toggle Debugger",
          },
          d = {
            function()
              require("dap").toggle_breakpoint()
            end,
            "Toggle Breakpoint",
          },
          e = {
            function()
              local expr = vim.fn.input("Expression: ", "", "expression")
              require("dapui").eval(expr)
            end,
            "Evaluate Expression",
          },
        },
        ["<leader>o"] = {
          name = "Code Actions",
          o = {
            function()
              vim.lsp.buf.code_action()
            end,
            "Organize / Add Missing Imports",
          },
          f = {
            "<cmd>Format<cr>",
            "Format",
          },
          d = {
            function()
              vim.diagnostic.open_float()
            end,
            "Diagnostic Preview",
          },
          D = {
            function()
              require('fzf-lua').diagnostics_workspace()
            end,
            "Diagnostic Window (Workspace)",
          },
        },
        ["<leader>p"] = {
          name = "Pane",
          o = { "<cmd>Neotree reveal<cr>", "Reveal" },
          s = {
            function()
              vim.api.nvim_command("vsplit")
              vim.api.nvim_command("bn")
            end,
            "Split (cur right)",
          },
          v = {
            function()
              vim.api.nvim_command("vsplit")
              vim.api.nvim_command("wincmd l")
              vim.api.nvim_command("bn")
              vim.api.nvim_command("wincmd h")
            end,
            "Split (cur left)",
          },
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
    },
  },
}
