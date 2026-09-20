local B=require("scripts.balance")
local D=require("scripts.diagnostics")
local S={}
local cyber={}
for _,op in ipairs(require("scripts.computing_spec").operations) do cyber["fai-"..op[1]]=op[6] end
cyber["fai-telemetry-spoofing"]={risk=.03}
local crafting={ ["assembling-machine"]=true, furnace=true, ["rocket-silo"]=true }
function S.track(e)
  local s=storage.fai
  if not s or not e or not e.valid or e.surface.name~=B.surface or e.force.name~=B.force then return end
  if not e.unit_number or s.tracked[e.unit_number] then return end
  if crafting[e.type] or B.building_heat[e.name] then
    s.tracked[e.unit_number]=true
    s.emitters[#s.emitters+1]={entity=e,id=e.unit_number,products=crafting[e.type] and e.products_finished or 0}
  end
end
function S.rescan()
  local s=storage.fai; s.emitters={}; s.tracked={}
  for _,e in pairs(game.surfaces[B.surface].find_entities_filtered{force=B.force}) do S.track(e) end
end
function S.recipe_risk(name)
  return B.recipe_risk(name, storage.fai.authorised)
end
function S.details(e)
  if not e or not e.valid or not storage.fai then return nil end
  local multiplier=settings.global["fai-suspicion-multiplier"].value
  local base=(B.building_heat[e.name] or 0)*multiplier
  local research=e.type=="lab" and e.status==defines.entity_status.working and game.forces[B.force].current_research
  local recipe=crafting[e.type] and e.get_recipe() or nil
  if recipe and recipe.name=="fai-network-link" then recipe=nil end
  local operation=recipe and cyber[recipe.name]
  return {remote=operation and operation.risk*multiplier or 0,reconciliation=operation and operation.kind=="reconcile",base=base, research=research and 1.44*multiplier or 0,
    pulse=e.type=="lab" and 2*multiplier or 0, recipe=recipe and recipe.name,
    per_craft=recipe and S.recipe_risk(recipe.name)*multiplier or 0}
end
function S.emit()
  local s, surface=storage.fai,game.surfaces[B.surface]
  local multiplier=settings.global["fai-suspicion-multiplier"].value
  -- Five-second sampling: entity existence emits building heat; completed crafts emit recipe heat.
  for i=#s.emitters,1,-1 do
    local row=s.emitters[i]; local e=row.entity
    if not e.valid then if row.id then s.tracked[row.id]=nil end; table.remove(s.emitters,i)
    else
      local amount=(B.building_heat[e.name] or 0)/12
      if crafting[e.type] then
        local n=e.products_finished
        local recipe=e.get_recipe()
        if recipe then amount=amount+math.max(0,n-row.products)*S.recipe_risk(recipe.name) end
        row.products=n
      end
      if e.type=="lab" and e.status==defines.entity_status.working and game.forces[B.force].current_research then amount=amount+0.12 end
      if amount>0 then surface.pollute(e.position,amount*multiplier) end
    end
  end
end
function S.add(amount,reason)
  local s=storage.fai; s.suspicion=math.max(0,math.min(100,s.suspicion+amount))
  if amount>0 then s.last_detected=game.tick end
  D.record("suspicion",{delta=amount,reason=reason,total=s.suspicion})
end
function S.stages()
  local s=storage.fai
  -- Support levels are irreversible intervention history, not suspicion thresholds.
  s.stage=s.support_level or 1
  if s.grid and s.grid.valid then
    local n=s.network
    s.grid.power_production=(s.isolated or (n and n.debug_state=="power-cycle")) and 0 or ((n and n.grid_mw or 20)*1000000/60)
  end
end
return S
