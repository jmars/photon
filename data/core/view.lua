local core = require "core"
local config = require "core.config"
local style = require "core.style"
local common = require "core.common"
local Object = require "core.object"


local View = Object:extend()


function View:new()
  local S = core.solver
  local left = S:var "left"
  local top = S:var "top"
  local right = S:var "right"
  local bottom = S:var "bottom"
  local width = S:var "width"
  local height = S:var "height"
  local centerX = S:var "centerX"
  local centerY = S:var "centerY"

  S:addconstraint(S:constraint()(left) ">=" (0))
  S:addconstraint(S:constraint()(top) ">=" (0))
  S:addconstraint(width :eq (right - left))
  S:addconstraint(height :eq (bottom - top))
  S:addconstraint(centerX :eq (left + (width / 2)))
  S:addconstraint(centerY :eq (top + (height / 2)))

  self.constraints = {
    left = left,
    top = top,
    right = right,
    bottom = bottom,
    width = width,
    height = height,
    centerX = centerX,
    centerY = centerY
  }
  self.scroll = { x = 0, y = 0, to = { x = 0, y = 0 } }
  self.cursor = "arrow"
  self.scrollable = false
  self.focusable = true
  self.children = {}
  self.parent = nil
  self.style = {
    background_color = style.background
  }
end


function View:move_towards(t, k, dest, rate)
  if type(t) ~= "table" then
    return self:move_towards(self, t, k, dest, rate)
  end
  local val = t[k]
  if math.abs(val - dest) < 0.5 then
    t[k] = dest
  else
    t[k] = common.lerp(val, dest, rate or 0.5)
  end
  if val ~= dest then
    core.redraw = true
  end
end


function View:try_close(do_close)
  do_close()
end


function View:get_name()
  return "---"
end


function View:get_scrollable_size()
  return math.huge
end


function View:get_scrollbar_rect()
  local sz = self:get_scrollable_size()
  local height = self.constraints.height:value()
  if sz <= height or sz == math.huge then
    return 0, 0, 0, 0
  end
  local h = math.max(20, height * height / sz)
  local right = self.constraints.right:value()
  local top = self.constraints.top:value()
  return
    right - style.scrollbar_size,
    top + self.scroll.y * (height - h) / (sz - height),
    style.scrollbar_size,
    h
end


function View:scrollbar_overlaps_point(x, y)
  local sx, sy, sw, sh = self:get_scrollbar_rect()
  return x >= sx - sw * 3 and x < sx + sw and y >= sy and y < sy + sh
end


function View:on_mouse_pressed(button, x, y, clicks)
  if self:scrollbar_overlaps_point(x, y) then
    self.dragging_scrollbar = true
    return true
  end
end


function View:on_mouse_released(button, x, y)
  self.dragging_scrollbar = false
end


function View:on_mouse_moved(x, y, dx, dy)
  if self.dragging_scrollbar then
    local height = self.constraints.height:value()
    local delta = self:get_scrollable_size() / height * dy
    self.scroll.to.y = self.scroll.to.y + delta
  end
  self.hovered_scrollbar = self:scrollbar_overlaps_point(x, y)
end


function View:on_text_input(text)
  -- no-op
end


function View:on_mouse_wheel(y)
  if self.scrollable then
    self.scroll.to.y = self.scroll.to.y + y * -config.mouse_wheel_scroll
  end
end


function View:get_content_bounds()
  local x = self.scroll.x
  local y = self.scroll.y
  local width = self.constraints.width:update()
  local height = self.constraints.height:update()
  return x, y, x + width, y + height
end


function View:get_content_offset()
  local left = self.constraints.left:value()
  local top = self.constraints.top:value()
  local x = common.round(left - self.scroll.x)
  local y = common.round(top - self.scroll.y)
  return x, y
end


function View:clamp_scroll_position()
  local max = self:get_scrollable_size() - self.constraints.height:value()
  self.scroll.to.y = common.clamp(self.scroll.to.y, 0, max)
end


function View:update()
  self:clamp_scroll_position()
  self:move_towards(self.scroll, "x", self.scroll.to.x, 0.3)
  self:move_towards(self.scroll, "y", self.scroll.to.y, 0.3)
end


function View:draw_background(color)
  local x, y = self.constraints.left:value(), self.constraints.top:value()
  local w, h = self.constraints.width:value(), self.constraints.height:value()
  renderer.draw_rect(x, y, w + x % 1, h + y % 1, color)
end


function View:draw_scrollbar()
  local x, y, w, h = self:get_scrollbar_rect()
  local highlight = self.hovered_scrollbar or self.dragging_scrollbar
  local color = highlight and style.scrollbar2 or style.scrollbar
  renderer.draw_rect(x, y, w, h, color)
end


function View:addChild(child)
  table.insert(self.children, child)
  child.parent = self
  return child
end


function View:draw()
  self:draw_background(self.style.background_color)
end


return View
