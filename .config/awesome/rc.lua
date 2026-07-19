--[[
  AwesomeWM rc.lua — "boring but reliable" Win9x taskbar
  ---------------------------------------------------------
  Goals:
    * Look like the classic Windows taskbar: numbered tag buttons,
      a layout/"start-ish" square, a client (task) list of raised
      buttons that go sunken when focused, a systray on the right
      with small info widgets and a clock.
    * No gaps, no animations, no fragile external deps beyond
      standard CLI tools already on most systems.
    * Mod+d opens rofi (drun). Everything else is stock-ish
      awesome default keybindings so muscle memory still works.

--]]

pcall(require, "luarocks.loader")

local gears     = require("gears")
local awful     = require("awful")
require("awful.autofocus")
local wibox     = require("wibox")
local beautiful = require("beautiful")
local naughty   = require("naughty")
local menubar   = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")
require("awful.hotkeys_popup.keys")

-- {{{ Error handling
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                      title = "Oops, there were errors during startup!",
                      text = awesome.startup_errors })
end

do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        if in_error then return end
        in_error = true
        naughty.notify({ preset = naughty.config.presets.critical,
                          title = "Oops, an error happened!",
                          text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Theme

beautiful.init(gears.filesystem.get_configuration_dir() .. "theme.lua")

local wallpaper_path = gears.filesystem.get_configuration_dir() .. "pape.png"
screen.connect_signal("property::geometry", function(s)
    if gears.filesystem.file_readable(wallpaper_path) then
        gears.wallpaper.maximized(wallpaper_path, s, false)
    else
        gears.wallpaper.set(beautiful.color_desktop or "#1B3C53")
    end
end)
-- }}}

-- }}}

-- {{{ Variable definitions
local terminal    = "alacritty"
local editor      = os.getenv("EDITOR") or "nvim"
local editor_cmd  = terminal .. " -e " .. editor
local browser     = "firefox"
local rofi_cmd    = "rofi -show drun -theme ~/.config/rofi/config.rasi"
local rofi_run    = "rofi -show run -theme ~/.config/rofi/config.rasi"

local modkey = "Mod4"

awful.layout.layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.max,
    awful.layout.suit.floating,
}
-- }}}

-- {{{ Bevel helper — real Win9x 3D depth on any widget, dynamically swappable.
-- make_bevel(content, face_bg, inner_margins) builds four nested layers:
--   dark_bg > outer_margin(1px) > light_bg > inner_margin(1-2px) > face_bg > content
-- Raised:  light edge top/left,  dark edge bottom/right, content sits flush.
-- Sunken:  dark edge top/left,   light edge bottom/right, content nudges 1px
--          (the classic "pressed in" look).
-- Returns { widget = <the renderable widget>, set_pressed = function(pressed, face_bg) } }
local function make_bevel(content, face_bg, inner_margins)
    inner_margins = inner_margins or 4
    face_bg = face_bg or beautiful.color_face

    local padded = wibox.widget {
        content,
        margins = inner_margins,
        widget  = wibox.container.margin,
    }
    local face_layer = wibox.widget {
        padded,
        bg     = face_bg,
        widget = wibox.container.background,
    }
    local inner_margin = wibox.widget {
        face_layer,
        left = 1, top = 1, right = 0, bottom = 0,
        widget = wibox.container.margin,
    }
    local light_layer = wibox.widget {
        inner_margin,
        bg     = beautiful.color_face_light,
        widget = wibox.container.background,
    }
    local outer_margin = wibox.widget {
        light_layer,
        left = 0, top = 0, right = 1, bottom = 1,
        widget = wibox.container.margin,
    }
    local dark_layer = wibox.widget {
        outer_margin,
        bg     = beautiful.color_face_dark,
        widget = wibox.container.background,
    }

    local obj = { widget = dark_layer }
    function obj:set_pressed(pressed, new_face_bg)
        if pressed then
            light_layer.bg = beautiful.color_face_dark
            dark_layer.bg  = beautiful.color_face_light
            inner_margin.left, inner_margin.top       = 2, 2
            inner_margin.right, inner_margin.bottom   = 0, 0
        else
            light_layer.bg = beautiful.color_face_light
            dark_layer.bg  = beautiful.color_face_dark
            inner_margin.left, inner_margin.top       = 1, 1
            inner_margin.right, inner_margin.bottom   = 0, 0
        end
        face_layer.bg = new_face_bg or face_bg
    end
    obj:set_pressed(false)
    return obj
end

-- Back-compat convenience for one-shot (non-interactive) boxes.
local function bevel(child, pressed, face_bg)
    local b = make_bevel(child, face_bg, 4)
    b:set_pressed(pressed)
    return b.widget
end
-- }}}

-- {{{ Menu (right-click on the "start" square)
local myawesomemenu = {
   { "hotkeys",     function() hotkeys_popup.show_help() end },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart",     awesome.restart },
   { "quit",        function() awesome.quit() end },
}

local mymainmenu = awful.menu({
    items = {
        { "awesome",     myawesomemenu, beautiful.awesome_icon },
        { "terminal",    terminal },
        { "file manager", "thunar" },
        { "web browser", browser },
    }
})
-- }}}

menubar.utils.terminal = terminal

-- {{{ Wibar widgets (right side info cluster)

-- generic boxed text widget (sunken well, like the classic clock area)
local function info_box(w)
    local b = make_bevel(w, beautiful.color_face, 4)
    b:set_pressed(true) -- sunken well
    return b.widget
end

-- Clock
local clock_text = wibox.widget.textclock("%a %d %b  %H:%M", 30)
clock_text.font = beautiful.font
local clock_widget = info_box(clock_text)

-- Memory usage
local mem_text = wibox.widget.textbox("MEM --")
mem_text.font = beautiful.font
local mem_widget = info_box(mem_text)
gears.timer {
    timeout   = 5,
    autostart = true,
    call_now  = true,
    callback  = function()
        local f = io.open("/proc/meminfo", "r")
        if not f then return end
        local vals = {}
        for line in f:lines() do
            local key, val = line:match("^(%a+):%s+(%d+)")
            if key then vals[key] = tonumber(val) end
        end
        f:close()
        if vals.MemTotal and vals.MemAvailable then
            local used_mb = (vals.MemTotal - vals.MemAvailable) / 1024
            local total_mb = vals.MemTotal / 1024
            mem_text:set_text(string.format("MEM %.0f/%.0fM", used_mb, total_mb))
        end
    end
}

-- Disk usage (root)
local disk_text = wibox.widget.textbox("DISK --")
disk_text.font = beautiful.font
local disk_widget = info_box(disk_text)
gears.timer {
    timeout   = 60,
    autostart = true,
    call_now  = true,
    callback  = function()
        awful.spawn.easy_async_with_shell(
            "df -h / | awk 'NR==2{print $3\"/\"$2}'",
            function(stdout)
                disk_text:set_text("DISK " .. stdout:gsub("%s+$", ""))
            end
        )
    end
}

-- Network throughput (default route interface, delta of rx/tx bytes)
local net_text = wibox.widget.textbox("NET --")
net_text.font = beautiful.font
local net_widget = info_box(net_text)
local net_prev = { rx = nil, tx = nil, t = os.time() }
gears.timer {
    timeout   = 2,
    autostart = true,
    callback  = function()
        awful.spawn.easy_async_with_shell(
            "ip route | awk '/default/{print $5; exit}'",
            function(iface)
                iface = iface:gsub("%s+$", "")
                if iface == "" then return end
                local rf = io.open("/sys/class/net/" .. iface .. "/statistics/rx_bytes")
                local tf = io.open("/sys/class/net/" .. iface .. "/statistics/tx_bytes")
                if not (rf and tf) then return end
                local rx, tx = tonumber(rf:read("*a")), tonumber(tf:read("*a"))
                rf:close(); tf:close()
                local now = os.time()
                if net_prev.rx and now > net_prev.t then
                    local dt = now - net_prev.t
                    local down = (rx - net_prev.rx) / dt / 1024
                    local up   = (tx - net_prev.tx) / dt / 1024
                    net_text:set_text(string.format("\u{2193}%.0fK \u{2191}%.0fK", down, up))
                end
                net_prev = { rx = rx, tx = tx, t = now }
            end
        )
    end
}

-- Volume (amixer; swap the two commands for pactl/pipewire-pulse if you use that stack)
local vol_text = wibox.widget.textbox("VOL --")
vol_text.font = beautiful.font
local vol_widget = info_box(vol_text)
local function update_volume()
    awful.spawn.easy_async_with_shell(
        "amixer get Master | grep -o '[0-9]*%' | head -1",
        function(stdout)
            local v = stdout:gsub("%s+$", "")
            if v == "" then v = "?" end
            vol_text:set_text("VOL " .. v)
        end
    )
end
gears.timer { timeout = 10, autostart = true, call_now = true, callback = update_volume }
vol_widget:buttons(gears.table.join(
    awful.button({}, 1, function() awful.spawn("amixer set Master toggle"); update_volume() end),
    awful.button({}, 4, function() awful.spawn("amixer set Master 5%+"); update_volume() end),
    awful.button({}, 5, function() awful.spawn("amixer set Master 5%-"); update_volume() end)
))


-- Systray, boxed to match the rest
local systray = wibox.widget.systray()
local systray_widget = bevel(
    wibox.widget { systray, left = 4, right = 4, top = 2, bottom = 2, widget = wibox.container.margin },
    true
)
-- }}}

-- {{{ Taglist (numbered squares, raised normally, sunken when selected)
local taglist_buttons = gears.table.join(
    awful.button({}, 1, function(t) t:view_only() end),
    awful.button({ modkey }, 1, function(t)
        if client.focus then client.focus:move_to_tag(t) end
    end),
    awful.button({}, 3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, function(t)
        if client.focus then client.focus:toggle_tag(t) end
    end),
    awful.button({}, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({}, 5, function(t) awful.tag.viewprev(t.screen) end)
)

-- Real depth this time: create_callback builds a make_bevel() stack once per
-- item and stashes the handle on `self`; update_callback just flips it
-- pressed/raised + swaps the face colour. Selected tag = sunken + cream
-- accent fill (with dark text so it stays legible); everything else = raised
-- face-coloured button.
local function taglist_paint(self, t)
    local selected = t.selected
    self._text.markup = string.format(
        '<span foreground="%s"><b> %s </b></span>',
        selected and beautiful.color_text_dark or beautiful.color_text, t.name
    )
    self._bevel:set_pressed(selected, selected and beautiful.color_accent or beautiful.color_face)
end

local taglist_template = {
    widget = wibox.container.background,
    create_callback = function(self, t)
        local text = wibox.widget.textbox()
        text.align = "center"
        local b = make_bevel(text, beautiful.color_face, 2)
        self._text, self._bevel = text, b
        self:set_widget(wibox.widget {
            b.widget,
            forced_width = 30,
            widget = wibox.container.constraint,
        })
        taglist_paint(self, t)
    end,
    update_callback = function(self, t) taglist_paint(self, t) end,
}
-- }}}

-- {{{ Tasklist (the actual Win9x-style running-app buttons)
local tasklist_buttons = gears.table.join(
    awful.button({}, 1, function(c)
        if c == client.focus then
            c.minimized = true
        else
            c:emit_signal("request::activate", "tasklist", { raise = true })
        end
    end),
    awful.button({}, 3, function(c)
        awful.menu.client_list({ theme = { width = 200 } })
    end),
    awful.button({}, 4, function() awful.client.focus.byidx(1) end),
    awful.button({}, 5, function() awful.client.focus.byidx(-1) end)
)

-- Authentic Win9x behaviour: the focused window's taskbar button looks
-- *pressed in* (sunken) but stays face-coloured — it does NOT turn navy/
-- accent. Only the Start button / selections get the accent treatment.
local function tasklist_paint(self, c)
    local focused = client.focus == c
    self._text.text = " " .. (c.name or c.class or "?"):sub(1, 30)
    self._bevel:set_pressed(focused, beautiful.color_face)
end
-- }}}

-- {{{ Screen setup
awful.screen.connect_for_each_screen(function(s)
    -- 9 tags, all visible always (predictable > clever)
    awful.tag({ "1", "2", "3", "4", "5" }, s, awful.layout.layouts[1])

    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
        awful.button({}, 1, function() awful.layout.inc(1) end),
        awful.button({}, 3, function() awful.layout.inc(-1) end),
        awful.button({}, 4, function() awful.layout.inc(1) end),
        awful.button({}, 5, function() awful.layout.inc(-1) end)
    ))
    local layoutbox_boxed = bevel(
        wibox.widget { s.mylayoutbox, margins = 3, widget = wibox.container.margin },
        false
    )

    s.mytaglist = awful.widget.taglist {
        screen          = s,
        filter          = awful.widget.taglist.filter.all,
        buttons         = taglist_buttons,
        widget_template = taglist_template,
        layout          = { spacing = 2, layout = wibox.layout.fixed.horizontal },
    }
    local taglist_layout = wibox.widget { s.mytaglist, widget = wibox.container.background }

    s.mytasklist = awful.widget.tasklist {
        screen  = s,
        filter  = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons,
        layout  = { spacing = 3, layout = wibox.layout.flex.horizontal },
        widget_template = {
            widget = wibox.container.background,
            create_callback = function(self, c)
                local icon = wibox.widget {
                    awful.widget.clienticon(c),
                    forced_width  = 16,
                    forced_height = 16,
                    widget = wibox.container.constraint,
                }
                local text = wibox.widget.textbox()
                local content = wibox.widget {
                    icon, text,
                    spacing = 4,
                    layout  = wibox.layout.fixed.horizontal,
                }
                local b = make_bevel(content, beautiful.color_face, 3)
                self._text, self._bevel = text, b
                self:set_widget(wibox.widget {
                    b.widget,
                    forced_height = 24,
                    widget = wibox.container.constraint,
                })
                tasklist_paint(self, c)
            end,
            update_callback = function(self, c) tasklist_paint(self, c) end,
        },
    }

    s.mywibox = awful.wibar({ position = "bottom", screen = s, height = beautiful.wibar_height })

    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        {
            layout = wibox.layout.fixed.horizontal,
            wibox.container.margin(taglist_layout, 3, 3, 3, 3),
            wibox.container.margin(layoutbox_boxed, 0, 4, 3, 3),
        },
        wibox.container.margin(s.mytasklist, 4, 4, 3, 3),
        {
            layout = wibox.layout.fixed.horizontal,
            spacing = 3,
            weather_widget,
            net_widget,
            mem_widget,
            disk_widget,
            vol_widget,
            systray_widget,
            clock_widget,
            wibox.container.margin(wibox.widget.textbox(""), 2, 2, 0, 0),
        },
    }
end)
-- }}}

-- {{{ Mouse bindings on the desktop
root.buttons(gears.table.join(
    awful.button({}, 3, function() mymainmenu:toggle() end),
    awful.button({}, 4, awful.tag.viewnext),
    awful.button({}, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
local globalkeys = gears.table.join(
    awful.key({ modkey }, "s", hotkeys_popup.show_help, { description = "show help", group = "awesome" }),
    awful.key({ modkey }, "Left",  awful.tag.viewprev, { description = "previous tag", group = "tag" }),
    awful.key({ modkey }, "Right", awful.tag.viewnext, { description = "next tag", group = "tag" }),
    awful.key({ modkey }, "Escape", awful.tag.history.restore, { description = "go back", group = "tag" }),

    awful.key({ modkey }, "j", function() awful.client.focus.byidx(1) end, { description = "focus next", group = "client" }),
    awful.key({ modkey }, "k", function() awful.client.focus.byidx(-1) end, { description = "focus prev", group = "client" }),

    -- launchers
    awful.key({ modkey }, "d", function() awful.spawn(rofi_cmd) end, { description = "app launcher (rofi)", group = "launcher" }),
    awful.key({ modkey }, "p", function() awful.spawn(rofi_run) end, { description = "run prompt (rofi)", group = "launcher" }),
    awful.key({ modkey }, "Return", function() awful.spawn(terminal) end, { description = "open terminal", group = "launcher" }),

    awful.key({ modkey, "Control" }, "r", awesome.restart, { description = "reload awesome", group = "awesome" }),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit, { description = "quit awesome", group = "awesome" }),

    awful.key({ modkey }, "l", function() awful.tag.incmwfact(0.05) end, { description = "increase master width", group = "layout" }),
    awful.key({ modkey }, "h", function() awful.tag.incmwfact(-0.05) end, { description = "decrease master width", group = "layout" }),
    awful.key({ modkey }, "space", function() awful.layout.inc(1) end, { description = "next layout", group = "layout" }),
    awful.key({ modkey, "Shift" }, "space", function() awful.layout.inc(-1) end, { description = "prev layout", group = "layout" }),

    awful.key({ modkey, "Control" }, "n", function()
        local c = awful.client.restore()
        if c then c:emit_signal("request::activate", "key.unminimize", { raise = true }) end
    end, { description = "restore minimized", group = "client" }),

    awful.key({}, "Print", function() awful.spawn("scrot -e 'mv $f ~/Pictures/ 2>/dev/null'") end,
        { description = "screenshot", group = "launcher" })
)

local clientkeys = gears.table.join(
    awful.key({ modkey }, "f", function(c) c.fullscreen = not c.fullscreen; c:raise() end,
        { description = "toggle fullscreen", group = "client" }),
    awful.key({ modkey },  "c", function(c) c:kill() end, { description = "close", group = "client" }),
    awful.key({ modkey, "Control" }, "space", awful.client.floating.toggle, { description = "toggle floating", group = "client" }),
    awful.key({ modkey }, "o", function(c) c:move_to_screen() end, { description = "move to screen", group = "client" }),
    awful.key({ modkey }, "t", function(c) c.ontop = not c.ontop end, { description = "toggle ontop", group = "client" }),
    awful.key({ modkey }, "n", function(c) c.minimized = true end, { description = "minimize", group = "client" }),
    awful.key({ modkey }, "m", function(c) c.maximized = not c.maximized; c:raise() end, { description = "maximize", group = "client" })
)

for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9, function()
            local screen = awful.screen.focused()
            local tag = screen.tags[i]
            if tag then tag:view_only() end
        end, { description = "view tag #" .. i, group = "tag" }),
        awful.key({ modkey, "Shift" }, "#" .. i + 9, function()
            if client.focus then
                local tag = client.focus.screen.tags[i]
                if tag then client.focus:move_to_tag(tag) end
            end
        end, { description = "move focused client to tag #" .. i, group = "tag" })
    )
end

local clientbuttons = gears.table.join(
    awful.button({}, 1, function(c) c:emit_signal("request::activate", "mouse_click", { raise = true }) end),
    awful.button({ modkey }, 1, function(c) c:emit_signal("request::activate", "mouse_click", { raise = true }); awful.mouse.client.move(c) end),
    awful.button({ modkey }, 3, function(c) c:emit_signal("request::activate", "mouse_click", { raise = true }); awful.mouse.client.resize(c) end)
)

root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    {
        rule = {},
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus = awful.client.focus.filter,
            raise = true,
            keys = clientkeys,
            buttons = clientbuttons,
            screen = awful.screen.preferred,
            placement = awful.placement.no_overlap + awful.placement.no_offscreen,
        }
    },
    { rule_any = { type = { "normal", "dialog" } },
      properties = { titlebars_enabled = true } },
    { rule = { class = "Pavucontrol" }, properties = { floating = true } },
    { rule = { class = "Arandr" },      properties = { floating = true } },
}
-- }}}

-- {{{ Signals
client.connect_signal("manage", function(c)
    if not awesome.startup then awful.client.setslave(c) end
end)

-- {{{ Titlebars — same make_bevel() 3D depth as the taskbar/taglist
client.connect_signal("request::titlebars", function(c)
    local titlebar_buttons = gears.table.join(
        awful.button({}, 1, function()
            c:emit_signal("request::activate", "titlebar", { raise = true })
            awful.mouse.client.move(c)
        end),
        awful.button({}, 3, function()
            c:emit_signal("request::activate", "titlebar", { raise = true })
            awful.mouse.client.resize(c)
        end)
    )

    -- small square button: bevel + a single glyph, click runs `fn`
    local function titlebar_btn(glyph, fn)
        local label = wibox.widget.textbox()
        label.align, label.valign = "center", "center"
        label.font = beautiful.font
        label.markup = string.format('<span foreground="%s">%s</span>', beautiful.color_text, glyph)
        local b = make_bevel(label, beautiful.color_face, 1)
        local w = wibox.widget { b.widget, forced_width = 22, widget = wibox.container.constraint }
        w:buttons(gears.table.join(
            awful.button({}, 1, function()
                b:set_pressed(true)
                fn()
                gears.timer.delayed_call(function() b:set_pressed(false) end)
            end)
        ))
        return w
    end

    local min_btn   = titlebar_btn("_",  function() c.minimized = true end)
    local max_btn   = titlebar_btn("[]", function() c.maximized = not c.maximized; c:raise() end)
    local close_btn = titlebar_btn("X",  function() c:kill() end)

    local title = wibox.widget.textbox()
    title.font = "Terminus 9"
    title.align, title.valign = "left", "center"
    title.text = c.name or ""
    c:connect_signal("property::name", function() title.text = c.name or "" end)
    local title_bevel = make_bevel(title, beautiful.color_face, 3)
    title_bevel:set_pressed(true) -- sunken well, matches the clock/info boxes

    awful.titlebar(c, { size = 22 }):setup {
        {
            buttons = titlebar_buttons,
            widget  = wibox.container.background,
        },
        {
            title_bevel.widget,
            left = 3, right = 3, top = 3, bottom = 3,
            widget = wibox.container.margin,
        },
        {
            min_btn, max_btn, close_btn,
            spacing = 2,
            layout  = wibox.layout.fixed.horizontal,
        },
        layout = wibox.layout.align.horizontal,
    }
end)
-- }}}

client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", "mouse_enter", { raise = false })
end)

client.connect_signal("focus",   function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

-- {{{ Autostart (keep it short and boring)
awful.spawn.with_shell("pgrep -x picom || picom --backend xrender -b")
awful.spawn.with_shell("nm-applet")
-- }}}
