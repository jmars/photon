local systems = {}
local objects = {}
local instances = {}
local behaviours = {}

local Object = {}
setmetatable(Object, Object)


function Object.new(name, triggers, behaviours)
  local obj = {
    triggers = triggers,
    behaviours = behaviours
  }
  obj.__index = obj
  objects[name] = obj
  instances[name] = {}
  return obj
end


function Object.register_system(system)
  system:init()
  
  for i=1,#system.triggers do
    systems[system.triggers[i]] = system
  end
end


function Object.create(name)
  local obj = setmetatable({}, objects[name])
  table.insert(instances[name], obj)

  for i=1,#obj.triggers do
    local trigger = obj.triggers[i]
    systems[trigger].register(trigger, obj)
  end

  Object.trigger(obj, "init")
  return obj
end


function Object.behaviour(name, triggers, reaction)
  local triggerMap = {}

  for i=1,#triggers do
    local trigger = triggers[i]
    triggerMap[trigger] = true
  end

  behaviours[name] = {
    triggers = triggerMap,
    reaction = reaction
  }
end


function Object.trigger(obj, event, ...)
  for i=1,#obj.behaviours do
    local behaviour = behaviours[obj.behaviours[i]]

    if behaviour.triggers[event] then
      behaviour.reaction(obj, event, ...)
    end
  end
end


function Object:__call(name, triggers, behaviours, init)
  return self.new(name, triggers, behaviours, init)
end


return Object
