local View = require 'core.view'


local TextView = View:extend()


local function noop() end


function TextView:new()
  TextView.super.new(self)
  self.text = noop
end


function TextView:draw()
  TextView.super.draw(self)
  self.text()
end


return TextView