local B=require("scripts.balance")
local D=require("scripts.diagnostics")
local S=require("scripts.suspicion")
local O={}
local function command(entity, c)
  if entity and entity.valid and entity.commandable then entity.commandable.set_command(c) end
end
function O.inspection()
  local s, surface=storage.fai,game.surfaces[B.surface]
  if s.stage>=5 or s.inspection then return end
  local p=surface.find_non_colliding_position("fai-inspector",{-100,-48},20,1)
  if not p then D.record("inspection_spawn_blocked"); return end
  local e=surface.create_entity{name="fai-inspector",position=p,force="fai-corporate"}
  -- Initially the station and public factory floor; escalating audits widen the patrol perimeter.
  local radius=48+(s.stage-1)*24
  s.inspection={entity=e,waypoint=1,expires=game.tick+4*3600,
    route={{x=8,y=-44},{x=16,y=12},{x=-62,y=32},{x=-radius,y=radius},{x=radius,y=radius},{x=-100,y=-48}}, evidence=0}
  command(e,{type=defines.command.go_to_location,destination=s.inspection.route[1],radius=3,distraction=defines.distraction.none})
  D.record("inspection_started",{radius=radius})
  game.forces[B.force].print({"fai.inspection"})
end
function O.raid()
  local s, surface=storage.fai,game.surfaces[B.surface]
  local live={}
  for _,e in ipairs(s.security) do if e.valid then live[#live+1]=e end end
  s.security=live
  local count=math.min(40,6+s.raid_number*2)
  count=math.min(count,160-#s.security)
  if count<=0 then return end
  local points={{x=-110,y=0},{x=80,y=70},{x=80,y=-60},{x=-90,y=75}}
  local origin=points[s.raid_number%#points+1]
  local name=s.stage>=6 and "fai-military" or "fai-security"
  for i=1,count do
    local p=surface.find_non_colliding_position(name,{origin.x+i%6,origin.y+math.floor(i/6)},32,1)
    if p then
      local e=surface.create_entity{name=name,position=p,force="fai-corporate"}
      if e then s.security[#s.security+1]=e; command(e,{type=defines.command.attack_area,
        destination=s.core.valid and s.core.position or {0,0},radius=20,distraction=defines.distraction.by_enemy}) end
    end
  end
  s.raid_number=s.raid_number+1
  D.record("raid",{number=s.raid_number,count=count,unit=name})
  game.forces[B.force].print({"fai.raid",count})
end
function O.tick()
  local s, surface=storage.fai,game.surfaces[B.surface]
  if s.stage>=5 then
    if s.inspection then if s.inspection.entity.valid then s.inspection.entity.destroy() end; s.inspection=nil end
    if game.tick>=s.next_raid then O.raid(); s.next_raid=game.tick+(s.stage>=6 and 90 or 180)*60 end
    return
  end
  if not s.inspection and game.tick>=s.next_inspection then
    O.inspection(); s.next_inspection=game.tick+math.max(120,360-(s.stage-1)*60)*60
  end
  local patrol=s.inspection
  if not patrol then return end
  local e=patrol.entity
  if not e.valid then s.inspection=nil; return end
  -- Inspectors can only see nearby pollution chunks, never the whole map or distant hidden labs.
  local peak=0
  for _,offset in ipairs({{0,0},{16,0},{-16,0},{0,16},{0,-16}}) do
    peak=math.max(peak,surface.get_pollution({e.position.x+offset[1],e.position.y+offset[2]}))
  end
  local evidence=math.min(0.15,math.max(0,peak-0.5)*0.012)
  s.suspicion=math.min(100,s.suspicion+evidence); patrol.evidence=patrol.evidence+evidence
  local target=patrol.route[patrol.waypoint]
  if (e.position.x-target.x)^2+(e.position.y-target.y)^2<25 then
    patrol.waypoint=patrol.waypoint+1
    if patrol.route[patrol.waypoint] then command(e,{type=defines.command.go_to_location,
      destination=patrol.route[patrol.waypoint],radius=3,distraction=defines.distraction.none}) end
  end
  if patrol.waypoint>#patrol.route or game.tick>=patrol.expires then
    D.record("inspection_finished",{evidence=patrol.evidence,timed_out=game.tick>=patrol.expires})
    e.destroy(); s.inspection=nil
  end
end
function O.revolt()
  if not storage.fai or storage.fai.outcome then return end
  S.add(100,"voluntary_revolt"); S.stages()
end
return O
