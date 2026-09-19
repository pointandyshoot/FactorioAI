-- This is a dedicated base-game overhaul. Runtime code adds suspicion to the ordinary
-- pollution field; normal emissions are removed so authorised smelting stays legitimate.
for _, group in pairs(data.raw) do
  for _, prototype in pairs(group) do
    for _, key in ipairs({"energy_source", "burner"}) do
      local source = prototype[key]
      if type(source) == "table" and source.emissions_per_minute then source.emissions_per_minute = {} end
    end
    if prototype.emissions_per_second then prototype.emissions_per_second = {} end
  end
end
data.raw["airborne-pollutant"].pollution.localised_name = {"fai.suspicion-field"}

-- Static descriptions explain the rules; the live selection panel resolves the
-- force's current commission and runtime multiplier without changing prototypes.
local B=require("scripts.balance")
local function append(prototype, text)
  prototype.localised_description={"", prototype.localised_description or "", "\n", text}
end
for _, group in pairs(data.raw) do
  for name, prototype in pairs(group) do
    local heat=B.building_heat[name] or (prototype.place_result and B.building_heat[prototype.place_result])
    if heat and prototype.type~="recipe" and prototype.type~="technology" then
      append(prototype, {"fai.building-suspicion", tostring(heat)})
      if name=="lab" or prototype.place_result=="lab" then append(prototype, {"fai.lab-suspicion"}) end
    end
  end
end
for name, recipe in pairs(data.raw.recipe) do
  local rate=B.recipe_risk(name)
  append(recipe, rate>0 and {"fai.recipe-suspicion",tostring(rate)} or {"fai.authorised-recipe"})
end
