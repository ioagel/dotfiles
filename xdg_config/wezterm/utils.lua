local wezterm = require("wezterm")

local M = {}

function M.get_appearance()
    if wezterm.gui then
        return wezterm.gui.get_appearance()
    end
    return 'Dark'
end

function M.scheme_for_appearance(appearance)
    if appearance:find 'Dark' then
        return 'Gruvbox Dark (Gogh)'
    else
        return 'Catppuccin Latte'
    end
end

return M
