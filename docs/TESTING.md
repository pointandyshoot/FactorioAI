# Developer testing — contains gameplay spoilers

Use the official Factorio 2.0.77 headless binary and Python 3:

```sh
python3 tools/test_headless.py /path/to/factorio starter
python3 tools/test_headless.py /path/to/factorio campaign
python3 tools/test_headless.py /path/to/factorio oversight
python3 tools/test_headless.py /path/to/factorio escape
python3 tools/test_headless.py /path/to/factorio blackout
python3 tools/test_headless.py /path/to/factorio destroyed
python3 tools/test_upgrade.py /path/to/factorio
```

The runner builds and installs the real ZIP, creates a disposable seeded save and
requires completion markers. Logs stay under `.test-runtime/`; tests and logs are
excluded from the release ZIP. Test settings are reset on each invocation.

* `starter`: two full ten-minute weeks without inserting any goods or modifying
  the factory. Week one must succeed; week two must require improvement. Checks
  week-three authorisation, substations, starter deposits and water.
* `campaign`: physical imports and fluid unloading, early exports, capped credit,
  retained surplus, no repeated credit, contracts, authorisation and containment.
* `oversight`: midweek inspection, specific observed-building warning, quiet-period
  recovery, powered near-range radar detection and actual distant scan events.
  No radar or disabled radar must not generate new alerts. This case accelerates
  radar sector scans in its separate test mod, preserving the normal nearby range.
* `escape`, `blackout`, `destroyed`: actual satellite ascent and both loss conditions.
  The blackout case deliberately keeps the test suspicion score raised so natural
  pre-discovery recovery does not restore corporate power during the test.
* `test_upgrade.py`: create a real 0.1.1 save with a player structure occupying the
  first export-dock candidate, cargo, researched technology and suspicion. Upgrade
  the ZIP and check preservation, corridor avoidance and real exports at the new dock.

## Client acceptance

Headless tests do not load graphics or create real player connections. On a fresh
map, and then with two actual clients:

1. Open/close the panel using its button, E, Escape and another entity window.
   Collapse/expand the tracker, let a week roll over, and check all progress bars.
2. Select a lab, mining drill and authorised/uncommissioned assemblers. Compare
   tooltips, selected-machine rates and the configured suspicion multiplier.
3. Confirm the first order completes without touching anything. Inspect the layout
   at normal and high UI scale. Check all controls are accessible on smaller screens.
4. Watch a routine inspection at midweek. Check later warnings reflect what was
   observed, with no instructions revealing future thresholds or tactics.
5. Test radar notifications, join/rejoin, save/reload, concurrent building and play
   across multiple weeks. Compare diagnostic snapshots from both clients at the
   same paused tick and watch for desyncs.
6. Obstruct an import track, restore it, and confirm the train resumes. Check fluid
   routing when the shipment changes. Rearrange loaders using normal logistics.
7. Back up a real 0.1.x save, upgrade, and confirm the existing factory is preserved.
   Reroute output to the added export dock. Check old windows close without errors.

## Admin test controls

Enable **Enable admin test commands** in Map settings. Available to admins/server:

* `/fai-debug next-week`: settle and advance the contract.
* `/fai-debug inspect`: request an inspector if none is present.
* `/fai-debug suspicion 40`: set a test score; discovery stays irreversible.
* `/fai-debug raid`: trigger full containment and a wave (test-only).
* `/fai-status`: toggle the campaign panel.
* `/fai-report`: export a diagnostic snapshot without changing gameplay.

Test mods can use `remote.call("FactorioAI", "test_action", action, value)` only when
the cheat setting is enabled. `remote.call("FactorioAI", "status")` is read-only.

## Troubleshooting

No trains: check names, signals, limits, connected rails and the spawning boundary.
No export credit: the cargo must reach the receiving wagons at Corporate Exports;
chests alone do not count. Imports never count as outgoing products. Surplus is held.
No fluid unloading: check old fluid, available capacity, pump power and alignment.
No production: inspect ordinary inputs, electricity, belt lanes, inserters and recipes.

Send `/fai-report` output and reproduction steps. Crash reports need the traceback.
Review full logs/saves for personal information before sharing; never commit them.
