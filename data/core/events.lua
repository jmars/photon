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
      if view:hit_test(x, y) then
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
  for i=1,#events.views do
    view = events.views[i]
    view:on_mouse_pressed_global(button, x, y, clicks)
  end
end


function events.on_mouse_released(button, x, y)
  local _, view = coroutine.resume(events.thread, x, y)
  while view ~= nil do
    view:on_mouse_released(button, x, y)
    _, view = coroutine.resume(events.thread, x, y)
  end
  for i=1,#events.views do
    view = events.views[i]
    view:on_mouse_released_global(button, x, y)
  end
end


function events.on_mouse_moved(x, y, dx, dy)
  local _, view = coroutine.resume(events.thread, x, y)
  while view ~= nil do
    view:on_mouse_moved(x, y, dx, dy)
    _, view = coroutine.resume(events.thread, x, y)
  end
  for i=1,#events.views do
    view = events.views[i]
    view:on_mouse_moved_global(x, y, dx, dy)
  end
end


function events.on_text_input(text)
  for i=1,#events.views do
    local view = events.views[i]
    view:on_text_input(text)
  end
end


function events.on_mouse_wheel(y)
  for i=1,#events.views do
    local view = events.views[i]
    view:on_mouse_wheel(y)
  end
end


return events