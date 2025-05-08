---@diagnostic disable: undefined-global

-- Function to get the system theme using vim.fn.system instead of io.popen
local function get_system_theme()
  local result = vim.fn.system("gsettings get org.gnome.desktop.interface color-scheme")
  if vim.v.shell_error ~= 0 then
    return "dark" -- Default to dark if command fails
  end

  -- Parse the result (output is typically something like "'prefer-dark'" or "'prefer-light'")
  if result:match("light") then
    return "light"
  else
    return "dark"
  end
end

-- Function to set the colorscheme based on system theme
local function update_colorscheme()
  local theme = get_system_theme()
  if theme == "light" then
    vim.o.background = "light"
    vim.cmd("colorscheme catppuccin-latte")
  else
    vim.o.background = "dark"
    vim.cmd("colorscheme gruvbox")
  end
end

-- Set the initial colorscheme
update_colorscheme()

-- Create a user command to manually update the colorscheme
-- This is used by the i3 theme-toggle.sh script
vim.api.nvim_create_user_command("UpdateColorscheme", update_colorscheme, {})
