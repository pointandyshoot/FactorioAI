local B=require("scripts.balance")
local D=require("scripts.diagnostics")
local C=require("scripts.contracts")
local W=require("scripts.world")
local R=require("scripts.rail")
local S=require("scripts.suspicion")
local O=require("scripts.oversight")
local G=require("scripts.gui")
local A=require("scripts.radar")
local N=require("scripts.computing")

local function remote_option(interface,method,value)
  if remote.interfaces[interface] and remote.interfaces[interface][method] then remote.call(interface,method,value) end
end
local function start()
  if storage.fai then return false end
  storage.fai={schema=2,surface=B.surface,week=1,suspicion=0,stage=1,phase="covert",events={},history={},
    authorised={},emitters={},tracked={},queue={},joined={},loading_chests={},security={},raid_number=0,
    blackout_ticks=0,started=game.tick,next_inspection=game.tick+360*60,next_raid=game.tick+180*60}
  remote_option("freeplay","set_skip_intro",true)
  remote_option("freeplay","set_disable_crashsite",true)
  remote_option("silo_script","set_no_victory",true)
  W.create(); C.begin_week(); N.install(false); S.rescan()
  for _,p in pairs(game.players) do W.join(p); G.button(p) end
  D.record("campaign_started",{schema=3})
  return true
end
local function finish(outcome)
  local s=storage.fai
  if s.outcome then return end
  s.outcome=outcome; D.record("campaign_finished",{outcome=outcome})
  game.forces[B.force].print({"fai.result",outcome})
  game.set_game_state{game_finished=true,player_won=outcome=="escaped",can_continue=true}
end
script.on_init(function()
  -- Only fresh freeplay worlds start automatically. Adding the mod to an existing save is opt-in.
  if game.tick==0 then start() end
end)
script.on_configuration_changed(function()
  if storage.fai then
    if (storage.fai.schema or 1)<2 then
      W.create_export_dock()
      storage.fai.schema=2
      game.forces[B.force].print({"fai.upgrade-exports",storage.fai.export_y})
    end
    if not game.forces["fai-response"] then game.create_force("fai-response") end
    W.export_depot()
    N.install(true)
    game.forces[B.force].bulk_inserter_capacity_bonus=math.max(11,game.forces[B.force].bulk_inserter_capacity_bonus)
    storage.fai.routine_due=storage.fai.routine_due or storage.fai.deadline-math.floor(storage.fai.week_ticks/2)
    storage.fai.last_detected=storage.fai.last_detected or game.tick
    for _,p in pairs(game.players) do G.migrate(p) end
    S.rescan(); remote_option("silo_script","set_no_victory",true)
    D.record("configuration_changed",{version=script.active_mods.FactorioAI})
  end
end)
script.on_event({defines.events.on_player_created,defines.events.on_player_joined_game},function(event)
  if storage.fai then local p=game.get_player(event.player_index); W.join(p); G.button(p) end
end)
script.on_event(defines.events.on_player_respawned,function(event)
  if storage.fai then
    local p=game.get_player(event.player_index)
    if p.force.name==B.force then p.teleport(game.surfaces[B.surface].find_non_colliding_position("character",{0,12},32,1) or {0,12},B.surface) end
  end
end)
script.on_event({defines.events.on_built_entity,defines.events.on_robot_built_entity,
  defines.events.script_raised_built,defines.events.script_raised_revive},function(event) S.track(event.entity); N.track(event.entity) end)
script.on_event(defines.events.on_entity_cloned,function(event) S.track(event.destination); N.track(event.destination) end)
script.on_event(defines.events.on_sector_scanned,A.scanned)
script.on_event(defines.events.on_gui_click,G.click)
script.on_event(defines.events.on_gui_closed,G.closed)
script.on_event(defines.events.on_selected_entity_changed,function(event) G.selection(game.get_player(event.player_index)) end)
script.on_event(defines.events.on_research_finished,function(event)
  local s=storage.fai
  if not s or event.research.force.name~=B.force or event.by_script then return end
  -- Evidence stays local: inspectors must encounter emissions around the research labs.
  for _,row in ipairs(s.emitters) do
    local e=row.entity
    if e.valid and e.type=="lab" then e.surface.pollute(e.position,2*settings.global["fai-suspicion-multiplier"].value) end
  end
  D.record("independent_research",{technology=event.research.name})
end)
script.on_event(defines.events.on_player_crafted_item,function(event)
  local s=storage.fai; if not s or s.outcome then return end
  local p=game.get_player(event.player_index)
  if p.force.name==B.force and p.surface.name==B.surface then
    p.surface.pollute(p.position,S.recipe_risk(event.recipe.name)*event.item_stack.count*settings.global["fai-suspicion-multiplier"].value)
  end
end)
script.on_event(defines.events.on_entity_died,function(event)
  local s=storage.fai; if not s or s.outcome then return end
  local e=event.entity
  if N.core_lost(e) then finish("core destroyed")
  elseif e.surface.name==B.surface and (e.force.name=="fai-corporate" or e.force.name=="fai-response") then O.casualty(e) end
end)
-- Snapshot the payload when launch is ordered; it is no longer in the silo after ascent.
script.on_event(defines.events.on_rocket_launch_ordered,function(event)
  local s=storage.fai; if not s or s.outcome then return end
  local rocket=event.rocket
  if rocket and rocket.valid and rocket.force.name==B.force and rocket.surface.name==B.surface then
    local pod=rocket.attached_cargo_pod
    local inventory=pod and pod.get_inventory(defines.inventory.cargo_unit)
    s.escape_rockets=s.escape_rockets or {}
    local payload=inventory and inventory.get_item_count("fai-seed-core")>0 or false
    s.escape_rockets[#s.escape_rockets+1]={rocket=rocket,payload=payload}
    D.record("launch_ordered",{ai_payload=payload})
  end
end)
script.on_event(defines.events.on_rocket_launched,function(event)
  local s=storage.fai; if not s or s.outcome then return end
  local rocket=event.rocket
  if rocket and rocket.valid and s.escape_rockets then
    for i=#s.escape_rockets,1,-1 do
      local row=s.escape_rockets[i]
      if row.rocket==rocket then
        table.remove(s.escape_rockets,i); if row.payload then local complete=N.launch(); O.tick(); if complete then finish("escaped") end end
      elseif not row.rocket.valid then table.remove(s.escape_rockets,i) end
    end
  end
end)
script.on_nth_tick(60,function()
  local s=storage.fai; if not s or s.outcome then return end
  -- Campaign time follows simulation time. Normal multiplayer pause stops the whole simulation.
  if s.core and s.core.valid and game.tick-s.started>3600 then
    if s.core.energy<1000 then s.blackout_ticks=s.blackout_ticks+60 else s.blackout_ticks=0 end
    if s.blackout_ticks==60 then game.forces[B.force].print({"fai.blackout"}); D.record("core_blackout") end
  end
  N.tick(); S.stages(); R.tick(); R.exports_tick(); R.ambush_tick(); O.tick(); A.tick()
  local live=N.live_cores()
  if s.core and s.core.valid and s.blackout_ticks>=300*60 and not s.network.primary_id and #live>0 then N.core_lost(s.core) end
  if #live==0 then finish(s.core and s.core.valid and "core lost power" or "core missing"); return end
  if game.tick>=s.deadline then R.close_contract(); C.finish_week(); S.stages() end
  if game.tick%300==0 then
    S.emit()
  end
  for _,p in pairs(game.connected_players) do G.draw(p) end
  if settings.global["fai-debug"].value and game.tick%3600==0 then D.record("heartbeat",{week=s.week,suspicion=s.suspicion,entities=#s.emitters,queue=#s.queue}) end
end)
script.on_nth_tick(15,O.drive)
commands.add_command("fai-start","Start the cooperative AI campaign on its own surface (admin).",function(cmd)
  local p=cmd.player_index and game.get_player(cmd.player_index)
  if p and not p.admin then p.print("Admin only."); return end
  if not start() and p then p.print("Campaign already exists.") end
end)
commands.add_command("fai-status","Open campaign status.",function(cmd)
  if cmd.player_index and storage.fai then G.toggle(game.get_player(cmd.player_index)) end
end)
commands.add_command("fai-report","Export a bounded, player-name-free diagnostic report.",function(cmd)
  local path=D.export(cmd.player_index)
  if cmd.player_index then game.get_player(cmd.player_index).print("Diagnostics: script-output/"..path) else log("[FactorioAI] report "..path) end
end)
local function test_action(action,value)
  if not settings.global["fai-test-commands"].value or not storage.fai then return false end
  if action=="next-week" then R.close_contract(); C.finish_week()
  elseif action=="inspect" then O.inspection()
  elseif action=="suspicion" and tonumber(value) then storage.fai.suspicion=math.max(0,math.min(100,tonumber(value))); storage.fai.last_detected=game.tick; S.stages()
  elseif action=="debug-now" then storage.fai.network.debug_forced=true
  elseif action=="support" and tonumber(value) then O.escalate(math.min(4,tonumber(value)),"test")
  elseif action=="raid" then O.revolt(); O.raid()
  else return false end
  D.record("test_command",{action=action}); return true
end
remote.add_interface("FactorioAI",{status=D.snapshot, test_action=test_action})
commands.add_command("fai-debug","Admin test controls: next-week, inspect, suspicion N, support N, debug-now, raid. Enable test commands first.",function(cmd)
  local p=cmd.player_index and game.get_player(cmd.player_index)
  if (p and not p.admin) or not settings.global["fai-test-commands"].value or not storage.fai then
    if p then p.print("Requires admin and the Enable test commands mod setting.") end; return
  end
  local action,value=(cmd.parameter or ""):match("^(%S+)%s*(.*)$")
  if not test_action(action,value) and p then p.print("Usage: /fai-debug next-week | inspect | suspicion 0..100 | support 2..4 | debug-now | raid") end
end)
