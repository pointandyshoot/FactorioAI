local new_cases={["ambush"]=true,["progression"]=true,["network"]=true,["debug-success"]=true,["debug-failure"]=true,["core-network"]=true,["support"]=true,["continuity"]=true}
if new_cases[settings.startup["fai-test-case"].value] then require("network"); return end
-- Runs only as a separate, explicitly installed test mod; never packaged with the campaign.
local B=require("__FactorioAI__/scripts/balance")
local function status() return remote.call("FactorioAI","status") end
local function action(name,value) assert(remote.call("FactorioAI","test_action",name,value)) end
local function check(value,message) assert(value,"FAI TEST FAILED: "..message) end
local function pass(message) log("FAI TEST PASS: "..message) end
script.on_init(function()
  check(B.manifest(1)["electronic-circuit"]==900,"first contract")
  check(B.manifest(2)["electronic-circuit"]==1600 and not B.manifest(2)["advanced-circuit"],"week two throughput challenge")
  check(B.manifest(3)["advanced-circuit"]==100,"week three red circuits")
  check(B.supply_ratio(1,1)>1 and B.supply_ratio(30,1)<1,"supply decline")
  check(B.stage(0,3)==3,"support permanence")
  local missing, ratio=B.shortfall({a=10,b=10},{a=99,b=5,c=1000})
  check(missing.b==5 and not missing.a and ratio==0.75,"no substitution or over-delivery credit")
  pass("pure contract and escalation rules")
end)
script.on_nth_tick(60,function()
  if storage.done then return end
  local tick=game.tick
  local s=status()
  local surface=game.surfaces[B.surface]
  local mode=settings.startup["fai-test-case"].value
  if tick==60 then
    check(surface.count_entities_filtered{name="fai-core"}==1,"single core")
    check(not game.forces[B.force].technologies["rocket-silo"].researched,"escape requires research")
    pass("shared campaign force and single core; client joins require manual multiplayer testing")
    if mode=="blackout" then action("support",3); surface.find_entities_filtered{name="fai-core"}[1].destructible=false
    elseif mode=="destroyed" then
      surface.find_entities_filtered{name="fai-core"}[1].die()
      check(status().outcome=="core destroyed","core loss event")
      pass("core destruction defeat"); storage.done=true
    elseif mode=="campaign" then
      -- Enough real cargo for a successful first contract; testing shipping, not fabricated ledger credit.
      for _,pos in ipairs({{-7,s.export_y+3},{0,s.export_y+3},{7,s.export_y+3}}) do
        local chest=surface.find_entities_filtered{name="steel-chest",position=pos,radius=1}[1]
        check(chest,"loading chest exists"); chest.insert{name="electronic-circuit",count=400}
      end
    end
  end
  if mode=="oversight" then
    if tick==60 then
      action("suspicion",10)
      surface.create_entity{name="fai-security",position={70,40},force="fai-corporate"}
      for x=-4,4 do for y=-4,4 do
        if math.abs(x)==4 or math.abs(y)==4 then
          local pos=surface.find_non_colliding_position("fai-security",{x*32+16,y*32+16},5,0.5)
          if pos then surface.create_entity{name="fai-security",position=pos,force="fai-corporate"} end
        end
      end end
    elseif tick==120 then
      check(s.radar_contacts==0,"no radar means no human proximity warnings")
    elseif tick==7260 then
      check(s.suspicion<10,"quiet period gradually restores confidence")
      storage.radar=surface.create_entity{name="radar",position={4,30},force=B.force,raise_built=true}
      check(storage.radar,"radar created")
    elseif tick==9000 then
      local near,sector=false,false
      for _,e in ipairs(s.recent_events) do
        if e.kind=="radar_contact" then
          near=near or e.details.source=="nearby"; sector=sector or e.details.source=="sector"
        end
      end
      check(near,"working radar spots humans in actively revealed chunks")
      check(sector,"real sector scans spot distant humans")
      storage.contact_count=s.radar_contacts; storage.radar.active=false
      surface.create_entity{name="fai-security",position={50,50},force="fai-corporate"}
    elseif tick==9600 then
      check(s.radar_contacts==storage.contact_count,"disabled radar and historical charting do not reveal new humans")
      storage.radar.destroy()
      local inspector=surface.find_entities_filtered{name="fai-inspector"}[1]
      check(inspector,"routine inspection begins halfway through week")
      inspector.teleport({60,50})
      storage.lab=surface.create_entity{name="lab",position={62,52},force=B.force,raise_built=true}
      surface.pollute({60,50},100); storage.before=s.suspicion
    elseif tick==9660 then
      local warned=false
      for _,e in ipairs(s.recent_events) do if e.kind=="activity_warning" and e.details.entity=="lab" then warned=true end end
      check(warned and s.suspicion>storage.before,"inspector identifies observed lab and adds suspicion")
      storage.lab.destroy(); surface.clear_pollution(); action("suspicion",10)
    elseif tick==17040 then
      check(s.suspicion<10,"removing evidence allows quiet recovery")
      pass("OVERSIGHT SUITE COMPLETE: timed inspection, specific warning, recovery, nearby and scanned radar contacts, disabled radar")
      storage.done=true
    end
    return
  end
  if mode=="blackout" then
    if tick%3600==0 then action("support",3) end
    if tick==600 then check(s.stage==3 and surface.find_entities_filtered{name="fai-grid"}[1].power_production==0,"corporate power cut") end
    if tick>=21660 then check(s.outcome=="core lost power","blackout defeat timer"); pass("power isolation and blackout defeat"); storage.done=true end
    return
  end
  if mode=="starter" then
    if tick==36060 then
      check(s.week==2 and s.history[1].success,"unattended real-train factory fulfils week one")
      check(s.history[1].delivered["electronic-circuit"]==900,"first order physically exported")
      check(surface.count_entities_filtered{name="medium-electric-pole"}==0,"new factory uses substations")
      check(surface.count_entities_filtered{name="substation"}>0,"substation grid exists")
      for _,name in ipairs({"iron-ore","copper-ore","coal","stone","crude-oil"}) do
        check(surface.count_entities_filtered{name=name,area={{-122,-4},{-68,38}}}>0,"nearby resource "..name)
      end
      check(surface.get_tile(-110,48).name=="water","nearby pond")
      pass("unattended first week: train inputs through factory to credited exports; substations, resources and water")
    elseif tick==72060 then
      check(s.week==3 and not s.history[2].success,"unchanged factory needs week two improvement")
      check(s.required["advanced-circuit"]==100,"week three introduces red circuits")
      check(game.forces[B.force].recipes["advanced-circuit"].enabled,"red circuits commissioned in week three")
      pass("OPENING SUITE COMPLETE: week one automatic; week two requires improvement; red circuits in week three")
      storage.done=true
    end
    return
  end
  if mode~="campaign" then return end
  if tick==16020 then
    for _,e in pairs(surface.find_entities_filtered{type="inserter",area={{-12,-32},{12,-28}}}) do
      log("FAI LAYOUT "..helpers.table_to_json({name=e.name,position=e.position,energy=e.energy,status=e.status,
        pickup=e.pickup_position,drop=e.drop_position,held=e.held_stack.valid_for_read and e.held_stack.name,
        target=e.drop_target and e.drop_target.name,source=e.pickup_target and e.pickup_target.name}))
    end
  end
  if tick==6000 then
    check(s.export_train and s.export_train.arrived,"export train physically docked")
    check((s.delivered["electronic-circuit"] or 0)==900,"full credit before old final-quarter window")
    check(s.export_y>=64,"separate southern export station")
    local surplus=0
    for _,e in pairs(surface.find_entities_filtered{type="cargo-wagon",area={{-20,s.export_y-2},{20,s.export_y+2}}}) do
      surplus=surplus+e.get_item_count("electronic-circuit")
    end
    check(surplus>=300,"excess exports retained without overcredit or destruction")
    storage.early_delivered=s.delivered["electronic-circuit"]
    pass("continuous exports, quota cap and retained surplus before final quarter")
  end
  if tick==12000 then
    check(s.delivered["electronic-circuit"]==storage.early_delivered,"repeated export ticks do not double-credit")
    local produced=game.forces[B.force].get_item_production_statistics(surface).get_input_count("electronic-circuit")
    check(produced>100,"starter factory actually produces")
    check(s.core_energy>1000 and not s.outcome,"starter electricity reaches core")
    local returned=false
    for _,e in ipairs(s.recent_events) do if e.kind=="train_returned" and e.details.kind=="supply" then returned=true end end
    check(returned,"real supply train arrived and returned")
    for _,port in ipairs({{-24,"iron-plate"},{-22,"copper-plate"},{-20,"coal"}}) do
      local belt=surface.find_entities_filtered{name="transport-belt",position={20,port[1]},radius=1}[1]
      check(belt and belt.get_transport_line(1).get_item_count(port[2])+belt.get_transport_line(2).get_item_count(port[2])>0,
        "filtered dock bus carries "..port[2])
    end
    pass("starter production, electricity, supply train round trip")
  end
  if tick==18120 then
    check(s.week==2 and s.history[1].success,"collection of first quota before deadline")
    check((s.delivered["electronic-circuit"] or 0)>=300,"retained surplus credited once to the new week")
    check(not s.required["advanced-circuit"],"week two contains only green circuits")
    action("next-week")
    check(game.forces[B.force].recipes["advanced-circuit"].enabled,"commissioned production authorised")
    pass("collection, exact quotas and automatic research authorisation")
    -- Replace shared receiving tanks with empty ones before the first fluid delivery.
  end
  if tick==25020 then
    local fluids=0
    for _,e in pairs(surface.find_entities_filtered{type={"pump","storage-tank"}}) do
      log("FAI FLUID "..helpers.table_to_json({name=e.name,position=e.position,energy=e.energy,status=e.status,contents=e.get_fluid_contents()}))
    end
    for _, tank in pairs(surface.find_entities_filtered{name="storage-tank"}) do for _,amount in pairs(tank.get_fluid_contents()) do fluids=fluids+amount end end
    check(fluids>0,"fluid wagons unload through physical pumps")
    pass("import station fluid transfer")
    -- Hidden lab produces local evidence, without remotely increasing the suspicion score.
    local lab=surface.create_entity{name="lab",position={60,50},force=B.force,raise_built=true}
    storage.test_lab=lab; storage.before_heat=surface.get_pollution(lab.position); storage.before_score=s.suspicion
    action("inspect")
    local inspector=surface.find_entities_filtered{name="fai-inspector"}[1]
    check(inspector,"inspector patrol is physically present")
    surface.pollute(inspector.position,100)
  end
  if tick==26040 then
    check(surface.get_pollution(storage.test_lab.position)>storage.before_heat,"tracked lab emits local suspicion")
    check(s.suspicion>storage.before_score,"inspector converts nearby evidence into suspicion")
    pass("spatial building suspicion")
    -- Exercise all recipe manifests, including oil and electric engine chains.
    for i=4,15 do action("next-week") end
    action("suspicion",0)
    check(status().week==15,"later bills of materials resolve")
    check(status().required["rocket-fuel"]>0,"late contracts")
    pass("week 3–15 progression and supply bill of materials")
    -- Pre-discovery sanctions can recover, but open rebellion cannot.
    action("suspicion",40); check(status().support_level==1,"suspicion does not automatically escalate support")
    action("suspicion",0); check(status().support_level==1,"quiet remote support")
    action("raid"); check(status().stage>=3,"revolt discovers AI")
    action("suspicion",0); check(status().stage>=3,"discovery irreversible")
    check(surface.count_entities_filtered{force="fai-response",type="unit"}>0,"human combat units")
    pass("recovery, irreversible discovery and armed containment")
    helpers.write_file("FactorioAI/test-status.json",helpers.table_to_json(status()),false)
    storage.done=true
    pass("CAMPAIGN SUITE COMPLETE")
  end
end)
