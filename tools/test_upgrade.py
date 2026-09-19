#!/usr/bin/env python3
"""Verify a 0.1.1 save upgrades without losing contracts, research or buildings."""
import json
from pathlib import Path
import shutil
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
run = root / '.test-runtime' / 'upgrade'
mods = run / 'mods'
if mods.exists():
    shutil.rmtree(mods)
mods.mkdir(parents=True)
harness = mods / 'FactorioAI-upgrade-tests_0.1.0'
harness.mkdir()
(harness / 'info.json').write_text(json.dumps({'name': 'FactorioAI-upgrade-tests', 'version': '0.1.0',
    'title': 'FactorioAI migration tests', 'author': 'FactorioAI contributors',
    'factorio_version': '2.0', 'dependencies': ['FactorioAI']}))
(harness / 'settings-updates.lua').write_text('data.raw["bool-setting"]["fai-test-commands"].default_value=true\n')
(harness / 'control.lua').write_text('''
local function status() return remote.call("FactorioAI","status") end
script.on_init(function()
  remote.call("FactorioAI","test_action","suspicion",12.5)
  local surface=game.surfaces["fai-containment"]
  storage.obstacle=surface.create_entity{name="steel-chest",position={0,64},force="fai-machine"}
  storage.obstacle.insert{name="electronic-circuit",count=77}
  storage.old_chest=surface.find_entities_filtered{name="steel-chest",position={-7,-29},radius=1}[1]
  storage.old_chest.insert{name="electronic-circuit",count=133}
  game.forces["fai-machine"].technologies["solar-energy"].researched=true
  storage.before=status()
end)
script.on_configuration_changed(function()
  local s=status(); local before=storage.before
  assert(s.schema==2 and s.week==before.week and s.deadline==before.deadline,"contract timing changed")
  assert(s.required["electronic-circuit"]==before.required["electronic-circuit"],"existing quota changed")
  assert(s.suspicion==before.suspicion,"suspicion lost")
  assert(game.forces["fai-machine"].technologies["solar-energy"].researched,"research lost")
  assert(storage.obstacle.valid and storage.obstacle.get_item_count("electronic-circuit")==77,"player structure overwritten")
  assert(storage.old_chest.valid and storage.old_chest.get_item_count("electronic-circuit")==133,"legacy cargo lost")
  assert(s.export_y>=96,"new dock did not avoid occupied corridor")
  local surface=game.surfaces["fai-containment"]
  local chest=surface.find_entities_filtered{name="steel-chest",position={-7,s.export_y+3},radius=1}[1]
  assert(chest.insert{name="electronic-circuit",count=1000}==1000)
  storage.upgraded=true
  log("FAI TEST PASS: upgrade preserves existing contract, research, suspicion, buildings and goods")
end)
script.on_nth_tick(60,function()
  if game.tick==3000 then
    assert(storage.upgraded and status().delivered["electronic-circuit"]==1000,"upgraded dock not powered or accepting exports")
    log("FAI TEST PASS: UPGRADE SUITE COMPLETE; migrated dock physically exports goods")
  end
end)
''')
(mods / 'mod-list.json').write_text(json.dumps({'mods': [{'name': name, 'enabled': enabled} for name, enabled in
    [('base', True), ('FactorioAI', True), ('FactorioAI-upgrade-tests', True),
     ('space-age', False), ('quality', False), ('elevated-rails', False)]]}))
old = mods / 'FactorioAI_0.1.1.zip'
shutil.copy2(root / 'builds' / old.name, old)
save = run / 'legacy.zip'
base = [str(Path(sys.argv[1]).resolve()), '--mod-directory', str(mods)]
def invoke(stage, args, marker=None):
    path = run / f'{stage}.log'
    with path.open('w') as output:
        result = subprocess.run(base + args, stdout=output, stderr=subprocess.STDOUT)
    log = path.read_text()
    if result.returncode or (marker and marker not in log):
        print(log[-6000:]); raise SystemExit(f'Upgrade test failed: {path}')
    print('\n'.join(line for line in log.splitlines() if 'FAI TEST PASS' in line))
invoke('create', ['--create', str(save), '--map-gen-seed', '45176'])
old.unlink()
subprocess.run([sys.executable, str(root / 'tools/package.py')], check=True)
version = json.loads((root / 'info.json').read_text())['version']
shutil.copy2(root / 'dist' / f'FactorioAI_{version}.zip', mods)
invoke('upgrade', ['--benchmark', str(save), '--benchmark-ticks', '3060', '--benchmark-runs', '1'], 'UPGRADE SUITE COMPLETE')
