# Version 0.2.0 validation

Engine: official Factorio 2.0.77 Linux headless, base game only, seed 45176.
The test runner installs the same packaged ZIP used by players. The harness and
proprietary game binaries are excluded from the release.

Passed engine checks:

* Untouched ten-minute opening: all 900 week-one circuits exported; the unchanged
  factory exports 1,228 of week two's 1,600 required circuits, then red circuits
  become commissioned in week three. Substations, resource patches and water exist.
* Campaign: early exports, exact quota caps, surplus retained across weeks, no
  duplicate credit, physical supply and fluid trains, authorisation, local evidence
  and containment progression through the later recipe requirements.
* Oversight: midweek inspection, warning identifying an observed lab, quiet-period
  recovery, current powered-radar coverage, actual distant sector scan detections,
  and no new detection from a disabled radar or old exploration alone. The radar
  case uses accelerated scan timing only in the separate test harness.

* Upgrade: a genuine 0.1.1 save retains its quota, deadline, research, suspicion,
  buildings and cargo. The dock avoids an occupied corridor and physically exports
  1,000 test goods after migration.

The untouched opening runs for 72,120 ticks. Other campaign tests run for up to
27,000 ticks. See `TESTING.md` for commands and precise test scopes.

Headless testing cannot establish graphical acceptance, E/Escape interaction with
real player windows, or actual two-client multiplayer stability. Those remain
client playtests. Version 0.1.1's icon fix was confirmed to load by a player; new UI
layout and the redesigned map still need visual feedback.

The pacing values are a starting point for playtesting, not a completed balance
pass. Other seeds and heavily modified/very large factories need further coverage.
No personal playthrough saves or machine-specific logs are published.
