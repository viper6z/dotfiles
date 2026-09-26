local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Looks ---------------------------------------------------------------------
-- Tokyo Night matches LazyVim's default colorscheme, so the terminal and
-- editor backgrounds line up with no visible border.
config.color_scheme = "Tokyo Night"

-- JetBrains Mono and the Nerd Font symbols are bundled inside WezTerm,
-- so LazyVim's icons render without installing any fonts on the VM.
config.font = wezterm.font("JetBrains Mono")
config.font_size = 12.0

config.window_padding = { left = 8, right = 8, top = 6, bottom = 6 }
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.window_close_confirmation = "NeverPrompt"

-- Environment ---------------------------------------------------------------
-- Don't phone home to GitHub for update checks on a locked-down network.
config.check_for_updates = false

-- If the window is black, flickers or crashes (no usable GPU in a
-- browser-streamed VM), start it with WEZTERM_SOFTWARE=1 once to confirm,
-- then uncomment the line below to make it permanent.
-- config.front_end = "Software"
if os.getenv("WEZTERM_SOFTWARE") then
  config.front_end = "Software"
end

-- Nvim-friendly -------------------------------------------------------------
config.scrollback_lines = 10000
config.audible_bell = "Disabled"

return config
