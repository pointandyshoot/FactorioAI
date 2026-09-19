-- Only this test case accelerates real scan events, without changing nearby range.
if settings.startup["fai-test-case"].value=="oversight" then
  data.raw.radar.radar.energy_per_sector="300kJ"
  data.raw.radar.radar.energy_per_nearby_scan="7.5kJ"
  data.raw.radar.radar.max_distance_of_sector_revealed=4
end
