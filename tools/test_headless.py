#!/usr/bin/env python3
"""Run engine integration tests with an existing, legally obtained Factorio headless binary.

Usage: python3 tools/test_headless.py /absolute/path/to/factorio [starter|campaign|oversight|network|progression|debug-success|debug-failure|core-network|support|continuity|blackout|destroyed]
Logs and test saves stay in .test-runtime. Raises on errors, assertion failures or absent completion.
"""
import json
from pathlib import Path
import shutil
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
binary = Path(sys.argv[1]).resolve()
case = sys.argv[2] if len(sys.argv) > 2 else 'campaign'
assert case in ('campaign', 'blackout', 'destroyed', 'starter', 'oversight', 'network', 'debug-success', 'debug-failure', 'core-network', 'support', 'continuity', 'progression', 'ambush')
run = root / '.test-runtime' / case
mods = run / 'mods'
mods.mkdir(parents=True, exist_ok=True)
(mods / 'mod-settings.dat').unlink(missing_ok=True)  # Each run uses its declared defaults.
# Exercise the same ZIP users install, rebuilding it from current source first.
subprocess.run([sys.executable, str(root / 'tools/package.py')], check=True)
info = json.loads((root / 'info.json').read_text())
for old in mods.glob('FactorioAI_*'):
    if old.is_symlink() or old.is_file():
        old.unlink()
    else:
        shutil.rmtree(old)
package = f"FactorioAI_{info['version']}.zip"
shutil.copy2(root / 'dist' / package, mods / package)
for name, source in [('FactorioAI-tests_0.1.0', root / 'tests/harness')]:
    target = mods / name
    if target.is_symlink():
        target.unlink()
    elif target.exists():
        shutil.rmtree(target)
    shutil.copytree(source, target)
    settings = target / 'settings.lua'
    settings.write_text(settings.read_text().replace('default_value="campaign"', f'default_value="{case}"'))
    if case == 'starter':
        updates = target / 'settings-updates.lua'
        updates.write_text(updates.read_text().replace('default_value=5', 'default_value=10'))
(mods / 'mod-list.json').write_text(json.dumps({'mods': [
    {'name': n, 'enabled': enabled} for n, enabled in
    [('base', True), ('FactorioAI', True), ('FactorioAI-tests', True),
     ('space-age', False), ('quality', False), ('elevated-rails', False)]]}))
save = run / 'test.zip'
base = [str(binary), '--mod-directory', str(mods)]
for stage, args in [('create', ['--create', str(save), '--map-gen-seed', '45176']),
                    ('run', ['--benchmark', str(save), '--benchmark-ticks', '72120' if case == 'starter' else '27000', '--benchmark-runs', '1'])]:
    log = run / f'{stage}.log'
    with log.open('w') as output:
        result = subprocess.run(base + args, stdout=output, stderr=subprocess.STDOUT)
    returncode = result.returncode
    text = log.read_text()
    if returncode or 'FAI TEST FAILED' in text or 'non-recoverable error' in text:
        print(text[-8000:]); raise SystemExit(f'{case} {stage} failed; see {log}')
    # A game-over pauses later tick callbacks, so verify the engine's outcome event too.
    outcomes = []
    for line in text.splitlines():
        if '[FactorioAI] {' in line:
            event = json.loads(line.split('[FactorioAI] ', 1)[1])
            if event.get('kind') == 'campaign_finished':
                outcomes.append(event)
    outcome_verified = case == 'blackout' and any(
        event['details']['outcome'] == 'core lost power' and event['tick'] >= 21600
        for event in outcomes)
    if stage == 'run' and not outcome_verified and not any(marker in text for marker in (
        'NETWORK SUITE COMPLETE', 'CAMPAIGN SUITE COMPLETE', 'actual satellite launch and escape',
        'power isolation and blackout defeat', 'core destruction defeat', 'OPENING SUITE COMPLETE', 'OVERSIGHT SUITE COMPLETE')):
        raise SystemExit(f'No completion marker; see {log}')
    print('\n'.join(line for line in text.splitlines() if 'FAI TEST PASS' in line))
    if outcome_verified:
        print('FAI TEST PASS: engine recorded timed blackout defeat')
print(f'{case}: PASS; logs: {run}')
