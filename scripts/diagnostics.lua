local copy=require("util").table.deepcopy
local D = {}
function D.record(kind, details)
  local s = storage.fai
  if not s then return end
  local row = {tick=game.tick, kind=kind, details=copy(details or {})}
  s.events[#s.events+1] = row
  if #s.events > 200 then table.remove(s.events, 1) end
  log("[FactorioAI] " .. helpers.table_to_json(row))
end
function D.snapshot()
  local s = storage.fai
  if not s then return {active=false} end
  local trains = {}
  if s.delivery and s.delivery.train and s.delivery.train.valid then
    local t = s.delivery.train
    trains[1] = {id=t.id, state=t.state, kind=s.delivery.kind, age=game.tick-s.delivery.spawn_tick,
      station=t.station and t.station.backer_name, carriages=#t.carriages}
  end
  local radar_contacts=0; for _,e in pairs(s.radar_seen or {}) do if e.valid then radar_contacts=radar_contacts+1 end end
  local mods = {}; for name, version in pairs(script.active_mods) do mods[name] = version end
  return {schema=s.schema, mod_version=script.active_mods.FactorioAI, mods=mods, tick=game.tick,
    seed=game.surfaces[s.surface].map_gen_settings.seed, week=s.week, deadline=s.deadline,
    week_ticks=s.week_ticks, suspicion=s.suspicion, stage=s.stage, phase=s.phase, outcome=s.outcome,
    required=s.required, delivered=s.delivered, supplies=s.supplies, supply_ratio=s.supply_ratio, authorised=s.authorised,
    queue_length=#s.queue, trains=trains,
    export_y=s.export_y, export_train=s.export_delivery and s.export_delivery.train.valid and {
      state=s.export_delivery.train.state, arrived=s.export_delivery.arrived,
      station=s.export_delivery.train.station and s.export_delivery.train.station.backer_name,
      carriages=#s.export_delivery.train.carriages}, core_valid=s.core and s.core.valid,
    core_energy=s.core and s.core.valid and s.core.energy or 0, blackout_ticks=s.blackout_ticks,
    radar_contacts=radar_contacts, last_detected=s.last_detected, routine_due=s.routine_due, routine_done=s.routine_done,
    inspection=s.inspection and {waypoint=s.inspection.waypoint, expires=s.inspection.expires},
    tracked_entities=#s.emitters, history=s.history, recent_events=s.events,
    debug=settings.global["fai-debug"].value, test_commands=settings.global["fai-test-commands"].value}
end
function D.export(player_index)
  local path = "FactorioAI/diagnostics-" .. game.tick .. ".json"
  helpers.write_file(path, helpers.table_to_json(D.snapshot()), false, player_index or 0)
  return path
end
return D
