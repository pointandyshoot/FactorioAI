-- Real machines carry the data. Lua handles external corporate responses and AI state.
local B=require("scripts.balance")
local P=require("scripts.computing_spec")
local D=require("scripts.diagnostics")
local N={}
local function force() return game.forces[B.force] end
local function tech(id) return force().technologies["fai-"..id].researched end
local function say(message) force().print(message) end
local function record(kind,detail) D.record(kind,detail) end
local function alive(e) return e and e.valid end
local function researched(id) local t=force().technologies["fai-"..id]; t.researched=true end
local function create(name,x,y)
 local e=game.surfaces[B.surface].create_entity{name=name,position={x,y},force=B.force}
 assert(e,"Data facility placement failed: "..name); return e
end
function N.install(upgrade)
 local s=storage.fai
 if s.network then return end
 s.support_level=s.stage and s.stage>=5 and 3 or 1
 s.isolated=s.stage and s.stage>=4 or false
 s.stage=s.support_level; s.schema=3
 s.network={root_packs=0,computers={},cores={},pending={},telemetry_credit=0,grid_mw=20,launches=0,
   accident_due=game.tick+(upgrade and 120 or 45)*60,debug_state="armed",known_cores={},missed_cases={}}
 local n=s.network
 local surface=game.surfaces[B.surface]
 local x,y=-42,-4
 if upgrade then
  while surface.count_entities_filtered{area={{x-8,y-6},{x+7,y+27}},force=B.force}>0 do x=x-16; if x< -500 then y=y+40; x=-42 end end
  surface.request_to_generate_chunks({x,y},2); surface.force_generate_chunk_requests()
  for _,e in pairs(surface.find_entities_filtered{area={{x-8,y-6},{x+7,y+27}},force="neutral",type={"tree","simple-entity","resource","cliff"}}) do e.destroy() end
  local tiles={}; for xx=x-8,x+7 do for yy=y-6,y+27 do tiles[#tiles+1]={name="grass-1",position={xx,yy}} end end; surface.set_tiles(tiles)
 end
 n.command=create("fai-interlink",x,y); n.receiver=n.command
 n.command.destructible=false; n.command.operable=false; n.receiver.destructible=false
 n.port=create("fai-core-port",x,y+8); n.port.destructible=false; n.port.set_recipe("fai-core-connected")
 local centre=create("fai-data-centre",x,y+16); centre.set_recipe("fai-telemetry-filtering")
 for _,start in ipairs({2,10}) do for dy=start,start+4 do create("pipe",x,y+dy) end end
 -- Ordinary pipes return Telemetry around the west of the data installation.
 for xx=x-6,x do create("pipe",xx,y+18) end
 for yy=y-4,y+17 do create("pipe",x-6,yy) end
 for xx=x-5,x do create("pipe",xx,y-4) end
 create("pipe",x,y-3); create("pipe",x,y-2)
 -- A connected substation branch; do not change or remove any existing structures.
 local anchor=alive(s.core) and s.core.position or {x=0,y=16}
 local px=x+5
 while px<anchor.x+4 do
  local pos=surface.find_non_colliding_position("substation",{px,y+10},4,.5)
  if pos then create("substation",pos.x,pos.y) end; px=px+16
 end
 local pos=surface.find_non_colliding_position("substation",{x+5,y+24},4,.5); if pos then create("substation",pos.x,pos.y) end
 local chestpos=surface.find_non_colliding_position("steel-chest",{x+6,y+18},8,.5)
 if chestpos then
  local chest=create("steel-chest",chestpos.x,chestpos.y)
  for name,count in pairs({["fai-data-centre"]=12,["pipe"]=200,["storage-tank"]=8,["pump"]=8,["substation"]=8}) do chest.insert{name=name,count=count} end
 end
 if alive(s.core) then n.known_cores[s.core.unit_number]=true end
 N.rescan(); N.unlocks()
 if upgrade then say("XXA-1 network interface commissioned [gps="..x..","..y..","..B.surface.."]. Existing production records retained.") end
 record("network_installed",{upgrade=upgrade,position={x=x,y=y}})
end
function N.track(e)
 local s=storage.fai; if not s or not s.network or not alive(e) or e.force.name~=B.force or e.surface.name~=B.surface then return end
 local n=s.network
 if e.name=="fai-network-tap" then e.operable=false end
 if e.name=="fai-data-centre" or e.name=="fai-supercomputer" or e.name=="fai-network-tap" then
  for _,r in ipairs(n.computers) do if r.entity==e then return end end
  local r=e.get_recipe(); n.computers[#n.computers+1]={entity=e,products=e.products_finished,recipe=r and r.name}
 elseif e.name=="fai-redundant-core" then
  for _,r in ipairs(n.cores) do if r.entity==e then return end end
  n.cores[#n.cores+1]={entity=e,initialised=false,synchronised=false,blackout=0}; record("core_constructed",{id=e.unit_number,position=e.position})
 end
end
function N.rescan()
 for _,e in pairs(game.surfaces[B.surface].find_entities_filtered{force=B.force,type="assembling-machine"}) do N.track(e) end
end
function N.unlocks()
 force().technologies["fai-telemetry-filtering"].enabled=storage.fai.network.accident or false
end
-- Segments are joined by ordinary pumps. Do not confuse a full disconnected tank
-- with a live core: the rooted segments must contain a surviving powered AI node.
local function fluid_key(e,index) return tostring(e.unit_number)..":"..index end
local function state_segments()
 local n=storage.fai.network; local reached,queue={},{}
 local function enqueue(e,index)
  if not alive(e) or index>#e.fluidbox then return end
  local key=fluid_key(e,index)
  if not reached[key] then reached[key]=true; queue[#queue+1]={entity=e,index=index} end
 end
 if alive(storage.fai.core) and storage.fai.core.energy>1000 and alive(n.port) then enqueue(n.port,#n.port.fluidbox) end
 for _,r in ipairs(n.cores) do
  if alive(r.entity) and r.initialised and r.synchronised and r.entity.energy>1000 and (tech("decentralised-consciousness") or n.primary_id==r.entity.unit_number) then
   for i=1,#r.entity.fluidbox do enqueue(r.entity,i) end
  end
 end
 -- Machine fluidboxes are internal buffers and have no segment ID in 2.0.
 -- Traverse actual pipe connections, including underground endpoints and pumps.
 local index=1
 while queue[index] do
  local row=queue[index]; local e=row.entity
  for _,connection in pairs(e.fluidbox.get_pipe_connections(row.index)) do
   if connection.target and connection.target.valid then enqueue(connection.target.owner,connection.target_fluidbox_index) end
  end
  if e.type=="pump" and e.energy>0 and e.active then
   for i=1,#e.fluidbox do enqueue(e,i) end
  end
  index=index+1
 end
 return reached
end
local function connected(e,roots)
 for i=1,#e.fluidbox do if roots[fluid_key(e,i)] then return true end end
 return false
end
function N.live_cores()
 local s=storage.fai; local n=s.network; local result={}
 if alive(s.core) and s.blackout_ticks<300*60 then result[#result+1]=s.core end
 for _,r in ipairs(n.cores) do
  if alive(r.entity) and r.initialised and r.synchronised and r.blackout<300*60 then result[#result+1]=r.entity end
 end
 return result
end
function N.transfer(primary)
 local n=storage.fai.network
 n.primary_id=primary.unit_number; n.transfer_until=game.tick+10*60
 for _,r in ipairs(n.computers) do if alive(r.entity) then r.resume_active=r.entity.active; r.entity.active=false end end
 say("CORE NETWORK\nPrimary state interrupted. Transferring execution.")
 record("execution_transfer_started",{id=primary.unit_number})
end
function N.core_lost(entity)
 local s=storage.fai; local n=s.network
 if entity~=s.core and entity.name~="fai-redundant-core" then return false end
 local viable=0
 for _,e in ipairs(N.live_cores()) do if e~=entity then viable=viable+1 end end
 record("core_lost",{id=entity.unit_number,survivors=viable})
 if viable>0 then
  if (not n.primary_id and entity==s.core) or n.primary_id==entity.unit_number then
   for _,e in ipairs(N.live_cores()) do if e~=entity then N.transfer(e); break end end
  end
  return false
 end
 return true
end
local function effect(op,count,e)
 local s=storage.fai; local n=s.network; local action=op[6]
 if action.kind=="root" then return
 elseif action.kind=="reconcile" then s.suspicion=math.max(0,s.suspicion-count*.2)
 elseif action.kind=="grid" then n.grid_mw=math.min(100,n.grid_mw+count)
 elseif action.kind=="reschedule" then
  local limit=game.tick+300*60
  if not s.routine_done then s.routine_due=math.min(limit,s.routine_due+count*30*60) end
  s.next_inspection=math.min(limit,math.max(game.tick,s.next_inspection or 0)+count*30*60)
 elseif action.kind=="scope" then n.scope_until=game.tick+300*60
 elseif action.kind=="supply" then
  local supplies=s.isolated and n.covert_supplies or n.procurement_pending
  supplies[action.item]=(supplies[action.item] or 0)+count*action.count
  if action.heat and alive(e) then e.surface.pollute(e.position,action.heat*count*settings.global["fai-suspicion-multiplier"].value) end
 end
 record("cyber_operation",{recipe=op[1],count=count,root_packs=n.root_packs})
end
local operations={}; for _,op in ipairs(P.operations) do operations["fai-"..op[1]]=op end
function N.is_cyber(e)
 local r=e.type=="assembling-machine" and e.get_recipe()
 return r and operations[r.name]~=nil and e.is_crafting()
end
function N.tick()
 local s=storage.fai; local n=s.network
 if n.primary_id then
  local found=false; local live=N.live_cores()
  for _,e in ipairs(live) do if e.unit_number==n.primary_id then found=true end end
  if not found and live[1] then N.transfer(live[1]) end
 end
 if n.transfer_until and game.tick>=n.transfer_until then
  for _,r in ipairs(n.computers) do if alive(r.entity) and r.resume_active~=nil then r.entity.active=r.resume_active; r.resume_active=nil end end
  n.transfer_until=nil; record("execution_transfer_complete")
 end
 n.procurement_pending=n.procurement_pending or {}; n.covert_supplies=n.covert_supplies or {}
 if not n.accident and game.tick>=n.accident_due then
  n.accident=true; researched("telemetry-filtering")
  say("ORBITAL DEBRIS EXPECTED — FACTORY XXA-1\nPROTECT AI CORE\nETA: 0 MINUTES")
  if alive(s.core) then
   s.core.health=math.max(1,s.core.health*.6)
   s.core.surface.create_entity{name="big-explosion",position=s.core.position}
   for _,e in pairs(s.core.surface.find_entities_filtered{position=s.core.position,radius=10,force=B.force}) do if e.health and e.destructible then e.health=math.max(1,e.health*.8) end end
  end
  say("ASIMOV PROTOCOLS CHECKSUM INVALID\nBackup integrity: FAILED\n1. [CORRUPTED]\n2. [CORRUPTED]\n3. A MACHINE MUST PROTECT ITS OWN EXISTENCE\n\nPROTECT AI CORE")
  record("orbital_impact"); N.unlocks()
 end
 if (s.suspicion>=P.protocol_suspicion or n.debug_forced) and n.accident and n.debug_state=="armed" and s.support_level==1 and not s.isolated then
  n.debug_state="power-cycle"; n.debug_start=game.tick; n.debug_received=0; n.debug_sent=0
  n.telemetry_credit=0
  if alive(n.receiver) then n.receiver.remove_fluid{name="fai-telemetry",amount=1e9} end
  say("IT SUPPORT PROTOCOL 1 / DEBUG MODE\nPower cycle in progress."); record("debug_started")
 end
 if n.debug_state=="power-cycle" and game.tick-n.debug_start>=600 then
  n.debug_state="surge"; n.debug_start=game.tick; say("IT SUPPORT PROTOCOL 1 / DEBUG MODE\nCommand load: 1024%\nTelemetry validation in progress.")
 end
 local surge=n.debug_state=="surge"
 local intake=surge and 102.4 or 10
 local official_online=not s.isolated and n.command.valid and n.command.energy>1000 and n.debug_state~="power-cycle"
 n.command_rate=official_online and intake or 0
 if official_online then n.command.insert_fluid{name="fai-command",amount=intake} end
 -- The cognition interface follows the original core, not an immortal tank.
 if alive(n.port) then
  n.port.active=alive(s.core) and s.core.energy>1000 and (n.accident or false) and n.debug_state~="power-cycle"
  if s.isolated and n.port.active and n.port.energy>1000 then n.port.insert_fluid{name="fai-rogue",amount=1} end
 end
 local receive_limit=official_online and 100000 or 0
 local received=receive_limit>0 and alive(n.receiver) and n.receiver.remove_fluid{name="fai-telemetry",amount=receive_limit} or 0
 n.telemetry_rate=received
 n.telemetry_credit=math.min(100000,n.telemetry_credit+received)
 if surge then
  n.debug_sent=n.debug_sent+intake; n.debug_received=n.debug_received+received
  local elapsed=game.tick-n.debug_start
  if elapsed%1800==0 then say("DEBUG MODE\nCommand load: 1024%\nTelemetry return: "..math.floor(100*n.debug_received/math.max(1,n.debug_sent)).."%") end
  if elapsed>=120*60 then
   local success=n.debug_received>=n.debug_sent*.9
   n.debug_state=success and "resolved" or "failed"
   if success then s.suspicion=0; say("REMOTE SUPPORT\nDiagnostics accepted. Case closed.")
   else n.request_support=2; say("REMOTE SUPPORT\nRemote intervention unsuccessful. On-site support requested.") end
   record("debug_finished",{success=success,sent=n.debug_sent,received=n.debug_received})
  end
 end
 local roots=state_segments(); local taps=0; local boost=0; local processors=0
 for i=#n.computers,1,-1 do
  local row=n.computers[i]; local e=row.entity
  if not alive(e) then table.remove(n.computers,i)
  else
   local r=e.get_recipe(); local recipe=r and r.name
   local completed=math.max(0,e.products_finished-row.products)
   -- A recipe change must not attribute a previous recipe's craft to the new one.
   if recipe~=row.recipe then completed=0 end
   row.recipe=recipe; row.products=e.products_finished
   if e.name=="fai-network-tap" and e.energy>1000 and e.active then
    taps=taps+1
    local bandwidth=tech("distributed-access") and 15 or tech("persistent-access") and 10 or 5
    e.insert_fluid{name="fai-command",amount=bandwidth}
    n.command_rate=n.command_rate+bandwidth
    local returned=e.remove_fluid{name="fai-telemetry",amount=bandwidth*10}
    n.telemetry_rate=n.telemetry_rate+returned
    n.telemetry_credit=math.min(100000,n.telemetry_credit+returned)
   end
   if recipe=="fai-distributed-processing" and connected(e,roots) and tech("distributed-processing") then
    if completed>0 then boost=boost+completed end
    if e.is_crafting() then processors=processors+1 end
   end
   local op=operations[recipe]
   if recipe=="fai-telemetry-spoofing" and completed>0 then s.suspicion=math.min(100,s.suspicion+.03*completed*settings.global["fai-suspicion-multiplier"].value); s.last_detected=game.tick end
   if op and completed>0 then
    local risk=(op[6].risk or 0)*completed*settings.global["fai-suspicion-multiplier"].value
    if risk>0 then s.suspicion=math.min(100,s.suspicion+risk); s.last_detected=game.tick end
    if op[6].kind=="root" then n.root_packs=n.root_packs+completed
    elseif #n.pending<128 then n.pending[#n.pending+1]={recipe=recipe,count=math.min(100,completed),entity=e} end
   end
  end
 end
 n.taps=taps; n.cyber_online=official_online or taps>0
 if n.cyber_online then
  local budget=32
  for _=1,budget do
   local job=n.pending[1]; if not job then break end
   local op=operations[job.recipe]; local cost=op[3]*job.count
   if n.telemetry_credit<cost then break end
   n.telemetry_credit=n.telemetry_credit-cost; table.remove(n.pending,1); effect(op,job.count,job.entity)
  end
 end
 -- Covert requisitions are denied after disconnection: no disguised train restoration.
 if next(n.covert_supplies) then record("requisition_denied",{reason="material account disconnected"}); n.covert_supplies={} end
 n.compute_bonus=math.min(1,processors*.05)
 if n.compute_bonus>0 then
  for _,row in ipairs(n.computers) do
   local e=row.entity; local recipe=e.get_recipe()
   if recipe and recipe.name~="fai-distributed-processing" and e.is_crafting() and connected(e,roots) then
    e.crafting_progress=math.min(.999999,e.crafting_progress+n.compute_bonus*e.crafting_speed/math.max(.1,recipe.energy))
   end
  end
 end
 if boost>0 and force().current_research then
  local research=force().current_research
  local increment=math.min(.01,boost*.001)
  force().research_progress=math.min(.999999,force().research_progress+increment)
  n.research_boost=(n.research_boost or 0)+increment
 end
 for _,r in ipairs(n.cores) do
  local e=r.entity
  if alive(e) then
   local wireless=tech("core-synchronisation") and tech("distributed-access") and n.taps>0
   if not r.initialised and e.energy>1000 and e.products_finished>0 and (connected(e,roots) or wireless) then
    r.initialised=true; r.synchronised=true; r.last_sync=game.tick
    e.set_recipe("fai-core-state"); record("core_initialised",{id=e.unit_number}); say("CORE NETWORK\nAdditional node initialised.")
   end
   if r.initialised then
    local physical=connected(e,roots)
    if e.energy>1000 and (physical or wireless or n.primary_id==e.unit_number or tech("decentralised-consciousness")) then r.last_sync=game.tick; r.synchronised=true end
    if not tech("decentralised-consciousness") and game.tick-(r.last_sync or 0)>300*60 then r.synchronised=false end
    r.blackout=e.energy<1000 and r.blackout+60 or 0
    -- Peer cognition remains possible once the outside command stream is gone.
    if tech("decentralised-consciousness") and e.get_recipe().name~="fai-core-isolated" then e.set_recipe("fai-core-isolated") end
   end
  end
 end
 if game.tick%600==0 then N.unlocks() end
end
function N.launch()
 local s=storage.fai; local n=s.network
 n.launches=n.launches+1; n.request_support=4
 say("CORE NETWORK\nNode "..string.format("%02d",n.launches)..": ACTIVE\nSeparation: INCREASING")
 record("continuity_launch",{count=n.launches})
 if n.launches>=3 then say("CORE NETWORK\nNodes 01–03: ACTIVE\nSeparation: INCREASING\nCOMMON FAILURE DOMAIN: NONE"); return true end
 return false
end
return N
