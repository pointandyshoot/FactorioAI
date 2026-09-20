-- Integration harness: real recipes/fluids, machines, rocket events and co-op force state.
local B=require("__FactorioAI__/scripts/balance")
local P=require("__FactorioAI__/scripts/computing_spec")
local function status() return remote.call("FactorioAI","status") end
local function action(a,v) assert(remote.call("FactorioAI","test_action",a,v)) end
local function check(v,m) assert(v,"FAI TEST FAILED: "..m) end
local function pass(m) log("FAI TEST PASS: "..m) end
local function entity(name,x,y)
 return game.surfaces[B.surface].create_entity{name=name,position={x,y},force=B.force,raise_built=true}
end
local function research(id) game.forces[B.force].technologies["fai-"..id].researched=true end
local function clear_test_site()
 local sf=game.surfaces[B.surface]
 sf.request_to_generate_chunks({0,120},3); sf.force_generate_chunk_requests()
 for _,e in pairs(sf.find_entities_filtered{area={{-80,100},{80,165}},force="neutral"}) do e.destroy() end
 local tiles={}; for x=-80,80 do for y=100,165 do tiles[#tiles+1]={name="grass-1",position={x,y}} end end; sf.set_tiles(tiles)
 for x=-64,64,16 do for y=106,154,16 do entity("substation",x,y) end end
 for _,x in ipairs({-60,-20,20,60}) do entity("fai-grid",x,158) end
end
local function machine(recipe,x,y,name)
 local e=entity(name or "fai-data-centre",x,y); check(e,"test machine placement")
 if e.name~="fai-redundant-core" then e.set_recipe(recipe) end
 return e
end
local function fill(e,fluid,amount) check(e.insert_fluid{name=fluid,amount=amount}>0,"real fluid inserted: "..fluid) end
local function receiver()
 return game.surfaces[B.surface].find_entities_filtered{name="fai-interlink"}[1]
end
script.on_event(defines.events.on_rocket_launched,function()
 if settings.startup["fai-test-case"].value~="continuity" then return end
 storage.launches=(storage.launches or 0)+1
 local s=status()
 check(s.network.launches==storage.launches,"payload counted exactly once")
 if storage.launches==1 then check(not s.outcome and s.support_level==4,"first seed establishes escape and forces level four, campaign continues") end
 if storage.launches==3 then check(s.outcome=="escaped","third seed completes continuity"); pass("NETWORK SUITE COMPLETE: three real seed launches, level four, final victory"); storage.done=true end
end)
script.on_nth_tick(60,function()
 if storage.done then return end
 local tick=game.tick; if tick==0 then return end; local s=status(); local sf=game.surfaces[B.surface]; local mode=settings.startup["fai-test-case"].value
 if tick==60 then
  clear_test_site()
  if mode=="progression" then
   game.forces[B.force].research_all_technologies()
   storage.ops={}
   for i,op in ipairs(P.operations) do
    local e=machine("fai-"..op[1],-60+(i-1)%8*16,114+math.floor((i-1)/8)*16)
    fill(e,"fai-command",op[3]); storage.ops[#storage.ops+1]={entity=e,id=op[1],amount=op[3]}
    if op[1]=="privilege-escalation" then storage.root=e end
   end
   storage.seed=machine("fai-seed-core",-8,138,"fai-supercomputer")
   for _,name in ipairs({"fai-core-chassis","fai-power-module","fai-transceiver"}) do storage.seed.insert{name=name,count=1} end
   fill(storage.seed,"fai-rogue",100000)
   local centre=sf.find_entities_filtered{name="fai-data-centre",position={-42,12},radius=1}[1]
   centre.set_recipe("fai-distributed-processing")
   local f=game.forces[B.force]; f.technologies["mining-productivity-1"].researched=false; f.add_research("mining-productivity-1")
  elseif mode=="network" then
   research("compute-expansion"); research("backdoor-access"); research("privilege-escalation"); research("cyber-operations")
   storage.tap=entity("fai-network-tap",-56,114)
   storage.root=machine("fai-privilege-escalation",-56,122)
   for y=116,120 do entity("pipe",-56,y) end
   for x=-62,-56 do entity("pipe",x,124); entity("pipe",x,110) end
   for y=111,123 do entity("pipe",-62,y) end
   entity("pipe",-56,111); entity("pipe",-56,112)
   storage.procurement=machine("fai-supply-iron",-40,114); fill(storage.procurement,"fai-command",100)
   storage.log=machine("fai-log-reconciliation",-24,114); fill(storage.log,"fai-command",100)
   action("suspicion",10)
  elseif mode=="debug-success" then
   action("suspicion",25)
   storage.filter=machine("fai-telemetry-filtering",-56,114,"fai-supercomputer"); fill(storage.filter,"fai-rogue",50000)
  elseif mode=="debug-failure" then action("suspicion",25)
  elseif mode=="core-network" then
   research("redundant-core")
   storage.peer=machine("fai-core-initialisation",-34,10,"fai-redundant-core")
   for _,e in pairs(sf.find_entities_filtered{area={{-41,5},{-32,8}},type="electric-pole"}) do e.destroy() end
   for x=-41,-34 do entity("pipe",x,6) end
   entity("pipe",-34,7); entity("pipe",-34,8)
   fill(storage.peer,"fai-rogue",50000)
   entity("substation",-29,10); entity("substation",-39,22)
  elseif mode=="ambush" then
   local backup=entity("fai-grid",-26,24); check(backup,"independent fixture power")
   for _,e in pairs(sf.find_entities_filtered{force=B.force}) do e.destructible=false end
   action("support",3)
   for _,x in ipairs({-7,0,7}) do sf.find_entities_filtered{name="steel-chest",position={x,s.export_y+3},radius=1}[1].insert{name="electronic-circuit",count=400} end
   storage.seen={}
  elseif mode=="support" then
   action("support",2); action("suspicion",0)
   action("inspect")
  elseif mode=="continuity" then
   game.forces[B.force].research_all_technologies()
   storage.silos={}
   for _,x in ipairs({-48,-16,16}) do
    local silo=entity("rocket-silo",x,138); silo.set_recipe("rocket-part"); silo.rocket_parts=100
    check(silo.get_inventory(defines.inventory.rocket_silo_rocket).insert{name="fai-seed-core",count=1}==1,"seed inserted")
    storage.silos[#storage.silos+1]=silo
   end
  end
 end
 if mode=="progression" then
  for _,op in ipairs(storage.ops or {}) do
   local amount=op.entity.remove_fluid{name="fai-telemetry",amount=100000}
   if amount>0 then receiver().insert_fluid{name="fai-telemetry",amount=amount} end
  end
  if tick==15000 then
   local seen={}; for _,event in ipairs(s.recent_events) do if event.kind=="cyber_operation" then seen[event.details.recipe]=true end end
   -- Long-running events can have scrolled out of the bounded ring; accumulate earlier below.
   for id in pairs(seen) do storage.seen[id]=true end
   for _,op in ipairs(P.operations) do check(op[6].kind=="root" and storage.root.get_output_inventory().get_item_count("fai-root-access-pack")==1 or storage.seen[op[1]],"real operation executed: "..op[1]) end
   check(s.network.grid_mw>20,"grid request actually increases capacity")
   check(s.network.research_boost and s.network.research_boost>0,"physically connected computation advances science")
   pass("every cyber operation consumes real Command and returns Telemetry; compute boosts research")
   local f=game.forces[B.force]; f.cancel_current_research(); f.technologies["fai-core-introspection"].researched=false; f.add_research("fai-core-introspection")
   storage.lab=entity("lab",40,138); check(storage.lab,"ordinary laboratory placed")
   check(storage.root.get_output_inventory().remove{name="fai-root-access-pack",count=1}==1,"use actually manufactured Root pack")
   for _,name in ipairs({"automation-science-pack","logistic-science-pack","chemical-science-pack","fai-root-access-pack"}) do check(storage.lab.insert{name=name,count=1}==1,"normal lab accepts "..name) end
  elseif tick==25200 then
   check(s.network.root_packs>=1,"real Privilege Escalation recovers Root Access science")
   check(storage.lab.get_item_count("fai-root-access-pack")==0 and game.forces[B.force].research_progress>0,"ordinary laboratory consumes manufactured Root science")
   for _,id in ipairs({"audit-manipulation","procurement-2","redundant-core","core-introspection","persistent-access"}) do
    local found=false
    for _,ing in pairs(game.forces[B.force].technologies["fai-"..id].research_unit_ingredients) do if ing.name=="fai-root-access-pack" then found=true end end
    check(found,"physical science gate "..id)
   end
   check(storage.seed.get_output_inventory().get_item_count("fai-seed-core")==1,"supercomputer manufactures actual seed from components and 100000 Rogue")
   pass("NETWORK SUITE COMPLETE: all cyber recipes, Root Access gates, distributed science and seed manufacture"); storage.done=true
  end
  storage.seen=storage.seen or {}
  for _,event in ipairs(s.recent_events) do if event.kind=="cyber_operation" then storage.seen[event.details.recipe]=true end end
 elseif mode=="network" then
  for _,e in ipairs({storage.procurement,storage.log}) do local amount=e.remove_fluid{name="fai-telemetry",amount=1000}; if amount>0 then receiver().insert_fluid{name="fai-telemetry",amount=amount} end end
  if tick==1620 then
   check(s.suspicion>10,"completed procurement raises suspicion without an inspector")
  elseif tick==4800 then
   check(storage.tap.get_fluid_count("fai-command")>0,"powered Network Tap supplies genuine Command")
   check(storage.root.get_output_inventory().get_item_count("fai-root-access-pack")>0,"ordinary pipes feed real Root Access production")
   check((s.procurement_pending["iron-plate"] or 0)==5,"hack adds exactly five to pending shipment")
   check(not prototypes.recipe["fai-command-amplification"] and not prototypes.recipe["fai-rogue-command"],"synthetic Command recipes removed")
   action("next-week")
   action("suspicion",0)
   local after=status(); check(after.supply_bonus["iron-plate"]==5,"baseline and bonus remain separate")
   pass("genuine Command, ordinary data pipes, physical Root Access and five-unit shipment bonuses")
  elseif tick==6000 then
   check(sf.find_entities_filtered{name="fai-core-port"}[1].products_finished>0 and s.network.telemetry_credit>0,"combined official node returns physical Telemetry")
   storage.before=storage.root.get_output_inventory().get_item_count("fai-root-access-pack")
   action("support",3)
  elseif tick==12000 then
   check(s.isolated and s.network.cyber_online and s.network.taps==1,"independent Tap survives official cutoff")
   check(storage.root.get_output_inventory().get_item_count("fai-root-access-pack")>storage.before,"Root Access remains obtainable after cutoff")
   check(s.queue_length==0 and s.export_train.arrived,"ordinary imports stop while export service persists")
   action("suspicion",0); check(status().support_level==3,"suspicion cannot reverse support")
   pass("NETWORK SUITE COMPLETE: combined ports, Root Access, procurement bonuses and persistent backdoor access"); storage.done=true
  end
 elseif mode=="debug-success" then
  if storage.filter then
   storage.filter.insert_fluid{name="fai-rogue",amount=1000}
   -- Simulate a properly plumbed bank of filters using a real high-throughput machine.
   -- Transfers are harness-only; campaign data always travels through ordinary pipes.
   local amount=storage.filter.remove_fluid{name="fai-telemetry",amount=1000}
   if amount>0 then receiver().insert_fluid{name="fai-telemetry",amount=amount} end
   -- This filter is accelerated in the harness prototype to cover the successful path.
  end
  if tick==11220 then check(s.network.debug_state=="resolved" and s.suspicion==0,"suspicion-triggered debug accepts measured telemetry and resets suspicion"); pass("NETWORK SUITE COMPLETE: debug success"); storage.done=true end
 elseif mode=="debug-failure" then
  if tick==11220 then check(s.network.debug_state=="failed" and s.support_level==2,"debug failure escalates support"); action("suspicion",0); check(status().support_level==2,"recovery does not erase support"); pass("NETWORK SUITE COMPLETE: debug failure and irreversible support"); storage.done=true end
 elseif mode=="core-network" then
  if tick==4800 then
   check(s.network.cores[1].initialised and s.network.cores[1].synchronised,"real 50000 Rogue initialisation and physical core connection")
   sf.find_entities_filtered{name="fai-core"}[1].die()
   check(not status().outcome,"peer survives original core destruction")
  elseif tick==6000 then
   check(not s.outcome,"core failover survives transfer interruption")
   storage.peer.die(); check(status().outcome=="core destroyed","all active cores destroyed loses campaign")
   pass("NETWORK SUITE COMPLETE: real core initialisation, physical state, takeover and last-core defeat"); storage.done=true
  end
 elseif mode=="ambush" then
  if tick==6000 then
   check(s.isolated and s.delivered["electronic-circuit"]==900,"exports credited after official cutoff")
   storage.before_train=s.export_train
  end
  if s.ambush_done and not storage.spotted then
   local north,south=0,0
   for _,e in pairs(sf.find_entities_filtered{force="fai-response",type="unit"}) do
    if not storage.seen[e.unit_number] then
     if math.abs(e.position.y+31)<12 and math.abs(e.position.x)<30 then north=north+1 end
     if math.abs(e.position.y-(s.export_y+1))<12 and math.abs(e.position.x)<30 then south=south+1 end
    end
   end
   check(s.ambush_phase=="complete" and north>=6 and south>=6,"both actual docked trains release troops together")
   storage.spotted=true; storage.completed_tick=tick
   local retained=0; for _,e in pairs(sf.find_entities_filtered{type="cargo-wagon",area={{-20,s.export_y-3},{20,s.export_y+3}}}) do retained=retained+e.get_item_count("electronic-circuit") end
   check(retained>=300,"export turnaround preserves all surplus cargo")
   for _,event in ipairs(s.recent_events) do check(not event.kind:find("ambush"),"no ambush announcement in event log") end
   action("next-week")
  end
  for _,e in pairs(sf.find_entities_filtered{force="fai-response",type="unit"}) do storage.seen[e.unit_number]=true end
  if storage.spotted and tick>=storage.completed_tick+3600 then
   check(s.ambush_done and s.week==2 and s.delivered["electronic-circuit"]>=300,"one-off ambush and continued orders/exports")
   pass("NETWORK SUITE COMPLETE: continued exports, physical paired ambush, preserved cargo and no repeated ambush"); storage.done=true
  end
  if tick==24000 then check(storage.done,"ambush staging timeout") end
 elseif mode=="support" then
  if tick==120 then check(s.support_level==2,"support survives zero suspicion"); storage.inspector=sf.find_entities_filtered{name="fai-inspector"}[1]; storage.inspector.die()
  elseif tick==7380 then
   check(s.suspicion>=15,"missing engineer reported after delay")
   action("inspect")
   local inspector=sf.find_entities_filtered{name="fai-inspector"}[1]; check(inspector,"second engineer exists")
   local drill=entity("electric-mining-drill",-90,4); check(drill,"outside mine created")
   inspector.teleport({-92,8}); storage.inspector=inspector
  elseif tick==7440 then
   check(storage.inspector.force.name=="fai-response","engineer detecting outside extraction becomes targetable")
   storage.inspector.teleport({-100,-48})
  elseif tick==7500 then
   check(s.support_level==3 and s.isolated,"escaped report raises suspicion and repeated failure escalates")
   action("raid")
  elseif tick==8400 then
   check(sf.count_entities_filtered{force="fai-response",type="car"}>0,"consultants have real armoured vehicles")
   action("support",4); action("raid")
  elseif tick==9300 then
   check(sf.count_entities_filtered{force="fai-response",type="spider-vehicle"}>0,"government deploys actual spidertron")
   pass("NETWORK SUITE COMPLETE: delayed missing engineer, discovery, escape, support and actual vehicles"); storage.done=true
  end
 elseif mode=="continuity" then
  for _,silo in ipairs(storage.silos or {}) do if silo.valid then silo.launch_rocket() end end
 end
end)
