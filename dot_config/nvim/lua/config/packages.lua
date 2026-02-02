local plugins = {
  "hrsh7th/nvim-cmp",
  "hrsh7th/cmp-nvim-lsp",
  "hrsh7th/cmp-buffer",
  "hrsh7th/cmp-path",
  "L3MON4D3/LuaSnip",
  "yetone/avante.nvim",
  "nvim-treesitter/nvim-treesitter",
  "stevearc/dressing.nvim",
  "nvim-lua/plenary.nvim",
  "MunifTanjim/nui.nvim",
  "nvim-tree/nvim-web-devicons",
  "zbirenbaum/copilot.lua",
  "HakonHarnes/img-clip.nvim",
  "MeanderingProgrammer/render-markdown.nvim",
  "github/copilot.vim",
  "mfussenegger/nvim-dap",
  "rcarriga/nvim-dap-ui",
  "nvim-neotest/nvim-nio",
  "mhartington/formatter.nvim",
  "ibhagwan/fzf-lua",
  "calebfroese/fzf-lua-zoxide",
  "olimorris/codecompanion.nvim",
  "stevearc/oil.nvim",
  "mbbill/undotree",
  "mfussenegger/nvim-jdtls",
  "windwp/nvim-autopairs",
  "williamboman/mason.nvim",
  "neovim/nvim-lspconfig",
  "williamboman/mason-lspconfig",
  "jay-babu/mason-nvim-dap.nvim",
  "folke/neodev.nvim",
  "tpope/vim-sleuth",
  "Mofiqul/vscode.nvim",
  "FabijanZulj/blame.nvim",
  "nvim-pack/nvim-spectre",
  "mfussenegger/nvim-lint",
  "numToStr/Comment.nvim",
  "folke/which-key.nvim",
}

local function get_name(repo)
  return repo:match(".*/(.*)")
end

local function ensure_plugins()
  -- Using 'deps' as the pack group
  local pack_dir = vim.fn.stdpath("data") .. "/site/pack/deps/start"
  
  if vim.fn.isdirectory(pack_dir) == 0 then
    vim.fn.mkdir(pack_dir, "p")
  end

  for _, repo in ipairs(plugins) do
    local name = get_name(repo)
    local path = pack_dir .. "/" .. name
    if vim.fn.isdirectory(path) == 0 then
      print("Installing " .. repo .. "...")
      local url = "https://github.com/" .. repo .. ".git"
      vim.fn.system({ "git", "clone", "--filter=blob:none", url, path })
      vim.cmd("packadd " .. name)
      
      -- Handle specific build steps if necessary (rudimentary)
      if name == "avante.nvim" then
         print("Building avante.nvim...")
         vim.fn.system({ "make", "-C", path })
      end
    end
  end
end

ensure_plugins()
