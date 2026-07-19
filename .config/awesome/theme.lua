--[[
  Win9x-ish theme for AwesomeWM — deep-blue palette edition
  -----------------------------------------------------------
  Hard 1px bevels everywhere, flat face colour, no gaps, no rounded
  corners, no drop shadows. Taskbar lives at the bottom now.

  Install Terminus for the authentic bitmap-console look:
    Arch:   sudo pacman -S terminus-font
    Debian: sudo apt install xfonts-terminus fonts-terminus
--]]

local theme_assets = require("beautiful.theme_assets")
local xresources   = require("beautiful.xresources")
local gears        = require("gears")
local dpi          = xresources.apply_dpi

local gfs = require("gears.filesystem")
local themes_path = gfs.get_themes_dir()

local theme = {}

-- ===== Palette =====
-- darkest -> lightest: shadow, face, highlight, accent/cream
theme.color_face_dark  = "#1B3C53"  -- shadow edge (bottom/right on raised, top/left on sunken)
theme.color_face       = "#234C6A"  -- button face / wibar background
theme.color_face_light = "#456882"  -- highlight edge (top/left on raised, bottom/right on sunken)
theme.color_accent     = "#D2C1B6"  -- cream accent: selected tag fill, focused border, highlights

theme.color_desktop     = theme.color_face_dark  -- solid desktop background
theme.color_text        = theme.color_accent      -- light text reads cleanly on the dark blues
theme.color_text_dark   = theme.color_face_dark   -- dark text, used on top of the cream accent
theme.color_text_inv    = theme.color_accent

-- ===== Fonts =====
theme.font          = "Terminus 12"
theme.taglist_font  = "Terminus 12"
theme.tasklist_font = "Terminus 12"

-- ===== Core =====
theme.wallpaper          = nil -- solid colour set in rc.lua via gears.wallpaper
theme.useless_gap        = dpi(0)
theme.gap_single_client  = false

theme.bg_normal   = theme.color_face
theme.bg_focus    = theme.color_face_dark
theme.bg_urgent   = "#7A2E2E"
theme.bg_minimize = theme.color_face_dark
theme.bg_systray  = theme.color_face

theme.fg_normal   = theme.color_text
theme.fg_focus    = theme.color_text
theme.fg_urgent   = theme.color_accent
theme.fg_minimize = theme.color_text

-- ===== Borders =====
theme.border_width  = dpi(1)
theme.border_normal = theme.color_face_dark
theme.border_focus  = theme.color_accent
theme.border_marked = "#7A2E2E"

-- ===== Titlebars =====
theme.titlebar_bg_normal = theme.color_face
theme.titlebar_bg_focus  = theme.color_face_dark
theme.titlebar_fg_normal = theme.color_text
theme.titlebar_fg_focus  = theme.color_accent

-- ===== Menu =====
theme.menu_height       = dpi(22)
theme.menu_width        = dpi(170)
theme.menu_bg_normal    = theme.color_face
theme.menu_bg_focus     = theme.color_accent
theme.menu_fg_normal    = theme.color_text
theme.menu_fg_focus     = theme.color_text_dark
theme.menu_border_width = dpi(1)
theme.menu_border_color = theme.color_face_dark

-- ===== Taglist / Tasklist base colours (actual depth handled in rc.lua) =====
theme.taglist_bg_focus     = theme.color_accent
theme.taglist_bg_occupied  = theme.color_face
theme.taglist_bg_empty     = theme.color_face
theme.taglist_bg_urgent    = "#7A2E2E"
theme.taglist_fg_focus     = theme.color_text_dark
theme.taglist_fg_occupied  = theme.color_text
theme.taglist_fg_empty     = theme.color_face_light

theme.tasklist_bg_normal = theme.color_face
theme.tasklist_bg_focus  = theme.color_face
theme.tasklist_fg_normal = theme.color_text
theme.tasklist_fg_focus  = theme.color_text

-- ===== Wibar (bottom taskbar; taller to fit Terminus 12 comfortably) =====
theme.wibar_height = dpi(32)
theme.wibar_bg      = theme.color_face
theme.wibar_fg      = theme.color_text

-- ===== Notifications =====
theme.notification_font         = theme.font
theme.notification_bg           = theme.color_face
theme.notification_fg           = theme.color_text
theme.notification_border_color = theme.color_face_dark
theme.notification_border_width = dpi(1)
theme.notification_shape        = function(cr, w, h) gears.shape.rectangle(cr, w, h) end
theme.notification_margin       = dpi(8)

-- ===== Hotkeys popup =====
theme.hotkeys_bg = theme.color_face
theme.hotkeys_fg = theme.color_text
theme.hotkeys_border_color = theme.color_face_dark
theme.hotkeys_shape = function(cr, w, h) gears.shape.rectangle(cr, w, h) end

-- ===== Layout icons (stock set; neutral enough to sit on any face colour) =====
theme.layout_fairh      = themes_path .. "default/layouts/fairhw.png"
theme.layout_fairv      = themes_path .. "default/layouts/fairvw.png"
theme.layout_floating   = themes_path .. "default/layouts/floatingw.png"
theme.layout_magnifier  = themes_path .. "default/layouts/magnifierw.png"
theme.layout_max        = themes_path .. "default/layouts/maxw.png"
theme.layout_fullscreen = themes_path .. "default/layouts/fullscreenw.png"
theme.layout_tilebottom = themes_path .. "default/layouts/tilebottomw.png"
theme.layout_tileleft   = themes_path .. "default/layouts/tileleftw.png"
theme.layout_tile       = themes_path .. "default/layouts/tilew.png"
theme.layout_tiletop    = themes_path .. "default/layouts/tiletopw.png"
theme.layout_spiral     = themes_path .. "default/layouts/spiralw.png"
theme.layout_dwindle    = themes_path .. "default/layouts/dwindlew.png"
theme.layout_cornernw   = themes_path .. "default/layouts/cornernww.png"
theme.layout_cornerne   = themes_path .. "default/layouts/cornernew.png"
theme.layout_cornersw   = themes_path .. "default/layouts/cornersww.png"
theme.layout_cornerse   = themes_path .. "default/layouts/cornersew.png"

-- Titlebar button icons: reuse stock set
theme.titlebar_close_button_normal = themes_path .. "default/titlebar/close_normal.png"
theme.titlebar_close_button_focus  = themes_path .. "default/titlebar/close_focus.png"
theme.titlebar_minimize_button_normal = themes_path .. "default/titlebar/minimize_normal.png"
theme.titlebar_minimize_button_focus  = themes_path .. "default/titlebar/minimize_focus.png"
theme.titlebar_ontop_button_normal_inactive = themes_path .. "default/titlebar/ontop_normal_inactive.png"
theme.titlebar_ontop_button_focus_inactive  = themes_path .. "default/titlebar/ontop_focus_inactive.png"
theme.titlebar_ontop_button_normal_active   = themes_path .. "default/titlebar/ontop_normal_active.png"
theme.titlebar_ontop_button_focus_active    = themes_path .. "default/titlebar/ontop_focus_active.png"
theme.titlebar_sticky_button_normal_inactive = themes_path .. "default/titlebar/sticky_normal_inactive.png"
theme.titlebar_sticky_button_focus_inactive  = themes_path .. "default/titlebar/sticky_focus_inactive.png"
theme.titlebar_sticky_button_normal_active   = themes_path .. "default/titlebar/sticky_normal_active.png"
theme.titlebar_sticky_button_focus_active    = themes_path .. "default/titlebar/sticky_focus_active.png"
theme.titlebar_floating_button_normal_inactive = themes_path .. "default/titlebar/floating_normal_inactive.png"
theme.titlebar_floating_button_focus_inactive  = themes_path .. "default/titlebar/floating_focus_inactive.png"
theme.titlebar_floating_button_normal_active   = themes_path .. "default/titlebar/floating_normal_active.png"
theme.titlebar_floating_button_focus_active    = themes_path .. "default/titlebar/floating_focus_active.png"
theme.titlebar_maximized_button_normal_inactive = themes_path .. "default/titlebar/maximized_normal_inactive.png"
theme.titlebar_maximized_button_focus_inactive  = themes_path .. "default/titlebar/maximized_focus_inactive.png"
theme.titlebar_maximized_button_normal_active   = themes_path .. "default/titlebar/maximized_normal_active.png"
theme.titlebar_maximized_button_focus_active    = themes_path .. "default/titlebar/maximized_focus_active.png"

theme.awesome_icon = theme_assets.awesome_icon(theme.menu_height, theme.color_face_dark, theme.color_accent)
theme.menu_submenu_icon = themes_path .. "default/submenu.png"

return theme
