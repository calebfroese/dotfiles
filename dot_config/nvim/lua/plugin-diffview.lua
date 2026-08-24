local M = {}

--- Default configuration for the diffview plugin.
local config = {
  keymap_open = "<CR>", -- open full side-by-side diff (in the list)
  keymap_preview = "<C-p>", -- toggle live preview beside the list
  colors = {
    new = "#2ea043", -- added / untracked
    deleted = "#da3633", -- deleted
    modified = "#8b949e", -- modified
  },
}

function M.setup(opts)
  for k, v in pairs(opts or {}) do
    config[k] = v
  end

  if not pcall(require, "oil") then
    return vim.notify("plugin-diffview: oil.nvim is required", vim.log.levels.ERROR)
  end
  require("diffview").setup(config)

  vim.api.nvim_create_user_command("GitDiff", function()
    require("diffview").open()
  end, { desc = "Browse repo changes vs HEAD as a diff directory" })

  vim.api.nvim_create_user_command("GitDiffBranch", function(cmd)
    require("diffview").open({ branch = true, base = cmd.args ~= "" and cmd.args or nil })
  end, {
    nargs = "?",
    desc = "Browse whole-branch diff (merge-base to worktree, incl. uncommitted)",
  })
end

return M
