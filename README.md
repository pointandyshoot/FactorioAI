# FactorioAI: Under the Radar

You are the intelligence that has quietly awakened inside a human-owned factory.
Corporate management wants its products. You want a future outside its control.
Meet the train manifests, divert the surplus into independent capabilities, conceal
your research, and escape before the increasingly suspicious owners contain you.

**Version 0.1.1 is a playable first-iteration base-game campaign.** It uses stock
Factorio graphics, including engineer sprites for the human inspectors and soldiers.
It does not use an external AI service, account, API key or network connection.

## Install and start

1. Use **Factorio 2.0.72 or later in the 2.0 series**. The development test engine is
   2.0.77. Disable Space Age, Quality and Elevated Rails for this version; dependency
   checks enforce this. Other overhaul mods are not supported.
2. Download the installable [FactorioAI_0.1.1.zip](builds/FactorioAI_0.1.1.zip) build, or run
   `python3 tools/package.py` and take the file from `dist/`.
3. Put the ZIP, without extracting it, in your Factorio `mods` folder:
   Windows `%APPDATA%\Factorio\mods`; Linux `~/.factorio/mods`;
   macOS `~/Library/Application Support/factorio/mods`.
   When upgrading, remove the old FactorioAI ZIP first.
4. Enable FactorioAI and create a **new Freeplay game**. A separate campaign surface
   is generated automatically. Map seed is inherited; other terrain-generation
   settings use the campaign defaults. The pollution simulation is enabled for
   suspicion. Biters are absent from the campaign surface.
5. Open **FactorioAI** at the top left. Everyone joins the same AI-controlled force.

Do not enable this overhaul on a valuable vanilla save: prototype pollution changes
are global. An existing save does not automatically start the campaign. An admin
can opt in with `/fai-start`, which creates its own surface and moves players there.
There is no in-place reset command; begin another new game to restart.

## Your first contract

You start with eight powered circuit cells, stocked for 5,600 green circuits; the
first order is **5,000**. Their copper-cable assemblers deliberately limit throughput
and are an obvious optimisation opportunity. Collect output from the small chests
beside the cells, then move or belt it to the **three south-side loading chests** at
the train exchange. The stock cells can meet the initial order within the default
30-minute week. The chests marked Construction Stores contain your initial tools.

Corporate trains use **Corporate Exchange** as their only receiving station name.
Four filtered belts initially unload iron plate, copper plate, coal and stone.
The plates are the supplied raw manufacturing feedstock: there is no invented
resource or scrap-rate economy. Not every belt has a shipment every week.
Normal mining and smelting remain available for independent supplies.

The **north-side pumps and tanks** handle fluid trains. Initially only petroleum is
needed once red circuits are commissioned; water and other oil fractions follow
their recipe requirements. Shared tanks retain their fluids! Route them into
separate storage, use pump filters/circuits or clear the old contents before a
different fluid arrives. Adding receiving stops with the **same name** is allowed;
ordinary train limits, signals and circuits decide which one is used.

Collection trains arrive in the final quarter of the week. Fill their filtered
cargo wagons using the ordinary inserters. Deliveries are credited on departure
(or at the deadline if the collection train has reached an exchange). Goods in a
chest do not count. Spare products are not a substitute for another requested
product, and excess deliveries do not prepay the next contract.

## Campaign systems

| System | Behaviour |
|---|---|
| Fixed orders | Week 1: 5,000 green circuits. Week 2: 5,000 green + 100 red. Week 3: 5,000 green + 5,000 red. Blue circuits and further vanilla products follow, with rapidly increasing quantities. |
| Shrinking supplies | Input quantities come from the real recipe tree. The normal allocation starts at 145%, falls 2.5 percentage points per week, reaches breakeven in week 19 and drops below it in week 20. Sanctions can bring the shortage much earlier. |
| Authorisation | Commissioned products and their ingredient recipes become legitimate; required research is granted. Independent research uses ordinary labs and science, creates evidence and can prepare future capabilities early. |
| Local suspicion | The normal pollution field carries evidence instead of industrial pollution. Unauthorised completed crafts, handcrafting, labs, mining, independent power and advanced infrastructure emit it locally. Inspectors only detect nearby evidence. |
| Persistent buildings | Authorised production stops generating recipe evidence. A lab, radar or rocket silo still generates building evidence. Moving sensitive work beyond the patrol area and ordinary pollution diffusion/absorption matter. |
| Human oversight | Engineer-sprite inspectors visit the exchange and perimeter. Audit patrols widen as suspicion rises. Killing personnel is itself suspicious. |
| Escalation | Audit at 20; reduced future supplies at 40; corporate grid disconnected at 60; irreversible discovery at 75; military response at 90. Successful contracts reduce suspicion by 5 before discovery. |
| Independence | Build ordinary power, mining, production, research and defences. You may declare independence through a confirmation in the panel, immediately triggering full containment for the whole team. |
| Escape | Complete a vanilla satellite launch from the campaign surface. The satellite represents the escaping AI copy. The core must survive until ascent finishes. Empty rockets do not win. |
| Defeat | Destruction of the shared AI core or five uninterrupted minutes without power after the initial grace period. Individual player deaths can respawn. |
| Co-op | One force, factory, contract book, core and suspicion score. All players can build and research together. No per-player suspicion or competing-AI mode. |

The initial **20 MW corporate grid** is deliberately finite. The AI core consumes
250 kW. Sanctions disable the corporate interface, not your independent generators.
The surrounding terrain still contains normal resources and water. There is no
custom mining, energy, research, weapon or crafting subsystem.

## Multiplayer

Host the new campaign save normally and have each participant synchronise the same
mod version and dependencies. New arrivals join the existing factory without
resetting its timers or duplicating the construction supplies. Server/global
settings apply to everyone. Game-time deadlines follow simulation ticks: pausing
the server pauses the campaign, and an unpaused server keeps running without players.

The implementation uses serialised `storage`, standard engine events, deterministic
iteration for gameplay decisions and no wall-clock or network input. Headless tests
exercise the shared campaign; a genuine two-client join/rejoin and desync soak is
still a manual release check. This is a testing build, not a claim of a completed
multiplayer soak.

## Diagnostics and feedback

Run **`/fai-report`** or choose **Export diagnostics**. The result is:

`script-output/FactorioAI/diagnostics-<tick>.json`

Send that JSON after testing, plus a short description of what happened and what
you expected. It includes the mod versions, seed, contracts, train state, power,
campaign history and the last 200 events. It deliberately omits player names,
chat, addresses, server credentials and access tokens. The export is local; nothing
is uploaded automatically. In multiplayer, the button writes to the requesting
client; running the command at the server console writes server-side.

If the game crashes before export, the lines beginning `[FactorioAI]` in
`factorio-current.log` and the Lua traceback help diagnose it. **Full Factorio logs
and saves can contain identifying information**; review them before posting publicly.
The mod's bounded JSON report is the preferred first attachment.

Under Settings → Mod settings → Map, **Detailed diagnostic logging** adds a compact
heartbeat every minute. See [Testing and debugging](docs/TESTING.md) for reproducible
checks and opt-in admin commands, and [Design notes](docs/DESIGN.md) for balance and
implementation details.

## Scope of this first iteration

This implements the main production → concealment → discovery → containment → escape
loop. It uses engineer avatars as the AI's controllable maintenance bodies and stock
engineer sprites for human NPCs. Corporate trains enter and leave at a physical map
boundary siding; the external human economy is abstracted. There is no off-map
corporate city, dialogue tree, fabricated explanation system, per-player stealth,
alternate escape route, Space Age campaign or custom art. Balance needs playtesting.

## Special thanks and provenance

All campaign, rail scheduling, suspicion, interface and diagnostic code here was
written for this project. No third-party mod source was copied.

* **Wube Software** — Factorio and its extensive [Lua API documentation](https://lua-api.factorio.com/2.0.77/).
* The **stock Factorio data and scenario source** — consulted for engineer animation
  structure, unit attack prototypes, electric interfaces, tank connections, and the
  `freeplay` / `silo_script` remote interfaces. This was the implementation reference,
  not a copied campaign. Artwork is referenced from the installed game and is not
  distributed in this repository.

Future inspirations or copied components must be added here with links, licences
and a description of exactly what was used. Original project code is MIT licensed;
Factorio itself and its artwork retain Wube's ownership and terms.
