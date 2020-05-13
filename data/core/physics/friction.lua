local Object = require 'core.object'


local Friction = Object:extend()


function Friction:new(drag)
  self.drag = drag
  self.dragLog = math.log(drag)
  self.x = 0
  self.v = 0
  self.startTime = 0
end


function Friction:set(x, v)
  self.x = x
  self.v = v
  self.startTime = system.get_time()
end


function Friction:x(dt)
  if dt == nil then
    dt = system.get_time - self.startTime
  end
  return self.x + self.v * math.pow(self.drag, dt) / self.dragLog - self.v / self.dragLog
end


function Friction:dx()
  local dt = system.get_time() - self.startTime
  return self.v * math.pow(self.drag, dt)
end


function Friction:done()
  return math.abs(self:dx()) < 1
end


function Friction:reconfigure(drag)
  local x = self:x()
  local v = self:dx()
  self.drag = drag
  self.dragLog = math.log(drag)
  self:set(x, v)
end


return Friction