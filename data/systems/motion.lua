local Object = require 'core.object'


local frameRate = 1/60


local ops = {}


function ops.greater(a, b)
  if a >= b then return 0 end
  return b - a
end


function ops.less(a, b)
  if a <= b then return 0 end
  return b - a
end


function ops.l(a, b)
  if a < b then return 0 end
  return b - a
end


function ops.g(a, b)
  if a > b then return 0 end
  return b - a
end


function ops.equal(a, b)
  return b - a
end


function ops.modulo(a, b, naturalEndPosition)
  local nearest = b * math.round(naturalEndPosition / b)
  return nearest - a
end


function ops.adjacentModulo(a, b, naturalEndPosition, gestureStartPosition)
  if gestureStartPosition == nil then
    return ops.modulo(a, b, naturalEndPosition)
  end

  local startNearest = math.round(gestureStartPosition / b)
  local endNearest = math.round(naturalEndPosition / b)

  local difference = endNearest - startNearest

  if difference > 0 then
    difference = difference / math.abs(difference)
  end

  local nearest = (startNearest + difference) * b

  return nearest - a
end


function ops.orr(a, b, naturalEndPosition)
  local MAX_SAFE_INTEGER = 9007199254740991

  if type(b) ~= 'table' then return 0 end

  local distance = MAX_SAFE_INTEGER
  local nearest = naturalEndPosition

  for i=1,#b do
    local dist = math.abs(b[i] - naturalEndPosition)

    if dist > distance then
      goto continue
    end

    distance = dist
    nearest = b[i]

    ::continue::
  end

  return nearest - a
end


local builder = {}


function builder:__call(var)
  local obj = setmetatable({}, builder)
  obj.var = var
  return obj
end


function builder:eq(target)
  self.op = ops.equal
  self.target = target
  return self
end


function builder:gte(target)
  self.op = ops.greater
  self.target = target
  return self
end


function builder:lte(target)
  self.op = ops.less
  self.target = target
  return self
end


function builder:lt(target)
  self.op = ops.l
  self.target = target
  return self
end


function builder:gt(target)
  self.op = ops.g
  self.target = target
  return self
end


function builder:orr(target)
  self.op = ops.orr
  self.target = target
  return self
end


function builder:modulo(target)
  self.op = ops.modulo
  self.target = target
  return self
end


function builder:adjacent(target)
  self.op = ops.adjacentModulo
  self.target = target
  return self
end


builder.__index = builder
setmetatable(builder, builder)


local motion = {}


motion.triggers = { "initMotion", "motionViolation" }


function motion.init()
  motion.objects = setmetatable({}, { __mode = 'v' })
end


function motion.register(trigger, obj)
  if trigger == 'initMotion' then
    obj.motion = {}
    Object.trigger(obj, "initMotion", builder, function(constraint)
      table.insert(obj.motion, constraint)
    end)
    table.insert(motion.objects, obj)
  end
end


function motion.step()
  for i=1,#motion.objects do
    local obj = motion.objects[i]

    for i=1,#obj.motion do
      local constraint = obj.motion[i]
      local current = constraint.var:value()
      local target = type(constraint.target) == 'number' and
        constraint.target or constraint.target:value()
      local op = constraint.op
      local delta = op(current, target)
      if delta ~= 0 then
        Object.trigger(obj, "motionViolation", constraint.var, target, delta)
      end
    end
  end
end


function motion.thread()
  while true do
    motion.step()
    coroutine.yield(frameRate)
  end
end


return motion