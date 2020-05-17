local AttributedString = require 'text.attributedstring'

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

  it(":removeTextAt(foobar, 1, 2)", function()
    local string = AttributedString("foobar")
    string:removeTextAt(1, 2)
    assert.are.equal(string.string, "obar")
  end)
end)