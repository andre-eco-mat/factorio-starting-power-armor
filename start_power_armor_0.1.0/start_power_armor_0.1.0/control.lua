-- Start Power Armor - control.lua
-- Robust version detection and cross-version compatibility helpers
local equipment_list = {
  "night-vision-equipment",
  "personal-laser-defense-equipment",
  "personal-laser-defense-equipment",
  "personal-battery-mk2-equipment",
  "personal-battery-mk2-equipment",
  "energy-shield-mk2-equipment",
  "personal-roboport-mk2-equipment",
  "exoskeleton-equipment",
  "fusion-reactor-equipment"
}

-- Determine the Factorio 'base' version string, prefer game.active_mods["base"]
local function get_base_version_string()
  if game and game.active_mods and game.active_mods["base"] then
    return game.active_mods["base"]
  end
  -- Fallback to game.version table if available
  if game and game.version then
    -- game.version may be a table with fields major/minor/patch/build or a string; try to construct a string
    if type(game.version) == "table" then
      local v = game.version
      return string.format("%d.%d.%d", v.major or 0, v.minor or 0, v.patch or 0)
    else
      return tostring(game.version)
    end
  end
  return "unknown"
end

-- Parse a version string like "2.0.43" into {major=2, minor=0, patch=43}
local function parse_version_string(s)
  if not s or type(s) ~= "string" then return nil end
  local major, minor, patch = s:match("^(%d+)%.(%d+)%.(%d+)")
  if major then
    return {major = tonumber(major), minor = tonumber(minor), patch = tonumber(patch)}
  end
  -- try two-part "2.0"
  major, minor = s:match("^(%d+)%.(%d+)")
  if major then
    return {major = tonumber(major), minor = tonumber(minor), patch = 0}
  end
  return nil
end

-- Robust equipment prototype existence checker that works across Factorio API versions.
local function equipment_prototype_exists(name)
  -- Try game.equipment_prototypes (older API)
  if game and game.equipment_prototypes and game.equipment_prototypes[name] then
    return true
  end
  -- Try prototypes.equipment (newer API where prototypes moved)
  if prototypes and prototypes.equipment and prototypes.equipment[name] then
    return true
  end
  -- Last-resort: some setups expose equipment_prototypes on global table 'equipment_prototypes'
  if _G and _G.equipment_prototypes and _G.equipment_prototypes[name] then
    return true
  end
  return false
end

-- Try to put equipment into a grid, but account for different API quirks.
local function try_put_equipment(grid, name)
  if not (grid and grid.valid) then return false end
  if not equipment_prototype_exists(name) then return false end
  local ok, err = pcall(function() grid.put({name = name}) end)
  return ok
end

-- Equip power armor and populate grid; robust to timing (defer if grid not ready)
local function try_equip_armor(player)
  if not (player and player.valid and player.character) then return end
  local armor_inv = player.get_inventory(defines.inventory.character_armor)
  if not armor_inv then return end

  local cur = armor_inv[1]
  if cur and cur.valid_for_read then
    return
  end

  local inserted = armor_inv.insert({name = "power-armor-mk2", count = 1})
  if inserted == 0 then
    local pos = player.surface.find_non_colliding_position("character", player.position, 2, 0.5) or player.position
    player.surface.spill_item_stack(pos, {name = "power-armor-mk2", count = 1}, true, player.force, false)
    player.play_sound{path = "utility/cannot_build"}
    return
  end

  local armor_stack = armor_inv[1]
  if not (armor_stack and armor_stack.valid_for_read) then return end
  local grid = armor_stack.grid
  if not grid then
    global.pending_players = global.pending_players or {}
    global.pending_players[player.index] = true
    return
  end

  for _, equip_name in ipairs(equipment_list) do
    try_put_equipment(grid, equip_name)
  end
end

script.on_event(defines.events.on_player_created, function(event)
  local player = game.get_player(event.player_index)
  try_equip_armor(player)
end)

script.on_event(defines.events.on_player_respawned, function(event)
  local player = game.get_player(event.player_index)
  try_equip_armor(player)
end)

script.on_event(defines.events.on_tick, function(event)
  if not (global and global.pending_players) then return end
  for player_index,_ in pairs(global.pending_players) do
    local player = game.get_player(player_index)
    if player and player.valid then
      local armor_inv = player.get_inventory(defines.inventory.character_armor)
      if armor_inv and armor_inv[1] and armor_inv[1].valid_for_read and armor_inv[1].grid then
        for _, equip_name in ipairs(equipment_list) do
          try_put_equipment(armor_inv[1].grid, equip_name)
        end
        global.pending_players[player_index] = nil
      end
    else
      global.pending_players[player_index] = nil
    end
  end
end)

-- Add a console command to report detected Factorio/base version and which prototype API will be used
commands.add_command("spa_version", "Print Start Power Armor detected Factorio/base version and prototype lookup method.", function(command)
  local player = nil
  if command.player_index then player = game.get_player(command.player_index) end
  local base_version_str = get_base_version_string()
  local parsed = parse_version_string(base_version_str)
  local proto_source = "unknown"
  if game and game.equipment_prototypes then
    proto_source = "game.equipment_prototypes"
  elseif prototypes and prototypes.equipment then
    proto_source = "prototypes.equipment"
  elseif _G and _G.equipment_prototypes then
    proto_source = "_G.equipment_prototypes"
  end
  local msg = "[Start Power Armor] base version: " .. (base_version_str or "unknown") .. "; prototype lookup: " .. proto_source
  if player then
    player.print(msg)
  else
    -- server console
    log(msg)
  end
end)

-- on_configuration_changed: handle migration when game version or mod list changes
script.on_configuration_changed(function(data)
  -- If the game version changed, re-run pending equips for players without armor (best-effort)
  for _, player in pairs(game.connected_players) do
    local armor_inv = player.get_inventory(defines.inventory.character_armor)
    if armor_inv and (not armor_inv[1] or not armor_inv[1].valid_for_read) then
      try_equip_armor(player)
    end
  end
end)
