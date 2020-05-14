local NAN  =  0.0 / 0.0
local NINF = -math.huge
local PINF =  math.huge

--- Returns true if given value is a finite number; otherwise false or nil if value is not of type string nor number.
function math.finite(value)
  if type(value) == "string" then
    value = tonumber(value)
    if value == nil then return nil end
  elseif type(value) ~= "number" then
    return nil
  end
  return value > NINF and value < PINF
end

--- Returns 1 if given value is a positive infinity or -1 if given value is a negative infinity; otherwise 0 or nil if value is not of type string nor number.
function math.isinf(value)
  if type(value) == "string" then
    value = tonumber(value)
    if value == nil then return nil end
  elseif type(value) ~= "number" then
    return nil
  end
  if value == PINF then return 1 end
  if value == NINF then return -1 end
  return 0
end

--- Returns true if given value is not a number (NaN); otherwise false or nil if value is not of type string nor number.
function math.isnan(value)
  if type(value) == "string" then
    value = tonumber(value)
    if value == nil then return nil end
  elseif type(value) ~= "number" then
    return nil
  end
  return value ~= value
end