local Object = require 'core.object'


local frameRate = 1/60


local events = {}


events.triggers = {
  "mouse_pressed",
  "mouse_released",
  "mouse_moved",
  "text_input",
  "mouse_wheel",
  "global_mouse_pressed",
  "global_mouse_released",
  "global_mouse_moved",
  "global_text_input",
  "global_mouse_wheel"
}


function events.init()
  local weakMT = { __mode = 'v' }
  events.objects = {}

  for i=1,#events.triggers do
    local trigger = events.triggers[i]
    events.objects[trigger] = setmetatable({}, weakMT)
  end

  events.hit_test_thread = coroutine.create(events.hit_test_thread)
  coroutine.resume(events.hit_test_thread, 0, 0)
end


local function hit_test(x, y, obj)
  local vl, vt = obj.layout.vars.left:value(), obj.layout.vars.top:value()
  local vr, vb = obj.layout.vars.right:value(), obj.layout.vars.bottom:value()

  return x >= vl and x <= vr and y >= vt and y <= vb
end


function events.hit_test_thread()
  while true do
    local event, x, y = coroutine.yield(nil)
    local objs = events.objects[event]

    for i=1,#objs do
      local obj = objs[i]
      if hit_test(x, y, obj) then
        coroutine.yield(obj)
      end
    end
  end
end


function events.register(trigger, obj)
  table.insert(events.objects[trigger], obj)
end


-- actual handlers


function events.on_mouse_pressed(button, x, y, clicks)
  local _, obj = coroutine.resume(events.hit_test_thread, "mouse_pressed", x, y)
  
  while obj ~= nil do
    Object.trigger(obj, "mouse_pressed", x, y, clicks)
    _, obj = coroutine.resume(events.hit_test_thread, "mouse_pressed", x, y)
  end

  for i=1,#events.objects.global_mouse_pressed do
    local obj = events.objects.global_mouse_pressed[i]
    Object.trigger(obj, "global_mouse_pressed", x, y, clicks)
  end
end


function events.on_mouse_released(button, x, y)
  local _, obj = coroutine.resume(events.hit_test_thread, "mouse_released", x, y)
  
  while obj ~= nil do
    Object.trigger(obj, "mouse_released", x, y)
    _, obj = coroutine.resume(events.hit_test_thread, "mouse_released", x, y)
  end

  for i=1,#events.objects.global_mouse_released do
    local obj = events.objects.global_mouse_released[i]
    Object.trigger(obj, "global_mouse_released", x, y)
  end
end


function events.on_mouse_moved(x, y, dx, dy)
  local _, obj = coroutine.resume(events.hit_test_thread, "mouse_moved", x, y)
  
  while obj ~= nil do
    Object.trigger(obj, "mouse_moved", x, y, dx, dy)
    _, obj = coroutine.resume(events.hit_test_thread, "mouse_moved", x, y)
  end

  for i=1,#events.objects.global_mouse_moved do
    local obj = events.objects.global_mouse_moved[i]
    Object.trigger(obj, "global_mouse_moved", x, y, dx, dx)
  end
end


function events.on_text_input(text)

end


function events.on_mouse_wheel(y)

end


function events.on_event(type, ...)
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
    os.exit()
  end
end


function events.step()
  local mouse_moved = false
  local mouse = { x = 0, y = 0, dx = 0, dy = 0 }

  for type, a,b,c,d in system.poll_event do
    if type == "mousemoved" then
      mouse_moved = true
      mouse.x, mouse.y = a, b
      mouse.dx, mouse.dy = mouse.dx + c, mouse.dy + d
    else
      events.on_event(type, a, b, c, d)
    end
  end

  if mouse_moved then
    events.on_event("mousemoved", mouse.x, mouse.y, mouse.dx, mouse.dy)
  end
end


function events.thread()
  while true do
    local status, err = pcall(events.step)
    coroutine.yield(frameRate)
  end
end


return events