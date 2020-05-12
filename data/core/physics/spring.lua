local Object = require 'core.object'

local epsilon = 0.001;

local function almostEqual(a, b, epsilon)
  return (a > (b - epsilon)) and (a < (b + epsilon))
end

local function almostZero(a, epsilon)
  return almostEqual(a, 0, epsilon)
end


local Spring = Object:extend()

function Spring:new(mass, springConstant, damping)
  self.m = mass
  self.k = springConstant
  self.c = damping
  self.solution = nil
  self.endPosition = 0
  self.startTime = 0
end


function Spring:solve(initial, velocity)
  local c = self.c
  local m = self.m
  local k = self.k

  return {
    x = function(t)
      local x, dx = physics.spring(c, m, k, initial, velocity, t)
      return x
    end,
    dx = function(t)
      local x, dx = physics.spring(c, m, k, initial, velocity, t)
      return dx
    end
  }
end


function Spring:x(dt)
  if dt == nil then
    dt = system.get_time() - self.startTime
  end
  if self.solution ~= nil then
    return self.endPosition + self.solution.x(dt)
  else
    return 0
  end
end


function Spring:dx(dt)
  if dt == nil then
    dt = system.get_time() - self.startTime
  end
  if self.solution ~= nil then
    self.solution.dx(dt)
  else
    return 0
  end
end


function Spring:setEnd(x, velocity, t)
  if not t then
    t = system.get_time()
  end
  if x == self.endPosition and almostZero(velocity, epsilon) then
    return
  end
  velocity = velocity or 0
  local position = self.endPosition
  if self.solution then
    if almostZero(velocity, epsilon) then
      velocity = self.solution.dx(t - self.startTime)
    end
    position = self.solution.x(t - self.startTime)
    if almostZero(velocity, epsilon) then
      velocity = 0
    end
    if almostZero(position, epsilon) then
      position = 0
    end
    position = position + self.endPosition
  end
  if self.solution and almostZero(position - x, epsilon) and almostZero(velocity, epsilon) then
    return
  end
  self.endPosition = x
  self.solution = self.solve(position - self.endPosition, velocity)
  self.startTime = t
end


function Spring:snap(x)
  self.startTime = system.get_time()
  self.endPosition = x
  self.solution = {
    x = function() return 0 end,
    dx = function() return 0 end
  }
end


function Spring:done(t)
  if not t then
    t = system.get_time()
  end
  return almostEqual(self:x(), self.endPosition, epsilon) and almostZero(self:dx(), epsilon)
end


function Spring:reconfigure(mass, springConstant, damping)
  self.m = mass
  self.k = springConstant
  self.c = damping

  if self:done() then
    return
  end

  self.solution = self:solve(self:x() - self.endPosition, self:dx())
  self.startTime = system.get_time
end


function Spring:springConstant()
  return self.k
end


function Spring:damping()
  return self.c
end


return Spring