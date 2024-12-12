-- Various keybindings
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Tab and shift tab indent/unindent capability
vim.keymap.set("i", "<S-Tab>", "<C-\\><C-N><<<C-\\><C-N>^i")
vim.keymap.set("v", "<S-Tab>", "<gv")
vim.keymap.set("v", "<Tab>", ">gv")
-- Backslash to open netrw
vim.keymap.set("n", "\\", function ()
  vim.cmd("Oil")
end)

-- Toggle between cpp .h and .cpp files
vim.keymap.set("n", "<C-c>", function()
  local file = vim.fn.expand("%:t:r")
  local ext = vim.fn.expand("%:e")
  if ext == "cpp" then
    vim.cmd("e " .. file .. ".h")
  elseif ext == "h" then
    vim.cmd("e " .. file .. ".cpp")
  end
end)
