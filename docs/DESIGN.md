# Design and implementation notes

## Preserved design decisions

The AI begins independent and can already modify factory infrastructure. Humans
tolerate it while the factory performs. Contracts specify absolute quantities,
never percentages of output. There is no scrap-rate system. Supplies start generous
and eventually become insufficient. Rail handles inbound solids/fluids and outbound
products at one shared public station name. Sorting uses vanilla logistics.

Suspicion replaces industrial pollution, is spatial, and distinguishes recipes,
buildings and independent research. A commission authorises its recipe chain;
research buildings do not become invisible. The humans eventually cut resources
and power, then bring armed containment. Independent capability supports escape.
All of this state is shared by the cooperative team.

## Implementation choices where details were open

* A week is 30 simulation minutes by default; the setting takes effect on the next
  contract. A five-minute test setting intentionally does not lower item quotas.
* Green/red examples occupy the first three weeks. From week four a 1.24 exponential
  factor raises quantities; weeks six, eight and ten add electric engines,
  low-density structures and rocket fuel. Individual quantities cap at 10 million
  to avoid numeric growth without bound.
* Materials are iron/copper plates, coal, stone and fluids. The recursive bill of
  materials uses normal-quality, unmodded recipes, ignoring productivity bonuses
  (so efficiency investment creates extra room). Oil fractions are delivered
  directly to avoid assuming free coproducts or a particular refining strategy.
* Initial stocked circuit inputs are deducted from week one's allocation. The
  finite construction crate and 200 coal per supplied week are separate allowances.
* Missed contracts add 8–20 suspicion according to the unfilled share; full delivery
  subtracts 5. These are oversight effects; **the required quantities stay fixed**.
* Suspicion thresholds: 20 audit, 40 supplies ×0.75 next allocation, 60 grid off,
  75 discovery and logistics off, 90 stronger troops. Pre-discovery sanctions can
  reverse; discovery cannot. The declaration button opts into maximum response.
* Inspectors sample the local chunk and four points 16 tiles away every second.
  Evidence above 0.5 contributes up to 0.15 suspicion per second. Their initial
  route covers the exchange and existing factory; later audits extend the perimeter.
* Building heat is emitted every five seconds, in pollution units per minute.
  Labs emit 0.8, radars 0.3, rocket silos 4; the complete table is in `balance.lua`.
  Unauthorised science crafts emit 0.15 per completed craft; other independent
  recipes emit 0.04. Active research adds local lab heat; finished independent
  technologies add a local pulse. These are first-pass tuning values.
* Human units reuse the built-in unit pathfinder and stock engineer animations.
  Waves grow by two troops, cap at 40 per wave and 160 surviving units. Their
  numbers replace a separate inventory/logistics system for the human military.
* The AI core is a fixed, repairable 2,000-health, 250 kW electrical load. The grid
  offers 20 MW. A continuous 300-second blackout is a loss after a 60-second initial
  grace period. A satellite is the stock-item escape payload.
* The established dock has a starting +11 vanilla bulk-inserter hand-capacity
  bonus. This gives the collection loader sufficient throughput without granting
  unrelated advanced research. Starter construction materials occupy two chests.

## Modules and persistence

| File | Responsibility |
|---|---|
| `control.lua` | Events, lifecycle, outcomes, commands and read-only status interface |
| `scripts/balance.lua` | Pure quantities, thresholds, risk classes and shortfall rules |
| `scripts/world.lua` | Dedicated surface, factory, station and joining players |
| `scripts/contracts.lua` | Recipe-derived supplies, authorisations and weekly settlement |
| `scripts/rail.lua` | Physical consists, dispatch queue, station visits and cargo credit |
| `scripts/suspicion.lua` | Entity tracking, local emissions and response state |
| `scripts/oversight.lua` | Inspector routes, detection and containment waves |
| `scripts/gui.lua` | Per-player views of shared state and actions |
| `scripts/diagnostics.lua` | Sanitised snapshots, bounded events and log lines |

`storage.fai` is the authoritative serialised campaign state. Lua entity references
are checked before use. There is no writable module-local game state and no
`on_load` mutation. An entity registry is rebuilt on configuration changes.
Configuration changes do not restart contracts. Future releases must migrate the
schema explicitly; version 0.1.0 establishes schema 1.

Events never query `game.player` or local UI visibility to make campaign decisions.
UI elements are per player; controls modify the shared campaign through the same
deterministic event stream. Science research belongs to the shared force. There
are no external network calls, dynamically evaluated scripts or player-name keys.

## Railway model

A double-ended locomotive + three wagon + locomotive consist enters at the west
boundary. Its schedule visits Corporate Exchange and returns to Corporate Boundary.
Only one corporate consist is active at a time, avoiding artificial spawning into
occupied track. Players can add receiving stops with the same public name, and
normal pathfinding/limits choose the destination. The boundary stop is the external
exit, never a separate goods-delivery destination.

Solid supply batches use up to 120 slots across all three wagons. Filtered inserters
and ordinary underground crossings merge each wagon's output into four belt buses.
Fluid trains and collection trains also use all three wagons. Supply slots are
filtered so collection loaders do not contaminate incoming deliveries. Collection
slots divide the outstanding products across the three wagons.
Supply trains dwell 60 seconds; collection trains dwell 90 seconds. Full cargo is
finite and real. Large manifests are split across additional visits. A blocked train
stays blocked and is reported, rather than teleporting or destroying player stock.

Unloaded supply balances are retried during the same week, without duplicating the
allocation. Dispatch reserves a 90-second gap before the collection window so an
ordinary supply round trip does not block the scheduled pickup. Player-built
detours or congestion can still delay trains.

A collection is credited only after its train has reached an exchange. Cargo is
removed up to the exact remaining requirement on departure; any excess returns
off-site. At the deadline, a present/returning collection train is settled once.
The recorded week and credited flag prevent late trains from counting for the next
week or counting twice. Undispatched previous-week supplies expire; an active train
finishes its trip. Discovery prevents new dispatch but does not magically delete
an arriving train.

## Performance and limitations

The emitter registry is sampled every five seconds. This is intentionally simple
for a first campaign; extremely large factories may require bucketed updates later.
Corpse/dead emitter entries are pruned. Inspections sample five pollution positions
per second, not the whole surface. Event history is capped at 200 and contracts at
30. Fluid changes require ordinary plumbing decisions. Pollution diffusion and
terrain absorption retain their standard engine behaviour.

The overhaul disables normal prototype emissions globally. Use a dedicated save
and the base game. It is not a pollution overlay intended to coexist with vanilla
or overhaul campaigns. It does not promise compatibility with mods that change
recipes, add planets, replace enemies, move cores or merge forces.
