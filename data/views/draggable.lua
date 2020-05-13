local core = require "core"
local View = require "core.view"


local Draggable = View:extend()

function Draggable:new(options)
  Draggable.super.new(self, options)
  self.dragging = false
  self.anchorX = 0
  self.anchorY = 0
end

function Draggable:on_mouse_pressed(button, x, y, clicks)
  self.dragging = true
  self.anchorX = x - self.vars.left:value()
  self.anchorY = y - self.vars.top:value()
end

function Draggable:on_mouse_released_global(button, x, y)
  self.dragging = false
end

function Draggable:on_mouse_moved_global(x, y, dx, dy)
  if self.dragging then
    local prevX = self.vars.left:value()
    local prevY = self.vars.top:value()
    local S = core.solver
    local newX = x - self.anchorX
    local newY = y - self.anchorY
    S:suggest(self.vars.left, newX)
    S:suggest(self.vars.top, newY)
    core.redraw = true
  end
end

return Draggable