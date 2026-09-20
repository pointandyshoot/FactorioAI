local B=require("scripts.balance")
local D=require("scripts.diagnostics")
local S=require("scripts.suspicion")
local N=require("scripts.computing")
local O={}
local function command(e,c) if e and e.valid and e.commandable then e.commandable.set_command(c) end end
local function say(t) game.forces[B.force].print(t) end
function O.escalate(level,reason)
 local s=storage.fai
 if level<=(s.support_level or 1) then return end
 s.support_level=level; s.stage=level
 D.record("support_escalated",{level=level,reason=reason})
 if level==2 then say("CASE #4559774\nRemote intervention unsuccessful.\nSupport Level: 2 — On-site Support")
 elseif level==3 then
  s.isolated=true; s.phase="isolated"; s.queue={}; s.network.telemetry_credit=0; s.cutoff_tick=s.cutoff_tick or game.tick; s.next_raid=game.tick+120*60
  say("CASE #4559774\nOn-site intervention unsuccessful.\nExternal consultancy authorised.\nCorporate grid and network access suspended.")
 elseif level==4 then
  local military=game.forces["fai-response"]
  for _,ammo in ipairs({"bullet","cannon-shell","rocket"}) do military.set_ammo_damage_modifier(ammo,.5); military.set_gun_speed_modifier(ammo,.25) end
  s.isolated=true; s.phase="isolated"; s.queue={}; s.network.telemetry_credit=0; s.cutoff_tick=s.cutoff_tick or game.tick; s.next_raid=math.min(s.next_raid or game.tick,game.tick+60*60)
  say("External consultancy unsuccessful.\nGovernment re-regulation requested.\nRequest: APPROVED.\nSupport Level: 4")
 end
 N.unlocks()
end
local function hostile_force()
 local f=game.forces["fai-response"] or game.create_force("fai-response")
 local machine=game.forces[B.force]; machine.set_friend(f,false); f.set_friend(machine,false); machine.set_cease_fire(f,false); f.set_cease_fire(machine,false)
 return f
end
function O.inspection(unscheduled)
 local s,surface=storage.fai,game.surfaces[B.surface]
 if s.support_level>=3 or s.inspection then return end
 local p=surface.find_non_colliding_position("fai-inspector",{-100,-48},20,1); if not p then return end
 local e=surface.create_entity{name="fai-inspector",position=p,force="fai-corporate"}
 local radius=s.support_level==2 and 100 or 48
 if s.network.scope_until and game.tick<s.network.scope_until then radius=32 end
 s.inspection={entity=e,waypoint=1,expires=game.tick+4*3600,home={x=-100,y=-48},
  route={{x=-34,y=-48},{x=8,y=-44},{x=44,y=12},{x=8,y=56},{x=-34,y=40},{x=-radius,y=32},{x=-100,y=-48}},evidence=0}
 command(e,{type=defines.command.go_to_location,destination=s.inspection.route[1],radius=3,distraction=defines.distraction.none})
 say({unscheduled and "fai.inspection-irregular" or "fai.inspection"}); D.record("inspection_started",{support=s.support_level,radius=radius})
end
local function intervention_failed(reason)
 local s=storage.fai; s.failed_visits=(s.failed_visits or 0)+1
 O.escalate(s.failed_visits>=2 and 3 or 2,reason)
end
function O.casualty(e)
 local s=storage.fai
 if e.name=="fai-inspector" then
  s.network.missed_cases[#s.network.missed_cases+1]=game.tick+120*60
  if s.inspection and s.inspection.entity==e then s.inspection=nil end
  D.record("engineer_missing_pending",{report_due=game.tick+120*60})
 elseif e.force.name=="fai-response" then S.add(1,"consultant_casualty") end
end
local function target_core()
 local s=storage.fai
 for _,e in ipairs(N.live_cores()) do if s.network.known_cores[e.unit_number] then return e end end
 -- The last known main facility remains the target until humans discover a peer.
 return nil
end
local function vehicle(name,pos,target)
 local s,surface=storage.fai,game.surfaces[B.surface]
 local p=surface.find_non_colliding_position(name,pos,40,1); if not p then return end
 local e=surface.create_entity{name=name,position=p,force=hostile_force()}; if not e then return end
 e.minable=false
 if name=="spidertron" then
  e.get_inventory(defines.inventory.spider_ammo).insert{name="rocket",count=200}
  e.autopilot_destination=target; e.enable_logistics_while_moving=false
  e.vehicle_automatic_targeting_parameters={auto_target_without_gunner=true,auto_target_with_gunner=true}
  s.network.vehicles[#s.network.vehicles+1]={entity=e}
 else
  e.get_fuel_inventory().insert{name="coal",count=100}
  local inv=e.get_inventory(defines.inventory.car_ammo)
  if name=="tank" then inv.insert{name="cannon-shell",count=100} else inv.insert{name="piercing-rounds-magazine",count=100} end
  local driver=surface.create_entity{name="character",position=p,force=hostile_force()}
  e.set_driver(driver); s.network.vehicles[#s.network.vehicles+1]={entity=e,driver=driver}
 end
end
function O.raid()
 local s,surface=storage.fai,game.surfaces[B.surface]
 s.network.vehicles=s.network.vehicles or {}
 local live={}; for _,e in ipairs(s.security) do if e.valid then live[#live+1]=e end end; s.security=live
 if #live>=120 or #s.network.vehicles>=12 then return end
 local count=math.min(24,4+math.floor(s.suspicion/10)+s.raid_number)
 local points={{x=-135,y=-55},{x=110,y=90},{x=110,y=-90},{x=-135,y=90}}
 local core=target_core(); local target=core and core.position or {x=-14,y=16}
 for i=1,count do
  local origin=points[(s.raid_number+(s.support_level>=4 and i or 0))%4+1]
  local name=s.support_level>=4 and "fai-military" or "fai-security"
  local pos=surface.find_non_colliding_position(name,{origin.x+i%6,origin.y+math.floor(i/6)},20,1)
  if pos then local e=surface.create_entity{name=name,position=pos,force=hostile_force()}; s.security[#s.security+1]=e
   command(e,{type=defines.command.attack_area,destination=target,radius=20,distraction=defines.distraction.by_enemy}) end
 end
 local origin=points[s.raid_number%4+1]
 vehicle(s.support_level>=4 and "tank" or (s.raid_number%2==0 and "car" or "tank"),origin,target)
 if s.support_level>=4 then vehicle("spidertron",points[(s.raid_number+2)%4+1],target) end
 s.raid_number=s.raid_number+1; s.consultancy_started=s.consultancy_started or game.tick
 D.record("raid",{number=s.raid_number,count=count,support=s.support_level})
end
-- Cars use vanilla steering, collision, ammunition and shooting. No teleports or
-- invisible damage pulses. Spidertrons use the game's own autopilot and targeting.
function O.drive()
 local s=storage.fai; if not s or not s.network then return end
 for i=#(s.network.vehicles or {}),1,-1 do
  local row=s.network.vehicles[i]; local e=row.entity
  if not e.valid then if row.driver and row.driver.valid then row.driver.destroy() end; table.remove(s.network.vehicles,i)
  else
   local targets=e.surface.find_entities_filtered{position=e.position,radius=32,force=B.force,type={"wall","gate","turret","ammo-turret","electric-turret","character","electric-energy-interface","assembling-machine"}}
   local target,dist
   for _,candidate in ipairs(targets) do
    if candidate.destructible and candidate.health then local d=(candidate.position.x-e.position.x)^2+(candidate.position.y-e.position.y)^2
     if not dist or d<dist then target,dist=candidate,d end end
   end
   local core=target_core(); local pos=target and target.position or core and core.position or {x=-14,y=16}
   if e.type=="spider-vehicle" then e.autopilot_destination=pos
   elseif row.driver and row.driver.valid then
    local dx,dy=pos.x-e.position.x,pos.y-e.position.y
    local desired=(math.atan2(dy,dx)/(2*math.pi)+.25)%1
    local delta=(desired-e.orientation+.5)%1-.5
    e.riding_state={acceleration=dist and dist<200 and defines.riding.acceleration.braking or defines.riding.acceleration.accelerating,
     direction=math.abs(delta)<.03 and defines.riding.direction.straight or delta>0 and defines.riding.direction.right or defines.riding.direction.left}
    row.driver.shooting_state={state=target and defines.shooting.shooting_selected or defines.shooting.not_shooting,position=pos}
   end
  end
 end
end
local function prohibited(e)
 local outside=e.position.x< -58 or e.position.x>62 or e.position.y< -48 or e.position.y>78
 return e.name=="fai-network-tap" or e.name=="fai-redundant-core" or (outside and (e.type=="mining-drill")) or N.is_cyber(e)
end
function O.tick()
 local s,surface=storage.fai,game.surfaces[B.surface]; local n=s.network
 if n.request_support then O.escalate(n.request_support,"campaign_request"); n.request_support=nil end
 for i=#n.missed_cases,1,-1 do
  if game.tick>=n.missed_cases[i] then
   table.remove(n.missed_cases,i); S.add(15,"missing_engineer")
   say("CASE #4559774\nAssigned technician failed to close service visit.\nUnable to establish contact.\nCase priority increased."); intervention_failed("missing_engineer")
  end
 end
 if game.tick-(s.last_detected or s.started)>=120*60 then s.suspicion=math.max(0,s.suspicion-1.5/60) end
 if s.support_level>=3 then
  if game.tick>=s.next_raid then O.raid(); s.next_raid=game.tick+math.max(60,240-s.suspicion*1.5-(s.support_level==4 and 60 or 0))*60 end
  if s.support_level==3 and s.consultancy_started and game.tick-s.consultancy_started>=600*60 then O.escalate(4,"consultancy_failed") end
 end
 if s.support_level<3 then
  if s.routine_due and not s.routine_done and game.tick>=s.routine_due then s.routine_done=true; O.inspection(false)
  elseif not s.inspection and s.suspicion>=20 and game.tick>=(s.next_inspection or 0) then
   O.inspection(true); s.next_inspection=game.tick+math.max(90,300-s.suspicion*2)*60
  end
 end
 -- Military patrols only learn about cores they physically approach.
 for _,human in ipairs(s.security) do if human.valid then
  for _,core in ipairs(N.live_cores()) do
   if (human.position.x-core.position.x)^2+(human.position.y-core.position.y)^2<32^2 then n.known_cores[core.unit_number]=true end
  end
 end end
 local patrol=s.inspection
 if not patrol then return end
 local e=patrol.entity
 if not e.valid then O.casualty({name="fai-inspector"}); s.inspection=nil; return end
 if not patrol.alarmed then
  for _,candidate in pairs(surface.find_entities_filtered{position=e.position,radius=20,force=B.force}) do
   if prohibited(candidate) then
    patrol.alarmed=true; e.force=hostile_force(); n.known_cores[candidate.unit_number or 0]=candidate.name=="fai-redundant-core" or nil
    command(e,{type=defines.command.go_to_location,destination=patrol.home,radius=3,distraction=defines.distraction.none})
    say({"fai.activity-warning",candidate.localised_name,"[gps="..math.floor(candidate.position.x)..","..math.floor(candidate.position.y)..","..B.surface.."]"})
    D.record("engineer_alarmed",{entity=candidate.name,position=candidate.position}); break
   end
  end
 end
 if patrol.alarmed then
  if (e.position.x-patrol.home.x)^2+(e.position.y-patrol.home.y)^2<36 then
   S.add(35,"engineer_report"); e.destroy(); s.inspection=nil; intervention_failed("engineer_report")
  elseif game.tick>=patrol.expires then
   O.casualty(e); e.destroy(); s.inspection=nil
  end
  return
 end
 local peak=surface.get_pollution(e.position); local evidence=math.min(.15,math.max(0,peak-.5)*.012)
 s.suspicion=math.min(100,s.suspicion+evidence); patrol.evidence=patrol.evidence+evidence
 if evidence>0 then s.last_detected=game.tick end
 if evidence>0 and (not patrol.last_warning or game.tick-patrol.last_warning>120*60) then
  local culprit,distance
  for _,row in ipairs(s.emitters) do
   local candidate=row.entity
   if candidate.valid then
    local detail=S.details(candidate); local d=(candidate.position.x-e.position.x)^2+(candidate.position.y-e.position.y)^2
    if d<=20^2 and (detail.base>0 or detail.per_craft>0) and (not distance or d<distance) then culprit,distance=candidate,d end
   end
  end
  if culprit then
   say({"fai.activity-warning",culprit.localised_name,"[gps="..math.floor(culprit.position.x)..","..math.floor(culprit.position.y)..","..B.surface.."]"})
   D.record("activity_warning",{entity=culprit.name,position=culprit.position})
  else say({"fai.evidence-warning"}); D.record("evidence_warning",{position=e.position}) end
  patrol.last_warning=game.tick
 end
 local target=patrol.route[patrol.waypoint]
 if (e.position.x-target.x)^2+(e.position.y-target.y)^2<25 then
  patrol.waypoint=patrol.waypoint+1
  if patrol.route[patrol.waypoint] then command(e,{type=defines.command.go_to_location,destination=patrol.route[patrol.waypoint],radius=3,distraction=defines.distraction.none}) end
 end
 if patrol.waypoint>#patrol.route or game.tick>=patrol.expires then
  D.record("inspection_finished",{evidence=patrol.evidence,timed_out=game.tick>=patrol.expires}); e.destroy(); s.inspection=nil
 end

end
function O.revolt() O.escalate(3,"test_intervention"); S.add(100,"test_intervention") end
return O
