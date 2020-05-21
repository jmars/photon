require "core.compat53"
require "core.strict"
require "core.nan"
local config = require "core.config"
local style = require "core.style"
local common = require "core.common"

local events = require 'systems.events'
local layout = require 'systems.layout'
local physics = require 'systems.physics'
local render = require 'systems.render'
local teardown = require 'systems.teardown'


local Object = require 'core.object'


local core = {}

function core.init()
  Object.register_system(render)
  Object.register_system(events)
  Object.register_system(layout)

  --renderer.show_debug(true)
  core.frame_start = 0
  core.threads = setmetatable({}, { __mode = "k" })

  core.add_thread(render.thread)
  core.add_thread(events.thread)
  core.add_thread(layout.thread)

  Object.behaviour("boxLayout", { "initLayout" }, function(obj, _, S, addConstraint)
    local vars = obj.layout.vars
    addConstraint(obj, vars.left :eq (0))
    addConstraint(obj, vars.top :eq (0))
    addConstraint(obj, vars.width :eq (100))
    addConstraint(obj, vars.height :eq (100))
  end)

  Object.behaviour("boxDraw", { "draw" }, function(obj, _, width, height)
    local vars = obj.layout.vars
    local x, y = vars.left:value(), vars.top:value()
    local w, h = vars.width:value(), vars.height:value()
    renderer.draw_rect(x, y, w, h, style.background)
  end)

  Object.new("box", { "initLayout", "draw" }, { "boxLayout", "boxDraw" })

  core.box = Object.create('box')
end


function core.add_thread(f, weak_ref)
  local key = weak_ref or #core.threads + 1
  local fn = function() return core.try(f) end
  core.threads[key] = { cr = coroutine.create(fn), wake = 0 }
end


local function log(icon, icon_color, fmt, ...)
  local text = string.format(fmt, ...)
  if icon then
    core.status_view:show_message(icon, icon_color, text)
  end

  local info = debug.getinfo(2, "Sl")
  local at = string.format("%s:%d", info.short_src, info.currentline)
  local item = { text = text, time = os.time(), at = at }
  table.insert(core.log_items, item)
  if #core.log_items > config.max_log_items then
    table.remove(core.log_items, 1)
  end
  return item
end


function core.log(...)
  return log("i", style.text, ...)
end


function core.log_quiet(...)
  return log(nil, nil, ...)
end


function core.error(...)
  return log("!", style.accent, ...)
end


function core.try(fn, ...)
  local err
  local ok, res = xpcall(fn, function(msg)
    local item = core.error("%s", msg)
    item.info = debug.traceback(nil, 2):gsub("\t", "")
    err = msg
  end, ...)
  if ok then
    return true, res
  end
  return false, err
end


function core.on_event(type, ...)
  if type == "textinput" then
    events.on_text_input(...)
  elseif type == "mousemoved" then
    events.on_mouse_moved(...)
  elseif type == "mousepressed" then
    events.on_mouse_pressed(...)
  elseif type == "mousereleased" then
    events.on_mouse_released(...)
  elseif type == "mousewheel" then
    events.on_mouse_wheel(...)
  elseif type == "quit" then
    core.quit()
  end
end


local run_threads = coroutine.wrap(function()
  while true do
    local max_time = 1 / config.fps - 0.004
    local ran_any_threads = false

    for k, thread in pairs(core.threads) do
      -- run thread
      if thread.wake < system.get_time() then
        local _, wait = assert(coroutine.resume(thread.cr))
        if coroutine.status(thread.cr) == "dead" then
          if type(k) == "number" then
            table.remove(core.threads, k)
          else
            core.threads[k] = nil
          end
        elseif wait then
          thread.wake = system.get_time() + wait
        end
        ran_any_threads = true
      end

      -- stop running threads if we're about to hit the end of frame
      if system.get_time() - core.frame_start > max_time then
        coroutine.yield()
      end
    end

    if not ran_any_threads then coroutine.yield() end
  end
end)


function core.run()
  while true do
    core.frame_start = system.get_time()
    run_threads()
    local elapsed = system.get_time() - core.frame_start
    system.sleep(math.max(0, 1 / config.fps - elapsed))
  end
end


function core.on_error(err)
  -- write error to file
  local fp = io.open(EXEDIR .. "/error.txt", "wb")
  fp:write("Error: " .. tostring(err) .. "\n")
  fp:write(debug.traceback(nil, 4))
  fp:close()
end


return core
