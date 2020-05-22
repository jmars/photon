local Object = require 'core.object'
local style = require 'core.style'


local render = {}


local frameRate = 1/60


render.triggers = { "draw" }


function render.push_clip_rect(x, y, w, h)
  local x2, y2, w2, h2 = table.unpack(render.clip_rect_stack[#render.clip_rect_stack])
  local r, b, r2, b2 = x+w, y+h, x2+w2, y2+h2

  x, y = math.max(x, x2), math.max(y, y2)
  b, r = math.min(b, b2), math.min(r, r2)
  w, h = r-x, b-y
  table.insert(render.clip_rect_stack, { x, y, w, h })
  renderer.set_clip_rect(x, y, w, h)
end


function render.pop_clip_rect()
  table.remove(render.clip_rect_stack)
  local x, y, w, h = table.unpack(render.clip_rect_stack[#render.clip_rect_stack])
  renderer.set_clip_rect(x, y, w, h)
end


function render.init()
  render.objects = setmetatable({}, {
    __mode = 'v'
  })
  render.clip_rect_stack = {{ 0,0,0,0 }}
end


function render.register(trigger, obj)
  obj.render = {
    redraw = true
  }
  table.insert(render.objects, obj)
end


function render.step()
  local width, height = renderer.get_size()

  renderer.begin_frame()
  render.clip_rect_stack[1] = { 0, 0, width, height }
  renderer.set_clip_rect(table.unpack(render.clip_rect_stack[1]))

  renderer.draw_rect(0, 0, width, height, style.white)

  for i=1,#render.objects do
    local obj = render.objects[i]
    Object.trigger(obj, "draw", width, height)
  end

  renderer.end_frame()
end


function render.thread()
  while true do
    local status, err = pcall(render.step)
    coroutine.yield(frameRate)
  end
end


return render