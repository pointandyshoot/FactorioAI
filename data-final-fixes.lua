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
