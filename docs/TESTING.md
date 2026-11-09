# Testing and debug workflow

**Development branch:** `feat/secondary-portrait-p1`. **Baseline:** `0.1.222-native-runner-up-duplicate-suppression-test`, 2026-11-09. The workflow is [`.github/workflows/package-addon.yml`](../.github/workflows/package-addon.yml).

## Automated pipeline

On development-branch pushes (and supported pull-request/workflow-dispatch triggers), GitHub Actions:

1. Installs Lua **5.1 and 5.4**.
2. Syntax checks all thirteen runtime `.lua` modules and `tests/*.lua` with `luac5.1 -p` / `luac5.4 -p`.
3. Executes all explicitly listed regression scripts for **both** Lua versions. See the workflow's `Check Lua syntax and behavioral regressions` step for the precise, authoritative list.
4. Packages `dist/bjarkiPortraits/` with **13 runtime modules and two `.toc` manifests**, and publishes the `bjarkiPortraits` workflow artifact.

For an installable ZIP, the extracted folder must have one `bjarkiPortraits` directory, with the `.toc` files immediately inside it. Check that both manifests and `Core.lua` report the same version. A successful ZIP integrity test only proves that the archive is readable; it does **not** prove that the platform's file-download handoff will succeed.

Useful regression scripts:

| Concern | Script(s) |
| --- | --- |
| Priority ordering, unique exact-ID owners | `tests/priority-overhaul.lua`, `tests/class-aura-coverage.lua`, `tests/world-buffs.lua`, `tests/mount-buffs.lua` |
| Informational/bottom tiers and Well-Rested | `tests/low-priority.lua`, `tests/shiny-silver-coin.lua` |
| Second-place readable election and priority init | `tests/secondary-aura-election.lua`, `tests/secondary-real-tiers.lua`, `tests/secondary-load-order.lua` |
| NPC harmful, friendly and hostile proof | `tests/secondary-npc-harmful.lua`, `tests/secondary-hostile-target.lua`, `tests/secondary-filter-proof.lua` |
| Native second cells, first-time enabled state, pooling, retarget swaps | `tests/native-second-probe.lua` |
| Circle/rim/mask sizing and pet family secondary | `tests/secondary-portrait.lua`, `tests/pet-secondary.lua`, `tests/pet-icon-crop.lua` |
| Combat positive retention, form/stance/Ghost states | `tests/secondary-ghost-state.lua`, `tests/secondary-ghost-real-host.lua`, `tests/secondary-form-ranking.lua`, `tests/stance-state.lua` |
| Countdowns, event evidence and restoration | `tests/decimal-threshold.lua`, `tests/derived-evidence.lua`, `tests/pending-evidence-recovery.lua`, `tests/portrait-restoration.lua` |

Tests use modeled native/client interfaces and cannot prove exact protected-frame behavior on the user's live client. Do not replace live verification with a passing mock.

## Live acceptance matrix

| Scenario | Expected presentation / invariant |
| --- | --- |
| One timed aura on self | Highest eligible main portrait; secondary race fallback if no true second effect is shown |
| Player enters combat with a significant/unclassified buff | Do not show the same spell in both portraits; native HostileHelpful group stays disabled on Player even when the readable election falls back to race |
| Two ordered helpful auras on self and a friendly Target/Focus | Main priority first; verified readable or native ranked runner-up in small circle, rather than race when actual second button exists |
| Hostile NPC with two harmful auras (e.g. Wendigo) | True first main aura, actual second in small circle when readable/native conditions allow; no fabricated race |
| One fresh untagged creature after a previously Rend-debuffed target | No stale Rend from the previous creature; same-token `target` transition must refresh or safely hide |
| Rapid target/focus swaps or combat retarget | No previous GUID's aura leaks onto the next unit; hidden until safe OOC refresh when a binding cannot be safely updated |
| Warrior stance / Druid form / Ghost | Positively observed static state competes at its intended place, without fabricated aura duration |
| Target combo points | Secondary remains at raised `TOPLEFT`, clear of native combo-point column |
| Player and party | Secondary on raised `TOPRIGHT`; compact party art uses 24px image rather than full 30px |
| Second countdown at 9.9s, 10s, 60s | Native formatter: one decimal strictly below 10; whole seconds 10–60; hidden above 60 |
| PetFrame/ToT/ToF | Full primary priority engine; **no secondary circles** |
| Verified Hunter/Warlock pet on Target/Focus | Actual pet-family artwork only when positive pet identity and native aura presence are established |
| Skyborne art unavailable | No blank/guessed Skyborne race icon |
| /bp off, disabled unit, combat teardown, reload | No stale owned secondary, protected layout taint or permanent frame-ownership corruption |

## Non-mutating diagnostics

Take these **before** running `/reload`, `/bp reset`, or manually switching target:

- `/bp secondary debug target` — current mode, public second-election reason and native fallback state.
- `/bp layout target` — current host and timer presentation state; includes `secondSpell`, `secondTier`, `secondReason`.
- `/bp inspect target` — bounded public aura spell IDs with permission/availability distinctions.
- `/bp geometry target` — sample bounds, no layout refresh.
- `/bp audit` — exact-tier audit, overlap count and guarded host/evidence summary.

A screenshot plus an exact `/bp secondary debug` result is more informative than a screenshot alone: race fallback can mean a **real zero/one-aura case**, **unrankable public metadata**, **secret/restricted identity**, or **a regression**. Keep those distinct.

## Documentation maintenance rules

- Keep [README](../README.md), [Architecture](../ARCHITECTURE.md) and [Known issues](../KNOWN_ISSUES.md) current at each meaningful checkpoint.
- Regenerate the numeric [priority reference](PRIORITIES.md) when `Priority.lua` changes. Update classification examples only from reviewed, applied spell IDs.
- Keep the historical [release notes](README_RELEASE_HISTORY.md), [architecture](ARCHITECTURE_HISTORY.md), [issue chronology](KNOWN_ISSUES_HISTORY.md) and [secondary design log](SECONDARY_PORTRAIT_PLAN.md) as provenance—not as the current settings/geometry authority.
- Distinguish **in-game observation**, **source-proven defect**, **Lua CI regression** and **not yet live verified**. Never label an unresolved client behavior as fixed simply because code compiles.
- For a documentation-only change, leave `Core.lua` and both `.toc` version strings unchanged. Add a docs-only commit to the development branch; avoid merging experimental secondary work into `main` implicitly.
