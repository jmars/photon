local Object = require 'core.class'


local function hit_test(x, y, obj)
  local vl, vt = obj.layout.vars.left:value(), obj.layout.vars.top:value()
  local vr, vb = obj.layout.vars.right:value(), obj.layout.vars.bottom:value()

  return x >= vl and x <= vr and y >= vt and y <= vb
end


local TextContainer = Object:extend()


function TextContainer:new(view, exclusions)
  self.view = view
  self.exclusions = exclusions
end


function TextContainer:maybeGetLine(width, height, y1, x)
  local vars = self.view.layout.vars

  if y1 == nil then
    y1 = vars.top:value()
  end

  if x == nil then
    x = vars.left:value()
  end

  local y2 = y1 + height

  local viewTop = vars.top:value()
  local viewBottom = vars.bottom:value()

  if y1 < viewTop or y2 > viewBottom then
    return nil
  end

  local exclusions = self.exclusions
  local right = vars.right:value()

  -- check all of the exclusions to see if we are inside them
  for i=1,#exclusions do
    local exclusion = exclusions[i]

    -- optimization: skip obvious bad candidates
    if y1 > exclusion.layout.vars.bottom:value()
    or y2 < exclusion.layout.vars.top:value() then
      goto continue
    end

    local next = exclusion[i + 1]
    local limit = next ~= nil and next.layout.vars.left:value() or right
    local er = exclusion.layout.vars.right:value()

    -- rect intersection test
    if (hit_test(x, y1, exclusion)
    or hit_test(x, y2, exclusion))
    or hit_test(x + width, y1, exclusion)
    or hit_test(x + width, y2, exclusion)
    and x < er then
      -- move outside the exclusion
      x = er + 1

      -- check if we have enough space now
      if (limit - x) >= width then
        return x, y1, (limit - x)
      end
    end

    ::continue::
  end

  if (right - x) >= width then
    return x, y1, (right - x)
  else
    return -1, y1, 0
  end
end


function TextContainer:setBatch(render)
  -- views know nothing about how text is rendered
  self.view.text = render
end


function TextContainer:getBounds()
  local vars = self.view.layout.vars
  return vars.left:value(), vars.top:value(), vars.right:value(), vars.bottom:value()
end


function TextContainer:reset()
  self.view.text = {}
end


return TextContainer
