-- Pull in the wezterm API
local wezterm = require("wezterm")
local utils = require("utils") -- Require the new utils file

-- This will hold the configuration.
local config = wezterm.config_builder()

-- Set Theme
local current_appearance = utils.get_appearance()
-- wezterm.log_info("Current appearance: " .. current_appearance)

config = {
	term = "wezterm",

	font = wezterm.font("CaskaydiaCove Nerd Font Mono"),
	font_size = 12,

	enable_tab_bar = false,

	color_scheme = utils.scheme_for_appearance(current_appearance),

	window_padding = {
		left = 2,
		right = 2,
		top = 0,
		bottom = 0
	},

	default_prog = { "zellij" },

	-- Enable OSC 52 clipboard integration (make zelliz support copy/paste)
	enable_kitty_keyboard = true,
	enable_csi_u_key_encoding = true
}

return config
