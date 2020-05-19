local AttributedString = require 'text.attributedstring'
local RangeEntry = require 'text.rangeentry'

describe("AttributedString", function()
  it(":new(string)", function()
    assert.truthy(AttributedString("test"))
    assert.are.equal(AttributedString("test").string, "test")
  end)

  it(":insertTextAt(bar, 1)", function()
    local string = AttributedString("foo")
    string:insertTextAt("ab", 1)
    assert.are.equal(string.string, "abfoo")
  end)

  it(":insertTextAt(bar, 2)", function()
    local string = AttributedString("foo")
    string:insertTextAt("ab", 2)
    assert.are.equal(string.string, "faboo")
  end)

  it(":removeTextAt(foobar, 2, 2)", function()
    local string = AttributedString("foobar")
    string:addAttributeAt("BOLD", 1, 6)
    string:removeTextAt(2, 2)
    assert.are.equal(4, #string.string)
    assert.are.equal(1, string.rangeEntries[1].start)
    assert.are.equal(1, string.rangeEntries[1].length)
    assert.are.equal(3, string.rangeEntries[2].length)
    assert.are.equal(2, string.rangeEntries[2].start)
  end)

  it(":removeTextAt(foobar, 2)", function()
    local string = AttributedString("foobar")
    string:removeTextAt(3)
    assert.are.equal(string.string, "fo")
  end)

  it(":addAttribute(BOLD, 2, 4)", function()
    local string = AttributedString("foobar")
    string:addAttributeAt("BOLD", 2, 4)
    local entries = string:attributesAt(3)
    assert.True(#entries == 1)
    assert.are.equal(entries[1].tag, "BOLD")
  end)

  it(":removeAttributeAt(BOLD, 2, 4)", function()
    local string = AttributedString("foobar")
    string:addAttributeAt("BOLD", 1, 6)
    string:removeAttributeAt("BOLD", 2, 2)
    assert.equal(2, #string.rangeEntries)
    assert.equal(string.rangeEntries[1].start, 1)
    assert.equal(string.rangeEntries[1].length, 1)
    assert.equal(string.rangeEntries[2].start, 4)
    assert.equal(string.rangeEntries[2].length, 3)
  end)

  it(":chunks()", function()
    local string = AttributedString("foobar")
    string:addAttributeAt("BOLD", 1, 3)
    string:addAttributeAt("ITALIC", 2, 5)
    local chunks = string:chunks()
    local bold = RangeEntry("BOLD", 1, 3)
    local italic = RangeEntry("ITALIC", 2, 5)
    assert.same({
      { 'f', { bold }, 1 },
      { 'oo', { bold, italic }, 2 },
      { 'bar', { italic }, 4 }
    }, chunks)
  end)

  it(":chunks() | one span", function()
    local string = AttributedString("foobar")
    string:addAttributeAt("BOLD", 1, 6)
    local chunks = string:chunks()
    local bold = RangeEntry("BOLD", 1, 6)
    assert.same({
      { 'foobar', { bold }, 1 }
    }, chunks)
  end)
end)