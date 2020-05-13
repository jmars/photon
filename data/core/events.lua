local events = {}


function events.init()
  events.views = setmetatable({}, {
    __mode = 'v'
  })
  events.thread = coroutine.create(events.hit_test_thread)
  coroutine.resume(events.thread, 0, 0)
end


function events.hit_test_thread()
  while true do
    local x, y = coroutine.yield(nil)
    for i=1,#events.views do
      local view = events.views[i]
      local vl, vt = view.vars.left:value(), view.vars.top:value()
      local vr, vb = view.vars.right:value(), view.vars.bottom:value()
      if x >= vl and x <= vr and y >= vt and y <= vb then
        coroutine.yield(view)
      end
    end
  end
end


function events.add_view(view)
  table.insert(events.views, view)
end

function events.on_mouse_pressed(button, x, y, clicks)
  local _, view = coroutine.resume(events.thread, x, y)
  while view ~= nil do
    view:on_mouse_pressed(button, x, y, clicks)
    _, view = coroutine.resume(events.thread, x, y)
  end
end


function events.on_mouse_released(button, x, y)
  local _, view = coroutine.resume(events.thread, x, y)
  while view ~= nil do
    view:on_mouse_released(button, x, y)
    _, view = coroutine.resume(events.thread, x, y)
  end
end


function events.on_mouse_moved(x, y, dx, dy)
  local _, view = coroutine.resume(events.thread, x, y)
  while view ~= nil do
    view:on_mouse_moved(button, x, y, dx, dy)
    _, view = coroutine.resume(events.thread, x, y)
  end
end


function events.on_text_input(text)
  local _, view = coroutine.resume(events.thread, x, y)
  while view ~= nil do
    view:on_text_input(button, text)
    _, view = coroutine.resume(events.thread, x, y)
  end
end


function events.on_mouse_wheel(y)
  local _, view = coroutine.resume(events.thread, x, y)
  while view ~= nil do
    view:on_mouse_pressed(y)
    _, view = coroutine.resume(events.thread, x, y)
  end
end

return events