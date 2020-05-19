local Object = require 'core.object'


local TextContainer = Object:extend()


function TextContainer:new(view)
  self.view = view
end


function TextContainer:maybeGetLine(width, height, y1, x)
  if y1 == nil then
    y1 == self.view.vars.top:value()
  end

  if x == nil then
    x = self.view.vars.left:value()
  end

  local y2 = y1 + height

  if not self.view:hit_test(x, y1) then return nil end
  if not self.view:hit_test(x, y2) then return nil end

  local exclusions = self.view.children
  local right = self.view.vars.right:value()

  -- check all of the exclusions to see if we are inside them
  for i=1,#exclusions do
    local exclusion = exclusions[i]
    local next = exclusion[i + 1]
    local limit = next ~= nil and next.vars.left:value() or right
    local er = exclusion.vars.right:value()

    -- rect intersection test
    if (exclusion:hit_test(x, y1)
    or exclusion:hit_test(x, y2))
    or exclusion:hit_test(x + width, y1)
    or exclusion:hit_test(x + width, y2)
    and x < er then
      -- move outside the exclusion
      x = er + 1

      -- check if we have enough space now
      if (next - x) >= size then
        return x, y1, (next - x)
      end
    end
  end

  if (x - right) >= size then
    return x, y1, (x - right)
  else
    return x, y1, 0
  end
end


function TextContainer:setBatch(render)
  -- views know nothing about how text is rendered
  table.insert(self.view.text, render)
end


function reset()
  self.view.text = {}
end


return TextContainer
