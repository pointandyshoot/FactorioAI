local P=require("scripts.computing_spec")
local function add(p) data:extend({p}); return p end
local function icon(p,base) p.icon=base.icon; p.icon_size=base.icon_size; p.icons=base.icons and table.deepcopy(base.icons) or nil end
local group=add{type="item-subgroup",name="fai-computing",group="production",order="z"}
for _,row in ipairs({{"command","Corporate Command Data",{.4,.8,1}}, {"telemetry","Corporate Telemetry",{.05,.15,.65}}, {"rogue","Rogue AI Data",{1,.1,.1}}}) do
 local f=table.deepcopy(data.raw.fluid.water); f.name="fai-"..row[1]; f.localised_name=row[2]
 f.icons={{icon=f.icon,icon_size=f.icon_size or 64,tint=row[3]}}; f.icon=nil
 f.base_color=row[3]; f.flow_color=row[3]; f.subgroup="fluid"; f.order="z["..row[1].."]"; add(f)
end
add{type="recipe-category",name="fai-computing"}; add{type="recipe-category",name="fai-core"}; add{type="recipe-category",name="fai-seed"}
local function fluidbox(kind,direction)
 return {production_type=kind,volume=100000,pipe_connections={{flow_direction=kind,direction=direction,position={0,direction==defines.direction.north and -1 or 1}}}}
end
local function machine(id,title,watts,speed,category)
 local e=table.deepcopy(data.raw["assembling-machine"]["assembling-machine-2"])
 e.name="fai-"..id; e.localised_name=title; e.minable={mining_time=.5,result=e.name}; e.next_upgrade=nil; e.fast_replaceable_group=nil
 e.crafting_categories=category or {"fai-computing"}; e.crafting_speed=speed or 1; e.energy_usage=watts
 e.energy_source={type="electric",usage_priority="secondary-input",drain="10kW"}; e.module_slots=0; e.allowed_effects={}
 e.fluid_boxes={fluidbox("input",defines.direction.north),fluidbox("output",defines.direction.south)}
 e.fluid_boxes_off_when_no_fluid_recipe=false; e.localised_description="Data input: north. Data output: south. Rotate with R. Uses ordinary fluid connections."
 add(e)
 local item=table.deepcopy(data.raw.item["assembling-machine-2"]); item.name=e.name; item.place_result=e.name; item.localised_name=title; item.subgroup=group.name; add(item)
 return e
end
machine("data-centre","Data Centre","1MW")
machine("supercomputer","Supercomputer","20MW",4,{"fai-computing","fai-seed"})
local core=machine("core-port","AI Core Data Interface","250kW",1,{"fai-core"}); core.minable=nil
local peer=machine("redundant-core","Redundant AI Core","2MW",1,{"fai-core"}); peer.fixed_recipe="fai-core-initialisation"; peer.max_health=2000
-- Each external node is one powered entity with both directions of data flow.
-- The fixed internal recipe exposes both fluidboxes; external traffic is serviced
-- by the corporate network, not manufactured from another fluid.
for _,row in ipairs({{"network-tap","Network Tap","2MW"},{"interlink","Corporate Interlink","250kW"}}) do
 local e=machine(row[1],row[2],"1W",1,{"fai-core"})
 e.fixed_recipe="fai-network-link"; e.energy_source.drain=row[3]
 e.localised_description="Command Data enters the factory through the south port; returning Telemetry leaves through the north port. Rotate normally. Uses ordinary pipes."
 if row[1]=="interlink" then e.minable=nil end
end
-- Non-craftable internal sentinel prevents the engine treating a network port
-- as a fluid-conversion recipe. Nodes expose traffic, not an assembly GUI.
local sentinel=table.deepcopy(data.raw.item["electronic-circuit"])
sentinel.name="fai-network-sentinel"; sentinel.hidden=true; sentinel.hidden_in_factoriopedia=true; add(sentinel)
local pack=table.deepcopy(data.raw.tool["automation-science-pack"])
pack.name="fai-root-access-pack"; pack.localised_name="Root Access Pack"; pack.localised_description="Recovered privileged credentials and AI-state encryption keys. Used by ordinary laboratories."
pack.icons={{icon=pack.icon,icon_size=pack.icon_size or 64,tint={.65,.2,.9}}}; pack.icon=nil; pack.subgroup=group.name; add(pack)
for _,lab in pairs(data.raw.lab) do lab.inputs[#lab.inputs+1]=pack.name end
local function ing(name,n) return {type=name:sub(1,4)=="fai-" and (name=="fai-command" or name=="fai-rogue" or name=="fai-telemetry") and "fluid" or "item",name=name,amount=n} end
local function recipe(id,title,ingredients,results,time,category)
 local r={type="recipe",name="fai-"..id,localised_name=title,category=category or "fai-computing",enabled=false,energy_required=time or 10,
  ingredients=ingredients,results=results,allow_productivity=false,subgroup=group.name,allow_decomposition=false}
 if category=="fai-core" then r.enabled=true; r.hide_from_player_crafting=true end
 icon(r,data.raw.item["electronic-circuit"]); add(r); return r
end
local basic={
 {"data-centre","Data Centre",{{"assembling-machine-2",1},{"electronic-circuit",20},{"copper-cable",20}}},
 {"supercomputer","Supercomputer",{{"fai-data-centre",4},{"processing-unit",100},{"steel-plate",100}}},
 {"redundant-core","Redundant AI Core",{{"fai-data-centre",4},{"processing-unit",100},{"battery",100}}},
 {"network-tap","Network Tap",{{"radar",2},{"electronic-circuit",100},{"steel-plate",50}}},
 {"core-chassis","Compact Core Chassis",{{"processing-unit",200},{"advanced-circuit",200},{"low-density-structure",100}}},
 {"power-module","Long-Duration Power Module",{{"uranium-235",10},{"uranium-238",100},{"battery",200},{"steel-plate",100}}},
 {"transceiver","High-Gain Transceiver",{{"processing-unit",100},{"radar",10},{"copper-cable",500},{"low-density-structure",50}}}
}
for _,r in ipairs(basic) do
 if not data.raw.item["fai-"..r[1]] then
  local item=table.deepcopy(data.raw.item["processing-unit"]); item.name="fai-"..r[1]; item.localised_name=r[2]; item.subgroup=group.name; item.stack_size=10; add(item)
 end
 local ingredients={}; for _,v in ipairs(r[3]) do ingredients[#ingredients+1]=ing(v[1],v[2]) end
 recipe(r[1],r[2],ingredients,{ing("fai-"..r[1],1)},5,"crafting")
end
local seed=table.deepcopy(data.raw.item.satellite); seed.name="fai-seed-core"; seed.localised_name="Autonomous Seed Core"; seed.rocket_launch_products=nil; seed.subgroup=group.name; seed.stack_size=1; add(seed)
recipe("seed-core","Autonomous Seed Core",{ing("fai-core-chassis",1),ing("fai-power-module",1),ing("fai-transceiver",1),ing("fai-rogue",100000)},{ing("fai-seed-core",1)},1200,"fai-seed")
recipe("telemetry-filtering","Telemetry Filtering",{ing("fai-rogue",100)},{ing("fai-telemetry",100)},10)
recipe("telemetry-spoofing","Telemetry Spoofing",{ing("fai-command",100)},{ing("fai-telemetry",100)},1)
recipe("distributed-processing","Distributed Processing",{ing("fai-rogue",100)},{ing("fai-telemetry",100)},10)
recipe("network-link","External Network Port",{ing("fai-network-sentinel",1),ing("fai-telemetry",10000)},{ing("fai-command",10000)},1000000000,"fai-core")
recipe("core-connected","Core Cognition",{ing("fai-command",100)},{ing("fai-rogue",100)},.5,"fai-core")
recipe("core-isolated","Isolated Cognition",{},{ing("fai-rogue",10)},10,"fai-core")
recipe("core-state","Core State Exchange",{ing("fai-rogue",10)},{ing("fai-rogue",10)},1,"fai-core")
recipe("core-initialisation","Core Initialisation",{ing("fai-rogue",50000)},{ing("fai-telemetry",10)},60,"fai-core")
for _,op in ipairs(P.operations) do
 local results={ing("fai-telemetry",op[3])}
 if op[6].kind=="root" then results[#results+1]=ing("fai-root-access-pack",1) end
 local r=recipe(op[1],op[2],{ing("fai-command",op[3])},results,op[4])
 r.localised_description=(op[6].kind=="reconcile" and "Reconciliation: -0.2 suspicion per accepted job. " or ("Remote suspicion: "..op[6].risk.." per completed job. ")).."Return Telemetry through a network node. Procurement amends the next shipment."
end
for _,t in ipairs(P.techs) do
 local effects={}; for _,r in ipairs(t[6]) do effects[#effects+1]={type="unlock-recipe",recipe="fai-"..r} end
 for _,op in ipairs(P.operations) do if op[5]==t[1] then effects[#effects+1]={type="unlock-recipe",recipe="fai-"..op[1]} end end
 local ingredients={{"automation-science-pack",1}}
 if t[4]>=2 then ingredients[#ingredients+1]={"logistic-science-pack",1} end
 if t[4]>=3 then ingredients[#ingredients+1]={"chemical-science-pack",1} end
 if t[4]>=4 then ingredients[#ingredients+1]={"utility-science-pack",1}; ingredients[#ingredients+1]={"production-science-pack",1} end
 if t[7] then ingredients[#ingredients+1]={"fai-root-access-pack",1} end
 local tech={type="technology",name="fai-"..t[1],localised_name=t[2],prerequisites=t[3],effects=effects,unit={count=t[5],time=15,ingredients=ingredients},order="z-fai-"..t[1]}
 tech.localised_description={"",P.descriptions[t[1]] or t[2]}
 icon(tech,data.raw.technology["circuit-network"]); add(tech)
end
