# Testing and troubleshooting

## Automated engine checks

Obtain the official Factorio 2.0.77 headless build. No proprietary binaries are
included here. With Python 3 available:

```sh
python3 tools/test_headless.py /path/to/factorio campaign
python3 tools/test_headless.py /path/to/factorio escape
python3 tools/test_headless.py /path/to/factorio blackout
python3 tools/test_headless.py /path/to/factorio destroyed
python3 tools/test_headless.py /path/to/factorio starter
python3 tools/package.py
```

The runner creates a disposable save with a separate test mod, executes actual game
ticks and requires explicit assertion-completion markers. It records logs under
`.test-runtime/<case>/`. The test harness is excluded from the installation ZIP.
It uses a fixed seed, five-minute weeks and cheat-enabled test controls.

Campaign tests cover fixed manifests and allocation crossover; actual starter
production and power; physical supply and collection train movement; 5,000-item
quota settlement; shared-station fluid unloading; local lab suspicion; later
recipe bills of materials; sanctions, irreversible discovery and human waves.
Separate runs exercise a real satellite launch and both loss conditions.
The starter case runs 108,060 ticks with the default 30-minute contract and verifies
that the unmodified factory produces at least 5,000 circuits from its initial stock.

## Manual multiplayer and visual acceptance

The headless binary cannot manufacture player connections. These need two real
clients and are not replaced by pure Lua or force-state tests:

1. Host a fresh game and join from a second client. Both should spawn by the same
   core, see the same contract and be able to build on the shared factory.
2. Open both panels; build a lab, research, fulfil a contract, export reports from
   both clients, and compare shared values at the same paused tick.
3. Disconnect/rejoin a client, save/reload the server, then join a new player.
   Confirm no duplicated construction stores, restarted deadline or missing UI.
4. Leave the game running across at least two contract boundaries with both
   players building, trains moving and an inspector visiting. Check for desyncs.
5. View engineer NPC animations, stock sprites, terrain labels, belts, pumps and
   the panel at ordinary and high UI scales. Confirm all buttons are reachable.
6. Add a second Corporate Exchange stop and use train limits/signals. Block the
   initial station and restore it; the delayed train should continue normally.
7. Test shared-tank fluid sorting and sustainable independent power. Verify an
   authorised red-circuit line creates no recipe evidence while nearby labs do.
8. Confirm the independence warning clearly affects everyone, then test combat,
   core repair, individual player respawn and continued play after victory/loss.

## Admin controls

Enable **Enable admin test commands** in the Map mod settings. Then:

| Command | Purpose |
|---|---|
| `/fai-debug next-week` | Settle the present contract and advance (can add suspicion) |
| `/fai-debug inspect` | Send an inspector if one is not already active |
| `/fai-debug suspicion 40` | Set a score and apply sanctions; discovery remains irreversible |
| `/fai-debug raid` | Declare full revolt and spawn a containment wave |
| `/fai-report` | Export status and recent events without changing the game |
| `/fai-status` | Open/close the campaign panel |

The same test actions are exposed to test mods via
`remote.call("FactorioAI", "test_action", action, value)`, gated by the cheat setting.
`remote.call("FactorioAI", "status")` is read-only and returns a plain snapshot.
The server console can use commands without a player; client cheats require admin.

## Reporting a problem

Prefer the JSON diagnostic export. Include the observed issue, expected result,
whether you were hosting/joining, reproduction steps, and whether test commands
were enabled. For a crash include the traceback and the nearby `[FactorioAI]` log
lines. Inspect full logs and saves for personal information before sharing them.

Common causes worth checking:

* **No trains:** exact receiving stop name, connected rails, signals, station
  limits, occupied west boundary and discovery state.
* **No contract credit:** items must enter the collection wagons. Chests do not
  count. Credit appears on departure or at the deadline.
* **Fluid wagon will not unload:** old fluid in the tank/pipeline, pump direction,
  pump electricity, wagon alignment, or insufficient storage.
* **No production:** cable/input/output bottlenecks, chest stock, electric supply,
  machine recipe and circuit conditions. These remain normal Factorio problems.
* **Core power countdown:** restore actual electric connectivity and generation;
  placing a disconnected generator does not help.
