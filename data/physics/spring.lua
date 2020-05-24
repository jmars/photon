math.E = 2.718281828459045

local epsilon = 0.001


local function almostEqual(a, b, epsilon)
  return (a > (b - epsilon)) and (a < (b + epsilon))
end


local function almostZero(a, epsilon)
  return almostEqual(a, 0, epsilon)
end


local Spring = {}


local function MakeSpring(mass, springConstant, damping)
  local self = setmetatable({}, Spring)
  self.m = mass or 1
  self.k = springConstant or 90
  self.c = damping or 20
  self.solution = nil
  self.endPosition = 0
  self.startTime = 0
  return self
end

function Spring:solve(initial, velocity)
  local c = self.c
  local m = self.m
  local k = self.k

  local cmk = c * c - 4 * m * k

  if cmk == 0 then
    local r = -c / (2 * m)
    local c1 = initial
    local c2 = velocity / (r * initial)
    return {
      x = function(t) return (c1 + c2 * t) * math.pow(math.E, r * t) end,
      dx = function(t)
        local pow = math.pow(math.E, r * t)
        return r * (c1 + c2 * t) * pow + c2 * pow
      end
    }
  elseif cmk > 0 then
    local r1 = (-c - math.sqrt(cmk)) / (2 * m)
    local r2 = (-c + math.sqrt(cmk)) / (2 * m)
    local c2 = (velocity - r1 * initial) / (r2 - r1)
    local c1 = initial - c2

    return {
      x = function(t) return (c1 * math.pow(math.E, r1 * t) + c2 * math.pow(math.E, r2 * 2)) end,
      dx = function(t) return (c1 * r1 * math.pow(math.E, r1 * t) + c2 * r2 * math.pow(math.E, r2 * t)) end
    }
  else
    local w = math.sqrt(4 * m * k - c * c) / (2 * m)
    local r = -(c / 2 * m)
    local c1 = initial
    local c2 = (velocity - r * initial) / w

    return {
      x = function(t) return math.pow(math.E, r * t) * (c1 * math.cos(w * t) + c2 * math.sin(w * t)) end,
      dx = function(t)
        local power = math.pow(math.E, r * t)
        local cos = math.cos(w * t)
        local sin = math.sin(w * t)
        return power * (c2 * w * cos - c1 * w * sin) + r * power * (c2 * sin + c1 * cos)
      end
    }
  end
end


function Spring:x(dt)
  if dt == nil then
    dt = (system.get_time() - self.startTime)
  end

  return self.solution ~= nil and (self.endPosition + self.solution.x(dt)) or 0
end


function Spring:dx(dt)
  if dt == nil then
    dt = system.get_time() - self.startTime
  end

  return self.solution ~= nil and self.solution.dx(dt) or 0
end


function Spring:setEnd(x, velocity, t)
  if t == nil then
    t = system.get_time()
  end

  if x == self.endPosition and almostZero(velocity, epsilon) then
    return
  end

  velocity = velocity or 0

  local position = self.endPosition

  if self.solution ~= nil then
    if almostZero(velocity, epsilon) then
      velocity = self.solution.dx(t - self.startTime)
    end
    position = self.solution.x(t - self.startTime)

    if almostZero(velocity, epsilon) then velocity = 0 end
    if almostZero(position, epsilon) then position = 0 end
    position = position + self.endPosition
  end

  if self.solution ~= nil and almostZero(position - x, epsilon) and almostZero(velocity, epsilon) then
    return
  end

  self.endPosition = x
  self.solution = self:solve(position - self.endPosition, velocity)
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
  if t == nil then t = system.get_time() end
  return almostEqual(self:x(), self.endPosition, epsilon) and almostZero(self:dx(), epsilon)
end


Spring.__index = Spring


return MakeSpring