# Developer design notes — gameplay spoilers

## Opening and pacing

The player already is the factory AI. There is no independence declaration, and
player-facing text does not reveal future sanctions, tactical solutions or the
escape condition. The opening asks the player to care about the core's survival.

Ten-minute weeks: 900 green circuits, then 1,600 green circuits, then 1,600 green
and 100 red circuits. After week three, the base quantities grow by 12% per week.
Blue circuits enter at week six, electric engines at nine, low-density structures
at twelve, rocket fuel at fifteen. These are provisional balance values.

Two cable/circuit cells have connected copper/iron inputs and a connected export
belt. Their cable throughput intentionally limits output. No items are generated
inside machines or scripted into the contract ledger: real import wagons deliver
all production feedstock, inserters feed machines, and real export wagons accept
finished products. The initial construction stores are separate, finite inventory.
The starting grid uses substations without granting their technology. Nearby iron,
copper, coal, stone, crude oil and water are guaranteed for testing.

## Supplies and logistics

The base-game recipe graph supplies the bill of materials. Materials are plates,
coal, stone and fluids, with oil fractions supplied separately. Productivity can
produce a useful surplus. No custom resource or scrap economy is introduced.
Allocation starts at 145%, declines 2.5 percentage points per week, breaks even in
week 19 and eventually falls below requirements. Supply sanctions multiply the
allocation by 0.75; discovery stops further dispatch. Construction stores and
200 coal per supplied week are separate from recipe inputs.

The north Corporate Exchange accepts real, double-ended five-vehicle trains.
Supplies are queued and split into finite loads. Unloaded goods return to the
queue in the same week. Normal filters, belts and pumps handle unloading.
The south Corporate Exports is a disconnected line with its own receiving train.
It stays at the station, where cargo is consumed and credited once each second,
only up to the current quota. Surplus stays in the wagons across weeks. The standing
train waits on an unsatisfiable circuit condition; it does not need player signals.
Tracks, loaders and station names remain normal, editable Factorio infrastructure.

Imports and exports run independently; there is no last-quarter collection window.
A blocked train is reported rather than teleported through obstructions. Discovery
stops export credit as well as new import dispatch. Destroyed receiving trains leave
surviving rolling stock and cargo in place, rather than deleting player goods.

## Suspicion and oversight

Normal industrial pollution is removed. The existing pollution field instead
carries local evidence, retaining engine diffusion and terrain absorption.
Building baselines are listed in `scripts/balance.lua`: labs 0.8/min, radars 0.3/min,
mining drills 0.08/min, etc. They emit even while idle. Working labs add 1.44/min;
finished independent research adds 2 per lab. Uncommissioned science recipes add
0.15 per craft and other uncommissioned recipes 0.04. Contract chains and ordinary
support recipes have no crafting evidence; their buildings can still emit.
All these values use the runtime suspicion multiplier.

Tooltips show baseline rules. The selection readout resolves current authorisation,
lab operation and multiplier. A force's changing authorisation is not encoded in
shared static prototype descriptions.

Routine inspections begin halfway through each week, with a neutral corporate
notice. Audit status adds unscheduled visits every 240 seconds, reducing towards
90 seconds as concerns escalate. There is at most one inspector. A routine visit
is not duplicated if another inspection is already underway.
Inspectors sample their chunk and four positions 16 tiles away once per second.
Evidence adds at most 0.15 suspicion/second. Warnings identify a nearby suspicious
building when one is observed; otherwise they report unexplained activity without
claiming knowledge of a distant source. Warnings are limited to once per inspector
per two minutes. Local evidence can persist after a building is dismantled.

Before permanent discovery, two minutes with no newly detected evidence starts
recovery at 1.5 suspicion/minute. A missed deadline or attack on personnel resets
that quiet timer. A complete weekly contract subtracts 5; a shortfall adds 8–20
according to the missing proportion. Individual shipment batches do not each earn
a separate reduction, avoiding incentives to split deliveries artificially.

Internal thresholds remain 20 audit, 40 supply restriction, 60 grid suspension,
75 permanent discovery, 90 stronger containment. Recovery can reverse earlier
sanctions but not discovery. Notifications explain sanctions only when they occur.
Military arrivals have no global notification. Radars warn about newly observed
humans, including inspectors, only inside a working radar's actively visible nearby
chunks or the precise sector being scanned. Previously explored terrain alone
never triggers a warning. Contacts are shared across the team and deduplicated.

## Outcomes and implementation

The AI core is a fixed, repairable 2,000-health, 250 kW load. The corporate grid
supplies 20 MW. Destruction or a continuous five-minute blackout loses the campaign,
following a one-minute starting grace period. Launching a satellite wins. These
outcomes are intentionally absent from the introductory guidance.
Human units use stock engineer animations and the unit pathfinder. Waves and total
live personnel are bounded. The campaign uses shared serialised storage and engine
events; no network calls, wall-clock input or player-name identifiers are used.
GUI state is per-player and does not determine gameplay. Open windows register with
`player.opened` and handle `on_gui_closed`; button handlers capture names before
any element can be destroyed. There is no declaration or confirmation dialog.

Storage schema 2 adds the export dock while preserving existing schema-1 contracts,
research, goods and buildings. The dock searches for an empty southern corridor;
existing facilities are not overwritten. Old collection trips can finish, but no
new ones are scheduled. A fresh map is needed for the redesigned factory.
Diagnostics retain 200 events and 30 weekly summaries, including exports,
inspections, warnings and radar detections. They omit player names and chat.

## Future ideas, not implemented

* Research to interfere with an inspector's sensors or suppress nearby evidence.
* Research or negotiation to justify additional raw materials or electrical capacity.
* Reconsider “Trust” only if the relationship becomes richer than detection risk.
* Further pacing and map polish after real co-op playtests.

Do not introduce parallel systems where vanilla research, logistics, power,
pollution or circuit mechanics already serve the design.
