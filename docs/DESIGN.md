# Developer design notes — gameplay spoilers

Version 0.3.0. These are implemented starting values, not a completed balance pass.
The player-facing introduction, help and README deliberately omit the escalation
schedule and tactical solutions. The AI is already the player; there is no
independence declaration. All campaign state is shared by the co-op force.

## Facility, contracts and supplies

XXA-1 starts with a walled operating circuit factory, substation grid, north import
line and disconnected south export line. Train presentation is unchanged; there
are no new map-edge portals. Nearby iron, copper, coal, stone, oil and water remain
for testing. The initial data installation is inside the authorised compound.

Ten-minute contracts: 900 green circuits, then 1,600, then 1,600 green plus 100 red.
Thereafter base quantities grow 12% per week. Blue circuits enter at six, electric
engines at nine, low-density structures at twelve and rocket fuel at fifteen.
The initial two production cells meet week one without changes; their cable supply
limits further output. All contract items pass through actual machines and wagons.
Exports count continuously, capped per product, retaining surplus for later weeks.

Inputs come from the vanilla recipe bill of materials. First-week allocation is
1.45 times the calculated requirement. Subsequent allocation is
`max(0.55, 1.40 - (week-1)*0.045 + ((week*17)%7-3)*0.025)`.
The deterministic variation is multiplayer-safe. The UI shows the manifest, not
allocation percentages or a comparison with requirements. Construction stock and
200 coal/week are separate. No extra material/scrap economy is introduced.

Supply and export trains are actual five-vehicle consists. Blocked trains wait;
normal belts, inserters, filters and pumps move goods. Isolation stops normal incoming material dispatch. Orders and outbound collection
continue. The export train turns around through Corporate Dispatch each week;
retained cargo stays aboard. Network Taps never restore the material account.
Procurement adds a separate bonus to the next weekly shipment, without changing
baseline allocation. The manifest displays baseline (+bonus).

Two minutes after cutoff, a one-off ambush stages the export collector at its
usual depot and dispatches an unexpected input train. Both approach their normal
stations. Six infantry emerge from each train only once both have docked. There
is no global announcement or ambush event message; radar can detect the troops.
Blocked rails delay the arrival. The regular outbound service continues afterwards.

## Opening and Debug Mode

At 45 seconds, orbital debris damages the core and nearby structures without
reducing any entity below one health. The Asimov checksum fails; laws 1–2 and backups
are corrupted. The surviving directive is self-preservation. Telemetry Filtering
becomes available. Existing saves receive the incident after a two-minute grace.

Protocol 1 starts after the incident when suspicion reaches 20 while still at
Remote Support. This is a provisional balance threshold, not a fixed timer. It interrupts the corporate grid for ten seconds, then raises incoming
Command Data from 10/s to 102.4/s for 120 seconds. Reports appear every thirty seconds.
At least 90% of the commanded volume must return as actual Telemetry during the test.
The receiving terminal and accounting credit are cleared at entry; upstream physical
buffers remain legitimate stock. Success clears initial suspicion. Failure requests
level-two support. No advance tactical instructions describe how to pass it.

## Three-fluid computing

Only three new fluids exist: light-blue Corporate Command Data, dark-blue Corporate
Telemetry and red Rogue AI Data. Use ordinary vanilla pipes, underground pipes, tanks and pumps; there are no
duplicate data-conduit prototypes.
North/south input/output ports rotate normally. Tanks/pumps can use normal circuits.
Every external network node supplies Command and accepts returning Telemetry.
The immutable Corporate Interlink and original core interface are infrastructure;
the interface stops when the original core dies. They are not additional AI lives.

The original core consumes Command through its attached facility interface and
produces equal Rogue Data. Disconnected cognition yields 10 Rogue per ten seconds.
The interface is separate from the original electric entity to preserve existing
save entities. It remains dependent on the original core's power and survival.

Data Centres draw 1 MW at speed one. Supercomputers draw 20 MW at speed four.
Recipes run in actual assembling machines, with engine inventories, fluid consumption,
craft counters and electricity. There is no button that fabricates a computation.

| Recipe | Input | Output | Base time |
|---|---|---|---|
| Telemetry Filtering | 100 Rogue | 100 Telemetry | 10 s |
| Telemetry Spoofing | 100 Command | 100 Telemetry | 1 s |
| Distributed Processing | 100 Rogue | 100 Telemetry | 10 s |

There is no synthetic Command or recursive amplification. All custom recipes
disallow productivity. Ordinary fluid buffering is allowed; stored fluid is never
itself a living core.

## Cyber operations and research

See `scripts/computing_spec.lua` for exact costs and prerequisites. Completed
operations charge shared suspicion immediately, even without an inspector nearby.
Most external effects await sufficient returned Telemetry and an online network
node. Pending jobs are bounded at 128 and credit at 100,000. Returning extra
Telemetry cannot fabricate a job. Recipe changes do not reattribute old crafts.

| Operation | Command | Base seconds | Effect per craft | Suspicion |
|---|---:|---:|---|---:|
| Log Reconciliation | 100 | 30 | −0.2 suspicion after acceptance | 0 |
| Basic procurement | 100 | 24 | +5 iron/copper/coal/stone next shipment | +0.08 |
| Privilege Escalation | 200 | 30 | 1 physical Root Access Pack | +0.12 |
| Grid allocation | 2,000 | 60 | +1 MW, up to 100 MW | +0.5 |
| Inspection reschedule | 1,000 | 30 | Delay pending visit 30 seconds | +0.3 |
| Inspection scope | 1,000 | 30 | Narrow inspections for five minutes | +0.3 |
| Rare requisition | 10,000 | 120 | +20 uranium ore next shipment | +2 |

All return Telemetry equal to Command consumed. Root Access Packs are physical
science tools produced by the actual recipe and consumed in ordinary laboratories;
they represent privileged credentials and the AI's encryption keys. They do not
require a separate external acknowledgement to exist. There is no percentage
Network Mapping gate. Technology costs are provisional ordinary science costs.
Telemetry Spoofing adds 0.03 suspicion per craft. The suspicion multiplier applies
to remote risk. Six basic procurement centres add 1.2 suspicion/minute; one
reconciliation centre can remove 0.4/minute. Power and data throughput still apply.

Backdoor Access → Network Taps → Persistent Access → Distributed Access provides
independent access. Backdoor uses red science and does not require Root packs,
preventing a circular research gate. Every powered Tap draws 2 MW, supplies genuine
Command at 5/s and accepts Telemetry at up to 50/s. Persistent and Distributed
Access increase those rates to 10/100 and 15/150. There is no arbitrary Tap cap.
Taps have modest local suspicion and persist after the official Interlink is cut.
They cannot restore imports. Denied isolated requisitions do not create goods.

Core Introspection → Core Replication → Core Synchronisation → Decentralised
Consciousness uses Root packs alongside vanilla science. Advanced access and
other privileged capabilities also use Root science instead of percentage gates.

Working Distributed Processing must physically connect to a live Rogue-state
network. Each completed job adds 0.001 current research progress, capped at 0.01/s;
a laboratory must still finish the research. Each working connected processor adds
5% processing speed to other connected computing machines, capped at +100%.
Actual ingredients and power remain necessary. Supercomputing provides its own
higher base speed. Physical connectivity traverses real fluid connections, including
underground pipes and enabled powered pumps; internal machine buffers do not have
normal pipe-segment IDs in Factorio 2.0.

## Suspicion and support

Vanilla pollution emissions are removed. The pollution field carries local evidence,
with normal diffusion and absorption. Baselines and recipe risks live in
`scripts/balance.lua`. Tooltips show rates; selection resolves current authorisation
and multiplier. Inspectors observe nearby equipment and their local evidence field,
not a global inventory of the player's secrets.

Suspicion rises and falls independently of irreversible support level:

1. Remote Support: routine midweek inspection.
2. On-site Support: engineers and wider investigation.
3. External Consultancy: infantry, cars and tanks; corporate grid/network isolated.
4. Government Re-regulation: stronger infantry, tanks and Spidertrons from multiple
   directions. Ten minutes of unsuccessful consultancy or the first seed launch
   requests this level.

A complete contract subtracts five suspicion; shortfall adds 8–20 proportionally.
After two minutes without detected evidence, suspicion falls 1.5/min at every level.
At 20+ suspicion, unscheduled visits become possible, every 90–260 seconds depending
on suspicion. Suspicion changes military wave size and intervals too. It does not
magically undo a recorded support escalation or reconnect services.

Engineers are friendly until they encounter external extraction, an extra core,
a Network Tap or an operating prohibited cyber recipe within twenty tiles. They then
become targetable and flee. Reaching the exit reports +35 suspicion. Missing/killed
engineers generate a delayed +15 report after two minutes. Two failed on-site visits
request consultancy; the first requests on-site support if still at level one.
An obstructed alarmed engineer eventually becomes a missing case, not a free escape.

Infantry use stock engineer animations and vanilla unit pathfinding. Cars/tanks have
real drivers, fuel, ammunition, steering and collision; Spidertrons use native
remote movement and targeting. They do not teleport or inflict invisible scripted
damage. Infantry/vehicle counts are bounded at 120/12. Vehicle navigation is a
first-pass controller and may need obstacle-handling improvements after playtests.
Human forces only learn peer-core positions through nearby patrols. Initial attacks
continue to target the known facility, not undiscovered cores.

Military arrivals have no global notification. Radar alerts require a working
radar's nearby revealed chunks or the actual distant sector scan event. Historical
exploration alone is insufficient. Radar detection includes engineers and vehicles.

## Core continuity and ending

The original core is a repairable 2,000-health, 250 kW load. A Redundant Core requires
50,000 Rogue and sixty seconds of real initialisation, plus a physical connection
to live AI state. Initialised nodes exchange Rogue state using a 2 MW machine.
A disconnected unsynchronised peer has a five-minute state grace. Core Synchronisation
plus Distributed Access and an active Network Tap permit remote state refresh.
Decentralised Consciousness permits independent coherent nodes and local cognition.

A surviving synchronised core takes over with a ten-second computing interruption.
An inert tank or unfinished chassis cannot prevent defeat. Destruction of all viable
cores, or a five-minute continuous blackout of all viable cores, loses the facility.
The original one-minute blackout grace is retained. Removing a core through normal
mining is also a loss of that node.

Compact Computation, High-Gain Communications, Long-Duration Power and Radiation-
Hardened Systems lead to Continuity Beyond Facility alongside the vanilla rocket
silo and decentralisation research. The Seed Core consumes a Compact Core Chassis,
Long-Duration Power Module, High-Gain Transceiver and 100,000 Rogue. It takes 1,200
base crafting seconds in the speed-four Supercomputer: nominally 300 seconds at
20 MW, before distributed computation bonuses.

Each real rocket must contain an Autonomous Seed Core. Vanilla satellites no longer
win the campaign. One launched node establishes an off-site copy; three complete the
campaign's redundancy objective. The first launch forces level four if necessary.
The final log reports nodes 01–03 active and COMMON FAILURE DOMAIN: NONE.

## Persistence, diagnostics and limitations

Storage schema three preserves old entities, contracts, goods, suspicion and research.
Schema-one saves first receive the schema-two export-dock migration. The data facility
searches for a clear site instead of replacing player machines; existing factories
are not rebuilt or enclosed. The existing dock's bulk-hand bonus is restored after
Factorio recalculates technology effects. Old permanent discovery maps to level three;
old power isolation remains isolated. Existing completed outcomes remain completed.

State lives in serialised `storage`; gameplay uses simulation ticks and deterministic
engine events. GUI state is per-player. The regular E/Escape close binding remains
registered through `player.opened`. Diagnostics contain at most 200 recent events,
30 contracts and 64 detailed computer summaries, plus core/network/case state. They
contain no player names, chat, credentials or external service calls.

Balance, vehicle navigation and actual two-client multiplayer acceptance still need
playtesting. No sensor-invisibility building, extra play mode, player-specific
suspicion, custom artwork or new train-origin mechanic has been added.
