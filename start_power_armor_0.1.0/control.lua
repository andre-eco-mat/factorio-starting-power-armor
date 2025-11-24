-- control.lua
-- Gives exactly "power-armor" to newly created characters (no substitutions).
-- Do NOT declare `local global` anywhere in this file.

global = global or {}

local SETTING_NAME = "swpa-auto-equip"
local POWER_ARMOR_NAME = "power-armor"

-- safe test whether game.item_prototypes[name] exists (avoids crashes)
local function prototype_exists(name)
  local ok, proto = pcall(function() return game.item_prototypes[name] end)
  return ok and proto ~= nil
end

local function give_power_armor(player)
  if not player or not player.valid then return end

  -- Only proceed if exact vanilla 'power-armor' exists
  if not prototype_exists(POWER_ARMOR_NAME) then
    -- Friendly message but do not substitute or give fallbacks
    player.print("Start Power Armor mod: exact prototype '" .. POWER_ARMOR_NAME .. "' not available — no items were given.")
    return
  end

  -- read startup setting for auto-equip (default true)
  local auto_equip = true
  if settings and settings.startup and settings.startup[SETTING_NAME] ~= nil then
    auto_equip = settings.startup[SETTING_NAME].value
  end

  -- Try armor slot first if auto-equip enabled
  if auto_equip then
    local armor_inv = player.get_inventory(defines.inventory.character_armor)
    if armor_inv and armor_inv.can_insert({name = POWER_ARMOR_NAME, count = 1}) then
      armor_inv.insert({name = POWER_ARMOR_NAME, count = 1})
      player.print("You received a Power Armor and it was auto-equipped.")
      return
    end
  end

  -- Try main inventory
  local main_inv = player.get_main_inventory()
  if main_inv and main_inv.can_insert({name = POWER_ARMOR_NAME, count = 1}) then
    main_inv.insert({name = POWER_ARMOR_NAME, count = 1})
    player.print("You received a Power Armor in your inventory.")
    return
  end

  -- Try quickbar
  local quickbar = player.get_quickbar()
  if quickbar and quickbar.can_insert({name = POWER_ARMOR_NAME, count = 1}) then
    quickbar.insert({name = POWER_ARMOR_NAME, count = 1})
    player.print("You received a Power Armor in your quickbar.")
    return
  end

  -- If all else fails, drop it on the ground
  if player.surface and player.position then
    player.surface.spill_item_stack(player.position, {name = POWER_ARMOR_NAME, count = 1}, true, nil, false)
    player.print("Your inventory was full; a Power Armor was dropped on the ground next to you.")
  else
    player.print("Start Power Armor: couldn't deliver the Power Armor (no inventory and no valid surface).")
  end
end

-- Initialize global safely
script.on_init(function()
  global = global or {}
end)

-- Hook into player creation
script.on_event(defines.events.on_player_created, function(event)
  local player = game.get_player(event.player_index)
  if not player or not player.valid then return end
  give_power_armor(player)
end)
