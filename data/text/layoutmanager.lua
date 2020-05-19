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
  local containerIndex = 1
  local container = self.containers[containerIndex]
  local chunks = self.text:chunks()
  local y = nil
  local x = nil
  local gap = 0
  local batch = {}

  for i=1,#chunks do
    local chunk = chunks[i]
    local words = chunk[1]:gmatch('%S+')
    local attrs = chunk[2]
    local fontConfig = attrs[#attrs] -- just take last for now, no inheritance
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
        if x == 0 then
          x = nil
          y = y + lineHeight
          goto retry
        end
        
        -- left the bounds of the container, try to get the next one
        if x == nil then
          containerIndex = containerIndex + 1
          container == self.containers[containerIndex]

          -- uh oh, no containers left
          if container == nil then
            -- we have run out of space for text
            goto end -- just bail out
          end

          -- we found one, let the loop run again
          table.insert(batch, { container = container, words = {} })
        end
      end

      -- we found a space! add it to the batch and
      table.insert(batch[#batch].words, {
        x = x,
        y = y + (lineHeight / 2) - (height / 2),
        text = word,
        font = font
      })

      -- move our requested x right as we have something there now
      x = x + width + spaceWidth
    end
  end

  ::end::

  -- gather all of the render batches and send them to the views
  for i=1,#batch do
    local container = batch.container
    local words = batch.words
    container:setBatch(function()
      -- keep this loop small, it could be run every frame in the worst case
      for i=1,#words do
        local word = words[i]
        renderer.draw_text(word.font, word.text, word.x, word.y)
      end
    end)
  end
end


return LayoutManager