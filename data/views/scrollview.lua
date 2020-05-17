local core = require 'core'
local View = require 'core.view'
local style = require "core.style"
local Scrollable = require 'views.scrollable'

local ScrollView = View:extend()


function ScrollView:new(direction)
  ScrollView.super.new(self)
  local panel = Scrollable(direction)
  local S = core.solver

  panel:add_constraint(
    panel.vars.top :eq (self.vars.top) :strength "weak",
    panel.vars.left :eq (self.vars.left) :strength "weak"
  )

  panel.style.background_color = style.text

  self.children = { panel }

  if direction == nil or direction == 'vertical' then
    panel:add_constraint(
      S:constraint()(panel.vars.top) "<=" (self.vars.top),
      S:constraint()(panel.vars.bottom) ">=" (self.vars.bottom),
      panel.vars.centerX :eq (self.vars.centerX),
      panel.vars.width :eq (self.vars.width)
    )
  elseif direction == 'horizontal' then
    panel:add_constraint(
      S:constraint()(panel.vars.left) "<=" (self.vars.left),
      S:constraint()(panel.vars.right) ">=" (self.vars.right),
      panel.vars.centerY :eq (self.vars.centerY),
      panel.vars.height :eq (self.vars.height)
    )
  else
    error('Scrollview: Invalid direction')
  end
end


function ScrollView:add_child(child)
  return self.children[1]:add_child(child)
end


function ScrollView:draw()
  local left = self.vars.left:value()
  local top = self.vars.top:value()
  local width = self.vars.width:value()
  local height = self.vars.height:value()
  core.push_clip_rect(left, top, width, height)
  ScrollView.super.draw(self)
  core.pop_clip_rect()
end


return ScrollView