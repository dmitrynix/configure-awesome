-- Standard awesome library
require("awful")
require("awful.autofocus")
require("awful.rules")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")
require("vicious")
require("revelation")
require("utility")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
  naughty.notify({ preset = naughty.config.presets.critical,
                   title = "Oops, there were errors during startup!",
                   text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
  local in_error = false
  awesome.add_signal("debug::error", function (err)
    -- Make sure we don't go into an endless error loop
    if in_error then return end
    in_error = true

    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, an error happened!",
                     text = err })
    in_error = false
  end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
-- beautiful.init("/usr/share/awesome/themes/default/theme.lua")
beautiful.init("/home/dmitry/.config/awesome/themes/dust/theme.lua")

-- This is used later as the default terminal and editor to run.
home = os.getenv("HOME")
terminal = "terminator"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -x " .. editor

-- Autorun apps (used every read)
autorunApps = {
  "setxkbmap us -variant mac"
}

-- Startup apps (read only on first run)
startupApps = {
  home .. "/.dropbox-dist/dropboxd start"
}

-- Default modkey (aka command).
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
command = "Mod4"
shift   = "Shift"
control = "Control"
option  = "Mod1"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts = {
  awful.layout.suit.floating,
  awful.layout.suit.tile,
  awful.layout.suit.tile.left,
  awful.layout.suit.tile.bottom,
  awful.layout.suit.tile.top,
  awful.layout.suit.fair,
  awful.layout.suit.fair.horizontal,
  awful.layout.suit.spiral,
  awful.layout.suit.spiral.dwindle,
  awful.layout.suit.max,
  awful.layout.suit.max.fullscreen,
  awful.layout.suit.magnifier
}
-- }}}

-- {{{ Autorun and startup apps
for app = 1, #autorunApps do
  awful.util.spawn(autorunApps[app])
end

for app = 1, #startupApps do
  utility.run_once(startupApps[app])
end
--}}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
  -- Each screen has its own tag table.
  tags[s] = awful.tag({ 1, 2, 3, 4, 5, 6 }, s, layouts[1])
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu

mymainmenu = awful.menu({ items =
  {
     { 'Google Chrome', 'chromium' },
     { 'PcManFM', 'pcmanfm' },
     { 'HandBrake', 'ghb' },
     { 'Skype', 'skype' },
     { 'VirtualBox', 'virtualbox' },
     { 'Terminal', 'terminator' },
     { 'restart', awesome.restart },
     { 'quit', awesome.quit }
  }
})

mylauncher = awful.widget.launcher({ image = image(beautiful.awesome_icon),
                                     menu = mymainmenu })
-- }}}

-- {{{ Wibox

volumewidget = widget({ type = "textbox"})
vicious.register(volumewidget, vicious.widgets.volume,
function(widget, args)
  return args[1] .. '% ' .. args[2]
end, 60, "Master")

-- Create a textclock widget
mytextclock = awful.widget.textclock({ align = "right" })

-- Create a systray
mysystray = widget({ type = "systray" })

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ command }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ command }, 3, awful.client.toggletag),
                    awful.button({ }, 4, awful.tag.viewnext),
                    awful.button({ }, 5, awful.tag.viewprev)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
  -- Create a promptbox for each screen
  mypromptbox[s] = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })
  -- Create an imagebox widget which will contains an icon indicating which layout we're using.
  -- We need one layoutbox per screen.
  mylayoutbox[s] = awful.widget.layoutbox(s)
  mylayoutbox[s]:buttons(awful.util.table.join(
                         awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                         awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                         awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                         awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
  -- Create a taglist widget
  mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, mytaglist.buttons)

  -- Create a tasklist widget
  mytasklist[s] = awful.widget.tasklist(function(c)
                                            return awful.widget.tasklist.label.currenttags(c, s)
                                        end, mytasklist.buttons)

  -- Create the wibox
  mywibox[s] = awful.wibox({ position = "top", screen = s })
  -- Add widgets to the wibox - order matters
  mywibox[s].widgets = {
      {
          mytaglist[s],
          mypromptbox[s],
          layout = awful.widget.layout.horizontal.leftright
      },
      mylayoutbox[s],
      mytextclock,
      volumewidget,
      s == 1 and mysystray or nil,
      mytasklist[s],
      layout = awful.widget.layout.horizontal.rightleft
  }
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
  awful.button({ }, 3, function () mymainmenu:toggle() end),
  awful.button({ }, 4, awful.tag.viewnext),
  awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
  awful.key({ command,         }, "Left",   awful.tag.viewprev       ),
  awful.key({ command,         }, "Right",  awful.tag.viewnext       ),
  awful.key({ command,         }, "Escape", awful.tag.history.restore),
  awful.key({                  }, "XF86LaunchA", revelation          ),
  awful.key({ command,         }, "j", function ()
    awful.client.focus.byidx( 1)
    if client.focus then client.focus:raise() end
  end),
  awful.key({ command,         }, "k", function ()
    awful.client.focus.byidx(-1)
    if client.focus then client.focus:raise() end
  end),
  awful.key({ command,         }, "w", function () mymainmenu:show({keygrabber=true}) end),

  -- Layout manipulation
  awful.key({ command, shift   }, "j", function () awful.client.swap.byidx(  1)    end),
  awful.key({ command, shift   }, "k", function () awful.client.swap.byidx( -1)    end),
  awful.key({ command, control }, "j", function () awful.screen.focus_relative( 1) end),
  awful.key({ command, control }, "k", function () awful.screen.focus_relative(-1) end),
  awful.key({ command,         }, "u", awful.client.urgent.jumpto),
  awful.key({ command,         }, "Tab", function ()
    awful.client.focus.history.previous()
    if client.focus then
      client.focus:raise()
    end
  end),

  -- Volume
  awful.key({ }, "XF86AudioRaiseVolume", function ()
    awful.util.spawn("amixer set Master 2%+")
    vicious.force({ volumewidget })
  end),
  awful.key({ }, "XF86AudioLowerVolume", function ()
    awful.util.spawn("amixer set Master 2%-")
    vicious.force({ volumewidget })
  end),
  awful.key({ }, "XF86AudioMute", function ()
    awful.util.spawn("amixer sset Master toggle")
    vicious.force({ volumewidget })
  end),

  -- Music
  awful.key({ }, "XF86AudioNext", function()
    awful.util.spawn("mpc next")
  end),
  awful.key({ }, "XF86AudioPrev", function()
    awful.util.spawn("mpc prev")
  end),
  awful.key({ }, "XF86AudioPlay", function()
    awful.util.spawn("mpc toggle")
  end),

  -- Screenshots
  awful.key({ command, shift }, "s", function()
    awful.util.spawn("scrot '" .. home .. "/Pictures/Screenshot %Y-%m-%d at %H.%M.%S_$wx$h.png'")
  end),

  -- Standard program
  awful.key({ command,         }, "Return", function () awful.util.spawn(terminal) end),
  awful.key({ command, control }, "r", awesome.restart),
  awful.key({ command, shift   }, "q", awesome.quit),

  awful.key({ option,          }, "l",     function () awful.tag.incmwfact( 0.05)    end),
  awful.key({ option,          }, "h",     function () awful.tag.incmwfact(-0.05)    end),
  awful.key({ option, shift    }, "h",     function () awful.tag.incnmaster( 1)      end),
  awful.key({ option, shift    }, "l",     function () awful.tag.incnmaster(-1)      end),
  awful.key({ command, control }, "h",     function () awful.tag.incncol( 1)         end),
  awful.key({ command, control }, "l",     function () awful.tag.incncol(-1)         end),
  awful.key({ command,         }, "space", function () awful.layout.inc(layouts,  1) end),
  awful.key({ command, shift   }, "space", function () awful.layout.inc(layouts, -1) end),

  awful.key({ command, control }, "h", awful.client.restore),

  -- Prompt
  awful.key({ command }, "r", function ()
    mypromptbox[mouse.screen]:run()
  end),
  awful.key({ command }, "x", function ()
    awful.prompt.run({ prompt = "Run Lua code: " },
    mypromptbox[mouse.screen].widget,
    awful.util.eval, nil,
    awful.util.getdir("cache") .. "/history_eval")
  end)
)

clientkeys = awful.util.table.join(
  awful.key({ command          }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
  awful.key({ command          }, "q",      function (c) c:kill()                         end),
  awful.key({ command, control }, "space",  awful.client.floating.toggle                     ),
  awful.key({ command, control }, "Return", function (c) c:swap(awful.client.getmaster()) end),
  awful.key({ command          }, "o",      awful.client.movetoscreen                        ),
  awful.key({ command, shift   }, "r",      function (c) c:redraw()                       end),
  awful.key({ command          }, "t",      function (c) c.ontop = not c.ontop            end),
  awful.key({ command          }, "h",      function (c)
      -- The client currently has the input focus, so it cannot be
      -- minimized, since minimized clients can't have the focus.
      c.minimized = true
  end),
  awful.key({ command }, "m", function (c)
    c.maximized_horizontal = not c.maximized_horizontal
    c.maximized_vertical   = not c.maximized_vertical
  end)
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
  keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
  globalkeys = awful.util.table.join(globalkeys,
    awful.key({ command }, "#" .. i + 9,
              function ()
                    local screen = mouse.screen
                    if tags[screen][i] then
                        awful.tag.viewonly(tags[screen][i])
                    end
              end),
    awful.key({ command, control }, "#" .. i + 9,
              function ()
                  local screen = mouse.screen
                  if tags[screen][i] then
                      awful.tag.viewtoggle(tags[screen][i])
                  end
              end),
    awful.key({ command, shift }, "#" .. i + 9,
              function ()
                  if client.focus and tags[client.focus.screen][i] then
                      awful.client.movetotag(tags[client.focus.screen][i])
                  end
              end),
    awful.key({ command, control, shift }, "#" .. i + 9,
              function ()
                  if client.focus and tags[client.focus.screen][i] then
                      awful.client.toggletag(tags[client.focus.screen][i])
                  end
              end))
end

clientbuttons = awful.util.table.join(
  awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
  awful.button({ command }, 1, awful.mouse.client.move),
  awful.button({ command }, 3, awful.mouse.client.resize)
)

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
  -- All clients will match this rule.
  {
    rule = { },
    properties = {
      border_width = beautiful.border_width,
      border_color = beautiful.border_normal,
      focus = true,
      keys = clientkeys,
      buttons = clientbuttons
    } },
    { rule = { class = "MPlayer" }, properties = { floating = true } },
    { rule = { class = "pinentry" }, properties = { floating = true } },
    { rule = { class = "gimp" }, properties = { floating = true } },
    { rule = { class = "Skype" }, properties = { floating = false, tag = tags[1][6] }
  }
    -- Set Firefox to always map on tags number 2 of screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { tag = tags[1][2] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
  -- Add a titlebar
  -- awful.titlebar.add(c, { modkey = modkey })

  -- Enable sloppy focus
  c:add_signal("mouse::enter", function(c)
    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
      and awful.client.focus.filter(c) then
      client.focus = c
    end
  end)

  if not startup then
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- awful.client.setslave(c)

    -- Put windows in a smart way, only if they does not set an initial position.
    if not c.size_hints.user_position and not c.size_hints.program_position then
      awful.placement.no_overlap(c)
      awful.placement.no_offscreen(c)
    end
  end
end)

client.add_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
