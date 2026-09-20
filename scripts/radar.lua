local B=require("scripts.balance")
local D=require("scripts.diagnostics")
local A={}
-- Vanilla base radar continuously reveals three chunks in each direction.
-- Use the working radar's current chunk footprint, never the explored-map history.
-- This also works for dedicated servers whose force has no connected players.
local function report(entities,source)
  local s=storage.fai; s.radar_seen=s.radar_seen or {}
  local first,count=nil,0
  for _,e in ipairs(entities) do
    if e.valid and e.unit_number and not s.radar_seen[e.unit_number] then
      s.radar_seen[e.unit_number]=e; count=count+1; first=first or e
    end
  end
  if count>0 then
    local gps="[gps="..math.floor(first.position.x)..","..math.floor(first.position.y)..","..B.surface.."]"
    game.forces[B.force].print({"fai.radar-contact",count,gps})
    D.record("radar_contact",{count=count,position=first.position,source=source})
  end
end
function A.tick()
  local s=storage.fai; if not s then return end
  for id,e in pairs(s.radar_seen or {}) do if not e.valid then s.radar_seen[id]=nil end end
  local surface=game.surfaces[B.surface]
  local humans=surface.find_entities_filtered{type={"unit","car","spider-vehicle"},force={"fai-corporate","fai-response"}}
  for _,radar in pairs(surface.find_entities_filtered{type="radar",force=B.force}) do
    if radar.status==defines.entity_status.working then
      local rx,ry=math.floor(radar.position.x/32),math.floor(radar.position.y/32)
      local visible={}
      for _,e in ipairs(humans) do
        local x,y=math.floor(e.position.x/32),math.floor(e.position.y/32)
        if math.abs(x-rx)<=3 and math.abs(y-ry)<=3 then visible[#visible+1]=e end
      end
      report(visible,"nearby")
    end
  end
end
function A.scanned(event)
  local radar=event.radar
  if not storage.fai or not radar or not radar.valid or radar.surface.name~=B.surface or radar.force.name~=B.force then return end
  report(radar.surface.find_entities_filtered{area=event.area,type={"unit","car","spider-vehicle"},force={"fai-corporate","fai-response"}},"sector")
end
return A
