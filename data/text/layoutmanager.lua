local Object = require 'core.object'


local LayoutManager = Object:extend()


function LayoutManager:new(text, containers)
  self.text = text
  self.containers = containers or {}
end


function LayoutManager:addContainer(container)
  table.insert(self.containers, container)
end


function LayoutManager.runLayout()
  for i=1,#self.text.string do
    local c = self.text.string:sub(i, i)
    local attrs = self.text:attributesAt(i)
    local font = nil
  end
  
end


return LayoutManager