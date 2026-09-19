local B=require("scripts.balance")
local D=require("scripts.diagnostics")
local S={}
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
  return {base=base, research=research and 1.44*multiplier or 0,
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
  local next_stage=B.stage(s.suspicion,s.stage)
  if next_stage~=s.stage then
    s.stage=next_stage
    D.record("stage_changed",{stage=s.stage,name=B.stage_names[s.stage]})
    if s.stage<5 then game.forces[B.force].print({"fai.stage-"..s.stage}) end
    if s.stage>=5 then
      s.phase="discovered"; s.queue={}
      local a,b=game.forces[B.force],game.forces["fai-corporate"]
      a.set_friend(b,false); b.set_friend(a,false)
      a.set_cease_fire(b,false); b.set_cease_fire(a,false)
    end
  end
  if s.grid and s.grid.valid then s.grid.power_production=s.stage>=4 and 0 or 20000000/60 end
end
return S
