local Object = require 'core.object'


local epsilon = 0.1;


local function almostEqual(a, b)
  return (a > (b - epsilon)) and (a < (b + epsilon))
end


local simulation = {}


-- constants
local Cd = 0.47 -- dimensionless
local rho = 1.22 -- fluid density
-- local ag = 9.81 -- gravity
local ag = 0
local frameRate = 1/60
local drag = 0.01
local k = -30 -- Spring stiffness, in kg / s^2 
local b = -30 -- Damping constant, in kg / s


simulation.triggers = { "physics" }


function simulation.init()
  simulation.objects = setmetatable({}, {
    __mode = 'v'
  })
end


function simulation.register(trigger, obj)
  if obj.layout == nil then
    error("Physics: object must have layout")
  end

  local S = obj.layout.solver
  local width = obj.layout.vars.width
  local height = obj.layout.vars.height
  local mass = S:var (num .. "mass")
  table.insert(
    obj.layout.constraints,
    mass :eq (width + height) :strength "required"
  )
  obj.physics = {
    mass = mass,
    velocity = { x = 0, y = 0 },
    restitution = -0.7,
    animating = false
  }
  table.insert(simulation.objects, obj)
end


function simulation.step()
  local objs = simulation.objects

  for i=1,#objs do
    local obj = objs[i]
    local animating = obj.physics.animating

    if not animating then
      goto skip
    end

    local physics = obj.physics
    local velocity = physics.velocity
    local mass = physics.mass:value()
    local restitution = physics.restitution

    local layout = obj.layout
    local area = (layout.vars.width:value() * layout.vars.height:value()) / 10000
    local left = layout.vars.left:value()
    local top = layout.vars.top:value()

    -- drag force from air
    local fx = -0.5 * Cd * area * rho * velocity.x * velocity.x * velocity.x / math.abs(velocity.x)
    local fy = -0.5 * Cd * area * rho * velocity.y * velocity.y * velocity.y / math.abs(velocity.y)

    if math.isnan(fx) or not math.finite(fx) then
      fx = 0
    end

    if math.isnan(fy) or not math.finite(fy) then
      fy = 0
    end

    -- acceleration
    local ax = fx / mass
    local ay = ag + (fy / mass)

    local pX = velocity.x
    local pY = velocity.y

    velocity.x = velocity.x + (ax * frameRate)
    velocity.y = velocity.y + (ay * frameRate)

    -- surface friction
    velocity.x = velocity.x * math.pow(drag, frameRate)
    velocity.y = velocity.y * math.pow(drag, frameRate)

    if almostEqual(velocity.x, pX) then
      if almostEqual(velocity.y, pY) then
        obj.physics.animating = false
        goto skip
      end
    end

    local newLeft = left + (velocity.x * frameRate * 100)
    local newTop = top + (velocity.y * frameRate * 100)

    Object.trigger(obj, "physics", newLeft, newTop)
    
    ::skip::
  end
end


function simulation.thread()
  while true do
    simulation.step()
    coroutine.yield(frameRate)
  end
end


return simulation
