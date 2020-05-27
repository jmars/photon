local Object = require 'core.class'


local RangeEntry = Object:extend()


function RangeEntry:new(tag, start, length)
  self.tag = tag
  self.start = start
  self.length = length
end


function RangeEntry:indexInside(index)
  return index >= self.start and index < (self.start + self.length)
end


function RangeEntry:splitAt(index)
  local finish = self.start + self.length
  local left = RangeEntry(self.tag, self.start, index - self.start)
  local right = RangeEntry(self.tag, index, self.length - (finish - index))
  return left, right
end


function RangeEntry:splitRangeAt(index, length)
  local finish = index + length
  local left, _ = self:splitAt(index)
  local _, right = self:splitAt(finish)
  return left, right
end


return RangeEntry