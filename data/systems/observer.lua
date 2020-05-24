local Object = require 'core.object'


local frameRate = 1/60


local observer = {}


observer.triggers = { "select" }


local function contains(v, t)
  for i=1,#t do
    if t[i] == v then
      return true
    end
  end

  return false
end


-- TODO: compile selectors to lua at runtime
function observer.proxy(name)
  local obj = observer.create(name)
  for i=1,#observer.selects do
    local watching = observer.selects[i]
    local selector = watching.selector

    if obj.name ~= selector.name then
      return obj
    end

    for i=1,#selector.triggers do
      if not contains(selector.triggers[i], obj.triggers) then
        return obj
      end
    end

    for i=1,#selector.behaviours do
      if not contains(selector.behaviours[i], obj.behaviours) then
        return obj
      end
    end

    for i=1,#selector.tags do
      if not contains(selector.tags[i], obj.tags) then
        return obj
      end
    end

    table.insert(selector.results, obj)
    Object.trigger(obj, "select", selector.results)
  end
end


function observer.init()
  observer.selects = setmetatable({}, { __mode = 'v' })
  observer.create = Object.create

  Object.create = observer.proxy
end


function observer.register(trigger, obj)
  obj.selector.results = setmetatable({}, { __mode = 'v' })
  table.insert(observer.selects, obj)
end


function observer.step()
  -- no incremental work
end


function observer.thread()
  -- no loop required
end


return observer