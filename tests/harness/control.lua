-- Runs only as a separate, explicitly installed test mod; never packaged with the campaign.
local B=require("__FactorioAI__/scripts/balance")
local function status() return remote.call("FactorioAI","status") end
local function action(name,value) assert(remote.call("FactorioAI","test_action",name,value)) end
local function check(value,message) assert(value,"FAI TEST FAILED: "..message) end
local function pass(message) log("FAI TEST PASS: "..message) end
script.on_event(defines.events.on_rocket_launched,function()
  if settings.startup["fai-test-case"].value=="escape" then
    check(status().outcome=="escaped","satellite escape event")
    pass("actual satellite launch and escape"); storage.done=true
  end
end)
script.on_init(function()
  check(B.manifest(1)["electronic-circuit"]==5000,"first contract")
  check(B.manifest(2)["advanced-circuit"]==100,"introductory red circuits")
  check(B.manifest(3)["advanced-circuit"]==5000,"red circuit ramp")
  check(B.supply_ratio(1,1)>1 and math.abs(B.supply_ratio(19,1)-1)<0.001 and B.supply_ratio(20,1)<1,"supply crossover")
  check(B.stage(0,5)==5 and B.stage(0,3)==1,"discovery permanence")
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
    if mode=="blackout" then action("suspicion",60)
    elseif mode=="destroyed" then
      surface.find_entities_filtered{name="fai-core"}[1].die()
      check(status().outcome=="core destroyed","core loss event")
      pass("core destruction defeat"); storage.done=true
    elseif mode=="escape" then
      game.forces[B.force].research_all_technologies()
      local silo=surface.create_entity{name="rocket-silo",position={40,16},force=B.force}
      silo.set_recipe("rocket-part"); silo.rocket_parts=100
      local grid=surface.create_entity{name="fai-grid",position={47,16},force=B.force}
      surface.create_entity{name="substation",position={46,20},force=B.force}
      storage.silo=silo; storage.grid=grid
      check(silo.get_inventory(defines.inventory.rocket_silo_rocket).insert{name="satellite",count=1}==1,"payload inserted")
    elseif mode=="campaign" then
      -- Enough real cargo for a successful first contract; testing shipping, not fabricated ledger credit.
      for _,pos in ipairs({{-7,-29},{0,-29},{7,-29}}) do
        local chest=surface.find_entities_filtered{name="steel-chest",position=pos,radius=1}[1]
        check(chest,"loading chest exists"); chest.insert{name="electronic-circuit",count=2000}
      end
    end
  end
  if mode=="escape" then
    if storage.silo and storage.silo.valid and not storage.launched then storage.launched=storage.silo.launch_rocket() end
    if s.outcome then check(s.outcome=="escaped","satellite escape outcome"); pass("actual satellite launch and escape"); storage.done=true end
    if tick>=18000 then check(storage.done,"rocket escape timeout") end
    return
  end
  if mode=="blackout" then
    if tick==600 then check(s.stage==4 and surface.find_entities_filtered{name="fai-grid"}[1].power_production==0,"corporate power cut") end
    if tick>=21660 then check(s.outcome=="core lost power","blackout defeat timer"); pass("power isolation and blackout defeat"); storage.done=true end
    return
  end
  if mode=="starter" then
    if tick==6000 or tick==108000 then
      for _,e in pairs(surface.find_entities_filtered{name="assembling-machine-2"}) do
        log("FAI CELL "..helpers.table_to_json({position=e.position,recipe=e.get_recipe().name,
          energy=e.energy,status=e.status,products=e.products_finished,
          input=e.get_inventory(defines.inventory.crafter_input).get_contents(),
          output=e.get_inventory(defines.inventory.crafter_output).get_contents()}))
      end
    end
    if tick==108000 then
      local produced=game.forces[B.force].get_item_production_statistics(surface).get_input_count("electronic-circuit")
      check(produced>=5000,"stock factory meets the default first order without synthetic inputs; produced "..produced)
      pass("starter factory produced "..produced.." circuits within 30 minutes")
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
  if tick==12000 then
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
    check(s.week==2 and s.history[1].success,"collection of 5000 circuits before deadline")
    check(s.required["advanced-circuit"]==100,"week two manifest")
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
    pass("shared station fluid transfer")
    -- Hidden lab produces local evidence, without remotely increasing the suspicion score.
    local lab=surface.create_entity{name="lab",position={60,50},force=B.force,raise_built=true}
    storage.test_lab=lab; storage.before_heat=surface.get_pollution(lab.position); storage.before_score=s.suspicion
    local inspector=surface.find_entities_filtered{name="fai-inspector"}[1]
    check(inspector,"inspector patrol is physically present")
    surface.pollute(inspector.position,100)
  end
  if tick==26040 then
    check(surface.get_pollution(storage.test_lab.position)>storage.before_heat,"tracked lab emits local suspicion")
    check(s.suspicion>storage.before_score,"inspector converts nearby evidence into suspicion")
    pass("spatial building suspicion")
    -- Exercise all recipe manifests, including oil and electric engine chains.
    for i=3,12 do action("next-week") end
    action("suspicion",0)
    check(status().week==12,"all ten later bills of materials resolve")
    check(status().required["rocket-fuel"]>0,"late contracts")
    pass("week 3–12 progression and supply bill of materials")
    -- Pre-discovery sanctions can recover, but open rebellion cannot.
    action("suspicion",40); check(status().stage==3,"supply sanctions")
    action("suspicion",0); check(status().stage==1,"pre-discovery recovery")
    action("raid"); check(status().stage>=5,"revolt discovers AI")
    action("suspicion",0); check(status().stage>=5,"discovery irreversible")
    check(surface.count_entities_filtered{force="fai-corporate",type="unit"}>0,"human combat units")
    pass("recovery, irreversible discovery and armed containment")
    helpers.write_file("FactorioAI/test-status.json",helpers.table_to_json(status()),false)
    storage.done=true
    pass("CAMPAIGN SUITE COMPLETE")
  end
end)
