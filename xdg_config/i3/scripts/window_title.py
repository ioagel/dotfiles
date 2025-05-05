#!/usr/bin/env python3
import i3ipc

MAX_LEN = 50
ICON_MAP = {
    # Browsers
    "firefox": "\uf269",                    # Firefox
    "Brave-browser": "\uf27f",              # Brave
    "Google-chrome": "\uf268",              # Google Chrome

    # IDEs / Dev tools
    "code": "\ue70c",                       # VSCode
    "Code": "\ue70c",
    "Cursor": "\uf285",                     # Mouse pointer (symbolic)
    "Windsurf": "\ue70c",                   # Dev icon for VSCode/IDE tools (nf-dev-code_badge)
    "jetbrains-rubymine": "\ue791",         # JetBrains icon (symbolic dev-icon for IntelliJ apps)

    # File managers
    "org.gnome.Nautilus": "\uf07b",         # Folder icon
    "Nautilus": "\uf07b",

    # Terminals
    "wezterm": "\uf120",                    # Terminal
    "org.wezfurlong.wezterm": "\uf120",
    "Alacritty": "\uf120",

    # Media
    "Spotify": "\uf1bc",                    # Spotify
    "mpv": "\uf144",                        # Play button

    # Default fallback
    "default": "\uf2d0",                    # fa-window-maximize
}



def get_icon_for_class(window_class):
    return ICON_MAP.get(window_class, ICON_MAP["default"])

def print_title():
    focused = i3.get_tree().find_focused()
    if focused:
        title = focused.name or ""
        app_class = focused.window_class or ""
        icon = get_icon_for_class(app_class)
        short_title = title[:MAX_LEN] + "…" if len(title) > MAX_LEN else title
        print(f"{icon} {short_title}", flush=True)
    else:
        print("🪟 No window", flush=True)

def on_event(i3, e):
    print_title()

i3 = i3ipc.Connection()

# Initial print
print_title()

# Listen to both focus and title change events
i3.on("window::focus", on_event)
i3.on("window::title", on_event)

i3.main()
