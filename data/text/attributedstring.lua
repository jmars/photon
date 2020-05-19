local Object = require 'core.object'
local RangeEntry = require 'text.rangeentry'


local AttributedString = Object:extend()


function AttributedString:new(string)
  self.string = string
  self.rangeEntries = {}
end


function AttributedString:insertTextAt(string, index)
  local length = #string
  local start = self.string:sub(1, index - 1)
  local finish = self.string:sub(index)
  self.string = start .. string .. finish
  for i=1,#self.rangeEntries do
    local range = self.rangeEntries[i]
    if range:indexInside(index) then
      range.length = range.length + length
    end
  end
end


function AttributedString:removeTextAt(start, length)
  if length == nil then
    length = #self.string - start + 1
  end
  local begin = self.string:sub(1, start - 1)
  local finish = self.string:sub(start + length)
  self.string = begin .. finish
  self:removeAttributeAt(nil, start, length)
  for i=1,#self.rangeEntries do
    local entry = self.rangeEntries[i]
    if entry.start > start then
      entry.start = entry.start - length
    end
  end
  self:sort()
end


function AttributedString:addAttributeAt(tag, start, length)
  local entry = RangeEntry(tag, start, length)
  table.insert(self.rangeEntries, entry)
  self:sort()
end


function AttributedString:sort()
  -- remove empty ranges
  local entries = {}
  for i=1,#self.rangeEntries do
    local entry = self.rangeEntries[i]
    if entry.length > 0 and entry.start >= 0 then
      table.insert(entries, entry)
    end
  end
  
  -- sort by start index
  table.sort(entries, function(a, b) return a.start < b.start end)
  
  self.rangeEntries = entries
end


function AttributedString:attributesAt(index)
  local entries = {}
  for i=1,#self.rangeEntries do
    local entry = self.rangeEntries[i]
    if entry:indexInside(index) then
      table.insert(entries, entry)
    end
  end
  return entries
end


function AttributedString:removeAttributeAt(tag, start, length)
  local effected = self:attributesAt(start)
  local entries = {}
  for i=1,#effected do
    local entry = effected[i]
    if entry.tag == tag or tag == nil then
      entry.length = 0
      local left, right = entry:splitRangeAt(start, length)
      if left.length > 0 then
        table.insert(entries, left)
      end
      if right.length > 0 then
        table.insert(entries, right)
      end
    end
  end
  self.rangeEntries = entries
  self:sort()
end


function AttributedString:chunks()
  -- find points where ranges overlap
  local breaks = {}
  for i=1,#self.rangeEntries do
    local entry = self.rangeEntries[i]
    table.insert(breaks, entry.start)
    table.insert(breaks, entry.start + entry.length)
  end

  -- sort by index
  table.sort(breaks)

  -- take the slices
  local chunks = {}
  for i=1,#breaks do
    local span = breaks[i]
    local next = breaks[i+1]
    if next ~= nil then
      next = next - 1
    end
    local string = self.string:sub(span, next)
    local attributes = self:attributesAt(span)
    if string ~= '' then
      table.insert(chunks, { string, attributes, span })
    end
  end
  return chunks
end


return AttributedString