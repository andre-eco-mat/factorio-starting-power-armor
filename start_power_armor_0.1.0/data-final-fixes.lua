-- data-final-fixes.lua
-- Ensure an exact "power-armor" prototype exists. Run in data-final stage so it
-- can create the prototype after other mods have loaded.

local function find_any_armor_template()
  if not data or not data.raw or not data.raw["armor"] then return nil end
  -- prefer these common armors if present
  if data.raw["armor"]["power-armor"] then return data.raw["armor"]["power-armor"] end
  if data.raw["armor"]["power-armor-mk2"] then return data.raw["armor"]["power-armor-mk2"] end
  if data.raw["armor"]["modular-armor"] then return data.raw["armor"]["modular-armor"] end
  -- otherwise pick first available armor
  for name, proto in pairs(data.raw["armor"]) do
    return proto
  end
  return nil
end

-- Only create if missing
if not (data.raw["armor"] and data.raw["armor"]["power-armor"]) then
  local template = find_any_armor_template()
  if template then
    local clone = table.deepcopy(template)
    clone.name = "power-armor"
    -- adjust order so it doesn't accidentally conflict in UI sorting
    if clone.order then clone.order = "z-" .. tostring(clone.order) end
    -- ensure localised name exists
    clone.localised_name = clone.localised_name or {"item-name.power-armor"}
    data:extend({ clone })
  else
    -- nothing to clone from; will leave missing (rare)
  end
end
