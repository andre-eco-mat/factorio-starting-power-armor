-- data.lua
-- Create a compatibility "power-armor" if it does not already exist.
-- This clones the first available armor prototype (modular-armor, power-armor-mk2, etc.)
-- and registers it as "power-armor".

local function find_any_armor_prototype()
  if not data or not data.raw or not data.raw["armor"] then return nil end
  -- prefer modular-armor (common) then any other
  if data.raw["armor"]["modular-armor"] then return data.raw["armor"]["modular-armor"] end
  for name, proto in pairs(data.raw["armor"]) do
    return proto
  end
  return nil
end

if not data.raw["armor"] or not data.raw["armor"]["power-armor"] then
  local template = find_any_armor_prototype()
  if template then
    local clone = table.deepcopy(template)
    clone.name = "power-armor"
    if clone.localised_name then
      clone.localised_name = clone.localised_name -- keep
    else
      clone.localised_name = {"item-name.power-armor"}
    end

    -- If the armor has an item subgroup/order settings, you may want to ensure unique order:
    if clone.order then clone.order = "z-" .. (clone.order) end

    -- Register the armor prototype
    data:extend({ clone })
    -- Also ensure an item-with-entity is present: armor prototypes are type "armor" and enough.
  else
    -- no armor to clone from - nothing to do
  end
end
