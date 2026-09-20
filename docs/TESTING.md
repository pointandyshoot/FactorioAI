# Testing — developer spoilers

Use an official, legally obtained Factorio 2.0 headless installation. The game and
proprietary graphics are not redistributed. Python 3 is the only runner dependency.
The runner rebuilds the distributable ZIP and installs it alongside a separate test
harness. Harness files and developer commands are not active in a normal installation.

```
python3 tools/test_headless.py /absolute/path/to/factorio starter
python3 tools/test_headless.py /absolute/path/to/factorio campaign
python3 tools/test_headless.py /absolute/path/to/factorio oversight
python3 tools/test_headless.py /absolute/path/to/factorio network
python3 tools/test_headless.py /absolute/path/to/factorio progression
python3 tools/test_headless.py /absolute/path/to/factorio debug-success
python3 tools/test_headless.py /absolute/path/to/factorio debug-failure
python3 tools/test_headless.py /absolute/path/to/factorio core-network
python3 tools/test_headless.py /absolute/path/to/factorio support
python3 tools/test_headless.py /absolute/path/to/factorio ambush
python3 tools/test_headless.py /absolute/path/to/factorio continuity
python3 tools/test_headless.py /absolute/path/to/factorio blackout
python3 tools/test_headless.py /absolute/path/to/factorio destroyed
python3 tools/test_upgrade.py /absolute/path/to/factorio 0.1.1
python3 tools/test_upgrade.py /absolute/path/to/factorio 0.2.0
```

Run sequentially: the engine installation has one write-directory lock. Each case
uses fresh mod settings and fails on an engine error, Lua assertion or missing
completion marker. Logs and test saves stay under `.test-runtime/` and are not
published. Opening uses 72,120 ticks; most other cases use 27,000. Migration uses
3,060 ticks. Benchmarks execute ticks 0 through N-1.

| Case | What it establishes |
|---|---|
| starter | Real import → machine → export flow; week one succeeds untouched, week two needs changes, red circuits at three; substations/resources/water |
| campaign | Early export credit, caps, surplus, no double credit; real solid/fluid trains; contract authorisation through week 15; evidence and isolation |
| oversight | Routine timing, local warnings, recovery, working nearby radar and actual distant scans; disabled radar/history cannot reveal contacts |
| network | Real Tap-supplied Command, physical Root science, reconciliation, next-shipment bonuses and isolated data access |
| progression | Every cyber recipe, returned telemetry accounting, Root science gates and ordinary lab consumption, connected research assistance, real Seed Core manufacture |
| debug-success/failure | Measured telemetry acceptance/rejection, success reset and irreversible support escalation |
| core-network | Actual 50,000 Rogue initialisation, pipe-connected state, original-core death, takeover, defeat on last-core death |
| support | Delayed missing report, mine discovery, targetable fleeing engineer, escape report, consultancy and real government vehicles |
| ambush | Paired real trains release troops only after both dock; no announcement; surplus and subsequent exports survive |
| continuity | Three real launch events, one payload credited once, first-launch escalation and final victory |
| blackout/destroyed | Timed power loss and immediate final-core destruction |
| upgrade | Archived saves retain contracts/deadlines/research/suspicion/buildings/cargo; added facilities avoid obstructions and exports work |

The harness accelerates radar scanning only in `oversight`, Supercomputer filtering
only in `debug-success`. Some cases
transfer *actually produced* fluid to a terminal to isolate accounting from pipe
layout, and inject recipe ingredients/build test power networks. They never modify
the campaign's private storage. The untouched opening and original data installation
exercise physical plumbing without that harness transfer. Rocket tests supply finished
payloads; `progression` independently verifies their real manufacture. Vehicle
presence/control is tested, but tactical competence is not established by these tests.

## Manual acceptance

Start a new game for XXA-1 and the incident. Check stock graphics, all icons, rotated
fluid ports, tooltips and the data layout. Observe the opening without reading the
spoiler design notes, then report where the game feels dull, confusing or unfair.
Test E/Escape closing, collapsed tracker persistence and per-player windows.

For co-op, host with two real clients. Build and remove computing/core infrastructure
concurrently, save/load during Debug Mode, disconnect/rejoin during an inspection,
and compare shared contract/Root science/support state. Try pumps controlled by circuits,
long underground runs and deliberately isolated data buffers. Stress vehicles against
walls, water and complex factory obstacles. Headless single-process tests cannot
prove client graphics or multiplayer desync stability.

## Diagnostics and development controls

`/fai-report` or **Export diagnostics** writes bounded JSON under
`script-output/FactorioAI/`. It includes version, seed, contracts, train state, support,
Debug measurements, Root science, shipment bonuses, credits, up to 64 computer inventories/statuses, core
synchronisation, launches and recent events. No player names or chat are included.
Send the report with the symptom and expected behaviour. For a crash include the
traceback and adjacent `[FactorioAI]` log entries. Review full saves/logs before sharing.

Only with **Enable test commands** and admin/server permission:

* `/fai-debug next-week`
* `/fai-debug inspect`
* `/fai-debug suspicion 0..100`
* `/fai-debug support 2..4`
* `/fai-debug debug-now`
* `/fai-debug raid`

The same gated actions are exposed by `remote.call("FactorioAI","test_action",action,value)`;
`remote.call("FactorioAI","status")` is read-only. Debug commands change the campaign
and belong in disposable test saves. All time is simulation time; pausing stops it.
