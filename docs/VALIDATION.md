# Version 0.1.0 validation

Tested with the official **Factorio 2.0.77 Linux headless engine**, base game only,
map seed 45176. The repository includes the reproducible test runner and separate
test mod; neither the test mod nor any Factorio binary is shipped in the mod ZIP.

## Engine checks passed

* Prototype loading, Lua control-stage loading, new-world generation and reload of
  the generated save into the benchmark engine.
* Fixed initial manifests, supply crossover at weeks 19/20, capped delivery credit
  and irreversible discovery rules.
* Powered starter machines produce **5,600 circuits within the default 30-minute
  first week**, using their initial stock, and the core remains powered.
* Physical supply train movement to the exchange and back to the boundary, with
  iron, copper and coal reaching their separate output belt buses.
* Physical collection loading and settlement of a 5,000-green-circuit order before
  the deadline; next-week progression and red-circuit authorisation.
* Actual fluid wagon → pump → pipe → tank transfer at the shared station.
* Lab construction registers as a local suspicion source, and an actual inspector
  converts nearby evidence into shared suspicion.
* Recipe-derived materials for all contract tiers through week 12.
* Supply sanctions, pre-discovery recovery, permanent discovery and human-unit waves.
* A real rocket loaded with a satellite launches and reaches the escape outcome.
* Corporate power isolation produces the timed blackout defeat.
* Destruction of the core produces the defeat outcome.

The five integration cases use disposable saves. The starter case runs 108,060
ticks; the other cases run up to 27,000 ticks.
Outcome cases stop simulation on the engine's victory/defeat screen; their terminal
event is asserted rather than treating an early stop as a successful full run.

## Remaining playtests

These checks do **not** establish a full balance pass, graphical acceptance or a
multiplayer desync soak. Two actual clients must still test join/rejoin, the GUI,
concurrent building, server save/reload during activity and sustained co-op play.
Additional seeds, custom station layouts and very large factories also need testing.
The detailed acceptance steps are in `TESTING.md`.

The build deliberately identifies itself as a first iteration. Runtime and test
logs are kept out of the public repository to avoid sharing environment details;
the reproducible harness and this factual results summary are included.
