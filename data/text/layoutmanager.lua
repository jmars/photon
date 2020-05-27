local Object = require 'core.class'
local style = require 'core.style'
local fontloader = require 'text.fontloader'

local LayoutManager = Object:extend()


function LayoutManager:new(text, containers)
  self.text = text
  self.containers = containers or {}
end


function LayoutManager:addContainer(container)
  table.insert(self.containers, container)
end


function LayoutManager:layout()
  local containerIndex = 1
  local container = self.containers[containerIndex]
  local chunks = self.text:chunks()
  local y = nil
  local x = nil
  local gap = 0
  local batches = { { container = container, words = {} } }

  for i=1,#chunks do
    local chunk = chunks[i]
    local words = chunk[1]:gmatch('%S+')
    local attrs = chunk[2]
    local fontConfig = attrs[#attrs].tag -- just take last for now, no inheritance
    local font = fontloader.load(fontConfig.name, fontConfig.size)
    local lineHeight = fontConfig.lineHeight
    local spaceWidth = font:get_width(" ")
    local height = font:get_height(" ")

    for word in words do
      local width = font:get_width(word)

      -- try to find a viable space candidate
      while gap < width do
        ::retry::

        x, y, gap = container:maybeGetLine(width, lineHeight, y, x)

        -- we have no width left but there may be space for a new line
        if x == -1 then
          x = nil
          y = y + lineHeight
          goto retry
        end
        
        -- left the bounds of the container, try to get the next one
        if x == nil then
          containerIndex = containerIndex + 1
          container = self.containers[containerIndex]
          gap = 0

          -- uh oh, no containers left
          if container == nil then
            -- we have run out of space for text
            goto finish -- just bail out
          end

          -- we found one, let the loop run again
          table.insert(batches, { container = container, words = {} })
        end
      end

      -- we found a space! add it to the batch and
      local l, t = container:getBounds()
      table.insert(batches[#batches].words, {
        x = x - l,
        y = (y + (lineHeight / 2) - (height / 2)) - t,
        text = word,
        font = font
      })

      -- move our requested x right as we have something there now
      x = x + width + spaceWidth
      gap = gap - width - spaceWidth
    end
  end

  ::finish::

  -- gather all of the render batches and send them to the views
  for i=1,#batches do
    -- TODO: relative offsets
    local batch = batches[i]
    local container = batch.container
    local words = batch.words
    container:setBatch(function(x, y)
      -- keep this loop small, it could be run every frame in the worst case
      for i=1,#words do
        local word = words[i]
        renderer.draw_text(word.font, word.text, x + word.x, y + word.y, style.text)
      end
    end)
  end
end


return LayoutManager