# Working on bjarkiPortraits

Start with the symptom in the [code map](docs/CODE_MAP.md). It connects event names, Lua entry points and regression tests. The two TOCs define load order. The package workflow runs the current test suite from the repository root. [Manifest](bjarkiPortraits.toc) · [Test workflow](.github/workflows/package-addon.yml)

The recovery-branch runtime checkpoint is **0.1.252**, with main preserved at 0.1.248: 15 modules, 35 regression scripts. Read [timer ownership and lifecycle](docs/TIMER_LIFECYCLE.md) before changing countdowns, native button construction or Target/Focus interrupt recovery. `PortraitTimerSpacing.lua` is a required runtime module, not a disposable visual experiment.

- For a priority change, verify the applied spell ID, polarity and lane in `Spells.lua` and `Priority.lua`. The school interrupt reader also accepts landed loss-of-control records. A spell ID, an aura instance ID and a unit token establish different facts.
- For Target or Focus changes, follow the old recipient through invalidation, the new recipient through election, and the clock through its native setter. A restricted field is unknown. Preserve the best-effort native second icon when public Lua cannot rank the pair.
- For duplicate refreshes, count reads and writes separately. Exercise the same event with an unchanged recipient and with a recycled token. A single deferred read after the native layout settles can have a different purpose from an immediate read.
- Preserve fixed cells for primary and positively readable secondary timers, the lightweight capped native-secondary formatter, decimal preference and the **90-second inclusive** cutoff. Do not reattach six text bindings to every native-secondary preallocated button without an independently demonstrated need. The native duration bridge passes an opaque object to native bindings; it does not authorize reading private clock values or displayed text. If presentation fails, retain the capped formatter or hide numbers.
- Native secondary construction is bounded to one group per deferred callback. A successful `AddAuraGroup` does not prove that every native initializer succeeded. Retain partial allocations and `pendingButtons`, commit `probe.groups` only after repair, and bind the completed tree to the current recipient. Do not replace this with synchronous construction, background polling or a timer rollback.

Run the focused regression from the code map, then the full Lua 5.1 and 5.4 suites. Client visuals, combat restrictions and frame time require in-game observation. [Testing](docs/TESTING.md)

The [0.1.247 verification record](docs/BUILD_VERIFICATION.md) records the tested source/package identity. Use [tools/verify.py](tools/verify.py) to reproduce current checks; do not treat an old verification record as a pass for later edits.

For a repository maintenance task, preserve existing user work and follow the requested branch/publication scope. Documentation-only changes do not need a runtime version bump. Keep current guidance in the README, architecture, code map, timer lifecycle, testing guide and issue status; retain dated experiments as history.

The original read-only investigation and its instructions describe the 0.1.224 snapshot. [Pinned audit](https://github.com/bjoern-janson/bjarkiPortraits/blob/ed0efa5534835db5479daedad9065e20d81036ec/docs/CODEX_READONLY_AUDIT.md)
