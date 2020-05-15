local core = require 'core'


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
local frameRate = 1/40
local drag = 0.01
local k = -30 -- Spring stiffness, in kg / s^2 
local b = -30 -- Damping constant, in kg / s


function simulation.init()
  simulation.views = setmetatable({}, {
    __mode = 'v'
  })
end


function simulation.add_view(view)
  table.insert(simulation.views, view)
end


function simulation.step()
  local views = simulation.views
  local redraw = false

  for i=1,#views do
    local view = views[i]
    local dragging = view.dragging
    local animating = view.animating
    local springing = view.springing

    if dragging or not animating then
      goto skip
    end

    local velocity = view.physics.velocity
    local mass = view.physics.mass
    local area = (view.vars.width:value() * view.vars.height:value()) / 10000
    local left = math.abs(view.vars.left:value())
    local top = math.abs(view.vars.top:value())
    local restitution = view.physics.restitution
    local physics = view.physics

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
    local ax = 0
    local ay = 0
    if not springing then
      ax = fx / mass
      ay = ag + (fy / mass)
    else
      local springX = k * (left - physics.target.x)
      local damperX = b * velocity.x
      ax = (springX + damperX) / mass
      local springY = k * (top - physics.target.y)
      local damperY = b * velocity.y
      ay = (springY + damperY) / mass
    end

    local pX = velocity.x
    local pY = velocity.y

    velocity.x = velocity.x + (ax * frameRate)
    velocity.y = velocity.y + (ay * frameRate)

    -- surface friction
    velocity.x = velocity.x * math.pow(drag, frameRate)
    velocity.y = velocity.y * math.pow(drag, frameRate)

    if almostEqual(velocity.x, pX) then
      if almostEqual(velocity.y, pY) then
        view.animating = false
        view.springing = false
        goto skip
      end
    end

    local newLeft = left + (velocity.x * frameRate * 100)
    local newTop = top + (velocity.y * frameRate * 100)

    local S = core.solver
    S:suggest(view.vars.left, newLeft)
    S:suggest(view.vars.top, newTop)

    S:update()

    if not springing and left == view.vars.left:value() then
      velocity.x = velocity.x * restitution
      if view.spring then
        view.springing = true
      end
      physics.target.x = left
      physics.target.y = top
    end

    if not springing and top == view.vars.top:value() then
      velocity.y = velocity.y * restitution
      if view.spring then
        view.springing = true
      end
      physics.target.x = left
      physics.target.y = top
    end

    redraw = true

    ::skip::
  end

  return redraw
end


function simulation.thread()
  while true do
    core.redraw = simulation.step()
    coroutine.yield(frameRate)
  end
end


return simulation
