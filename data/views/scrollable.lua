local Draggable = require 'views.draggable'

local Scrollable = Draggable:extend()


function Scrollable:new(direction)
  Scrollable.super.new(self)
  self.scroll = direction
end


return Scrollable