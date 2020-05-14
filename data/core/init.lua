require "core.compat53"
require "core.strict"
require "core.nan"
local config = require "core.config"
local style = require "core.style"
local events = require "core.events"
local common = require "core.common"
local View


local core = {}


function core.init()
  events.init()

  local simulation = require 'core.physics'
  simulation.init()
  
  View = require "core.view"
  local Draggable = require 'views.draggable'

  --renderer.show_debug(true)
  core.frame_start = 0
  core.clip_rect_stack = {{ 0,0,0,0 }}
  core.threads = setmetatable({}, { __mode = "k" })
  core.solver = amoeba.new()
  local S = core.solver
  S:autoupdate(false)

  core.root_view = View()
  core.root_view:add_constraint(
    core.root_view.vars.left :eq (0) :strength "required",
    core.root_view.vars.top :eq (0) :strength "required"
  )
  S:addedit(core.root_view.vars.width, "required")
  S:addedit(core.root_view.vars.height, "required")

  local boundaries = View()
  boundaries:add_constraint(
    boundaries.vars.top :eq (100) :strength "required",
    boundaries.vars.left :eq (300) :strength "required",
    boundaries.vars.height :eq (500) :strength "required",
    boundaries.vars.width :eq (500) :strength "required"
  )

  boundaries.style.background_color = { common.color "#111111" }

  core.root_view:add_child(boundaries)

  local test = Draggable()
  test:add_constraint(
    test.vars.width :eq (100) :strength "required",
    test.vars.height :eq (100) :strength "required"
  )
  test.style.background_color = style.text
  core.root_view:add_child(test)

  core.solver:addedit(test.vars.left)

  local test2 = View()
  boundaries:add_child(test2)
  test2.style.background_color = style.selection
  test2:add_constraint(
    S:constraint()(test2.vars.left) ">=" (test.vars.right + 100) :strength "medium",
    S:constraint()(test2.vars.left) "==" (test.vars.right) :strength "medium",
    S:constraint()(test2.vars.top) "==" (test.vars.top) :strength "medium",
    test2.vars.width :eq (100) :strength "required",
    test2.vars.height :eq (100) :strength "required"
  )

  core.active_view = core.root_view
  core.add_thread(simulation.thread)
  core.redraw = true
end


function core.quit(force)
  if force then
    os.exit()
  end
  core.quit(true)
end


function core.reload_module(name)
  local old = package.loaded[name]
  package.loaded[name] = nil
  local new = require(name)
  if type(old) == "table" then
    for k, v in pairs(new) do old[k] = v end
    package.loaded[name] = old
  end
end


function core.add_thread(f, weak_ref)
  local key = weak_ref or #core.threads + 1
  local fn = function() return core.try(f) end
  core.threads[key] = { cr = coroutine.create(fn), wake = 0 }
end


function core.push_clip_rect(x, y, w, h)
  local x2, y2, w2, h2 = table.unpack(core.clip_rect_stack[#core.clip_rect_stack])
  local r, b, r2, b2 = x+w, y+h, x2+w2, y2+h2
  x, y = math.max(x, x2), math.max(y, y2)
  b, r = math.min(b, b2), math.min(r, r2)
  w, h = r-x, b-y
  table.insert(core.clip_rect_stack, { x, y, w, h })
  renderer.set_clip_rect(x, y, w, h)
end


function core.pop_clip_rect()
  table.remove(core.clip_rect_stack)
  local x, y, w, h = table.unpack(core.clip_rect_stack[#core.clip_rect_stack])
  renderer.set_clip_rect(x, y, w, h)
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


function core.step()
  -- handle events
  local mouse_moved = false
  local mouse = { x = 0, y = 0, dx = 0, dy = 0 }

  for type, a,b,c,d in system.poll_event do
    if type == "mousemoved" then
      mouse_moved = true
      mouse.x, mouse.y = a, b
      mouse.dx, mouse.dy = mouse.dx + c, mouse.dy + d
    else
      local _, res = core.try(core.on_event, type, a, b, c, d)
    end
  end
  if mouse_moved then
    core.try(core.on_event, "mousemoved", mouse.x, mouse.y, mouse.dx, mouse.dy)
  end

  local width, height = renderer.get_size()

  -- update
  core.solver:suggest(core.root_view.vars.width, width)
  core.solver:suggest(core.root_view.vars.height, height)
  core.solver:update()
  core.root_view:update()
  if not core.redraw then
    if not system.window_has_focus() then system.wait_event(0.5) end
    return
  end
  core.redraw = false

  -- update window title
  local name = core.active_view:get_name()
  if name ~= "---" then
    system.set_window_title(name .. " - lite")
  else
    system.set_window_title("lite")
  end

  -- draw
  renderer.begin_frame()
  core.clip_rect_stack[1] = { 0, 0, width, height }
  renderer.set_clip_rect(table.unpack(core.clip_rect_stack[1]))
  core.root_view:draw()
  renderer.end_frame()
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
    core.step()
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
