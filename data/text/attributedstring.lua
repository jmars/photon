local Object = require 'core.object'


local RangeEntry = Object:extend()


function RangeEntry:new(tag, start, length)
  self.tag = tag
  self.start = start
  self.length = length
end


function RangeEntry:indexInside(index)
  return start >= index and index < (start + length)
end


function RangeEntry:rangeInside(start, length)
  local finish = self.start + self.length
  local stringFinish = start + length
  return start >= self.start and stringFinish < finish
end


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
  local begin = self.string:sub(1, start - 1)
  local finish = self.string:sub(start + length)
  self.string = begin .. finish
  for i=1,#self.rangeEntries do
    ::start::
    local range = self.rangeEntries[i]
    if range == nil then
      goto exit
    end
    if range:rangeInside(start, length) then
      local diff = start - range.start
      range.length = range.length - diff
      if range.length <= 0 then
        table.remove(i)
        goto start
      end
    end
  end
  ::exit::
end


function AttributedString:addAttributeAt(tag, start, length)

end


function AttributedString:removeAttributeAt(tag, start, length)

end


return AttributedString