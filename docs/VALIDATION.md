# Version 0.3.0 validation

Engine: official Factorio 2.0.77 Linux headless, base game only, seed 45176.
Tests install the packaged ZIP, not an unpackaged source directory.

Engine checks cover:

* Connected untouched opening, continuous exports, retained surplus, ordinary solid
  and fluid trains, weekly authorisation and the green/red progression.
* Real fluid conversion, Tap supply and Root science production; measured Debug success/failure.
* All cyber recipes, telemetry-gated effects, Root science gates, ordinary lab consumption and physical compute
  assistance. Actual Supercomputer manufacture of an Autonomous Seed Core.
* Powered Taps after cutoff, continuing exports, separate procurement bonuses and
  independent permanent support level despite falling suspicion.
* Coordinated two-train ambush, docked troop release, retained cargo and later exports.
* Real redundant-core initialisation, pipe state connection, execution transfer and
  final-core destruction; timed blackout defeat.
* Delayed missing-engineer cases, discovery, fleeing/reporting, armed support,
  stock cars/tanks and native Spidertrons.
* Three actual rocket launches, exact-once payload credit and continuity victory.
* Routine inspections, local evidence/warnings, quiet recovery, working radar range,
  actual distant scans and disabled-radar/history exclusions.
* Upgrades from archived 0.1.1 and 0.2.0 preserve progress and goods. Added facilities
  avoid test obstructions; migrated docks retain powered bulk-hand throughput.

See `TESTING.md` for reproducible commands, harness acceleration/fixture details and
which behaviours remain manual acceptance. These tests are not a full campaign
balance run: ingredients/power are supplied in focused integration cases.

Headless cannot establish graphics rendering, real E/Escape interaction, visual
layout acceptance or two-client multiplayer/desync stability. Full wireless-core
and large-factory stress, vehicle obstacle tactics and end-to-end difficulty still
need playtesting. All mechanics use shared serialised state and engine events, but
this is an implementation property, not a substitute for actual co-op testing.

No personal playthrough saves, machine-specific logs, proprietary binaries, account
information or private conversation transcripts are included in the release.
