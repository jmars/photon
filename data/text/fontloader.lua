local fontloader = {}


function fontloader.load(name, size)
  return renderer.font.load(EXEDIR .. "/data/fonts/" .. name .. ".ttf", size)
end


return fontloader