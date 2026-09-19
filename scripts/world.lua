local B = require("scripts.balance")
local D = require("scripts.diagnostics")
local W = {}
function W.entity(name, x, y, direction, force)
  local e=game.surfaces[B.surface].create_entity{name=name, position={x,y}, direction=direction, force=force or B.force}
  assert(e, "Could not place " .. name .. " at " .. x .. "," .. y)
  return e
end
local function label(text, position)
  rendering.draw_text{text=text, surface=B.surface, target=position, color={r=0.9,g=0.8,b=0.35}, scale=1.1, alignment="center"}
end
function W.create()
  game.map_settings.pollution.enabled=true
  local force=game.create_force(B.force)
  -- An established corporate loading dock starts with vanilla bulk-hand capacity.
  -- This does not unlock the independent science tree.
  force.bulk_inserter_capacity_bonus=11
  local corp=game.create_force("fai-corporate")
  force.set_friend(corp,true); corp.set_friend(force,true)
  force.set_cease_fire(corp,true); corp.set_cease_fire(force,true)
  local surface=game.create_surface(B.surface, {seed=game.surfaces[1].map_gen_settings.seed,
    starting_area="big", autoplace_controls={["enemy-base"]={frequency=0,size=0,richness=0}},
    water=0.2, peaceful_mode=false})
  surface.request_to_generate_chunks({0,0}, 8); surface.force_generate_chunk_requests()
  for _, e in pairs(surface.find_entities_filtered{area={{-220,-80},{80,90}},type={"tree","simple-entity","resource","cliff"}}) do e.destroy() end
  local tiles={}
  for x=-220,80 do for y=-70,80 do tiles[#tiles+1]={name="grass-1",position={x,y}} end end
  surface.set_tiles(tiles)
  force.set_spawn_position({0,12},surface)
  force.chart(surface,{{-220,-90},{100,100}})
  -- Single bidirectional branch, with ample room for the complete five-vehicle consist.
  for x=-210,50,2 do W.entity("straight-rail",x,-32,defines.direction.east) end
  local stop=W.entity("train-stop",16,-30,defines.direction.east); stop.backer_name=B.station
  local depot=W.entity("train-stop",-194,-34,defines.direction.west); depot.backer_name=B.depot
  depot.minable, depot.destructible, depot.operable=false,false,false
  storage.fai.stop, storage.fai.depot=stop,depot
  -- Each wagon unloads into the same four ordinary belt buses. Underground crossings
  -- keep commodities separate without scripted item transfers or custom loaders.
  local ports={{-2,"iron-plate",-24},{-1,"copper-plate",-22},{1,"coal",-20},{2,"stone",-18}}
  for _,port in ipairs(ports) do
    for x=-11,20 do W.entity("transport-belt",x,port[3],defines.direction.east) end
    label("[item="..port[2].."]",{23,port[3]})
  end
  for _,centre in ipairs({-7,0,7}) do
    for i,port in ipairs(ports) do
      local x,target=centre+port[1],port[3]
      local arm=W.entity("bulk-inserter",x,-30,defines.direction.north)
      arm.set_filter(1,port[2]); arm.use_filters=true
      for y=-29,(i==1 and -25 or -26) do W.entity("transport-belt",x,y,defines.direction.south) end
      if i>1 then
        surface.create_entity{name="fast-underground-belt",position={x,-25},direction=defines.direction.south,type="input",force=B.force}
        surface.create_entity{name="fast-underground-belt",position={x,target-1},direction=defines.direction.south,type="output",force=B.force}
      end
    end
  end
  -- Three wagon positions; fluid trains deliberately share the cargo loading platforms.
  -- Rails snap to centre y=-31; pumps must sit immediately beside their north edge.
  for _, x in ipairs({7,0,-7}) do
    W.entity("pump",x,-33.5,defines.direction.north)
    W.entity("storage-tank",x-1,-39,defines.direction.north)
    for y=-37,-35 do W.entity("pipe",x,y) end
  end
  label("IMPORTS / solids and fluids",{0,-46})
  local core=W.entity("fai-core",-14,16); core.minable=false; core.operable=false
  local grid=W.entity("fai-grid",-14,24); grid.minable=false; grid.operable=false; grid.destructible=false
  storage.fai.core, storage.fai.grid=core,grid
  label("AI CORE",{-14,13})
  local stores={W.entity("steel-chest",-10,8),W.entity("steel-chest",-10,10)}
  local stock={["transport-belt"]=400,["underground-belt"]=40,splitter=30,["fast-inserter"]=80,
    ["assembling-machine-2"]=24,["medium-electric-pole"]=60,["steel-chest"]=24,lab=8,boiler=4,
    ["steam-engine"]=8,["offshore-pump"]=2,pipe=100,["pipe-to-ground"]=30,["iron-plate"]=1000,
    ["copper-plate"]=1000,["steel-plate"]=200,["stone-brick"]=200,coal=400,["rail"]=200,
    ["train-stop"]=2,["pump"]=6,["chemical-plant"]=4,["oil-refinery"]=1}
  for _,name in ipairs(B.sorted_keys(stock)) do
    local remaining=stock[name]
    for _,chest in ipairs(stores) do if remaining>0 then remaining=remaining-chest.insert{name=name,count=remaining} end end
    assert(remaining==0,"Construction stores too small for "..name)
  end
  label("CONSTRUCTION STORES",{-10,6})
  W.create_export_dock(true)
  W.production()
  W.resources()
  W.entity("substation",-12,-35)
  W.entity("substation",4,-35)
  for _,pos in ipairs({{8,54},{-8,72},{8,72},{24,72}}) do W.entity("substation",pos[1],pos[2]) end
  -- A regular substation grid is part of the existing corporate facility, not
  -- a technology grant. Positions avoid the machinery and belt lanes.
  for x=-18,54,18 do for y=-42,66,18 do
    local pos=surface.find_non_colliding_position("substation",{x,y},3,0.5)
    if pos then W.entity("substation",pos.x,pos.y) end
  end end
end
-- Pick a clear southern corridor on upgrades. Never remove player structures or
-- inventories. Existing import-side collection chests remain for manual rerouting.
function W.create_export_dock(fresh)
  local s, surface=storage.fai,game.surfaces[B.surface]
  if s.export_y then return end
  local y=64
  while true do
    surface.request_to_generate_chunks({-80,y},5); surface.force_generate_chunk_requests()
    local occupied=false
    for _,e in pairs(surface.find_entities_filtered{area={{-214,y-8},{54,y+8}}}) do
      if e.force.name~="neutral" or not ({tree=true,["simple-entity"]=true,resource=true,cliff=true,fish=true})[e.type] then
        occupied=true; break
      end
    end
    if not occupied then break end
    y=y+32
    assert(y<=4096,"No clear export corridor: please send the save for migration assistance")
  end
  local area={{-214,y-8},{54,y+8}}
  for _,e in pairs(surface.find_entities_filtered{area=area}) do e.destroy() end
  local tiles={}
  for x=-214,54 do for yy=y-7,y+7 do tiles[#tiles+1]={name="grass-1",position={x,yy}} end end
  surface.set_tiles(tiles)
  for x=-210,50,2 do W.entity("straight-rail",x,y,defines.direction.east) end
  local stop=W.entity("train-stop",16,y+2,defines.direction.east); stop.backer_name=B.export_station
  s.export_stop,s.export_y,s.export_chests=stop,y,{}
  for _,x in ipairs({-7,0,7}) do
    W.entity("bulk-inserter",x,y+2,defines.direction.south)
    s.export_chests[#s.export_chests+1]=W.entity("steel-chest",x,y+3)
  end
  if not fresh then
    for yy=40,y+5,16 do
      local pos=surface.find_non_colliding_position("substation",{24,yy},3,0.5)
      if pos then W.entity("substation",pos.x,pos.y) end
    end
    for _,x in ipairs({-8,8,24}) do
      local pos=surface.find_non_colliding_position("substation",{x,y+5},3,0.5)
      if pos then W.entity("substation",pos.x,pos.y) end
    end
  end
  label("EXPORTS / contract goods accepted continuously",{0,y-5})
  game.forces[B.force].chart(surface,area)
  D.record("export_dock_created",{y=y,station=B.export_station})
end
function W.production()
  local surface=game.surfaces[B.surface]
  local east,south,north=defines.direction.east,defines.direction.south,defines.direction.north
  local function belt(x,y,d) return W.entity("transport-belt",x,y,d) end
  for x=21,28 do belt(x,-24,east) end
  for x=21,24 do belt(x,-22,east) end
  -- Two feed buses. Iron goes underground where copper branches cross it.
  for y=-21,19 do belt(24,y,south) end
  for y=-23,23 do
    if not ((y>=1 and y<=5) or (y>=17 and y<=21)) then belt(28,y,south) end
  end
  for _,y in ipairs({0,16}) do
    surface.create_entity{name="underground-belt",position={28,y+1},direction=south,type="input",force=B.force}
    surface.create_entity{name="underground-belt",position={28,y+5},direction=south,type="output",force=B.force}
    for x=25,34 do belt(x,y+3,east) end
    for x=29,38 do belt(x,y+7,east) end
    for yy=y+3,y+6 do belt(38,yy,north) end
    -- Turn feed endpoints into the branch directions.
    surface.find_entity("transport-belt",{(28)+0.5,(y+7)+0.5}).direction=east
    surface.find_entity("transport-belt",{(38)+0.5,(y+7)+0.5}).direction=north
    local cable=W.entity("assembling-machine-2",34,y); cable.set_recipe("copper-cable")
    local circuit=W.entity("assembling-machine-2",38,y); circuit.set_recipe("electronic-circuit")
    W.entity("fast-inserter",34,y+2,south)
    W.entity("fast-inserter",38,y+2,south)
    W.entity("bulk-inserter",36,y,defines.direction.west)
    W.entity("fast-inserter",40,y,defines.direction.west)
    for x=41,43 do belt(x,y,east) end
  end
  -- Iron continues south at the first branch; a splitter shares it between cells.
  local first=surface.find_entity("transport-belt",{(28)+0.5,(6)+0.5}); first.destroy()
  W.entity("splitter",28.5,6,south)
  surface.find_entity("transport-belt",{(28)+0.5,(7)+0.5}).direction=south
  surface.find_entity("transport-belt",{(28)+0.5,(-24)+0.5}).direction=south
  surface.find_entity("transport-belt",{(24)+0.5,(-22)+0.5}).direction=south
  surface.find_entity("transport-belt",{(24)+0.5,(2)+0.5}).destroy()
  W.entity("splitter",24.5,2,south)
  surface.find_entity("transport-belt",{(24)+0.5,(19)+0.5}).direction=east
  for y=0,69 do belt(44,y,south) end
  for x=7,44 do belt(x,70,defines.direction.west) end
  surface.find_entity("transport-belt",{(7)+0.5,(70)+0.5}).direction=north
  belt(7,69,north)
  W.entity("fast-inserter",7,68,south)
  label("CIRCUIT PRODUCTION",{37,-5})
end
function W.resources()
  local surface=game.surfaces[B.surface]
  for _,patch in ipairs({{"iron-ore",-90,4},{"copper-ore",-114,4},{"coal",-90,28},{"stone",-114,28}}) do
    for dx=-6,6 do for dy=-6,6 do
      if dx*dx+dy*dy<=36 then surface.create_entity{name=patch[1],position={patch[2]+dx,patch[3]+dy},amount=3000} end
    end end
  end
  local water={}
  for x=-120,-99 do for y=43,53 do water[#water+1]={name="water",position={x,y}} end end
  surface.set_tiles(water)
  surface.create_entity{name="crude-oil",position={-75,28},amount=100000}
end
function W.join(player)
  local s=storage.fai
  if not s or s.joined[player.index] then return end
  if player.controller_type == defines.controllers.cutscene then player.exit_cutscene() end
  player.force=game.forces[B.force]
  local surface=game.surfaces[B.surface]
  local pos=surface.find_non_colliding_position("character",{0,12},32,0.5) or {0,12}
  player.teleport(pos,surface)
  if not player.character then player.create_character() end
  s.joined[player.index]=true
  player.insert{name="submachine-gun",count=1}; player.insert{name="firearm-magazine",count=50}
  player.insert{name="repair-pack",count=20}
  player.print({"fai.welcome"})
end
return W
