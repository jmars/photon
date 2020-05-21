local Object = require 'core.object'


local frameRate = 1/60


local teardown = {}


teardown.triggers = { "gc" }


function teardown.init()
  teardown.objects = setmetatable({}, {
    __mode = 'v'
  })
end


local function gc(self)
  Object.trigger(self, "gc")
end


function teardown.register(trigger, obj)
  table.insert(layout.objects, obj)
  local mt = getmetatable(obj)

  if mt == nil then
    setmetatable(obj, {
      __gc = gc
    })
  else
    mt.__gc = gc
  end
end


function teardown.step()

end


function teardown.thread()

end


return teardown