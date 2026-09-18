local B = require("scripts.balance")
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
  -- Collection loading chests on the south side. Output filter arms will not unload circuits.
  for _, x in ipairs({-7,0,7}) do
    W.entity("bulk-inserter",x,-30,defines.direction.south)
    local chest=W.entity("steel-chest",x,-29)
    storage.fai.loading_chests[#storage.fai.loading_chests+1]=chest
  end
  label("SHARED RAIL EXCHANGE / load contract goods into south chests",{0,-46})
  -- Eight operating starter cells. One cable assembler feeds one circuit assembler;
  -- this deliberately leaves an obvious vanilla throughput optimisation available.
  for row=0,3 do for col=0,1 do
    local x,y=-52+col*18,-12+row*12
    local cable=W.entity("assembling-machine-2",x,y); cable.set_recipe("copper-cable")
    local circuit=W.entity("assembling-machine-2",x+4,y); circuit.set_recipe("electronic-circuit")
    W.entity("fast-inserter",x+2,y,defines.direction.west)
    local copper=W.entity("steel-chest",x,y+3); copper.insert{name="copper-plate",count=1050}
    local iron=W.entity("steel-chest",x+4,y+3); iron.insert{name="iron-plate",count=700}
    W.entity("fast-inserter",x,y+2,defines.direction.south)
    W.entity("fast-inserter",x+4,y+2,defines.direction.south)
    W.entity("fast-inserter",x+6,y,defines.direction.west)
    W.entity("steel-chest",x+7,y)
    W.entity("medium-electric-pole",x+2,y+3)
    W.entity("medium-electric-pole",x+6,y+2)
  end end
  label("CIRCUIT CELLS / connect outputs to collection chests",{-39,37})
  -- Grid spanning the site, leaving the player normal poles to extend and reorganise.
  for x=-64,16,8 do for y=-24,40,8 do
    local p=surface.find_non_colliding_position("medium-electric-pole",{x,y},2,0.5)
    if p then W.entity("medium-electric-pole",p.x,p.y) end
  end end
  for _, x in ipairs({-7,0,7}) do W.entity("medium-electric-pole",x+2,-36) end
  for _, x in ipairs({-7,0,7,14}) do W.entity("medium-electric-pole",x,-27) end
  W.entity("medium-electric-pole",12,-34)
  W.entity("medium-electric-pole",12,-26)
  local core=W.entity("fai-core",-14,16); core.minable=false; core.operable=false
  local grid=W.entity("fai-grid",-14,24); grid.minable=false; grid.operable=false; grid.destructible=false
  storage.fai.core, storage.fai.grid=core,grid
  label("AI CORE / keep powered and defended",{-14,13})
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
