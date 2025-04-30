-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

config = {
	term = "wezterm",

	font = wezterm.font("CaskaydiaMono Nerd Font"),
	-- font = wezterm.font("Hasklug Nerd Font Mono"),
	-- font = wezterm.font("JetBrainsMono Nerd Font"),
	font_size = 12,

	enable_tab_bar = false,

	color_scheme = "Gruvbox Dark (Gogh)",

	window_padding = {
		left = 2,
		right = 2,
		top = 0,
		bottom = 0
	},
}

return config
