-- Pure campaign rules: deliberately separate from the Factorio runtime for testing.
local B = {}
B.station = "Corporate Exchange"
B.export_station = "Corporate Exports"
B.export_depot = "Corporate Dispatch"
B.depot = "Corporate Boundary"
B.surface = "fai-containment"
B.force = "fai-machine"
B.stage_names = {"Remote Support", "On-site Support", "External Consultancy", "Government Re-regulation"}
B.primitives = { ["iron-plate"]=true, ["copper-plate"]=true, coal=true, stone=true,
  water=true, ["petroleum-gas"]=true, ["crude-oil"]=true }
B.building_heat = {lab=0.8, radar=0.3, roboport=0.2, ["rocket-silo"]=4,
  ["electric-mining-drill"]=0.08, ["pumpjack"]=0.1, ["solar-panel"]=0.015,
  ["steam-engine"]=0.1, ["nuclear-reactor"]=2, ["centrifuge"]=0.4}
B.building_heat["fai-network-tap"]=.2
B.building_heat["fai-redundant-core"]=1
B.building_heat["fai-supercomputer"]=.5
B.legitimate = {"automation", "logistics", "electronics", "steam-power", "automation-science-pack",
  "steel-processing", "railway", "fluid-handling", "circuit-network", "logistics-2", "fast-inserter"}
B.support_recipes={ ["iron-gear-wheel"]=true, ["iron-stick"]=true,["steel-plate"]=true,["stone-brick"]=true,
    ["transport-belt"]=true,["underground-belt"]=true,splitter=true,inserter=true,["fast-inserter"]=true,
    ["medium-electric-pole"]=true,["small-electric-pole"]=true,["big-electric-pole"]=true,
    ["steel-chest"]=true,["iron-chest"]=true,["wooden-chest"]=true,pipe=true,["pipe-to-ground"]=true,
    ["assembling-machine-1"]=true,["assembling-machine-2"]=true,rail=true,["train-stop"]=true,
    ["rail-signal"]=true,["rail-chain-signal"]=true,["repair-pack"]=true,["stone-furnace"]=true,
    ["steel-furnace"]=true,["iron-plate"]=true,["copper-plate"]=true}
function B.recipe_risk(name, authorised)
  if (authorised and authorised[name]) or B.support_recipes[name] then return 0 end
  if name:find("^fai%-") then return 0 end -- Cyber risk is charged remotely on actual completed jobs.
  return name:find("science%-pack") and 0.15 or 0.04
end
function B.manifest(week)
  if week==1 then return {["electronic-circuit"]=900} end
  if week==2 then return {["electronic-circuit"]=1600} end
  local n=math.min(week-3,100)
  local function scale(base) return math.min(10000000,math.floor(base*1.12^n/10)*10) end
  local m={["electronic-circuit"]=scale(1600),["advanced-circuit"]=scale(100)}
  if week>=6 then m["processing-unit"]=math.min(10000000,math.floor(20*1.12^math.min(week-6,100))) end
  if week>=9 then m["electric-engine-unit"]=math.min(10000000,math.floor(30*1.12^math.min(week-9,100))) end
  if week>=12 then m["low-density-structure"]=math.min(10000000,math.floor(50*1.12^math.min(week-12,100))) end
  if week>=15 then m["rocket-fuel"]=math.min(10000000,math.floor(20*1.12^math.min(week-15,100))) end
  return m
end
function B.supply_ratio(week, level)
  -- Deterministic variation is identical for every multiplayer peer.
  if week==1 then return 1.45 end
  return math.max(.55,1.40-(week-1)*.045+(((week*17)%7)-3)*.025)
end
function B.stage(_, previous) return previous or 1 end
function B.shortfall(required, delivered)
  local missing, total, received = {}, 0, 0
  for name, count in pairs(required) do
    local credit = math.min(count, delivered[name] or 0)
    total, received = total + count, received + credit
    if credit < count then missing[name] = count - credit end
  end
  return missing, total > 0 and received / total or 1
end
function B.sorted_keys(t)
  local keys = {}; for k in pairs(t) do keys[#keys+1] = k end
  table.sort(keys); return keys
end
return B
