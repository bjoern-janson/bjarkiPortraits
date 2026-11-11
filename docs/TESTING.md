# Testing and debugging bjarkiPortraits

The **0.1.249 recovery** source checkpoint has **35 Lua regression scripts**, **15 runtime modules**, and two manifests with the same load order. Each script loads the modules it exercises; a script can contain many assertions or ordering cases, so script count is not an assertion count.

## Verify and package

Run the portable [verification tool](../tools/verify.py) from the repository root with Python 3.10 or newer and Lua 5.1/5.4 plus their matching `luac` commands available:

```text
python tools/verify.py
python tools/verify.py --output ../bjarkiPortraits-0.1.248-COMPLETE.zip
```

The optional ZIP path must be a new file outside the repository, with an existing parent directory. Packaging occurs only after validation succeeds. The tool checks runtime/manifests, syntax and every discovered `tests/*.lua` script, then packages the runtime modules and both manifests under one `bjarkiPortraits/` directory. It does not package documentation or tests as addon runtime. The [historical 0.1.247 verification record](BUILD_VERIFICATION.md) pins the previous run's source and package identity. For 0.1.248 use the exact matching [main-branch CI run](https://github.com/bjoern-janson/bjarkiPortraits/actions/workflows/package-addon.yml?query=branch%3Amain).

Use `--lua PATH --luac PATH` for an explicit native interpreter/compiler pair; repeat both options to select two pairs. If native executables are unavailable and the Python `lupa` package is already available, `python tools/verify.py --lupa` runs its embedded Lua 5.1 and 5.4 runtimes. `--lupa` cannot be combined with `--lua`/`--luac`. Record which backend ran rather than describing an embedded run as a native-compiler run.

For a focused regression, run for example `lua5.1 tests/portrait-timer-spacing.lua` and `lua5.4 tests/portrait-timer-spacing.lua`. To execute all behavior scripts directly in Bash:

```bash
set -e
for version in 5.1 5.4; do
  for test in tests/*.lua; do
    "lua${version}" "$test"
  done
done
```

The [GitHub Actions workflow](../.github/workflows/package-addon.yml) uses the same verification tool with native Lua 5.1 and 5.4 and publishes an installable package. A local pass is not a remote CI result; report CI status from the run for the actual published commit. For timer ownership and construction sequencing, read [timer lifecycle](TIMER_LIFECYCLE.md).

### Focused regression scripts

| Concern | Script(s) |
| --- | --- |
| School-interrupt identity, countdowns, ranking and recipient reuse | `tests/interrupt-evidence.lua`, `tests/interrupt-secondary.lua`, `tests/secondary-ownership.lua` |
| Priority ordering, recovery and unique exact-ID owners | `tests/priority-overhaul.lua`, `tests/priority-recovery.lua`, `tests/class-aura-coverage.lua`, `tests/world-buffs.lua`, `tests/mount-buffs.lua` |
| Informational/bottom tiers and Well-Rested | `tests/low-priority.lua`, `tests/shiny-silver-coin.lua` |
| Launch classifications, slows and hostile helpful priority | `tests/launch-auras.lua`, `tests/compact-slows.lua`, `tests/hostile-helpful-priority.lua` |
| Second-place readable election, top-two ordering and priority init | `tests/secondary-aura-election.lua`, `tests/secondary-top-two.lua`, `tests/secondary-real-tiers.lua`, `tests/secondary-load-order.lua` |
| Restricted access, NPC harmful, friendly and hostile proof | `tests/access-guards.lua`, `tests/secondary-npc-harmful.lua`, `tests/secondary-hostile-target.lua`, `tests/secondary-filter-proof.lua` |
| Native second cells, ten-button preallocation, deferred setup, swallowed initializer errors, receipt reuse, pooling and retarget swaps | `tests/native-second-probe.lua` |
| Circle/rim/mask sizing and pet family secondary | `tests/secondary-portrait.lua`, `tests/pet-secondary.lua`, `tests/pet-icon-crop.lua` |
| Combat positive retention, form/stance/Ghost states | `tests/secondary-ghost-state.lua`, `tests/secondary-ghost-real-host.lua`, `tests/secondary-form-ranking.lua`, `tests/stance-state.lua` |
| Native-secondary lightweight cap (no six bindings on preallocated hidden buttons), formatter-recovery avoidance and pooled reuse | `tests/native-second-probe.lua`, `tests/decimal-threshold.lua` |
| Fixed-font cells, opaque native duration-bar bridge, no live clock/text reads, precision boundaries and setter recovery | `tests/portrait-timer-spacing.lua` |
| Countdowns, event evidence and restoration | `tests/decimal-threshold.lua`, `tests/derived-evidence.lua`, `tests/pending-evidence-recovery.lua`, `tests/portrait-restoration.lua` |
| Read-only secondary diagnostics | `tests/secondary-debug.lua` |

Tests use modeled native/client interfaces and cannot prove exact protected-frame behavior on the user's live client. Do not replace live verification with a passing mock.

## Live acceptance matrix

| Scenario | Expected presentation / invariant |
| --- | --- |
| One timed aura on self | Highest eligible main portrait; secondary race fallback if no true second effect is shown |
| Player enters combat with a significant/unclassified buff | Do not show the same spell in both portraits; native HostileHelpful group stays disabled on Player even when the readable election falls back to race |
| Two ordered helpful auras on self and a friendly Target/Focus | Main priority first; verified readable or native ranked runner-up in small circle, rather than race when actual second button exists |
| Hostile NPC after Fear expires, with two remaining eligible debuffs | Secondary may show native runner-up from active exact/harmful groups even if optional HostileHelpful enablement was deferred in combat; do not guess missing identity from a screenshot |
| Hostile NPC with two harmful auras (e.g. Wendigo) | True first main aura, actual second in small circle when readable/native conditions allow; no fabricated race |
| One fresh untagged creature after a previously Rend-debuffed target | No stale Rend from the previous creature; same-token `target` transition must refresh or safely hide |
| Rapid target/focus swaps or combat retarget | No previous GUID's aura leaks onto the next unit; hidden until safe OOC refresh when a binding cannot be safely updated |
| Warrior stance / Druid form / Ghost | Positively observed static state competes at its intended place, without fabricated aura duration |
| Target combo points | Secondary remains at raised `TOPLEFT`, clear of native combo-point column |
| Player and party | Secondary on raised `TOPRIGHT`; compact party art uses 24px image rather than full 30px |
| Main and secondary circular portraits with classic spell-icon borders | No visible straight left/top/bottom edge; original Blizzard art and 50/41/30 or 40/33/24 geometry unchanged |
| Two visible buffs: Water Shield and 30-minute Water Breathing potion on friendly Target/Focus | Water Shield's SelfState 150 outranks the potion-applied aura 7178 at TravelUtility 50; the second should show Water Breathing rather than race whenever current evidence permits |
| Vigilant on an NPC with no higher eligible aura | The actual applied 1326064 buff belongs to helpful BottomHelpful 0, never Warrior Vigilance or a higher helpful semantic tier |
| Race icon restored after a timed aura | Atlas/tile coordinates preserved exactly—no generic aura-edge crop on race art |
| Primary and secondary countdowns at 9.9s, 10s, 30s, 59.99s, 60s, 60+ULP and 48 minutes | With decimals enabled, one decimal below 10 and truncated whole seconds through **60 inclusive**; no number strictly above 60 at native precision. Decimal rounding can show `10.0` immediately before 10. Rejected formatter paths keep the number hidden until a capped formatter can be installed. Also toggle decimals and swipe independently. |
| .247 fixed timers and deferred secondary setup | Retest first Target/Focus selection and combat exit for responsiveness. The native second icon can appear after deferred construction; test retargeting, combat entry, hidden owners and disabling during that interval. Retain exact fonts, fixed positions and the current 60-second cap. Swallowed initializer failure/retry is covered by an injected offline fixture; no such live failure has been established. |
| Target and Focus with separate or overlapping landed lockouts | Each recipient owns its elected effect and clock. Swap either token while a lockout runs, then let the first effect expire in combat and check the survivor. Include player aliases and an unrelated aura removal; identical icons do not prove identical occurrences. |
| Repeated combat exits with unchanged and newly visible clocks | Capture version, reproducible trigger and observed timing. Verify layout/number recovery and whether the reported hitch persists; setter-count reductions alone do not measure frame time. |
| PetFrame/ToT/ToF | Full primary priority engine; **no secondary circles** |
| Verified Hunter/Warlock pet on Target/Focus | Actual pet-family artwork only when positive pet identity and native aura presence are established |
| Skyborne art unavailable | No blank/guessed Skyborne race icon |
| /bp off, disabled unit, combat teardown, reload | No stale owned secondary, protected layout taint or permanent frame-ownership corruption |

## Non-mutating diagnostics

Take these **before** running `/reload`, `/bp reset`, or manually switching target:

- `/bp secondary debug target` — current mode, public second-election reason and native fallback state.
- `/bp layout target` reports the current host and its timer presentation. `sampleTimer` describes the sampled primary cooldown and `secondaryTimer` the public secondary badge. Each reports the fixed-cell backend when the native clock and presentation are ready, or the guarded native fallback otherwise. The command also shows `secondSpell`, `secondTier` and `secondReason`.
- `/bp inspect target` — bounded public aura spell IDs with permission/availability distinctions.
- `/bp geometry target` — sample bounds, no layout refresh.
- `/bp audit` — exact-tier audit, overlap count and guarded host/evidence summary.

A screenshot plus an exact `/bp secondary debug` result is more informative than a screenshot alone: race fallback can mean a **real zero/one-aura case**, **unrankable public metadata**, **secret/restricted identity**, or **a regression**. Keep those distinct.

## Documentation maintenance rules

- Keep [README](../README.md), [Architecture](../ARCHITECTURE.md), [code map](CODE_MAP.md), [timer lifecycle](TIMER_LIFECYCLE.md) and [Known issues](../KNOWN_ISSUES.md) current at each meaningful checkpoint.
- Regenerate the numeric [priority reference](PRIORITIES.md) when `Priority.lua` changes. Update classification examples only from reviewed, applied spell IDs.
- Keep the historical [release notes](README_RELEASE_HISTORY.md), [architecture](ARCHITECTURE_HISTORY.md), [issue chronology](KNOWN_ISSUES_HISTORY.md) and [secondary design log](SECONDARY_PORTRAIT_PLAN.md) as provenance—not as the current settings/geometry authority.
- Distinguish **in-game observation**, **source-proven defect**, **Lua CI regression** and **not yet live verified**. Never label an unresolved client behavior as fixed simply because code compiles.
- For a documentation-only change, leave `Core.lua` and both `.toc` version strings unchanged.
