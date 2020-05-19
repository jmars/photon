local Object = require 'core.object'


local TextContainer = Object:extend()


function TextContainer:new(view)
  self.view = view
end


function TextContainer:maybeGetLine(x, y)
  local exclusions = self.view.children
  local right = self.view.vars.right:value()

  if not self.view:hit_test(x, y) then return nil end

  for i=1,#exclusions do
    local exclusion = exclusions[i]
    local er = exclusion.vars.right:value()
    if exclusion:hit_test(x, y) and x < er then
      x = er
    end
  end

  return right - x
end


function TextContainer:writeLine(x, y, string)
  table.insert(self.view.text, {
    x = x,
    y = y,
    string = string
  })
end


function reset()
  self.view.text = {}
end


return TextContainer
