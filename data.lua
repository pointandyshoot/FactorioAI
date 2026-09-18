-- Stock artwork stays referenced in the game installation; no Wube assets are redistributed.
local function interface(name, production, usage, priority)
  local e = table.deepcopy(data.raw["electric-energy-interface"]["electric-energy-interface"])
  e.name, e.hidden, e.minable = name, false, nil
  e.localised_name = {"entity-name." .. name}
  e.max_health = 2000
  e.energy_production, e.energy_usage = production, usage
  e.energy_source = {type="electric", buffer_capacity="10MJ", usage_priority=priority,
    input_flow_limit=usage == "0W" and "0W" or "2MW", output_flow_limit=production}
  e.gui_mode, e.allow_copy_paste = "none", false
  return e
end
data:extend({interface("fai-core", "0W", "250kW", "primary-input"),
  interface("fai-grid", "20MW", "0W", "primary-output")})

-- Human units use the vanilla engineer animations on the vanilla unit pathfinder.
for i, name in ipairs({"fai-inspector", "fai-security", "fai-military"}) do
  local u = table.deepcopy(data.raw.unit["small-biter"])
  u.name, u.icon = name, "__base__/graphics/icons/character.png"
  u.localised_name, u.factoriopedia_simulation = {"entity-name." .. name}, nil
  u.max_health, u.movement_speed = ({150, 250, 600})[i], 0.12
  u.run_animation = table.deepcopy(data.raw.character.character.animations[1].running)
  u.attack_parameters.animation = table.deepcopy(data.raw.character.character.animations[1].running_with_gun)
  u.attack_parameters.range, u.attack_parameters.cooldown = 15, 45
  u.attack_parameters.ammo_category = "bullet"
  u.attack_parameters.ammo_type = {category="bullet", action={type="direct", action_delivery={type="instant",
    target_effects={{type="damage", damage={amount=({1, 8, 18})[i], type="physical"}}}}}}
  u.attack_parameters.sound = nil
  u.corpse, u.dying_explosion, u.dying_sound = nil, nil, nil
  u.working_sound, u.walking_sound, u.water_reflection = nil, nil, nil
  u.absorptions_to_join_attack = {}
  data:extend({u})
end
