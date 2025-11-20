Start Power Armor - v0.1.0
---------------------------------
This Factorio mod inserts a Power Armor MK2 pre-equipped for the player when they are created
(new game) and when they respawn if they don't have armor equipped.

**Equipment attempted to be installed (in order):**
- night-vision-equipment
- personal-laser-defense-equipment (two copies)
- personal-battery-mk2-equipment (two copies)
- energy-shield-mk2-equipment
- personal-roboport-mk2-equipment
- exoskeleton-equipment
- fusion-reactor-equipment

**Notes & behavior**
- The mod checks whether each equipment prototype exists in the running Factorio version/mod-list.
  If a named equipment does not exist, it will be skipped (no error).
- The mod equips the armor on player creation (new game) and on respawn if the player has no armor.
- If you want different behavior (only once per save, or give again on join), tell me and I can adjust.
- **Compatibility:** Updated to declare support for Factorio 2.0 in info.json.
