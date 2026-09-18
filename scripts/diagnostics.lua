local D = {}
function D.record(kind, details)
  local s = storage.fai
  if not s then return end
  local row = {tick=game.tick, kind=kind, details=details or {}}
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
  local mods = {}; for name, version in pairs(script.active_mods) do mods[name] = version end
  return {schema=1, mod_version=script.active_mods.FactorioAI, mods=mods, tick=game.tick,
    seed=game.surfaces[s.surface].map_gen_settings.seed, week=s.week, deadline=s.deadline,
    week_ticks=s.week_ticks, suspicion=s.suspicion, stage=s.stage, phase=s.phase, outcome=s.outcome,
    required=s.required, delivered=s.delivered, supplies=s.supplies, supply_ratio=s.supply_ratio, authorised=s.authorised,
    queue_length=#s.queue, trains=trains, core_valid=s.core and s.core.valid,
    core_energy=s.core and s.core.valid and s.core.energy or 0, blackout_ticks=s.blackout_ticks,
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
