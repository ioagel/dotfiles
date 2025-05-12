---@diagnostic disable: undefined-global

-- Mapping from system theme names to Neovim colorschemes
local theme_map = {
  ["gruvbox-dark"] = { colorscheme = "gruvbox", background = "dark" },
  ["catppuccin-latte"] = { colorscheme = "catppuccin-latte", background = "light" },
  -- Add more mappings as needed
}

-- Function to get the system theme and mode
local function get_system_theme_and_mode()
  local result = vim.fn.system("gsettings get org.gnome.desktop.interface color-scheme")
  if vim.v.shell_error ~= 0 then
    return "gruvbox-dark", "dark" -- Default
  end
  if result:match("light") then
    return "catppuccin-latte", "light"
  else
    return "gruvbox-dark", "dark"
  end
end

-- Function to update colorscheme, optionally with theme and mode
local function update_colorscheme(opts)
  local theme, mode
  if opts and opts.fargs and #opts.fargs >= 1 then
    theme = opts.fargs[1]
    mode = opts.fargs[2]
  else
    theme, mode = get_system_theme_and_mode()
  end
  local entry = theme_map[theme]
  if entry then
    vim.o.background = entry.background
    vim.cmd("colorscheme " .. entry.colorscheme)
  else
    vim.o.background = mode or "dark"
    vim.cmd("colorscheme gruvbox") -- fallback
  end
end

-- Set the initial colorscheme
update_colorscheme()

-- User command that accepts optional theme and mode
vim.api.nvim_create_user_command("UpdateColorscheme", update_colorscheme, { nargs = "*" })
