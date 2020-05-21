local systems = {}
local objects = {}
local instances = {}
local behaviours = {}
local tags = {}

local Object = {}
setmetatable(Object, Object)


function Object.tag_behaviours(name, behaviours)
  tags[name] = behaviours
end


function Object.new(name, triggers, behaviours, tags)
  local obj = {
    tags = tags or {},
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
  for i=0,#obj.tags do
    local bes = i == 0 and obj.behaviours or tags[obj.tags[i]]
    for i=1,#bes do
      local behaviour = behaviours[bes[i]]

      if behaviour.triggers[event] then
        behaviour.reaction(obj, event, ...)
      end
    end
  end
end


function Object:__call(name, triggers, behaviours, init)
  return self.new(name, triggers, behaviours, init)
end


return Object
