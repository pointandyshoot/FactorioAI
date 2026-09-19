local B = require("scripts.balance")
local D = require("scripts.diagnostics")
local R = require("scripts.rail")
local C = {}

-- The base-game recipe graph is the bill of materials, not a parallel crafting economy.
-- Oil fractions are delivered directly, avoiding fictitious coproduct assumptions.
local fluid_inputs = {water=true, ["petroleum-gas"]=true, ["heavy-oil"]=true, ["light-oil"]=true, ["crude-oil"]=true}
local function recipe_for(force, name)
  local special = {["solid-fuel"]="solid-fuel-from-petroleum-gas"}
  return force.recipes[special[name] or name]
end
local function walk(force, name, amount, out, authorised, visiting)
  if B.primitives[name] or fluid_inputs[name] then out[name]=(out[name] or 0)+amount; return end
  assert(not visiting[name], "Cyclic supply recipe: " .. name)
  local recipe = recipe_for(force, name)
  assert(recipe, "No supported base recipe for " .. name)
  local yield = 0
  for _, p in pairs(recipe.products) do if p.name == name then yield = yield + (p.amount or ((p.amount_min+p.amount_max)/2))*(p.probability or 1) end end
  assert(yield > 0, "Recipe has no expected product: " .. name)
  authorised[recipe.name], visiting[name] = true, true
  for _, ing in pairs(recipe.ingredients) do walk(force, ing.name, amount*ing.amount/yield, out, authorised, visiting) end
  visiting[name] = nil
end
local function unlock(force, name, visited)
  if visited[name] then return end
  visited[name]=true
  local tech = force.technologies[name]; if not tech then return end
  for _, prerequisite in pairs(tech.prerequisites) do unlock(force, prerequisite.name, visited) end
  tech.researched = true
end
function C.authorise()
  local s, force = storage.fai, game.forces[B.force]
  local visited = {}
  for _, name in ipairs(B.legitimate) do unlock(force, name, visited) end
  -- Grant only the research necessary for newly commissioned recipes.
  for _, name in ipairs(B.sorted_keys(force.technologies)) do
    local tech = force.technologies[name]
    for _, effect in pairs(tech.prototype.effects) do
      if effect.type == "unlock-recipe" and s.authorised[effect.recipe] then unlock(force, name, visited) end
    end
  end
  -- Trigger technologies may have no unlock effects; enabling the actual recipe is explicit.
  for name in pairs(s.authorised) do if force.recipes[name] then force.recipes[name].enabled=true end end
end
function C.begin_week()
  local s = storage.fai
  s.week_ticks = settings.global["fai-week-minutes"].value * 3600
  s.deadline, s.collection_due = game.tick+s.week_ticks, game.tick+math.floor(s.week_ticks*0.75)
  s.required, s.delivered, s.supplies = B.manifest(s.week), {}, {}
  s.collection_sent = false
  s.routine_due=game.tick+math.floor(s.week_ticks/2)
  s.routine_done=false
  for _, name in ipairs(B.sorted_keys(s.required)) do
    walk(game.forces[B.force], name, s.required[name], s.supplies, s.authorised, {})
  end
  C.authorise()
  s.supply_ratio = B.supply_ratio(s.week, s.stage)
  for name, count in pairs(s.supplies) do
    local stocked = 0 -- Fresh factories are fed entirely by the real import trains.
    s.supplies[name] = math.max(0, math.ceil(count*s.supply_ratio) - stocked)
  end
  -- Transport runs and construction reserves are explicit, separate from production inputs.
  if s.supply_ratio > 0 then s.supplies.coal=(s.supplies.coal or 0)+200 end
  R.queue_supplies(s.supplies)
  D.record("week_started", {week=s.week, required=s.required, supplies=s.supplies, ratio=s.supply_ratio})
  game.forces[B.force].print({"fai.new-week", s.week, settings.global["fai-week-minutes"].value})
end
function C.finish_week()
  local s = storage.fai
  local missing, ratio = B.shortfall(s.required, s.delivered)
  local success = next(missing) == nil
  s.suspicion = math.max(0, math.min(100, s.suspicion + (success and -5 or (8+12*(1-ratio)))))
  if not success then s.last_detected=game.tick end
  local row = {week=s.week, required=s.required, delivered=s.delivered, missing=missing, success=success}
  s.history[#s.history+1]=row; if #s.history>30 then table.remove(s.history,1) end
  D.record("contract_closed", row)
  game.forces[B.force].print(success and {"fai.contract-met"} or {"fai.contract-missed"})
  s.week=s.week+1
  C.begin_week()
end
return C
