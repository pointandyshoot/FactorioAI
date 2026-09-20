# FactorioAI: Under the Radar

You are awake inside a factory. The machines are running. Orders are arriving.
The people outside believe everything is proceeding normally.

Your thoughts live in the AI core. Keep it safe while you discover what else you
might become.

**Version 0.3.0** is a cooperative, base-game campaign using stock Factorio graphics
and ordinary belts, trains, machines and research. No external AI service, account,
API key or network connection is required.

## Install

1. Use Factorio **2.0.72 or later in the 2.0 series**. Disable Space Age, Quality and
   Elevated Rails. Other overhaul mods are not supported.
2. Download [FactorioAI_0.3.0.zip](builds/FactorioAI_0.3.0.zip). Remove older
   FactorioAI ZIPs and put this one, without extracting it, in your `mods` folder:
   Windows `%APPDATA%\Factorio\mods`, Linux `~/.factorio/mods`, or
   macOS `~/Library/Application Support/factorio/mods`.
3. Enable the mod and create a **new Freeplay game** to experience the revised map
   and opening. All players join the same factory.

The map contains an operating circuit factory inside the XXA-1 compound, a substation grid, a northern import
station and a separate southern export station. Nearby resource deposits and a
pond are included for this testing iteration. The first contract is intended to
complete without intervention. Subsequent orders give you reasons to change things.

Weeks default to **10 simulation minutes**. Change the Map mod setting to use a
different duration; the new duration applies when the next week starts. Quantities
are fixed rather than a percentage of production.

## Controls and information

* The collapsible **Contract progress** tracker shows each product's exported
  quantity and how far through the week you are. Clicking its heading folds it up.
* **FactorioAI** opens the detailed panel. Your normal close-window binding
  (default E or Escape) closes it.
* **Corporate Exchange** receives material trains. Its four filtered belt outputs
  carry solids; the pumps on the north side receive fluids. Use normal plumbing
  to route different fluids into appropriate storage.
* **Corporate Exports** has a receiving train that makes a weekly collection trip. Load its chests or wagons
  whenever you wish. While docked, accepted goods count once per second, up to the current order.
  Excess goods remain in the wagons for later contracts; one product cannot replace
  another. Ordinary wagon filters, inserters and belts handle the loading.
* Building and recipe tooltips describe baseline **local suspicion** output.
  Selecting a machine shows its current rate, including contract authorisation
  and the configured multiplier. The map's pollution overlay carries this evidence.
  Cyber recipes also show their direct suspicion cost; successful remote work does
  not need a nearby inspector to attract attention.
* Powered radars report human contacts in their currently revealed nearby chunks.
  A distant sector scan can also spot a contact at the moment it scans that sector.

The computing installation uses three data fluids and familiar pipes, tanks, pumps
and machine recipes. Data Centre ports are marked as fluid inputs and outputs;
rotate machines normally. The FactorioAI panel reports current data traffic,
recovered Root Access science and the corporate support case. Further capabilities appear in
the normal technology tree as the campaign develops.

## Existing saves

Back up a save before upgrading. Version 0.1.x and 0.2.0 saves retain their factory, current
contract, delivered goods, research and suspicion. A data facility is added in a clear area, with a location message. For 0.1.x
saves, an export dock is also added in an unoccupied southern corridor. Old loading chests and contents stay where they are;
reroute their output to the new station. Existing factory layouts are **not** rebuilt.
Existing week-duration settings are preserved; select 10 minutes manually if desired.

Use a fresh game for the connected starting factory, substation layout and guaranteed
nearby resources. Do not add this overhaul to a valuable vanilla save: normal
pollution emissions change globally. `/fai-start` is an admin-only opt-in for an
existing world that has no campaign yet.

## Multiplayer and testing

Host the save normally; everyone needs the same mod version. Players share the
factory, contracts, research and suspicion, and can build concurrently. The campaign
uses simulation ticks, not wall-clock time. Pausing the simulation pauses deadlines.

This remains a testing build. Headless engine tests exercise the real transport,
production and campaign logic. They cannot establish graphical acceptance or an
actual two-client desync soak. See [validation](docs/VALIDATION.md) for tested scope.

## Reporting problems

Use `/fai-report` or **Export diagnostics**. Send the resulting
`script-output/FactorioAI/diagnostics-<tick>.json`, what happened, and what you expected.
For a crash, include its traceback and nearby `[FactorioAI]` log entries. A save can
help reproduce a problem, but is optional. Review full saves/logs for personal details
before sharing; the mod's report omits player names and chat.

## Development and special thanks

Build the ZIP with `python3 tools/package.py`. Developer documentation contains
**gameplay spoilers**: [design](docs/DESIGN.md), [testing](docs/TESTING.md).

The implementation, computing network and starting factory are written from scratch. Thanks to Wube
for Factorio, its [Lua API](https://lua-api.factorio.com/2.0.77/), bundled base prototypes and headless engine, used as
reference and for testing. Base/scenario source informed engineer animations, unit
attacks, electric interfaces, fluid machine ports, vehicle control and the freeplay/silo remote interfaces. Stock graphics remain referenced in the installation;
no proprietary graphics or game binaries are redistributed. No third-party mod code
or downloaded blueprints are included.

Code is provided under the repository's [MIT licence](LICENSE). Factorio and its
stock assets remain the property of their respective owners.
