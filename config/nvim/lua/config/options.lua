-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- To prevent conflicts with asdf manager's python versions
vim.g.python3_host_prog = "/usr/bin/python3"

-- add file path in open buffer
vim.opt.winbar = "%=%m %f"
