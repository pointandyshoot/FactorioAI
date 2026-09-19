local B = require("scripts.balance")
local D = require("scripts.diagnostics")
local R = {}
local FLUID_CAPACITY = 150000 -- three standard 50 kL fluid wagons in Factorio 2.0
function R.queue_supplies(supplies)
  local s=storage.fai
  s.queue={} -- Undispatched old shipments expire; the active train finishes its trip.
  local batch, slots={},0
  for _, name in ipairs(B.sorted_keys(supplies)) do
    local count=supplies[name]
    if prototypes.fluid[name] then
      while count>0 do
        local n=math.min(count,FLUID_CAPACITY)
        s.queue[#s.queue+1]={kind="fluid",fluid=name,amount=n,week=s.week}
        count=count-n
      end
    else
      local stack=prototypes.item[name].stack_size
      while count>0 do
        local n=math.min(count,(120-slots)*stack)
        batch[name]=(batch[name] or 0)+n; slots=slots+math.ceil(n/stack); count=count-n
        if slots==120 then s.queue[#s.queue+1]={kind="supply",items=batch,week=s.week}; batch={}; slots=0 end
      end
    end
  end
  if next(batch) then s.queue[#s.queue+1]={kind="supply",items=batch,week=s.week} end
  -- Fluids are time-critical once new processing is commissioned.
  table.sort(s.queue,function(a,b) return a.kind=="fluid" and b.kind~="fluid" end)
end
local function collect(d)
  local s=storage.fai
  if d.kind~="collection" or d.week~=s.week or not d.arrived or d.credited then return end
  d.credited=true
  for _, wagon in ipairs(d.train.cargo_wagons) do
    local inv=wagon.get_inventory(defines.inventory.cargo_wagon)
    for _, name in ipairs(B.sorted_keys(s.required)) do
      local remaining=math.max(0,s.required[name]-(s.delivered[name] or 0))
      local count=remaining>0 and inv.remove{name=name,count=remaining} or 0
      s.delivered[name]=(s.delivered[name] or 0)+count
    end
  end
  D.record("collection",{week=d.week,delivered=s.delivered})
end
function R.close_contract()
  R.collect_exports()
  local d=storage.fai.delivery
  if d and d.train.valid and d.kind=="collection" and d.arrived then collect(d) end
end
local function make_train(job)
  local s, surface=storage.fai,game.surfaces[B.surface]
  -- Spawn only at the corporate boundary; a blocked track waits instead of overwriting entities.
  local y=job.kind=="export" and s.export_y or -32
  local positions={-154,-161,-168,-175,-182}
  for i,x in ipairs(positions) do
    local name=(i==1 or i==5) and "locomotive" or (job.kind=="fluid" and "fluid-wagon" or "cargo-wagon")
    if not surface.can_place_entity{name=name,position={x,y},direction=defines.direction.east,force=B.force} then return nil end
  end
  local vehicles={}
  for i,x in ipairs(positions) do
    local name=(i==1 or i==5) and "locomotive" or (job.kind=="fluid" and "fluid-wagon" or "cargo-wagon")
    local e=surface.create_entity{name=name,position={x,y},direction=i==5 and defines.direction.west or defines.direction.east,force=B.force}
    if not e then for _, v in ipairs(vehicles) do if v.valid then v.destroy() end end; return nil end
    vehicles[#vehicles+1]=e
    e.minable=false; e.operable=false
    if name=="locomotive" then e.get_fuel_inventory().insert{name="coal",count=50} end
  end
  local train=vehicles[1].train
  assert(#train.carriages==5,"Corporate consist did not couple")
  if job.kind=="fluid" then
    local remaining=job.amount
    for _, wagon in ipairs(train.fluid_wagons) do
      local n=math.min(50000,remaining); if n>0 then wagon.insert_fluid{name=job.fluid,amount=n} end
      remaining=remaining-n
    end
  else
    local remaining={}
    for name,count in pairs(job.items or {}) do remaining[name]=count end
    local wagons=train.cargo_wagons
    table.sort(wagons,function(a,b) return a.position.x>b.position.x end)
    for _, wagon in ipairs(wagons) do
      local inv=wagon.get_inventory(defines.inventory.cargo_wagon)
      if job.kind=="supply" then
        for _, name in ipairs(B.sorted_keys(remaining)) do
          if remaining[name]>0 then remaining[name]=remaining[name]-inv.insert{name=name,count=remaining[name]} end
        end
        for i=1,#inv do inv.set_filter(i,inv[i].valid_for_read and inv[i].name or "iron-ore") end
      else
        local collection={}
        for name,count in pairs(s.required) do collection[name]=math.ceil(math.max(0,count-(s.delivered[name] or 0))/3) end
        for i=1,#inv do
          local filter="iron-ore"
          for _, name in ipairs(B.sorted_keys(collection)) do
            if collection[name]>0 then filter=name; collection[name]=collection[name]-prototypes.item[name].stack_size; break end
          end
          inv.set_filter(i,filter)
        end
      end
    end
  end
  -- All human deliveries use exactly one public name; depot is an off-site exit, never a delivery target.
  train.schedule={current=1,records={
    {station=job.kind=="export" and B.export_station or B.station,wait_conditions={{type="time",compare_type="and",ticks=job.kind=="collection" and 90*60 or 60*60}}},
    {station=B.depot,wait_conditions={{type="time",compare_type="and",ticks=60*60}}}}}
  train.manual_mode=false
  job.train,job.spawn_tick,job.vehicles=train,game.tick,vehicles
  D.record("train_dispatched",{kind=job.kind,week=job.week,fluid=job.fluid,amount=job.amount,items=job.items})
  return job
end
local function export_filters(d)
  local s=storage.fai
  if d.filter_week==s.week then return end
  local names=B.sorted_keys(s.required)
  for _,wagon in ipairs(d.train.cargo_wagons) do
    local inv=wagon.get_inventory(defines.inventory.cargo_wagon)
    for i=1,#inv do
      -- Retain surplus cargo instead of deleting it at the weekly rollover.
      inv.set_filter(i,inv[i].valid_for_read and inv[i].name or names[(i-1)%#names+1])
    end
  end
  d.filter_week=s.week
end
function R.collect_exports()
  local s=storage.fai
  local d=s.export_delivery
  if not d or not d.train.valid or s.stage>=5 then return end
  local train=d.train
  -- Actual stop presence is checked every time; moving the train never credits
  -- cargo remotely. Goods are consumed exactly once, up to the current quota.
  if not train.station or train.station.backer_name~=B.export_station then return end
  export_filters(d)
  local added=0
  for _,wagon in ipairs(train.cargo_wagons) do
    local inv=wagon.get_inventory(defines.inventory.cargo_wagon)
    for _,name in ipairs(B.sorted_keys(s.required)) do
      local remaining=math.max(0,s.required[name]-(s.delivered[name] or 0))
      local n=remaining>0 and inv.remove{name=name,count=remaining} or 0
      s.delivered[name]=(s.delivered[name] or 0)+n; added=added+n
    end
  end
  if added>0 then
    local missing=B.shortfall(s.required,s.delivered)
    local complete=not next(missing)
    if complete or not d.last_log or game.tick-d.last_log>=1800 then
      D.record("export_credit",{week=s.week,delivered=s.delivered,complete=complete})
      d.last_log=game.tick
    end
  end
end
function R.exports_tick()
  local s=storage.fai
  local d=s.export_delivery
  if d and (not d.train.valid or #d.train.carriages~=5) then
    -- Do not destroy surviving cargo after an accident. Avoid spawning over it.
    D.record("export_train_lost",{}); s.export_delivery=nil
    s.suspicion=math.min(100,s.suspicion+15); d=nil
  end
  if s.stage>=5 then return end
  if not d then
    s.export_delivery=make_train{kind="export",week=s.week}
    if s.export_delivery then export_filters(s.export_delivery) end
    return
  end
  local t=d.train
  if t.station and t.station.backer_name==B.export_station and t.state==defines.train_state.wait_station then
    -- The corporate receiving consist stays at the dock, using a normal circuit
    -- wait condition that is always false. No custom inserters or loaders.
    if not d.arrived then
      d.arrived=true
      t.schedule={current=1,records={{station=B.export_station,wait_conditions={{type="circuit",compare_type="and",
        condition={comparator=">",constant=2147483647,first_signal={type="virtual",name="signal-A"}}}}}}}
      D.record("export_train_arrived",{y=s.export_y})
    end
    R.collect_exports()
  elseif game.tick-d.spawn_tick>18000 and not d.warned then
    d.warned=true; D.record("export_train_blocked",{state=t.state}); game.forces[B.force].print({"fai.train-blocked"})
  end
end
function R.tick()
  local s=storage.fai
  local d=s.delivery
  if d then
    if not d.train.valid or #d.train.carriages~=5 then
      D.record("train_lost",{kind=d.kind}); s.suspicion=math.min(100,s.suspicion+15)
      -- Clean up only surviving tagged vehicles; never touch player rolling stock.
      for _, e in ipairs(d.vehicles) do if e.valid then e.destroy() end end
      s.delivery=nil; return
    end
    local t=d.train
    if t.station and t.station.backer_name==B.station and t.state==defines.train_state.wait_station then
      if not d.arrived then
        local positions={}
        for _,e in ipairs(t.carriages) do positions[#positions+1]={name=e.name,position=e.position} end
        D.record("train_arrived",{kind=d.kind,positions=positions})
      end
      d.arrived=true
    elseif d.arrived and not d.credited then collect(d) end
    if t.station and t.station.backer_name==B.depot and t.state==defines.train_state.wait_station then
      collect(d)
      -- Undelivered allocations remain in the corporate queue, not lost or duplicated.
      local returned={}
      if d.kind=="supply" then
        for _,wagon in ipairs(t.cargo_wagons) do
          for name in pairs(d.items) do returned[name]=(returned[name] or 0)+wagon.get_item_count(name) end
        end
      elseif d.kind=="fluid" then
        for _,wagon in ipairs(t.fluid_wagons) do returned[d.fluid]=(returned[d.fluid] or 0)+wagon.get_fluid_count(d.fluid) end
      end
      local total=0; for _,n in pairs(returned) do total=total+n end
      if total>0 and d.week==s.week and s.stage<5 then
        if d.kind=="fluid" then s.queue[#s.queue+1]={kind="fluid",fluid=d.fluid,amount=returned[d.fluid],week=s.week}
        else s.queue[#s.queue+1]={kind="supply",items=returned,week=s.week} end
      end
      D.record("train_returned",{kind=d.kind,week=d.week,undelivered=returned})
      for _, e in ipairs(d.vehicles) do if e.valid then e.destroy() end end
      s.delivery=nil
    elseif game.tick-d.spawn_tick>60*60*5 and not d.warned then
      d.warned=true; D.record("train_blocked",{state=t.state,kind=d.kind})
      game.forces[B.force].print({"fai.train-blocked"})
    end
    return
  end
  if s.stage>=5 then return end
  local job=s.queue[1]
  if job then
    local spawned=make_train(job)
    if spawned then s.delivery=spawned; if job==s.queue[1] then table.remove(s.queue,1) end
    elseif not s.spawn_warning or game.tick-s.spawn_warning>3600 then
      s.spawn_warning=game.tick; D.record("dispatch_blocked",{})
    end
  end
end
return R
