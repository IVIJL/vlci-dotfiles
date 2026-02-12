-- These are the basic's for using wezterm.
-- Mux is the mutliplexes for windows etc inside of the terminal
-- Action is to perform actions on the terminal
local wezterm = require("wezterm")
local mux = wezterm.mux
local act = wezterm.action
-- načti globály
local globals = require("globals")

-- These are vars to put things in later (i dont use em all yet)
local config = {}
local keys = {}
local mouse_bindings = {}
local launch_menu = {}

local function save_global_theme(label)
	local path = wezterm.config_dir .. "/globals.lua"
	local f = io.open(path, "w")
	if f then
		f:write("local M = {}\n")
		f:write(string.format("M.colorscheme = %q\n", label))
		f:write("return M\n")
		f:close()
	end
end

local function theme_switcher(window, pane)
	local schemes = wezterm.get_builtin_color_schemes()
	local choices = {}
	for name, _ in pairs(schemes) do
		table.insert(choices, { label = name })
	end
	table.sort(choices, function(a, b)
		return a.label < b.label
	end)

	window:perform_action(
		wezterm.action.InputSelector({
			title = "Choose a color scheme",
			choices = choices,
			fuzzy = true,

			action = wezterm.action_callback(function(_, _, _, label)
				save_global_theme(label)

				-- reload config po změně
				window:perform_action(wezterm.action.ReloadConfiguration, pane)
			end),
		}),
		pane
	)
end

-- This is for newer wezterm vertions to use the config builder
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- Default config settings
-- These are the default config settins needed to use Wezterm
-- Just add this and return config and that's all the basics you need

-- Color scheme, Wezterm has 100s of them you can see here:
-- https://wezfurlong.org/wezterm/colorschemes/index.html
-- config.color_scheme = 'Oceanic Next (Gogh)'
-- config.color_scheme = 'Catppuccin Latte'
config.color_scheme = globals.colorscheme
config.enable_scroll_bar = true
-- This is my chosen font, we will get into installing fonts on windows later
config.font = wezterm.font("Hack Nerd Font")
config.font_size = 11
config.launch_menu = launch_menu
-- makes my cursor blink
config.default_cursor_style = "BlinkingBar"
-- config.disable_default_key_bindings = true
-- this adds the ability to use ctrl+v to paste the system clipboard
config.keys = {
	{ key = "V", mods = "CTRL", action = act.PasteFrom("Clipboard") },
	{ key = "Enter", mods = "SHIFT", action = wezterm.action({ SendString = "\x1b\r" }) },
	{
		key = "s", -- stiskni S
		mods = "CTRL|SHIFT", -- s Ctrl+Shift
		action = wezterm.action.SendString("screenshot\r"), -- spustí tvůj alias
	},
	{
		key = "k",
		mods = "CTRL|ALT",
		action = wezterm.action_callback(function(window, pane)
			print("HOTKEY CTRL+ALT+K PRESSED!")
			theme_switcher(window, pane)
		end),
	},
}
config.mouse_bindings = mouse_bindings

-- There are mouse binding to mimc Windows Terminal and let you copy
-- To copy just highlight something and right click. Simple
mouse_bindings = {
	{
		event = { Down = { streak = 3, button = "Left" } },
		action = wezterm.action.SelectTextAtMouseCursor("SemanticZone"),
		mods = "NONE",
	},
	{
		event = { Down = { streak = 1, button = "Right" } },
		mods = "NONE",
		action = wezterm.action_callback(function(window, pane)
			local has_selection = window:get_selection_text_for_pane(pane) ~= ""
			if has_selection then
				window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
				window:perform_action(act.ClearSelection, pane)
			else
				window:perform_action(act({ PasteFrom = "Clipboard" }), pane)
			end
		end),
	},
}
-- SIZE of window:
-- difficult to find as manual ref/google-results answer initial_cols = & initial_rows = DO NOT WORK,
-- but config.initial_cols = WORKS! from answer by Daniel-Lizik:
-- https://stackoverflow.com/questions/78738575/how-to-maximize-wezterm-on-startup

config.enable_tab_bar = true
config.initial_rows = 48
config.initial_cols = 170

--config.window_decorations = "NONE"
config.window_decorations = "TITLE | RESIZE"

-- This is used to make my foreground (text, etc) brighter than my background
config.foreground_text_hsb = {
	hue = 1.0,
	saturation = 1.2,
	brightness = 1.5,
}

-- This is used to set an image as my background
-- config.background = {
--     {
--         source = { File = {path = 'C:/Users/someuserboi/Pictures/Backgrounds/theone.gif', speed = 0.2}},
--  opacity = 1,
--  width = "100%",
--  hsb = {brightness = 0.5},
--     }
-- }

-- This is used to set the default working directory when opening Wezterm
config.default_cwd = "/mnt/c/Users/milos/OneDrive/Documents"

-- IMPORTANT: Sets WSL2 UBUNTU-22.04 as the defualt when opening Wezterm
config.default_domain = "WSL:Ubuntu-24.04"

return config
