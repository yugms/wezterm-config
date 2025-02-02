local wezterm = require 'wezterm'
local act = wezterm.action
local theme = wezterm.plugin.require('https://github.com/neapsix/wezterm').moon -- rose pine theme

local config = {}
if wezterm.config_builder then config = wezterm.config_builder() end

config.font = wezterm.font("Cartograph CF", {weight="Bold", stretch="Normal", style="Normal", features = { "+ss02" }})
font_rules = {
    {
      intensity = "Bold",
      italic = false,
      font = wezterm.font("Cartograph CF", { weight = "Black", stretch="Normal", style="Normal" }),
    },
    {
      intensity = "Bold",
      italic = true,
      font = wezterm.font("Cartograph CF", {weight="Black", stretch="Normal", style="Normal"}),
    },
}

config.use_fancy_tab_bar = true
config.colors = theme.colors()
config.window_frame = {
    active_titlebar_bg = "#232136",
    inactive_titlebar_bg = "#232136",
    font_size = 10,
    font = wezterm.font("Cartograph CF", {weight="Black", stretch="Normal", style="Normal"})
}
config.font_size = 10
config.window_decorations = "RESIZE"
config.status_update_interval = 1000
config.inactive_pane_hsb = {
  saturation = 0.75,
  brightness = 0.6
}

-- keybindings
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }
config.keys = {
  -- Send C-a when pressing C-a twice
  { key = "a", mods = "LEADER",       action = act.SendKey { key = "a", mods = "CTRL" } },
  { key = "c", mods = "LEADER",       action = act.ActivateCopyMode },

  -- Pane keybindings
  { key = "-", mods = "LEADER",       action = act.SplitVertical { domain = "CurrentPaneDomain" } },
  -- SHIFT is for when caps lock is on
  { key = "|", mods = "LEADER|SHIFT", action = act.SplitHorizontal { domain = "CurrentPaneDomain" } },
  { key = "h", mods = "LEADER",       action = act.ActivatePaneDirection("Left") },
  { key = "j", mods = "LEADER",       action = act.ActivatePaneDirection("Down") },
  { key = "k", mods = "LEADER",       action = act.ActivatePaneDirection("Up") },
  { key = "l", mods = "LEADER",       action = act.ActivatePaneDirection("Right") },
  { key = "x", mods = "LEADER",       action = act.CloseCurrentPane { confirm = true } },
  { key = "z", mods = "LEADER",       action = act.TogglePaneZoomState },
  { key = "s", mods = "LEADER",       action = act.RotatePanes "Clockwise" },
  -- We can make separate keybindings for resizing panes
  -- But Wezterm offers custom "mode" in the name of "KeyTable"
  { key = "r", mods = "LEADER",       action = act.ActivateKeyTable { name = "resize_pane", one_shot = false } },

  -- Tab keybindings
  { key = "n", mods = "LEADER",       action = act.SpawnTab("CurrentPaneDomain") },
  { key = "[", mods = "LEADER",       action = act.ActivateTabRelative(-1) },
  { key = "]", mods = "LEADER",       action = act.ActivateTabRelative(1) },
  { key = "t", mods = "LEADER",       action = act.ShowTabNavigator },
  -- Key table for moving tabs around
  { key = "m", mods = "LEADER",       action = act.ActivateKeyTable { name = "move_tab", one_shot = false } },


  -- Lastly, workspace
  { key = "w", mods = "LEADER",       action = act.ShowLauncherArgs { flags = "FUZZY|WORKSPACES" } },

  -- rename tab
  {
    key = 'e',
    mods = "LEADER",
    action = act.PromptInputLine {
      description = 'Enter new name for tab',
      action = wezterm.action_callback(function(window, pane, line)
        -- line will be `nil` if they hit escape without entering anything
        -- An empty string if they just hit enter
        -- Or the actual line of text they wrote
        if line then
          window:active_tab():set_title(line)
        end
      end),
    },
  },

}
-- I can use the tab navigator (LDR t), but I also want to quickly navigate tabs with index
for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = "LEADER",
    action = act.ActivateTab(i - 1)
  })
end

config.key_tables = {
  resize_pane = {
    { key = "h",      action = act.AdjustPaneSize { "Left", 1 } },
    { key = "j",      action = act.AdjustPaneSize { "Down", 1 } },
    { key = "k",      action = act.AdjustPaneSize { "Up", 1 } },
    { key = "l",      action = act.AdjustPaneSize { "Right", 1 } },
    { key = "Escape", action = "PopKeyTable" },
    { key = "Enter",  action = "PopKeyTable" },
  },
  move_tab = {
    { key = "h",      action = act.MoveTabRelative(-1) },
    { key = "j",      action = act.MoveTabRelative(-1) },
    { key = "k",      action = act.MoveTabRelative(1) },
    { key = "l",      action = act.MoveTabRelative(1) },
    { key = "Escape", action = "PopKeyTable" },
    { key = "Enter",  action = "PopKeyTable" },
  }
}

wezterm.on("update-status", function(window, pane)
  -- Workspace name
  local stat = window:active_workspace()
  local stat_color = "#f7768e"
  -- It's a little silly to have workspace name all the time
  -- Utilize this to display LDR or current key table name
  if window:active_key_table() then
    stat = window:active_key_table()
    stat_color = "#eb6f92"
  end
  if window:leader_is_active() then
    stat = "LDR"
    stat_color = "#bb9af7"
  end

  local basename = function(s)
    return string.gsub(s, "(.*[/\\])(.*)", "%2")
  end

  -- Current working directory
  local cwd = pane:get_current_working_dir()
  if cwd then
    if type(cwd) == "userdata" then
      cwd = basename(cwd.file_path)
    else
      cwd = basename(cwd)
    end
  else
    cwd = ""
  end

  local cmd = pane:get_foreground_process_name()
  cmd = cmd and basename(cmd) or ""

  -- Time
  local time = wezterm.strftime("%-I:%M %p")

  -- Left status (left of the tab line)
  window:set_left_status(wezterm.format({
    { Foreground = { Color = stat_color } },
    { Text = " " },
    { Text = stat },
    { Text = " | " },
  }))

  -- Right status
  window:set_right_status(wezterm.format({
    -- Wezterm has a built-in nerd fonts
    -- https://wezfurlong.org/wezterm/config/lua/wezterm/nerdfonts.html
    { Foreground = { Color = "#3e8fb0" } },
    { Text = wezterm.nerdfonts.md_folder .. " " .. cwd },
    "ResetAttributes",
    { Foreground = { Color = "#908caa" } },
    { Text = " | " },
    "ResetAttributes",
    { Foreground = { Color = "#f6c177" } },
    { Text = wezterm.nerdfonts.fa_code .. " " .. cmd },
    "ResetAttributes",
    { Foreground = { Color = "#908caa" } },
    { Text = " | " },
    "ResetAttributes",
    { Foreground = { Color = "#c4a7e7" } },
    { Text = wezterm.nerdfonts.md_clock .. " " .. time },
    "ResetAttributes",
    { Text = "  " },
  }))
end)

return config
