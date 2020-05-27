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
local observer = require 'systems.observer'
local motion = require 'systems.motion'

local Object = require 'core.object'


local core = {}


function core.init()
  Object.register_system(render)
  Object.register_system(events)
  Object.register_system(layout)
  Object.register_system(physics)
  Object.register_system(observer)
  Object.register_system(teardown)
  Object.register_system(motion)

  --renderer.show_debug(true)
  core.frame_start = 0
  core.threads = setmetatable({}, { __mode = "k" })

  core.add_thread(render.thread)
  core.add_thread(events.thread)
  core.add_thread(layout.thread)
  core.add_thread(physics.thread)
  core.add_thread(observer.thread)
  core.add_thread(teardown.thread)
  core.add_thread(motion.thread)

  Object.behaviour(
    "boxRender",
    { "initLayout", "draw" },
    function(obj, _, S, addConstraint)
      if _ == "initLayout" then
        local vars = obj.layout.vars
        addConstraint(obj, vars.left :eq (0) :strength "weak")
        addConstraint(obj, vars.top :eq (0) :strength "weak")
        addConstraint(obj, vars.width :eq (100))
        addConstraint(obj, vars.height :eq (100))
      else
        local vars = obj.layout.vars
        local x, y = vars.left:value(), vars.top:value()
        local w, h = vars.width:value(), vars.height:value()
        renderer.draw_rect(x, y, w, h, style.background)
      end
  end)

  Object.behaviour(
    "throwable",
    { 
      "global_mouse_moved",
      "mouse_pressed",
      "global_mouse_released",
      "physicsUpdate"
    },
    function(obj, _, x, y, dx, dy)
      local vars = obj.layout.vars

      if _ == "mouse_pressed" then
        obj.anchorX = x - vars.left:value()
        obj.anchorY = y - vars.top:value()
        obj.dragging = true
      end

      if _ == "global_mouse_released" then
        obj.dragging = false
        obj.physics.animating = true
      end
      
      local S = obj.layout.solver

      if _ == "global_mouse_moved" then
        if not obj.dragging then return end

        obj.physics.velocity.x = x - obj.anchorX - vars.left:value()
        obj.physics.velocity.y = y - obj.anchorY - vars.top:value()

        S:suggest(vars.left, x - obj.anchorX, "required")
        S:suggest(vars.top, y - obj.anchorY, "required")
      end

      if _ == "physicsUpdate" then
        S:suggest(vars.left, x, "required")
        S:suggest(vars.top, y, "required")
      end
  end)

  local Spring = require 'physics.spring'

  Object.behaviour("test", { "initMotion", "motionViolation" }, function(obj, _, a, b, c)
    if _ == "initMotion" then
      local constraint, addConstraint = a, b
      local vars = obj.layout.vars
      addConstraint(constraint(vars.right) :lt (400))
      return
    end

    local var, target, delta = a, b, c

    local S = obj.layout.solver
    obj.physics.animating = false
    local mass = obj.physics.mass:value()

    if obj.motion.spring == nil then
      obj.motion.spring = Spring()
      obj.motion.spring:snap(-var:value())
      obj.motion.spring:setEnd(target, delta)
      S:suggest(var, obj.motion.spring:x())
    else
      S:suggest(var, obj.motion.spring:x())
    end
  end)

  Object()
    :name "box"
    :triggers {
      "initLayout",
      "draw",
      "global_mouse_moved",
      "global_mouse_released",
      "mouse_pressed",
      "physicsUpdate",
      "initMotion",
      "motionViolation"
    }
    :behaviours { "throwable", "boxRender", "test" }
    :define()

  Object 'box'
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
