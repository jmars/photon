local Object = require 'core.object'


local frameRate = 1/60


local count = 0
local function inc()
  count = count + 1
  return count
end


local layout = {}


layout.triggers = { "layout", "initLayout" }


local function addConstraint(self, constraint)
  layout.solver:addconstraint(constraint)
  table.insert(self.layout.constraints, constraint)
end


function layout.init()
  layout.objects = setmetatable({}, {
    __mode = 'v'
  })
  local S = amoeba.new()
  layout.solver = S
  S:autoupdate(false)
end


function layout.register(trigger, obj)
  if trigger == 'initLayout' then
    local S = layout.solver

    local num = inc()
    local left = S:var (num .. "left")
    local top = S:var (num .. "top")
    local right = S:var (num .. "right")
    local bottom = S:var (num .. "bottom")
    local width = S:var (num .. "width")
    local height = S:var (num .. "height")
    local centerX = S:var (num .. "centerX")
    local centerY = S:var (num .. "centerY")

    local constraints = {
      width :eq (right - left) :strength "required",
      height :eq (bottom - top) :strength "required",
      centerX :eq (left + (width / 2)) :strength "required",
      centerY :eq (top + (height / 2)) :strength "required",
      S:constraint()(left) "<=" (right) :strength "required",
      S:constraint()(top) "<=" (bottom) :strength "required"
    }

    for i=1,#constraints do
      S:addconstraint(constraints[i])
    end

    obj.layout = {
      vars = {
        left = left,
        top = top,
        right = right,
        bottom = bottom,
        width = width,
        height = height,
        centerX = centerX,
        centerY = centerY
      },
      constraints = constraints,
      solver = S
    }

    table.insert(layout.objects, obj)
    Object.trigger(obj, "initLayout", S, addConstraint)
  end
end


function layout.step()
  layout.solver:update()
  for i=1,#layout.objects do
    local obj = layout.objects[i]
    Object.trigger(obj, 'layout', layout.solver)
  end
end


function layout.thread()
  while true do
    layout.step()
    coroutine.yield(frameRate)
  end
end


return layout