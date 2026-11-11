# bjarkiPortraits code map

This recovery branch follows version 0.1.250. The two manifests load the same Lua files in order. `Core.lua` creates `BP.Runtime`, usually called `R` inside a module, and `Main.lua` registers the events. [Standard manifest](../bjarkiPortraits.toc) · [Camelot manifest](../bjarkiPortraits_Camelot.toc)

Use this file as the entry index for a source or AI-assisted review. Resolve exact symbols with `rg -n -g '*.lua' "symbol" .`; file names and function names are more stable than copied line numbers. Current behavior lives in the Lua modules and tests. The [0.1.224 read-only audit](CODEX_READONLY_AUDIT.md) and dated design/release logs are historical snapshots, not the current task's permissions or runtime specification.

## Module owners in manifest order

| Module | Responsibility / useful entry points |
| --- | --- |
| [Spells.lua](../Spells.lua) | Reviewed applied spell-ID categories; inputs to exact lanes. |
| [Core.lua](../Core.lua) | Runtime/defaults; `R.CanAccess`, guarded unit readers, `R.ExactFilterAllowed`, shared secondary geometry, `R.GetCountdownFormatter`, `R.ApplyCountdownFormat`. |
| [PortraitTimerSpacing.lua](../PortraitTimerSpacing.lua) | `R.AttachPortraitAuraClock`, `R.ApplyPortraitTimer`; native clock transport, final-font glyph cells, fixed-position presentation and fallback cleanup. |
| [Interrupts.lua](../Interrupts.lua) | `R.GetSchoolInterrupt`, `R.SetSchoolInterruptClock`, duplicate-effect and public-aura-link evidence. |
| [StanceState.lua](../StanceState.lua) | `R.ResolveWarriorStance`; positive state evidence without a fabricated aura clock. |
| [SharedEvidence.lua](../SharedEvidence.lua) | `BjarkiEvidenceV1`; validation, bounded storage and replay of positive observations. |
| [EvidencePublisher.lua](../EvidencePublisher.lua) | `R.PublishAuraEvent`, `R.PublishDerivedSnapshot`; readable hostile-player helpful evidence. |
| [Priority.lua](../Priority.lua) | `R.TIERS`, `R.TIER_BY_KEY`, `R.CandidateFilters`; 62 exact/semantic lanes and derived indexes. Must precede the secondary election. |
| [SecondaryPortrait.lua](../SecondaryPortrait.lua) | `R.GetReadableSecondaryAura`, `R.ReconcileSecondaryPortrait`, `R.NoteSecondaryAuraEvent`; readable first/second pair, retention and race fallback. |
| [NativeSecondProbe.lua](../NativeSecondProbe.lua) | `R.UpdateNativeSecondProbe`, `R.CreateNativeSecondProbe`, `R.ReleaseNativeSecondProbe`, `R.ApplyNativeSecondPresentation`; best-effort clipped native second cell and deferred construction. |
| [AuraEngine.lua](../AuraEngine.lua) | `R.CreateHost`, `R.UpdateHost`, `R.Refresh`, `R.DestroyHost`, `R.ApplyPresentation`; physical portrait ownership, primary containers, readable projections and restoration. |
| [PetPortraits.lua](../PetPortraits.lua) | Local pet foundation and positively observed target/focus pet identity; `R.ResolveObservedPetSecondaryArt`. |
| [PetSecondary.lua](../PetSecondary.lua) | `R.UpdatePetSecondaryFallback`; family artwork gated by native aura presence. |
| [Commands.lua](../Commands.lua) | `/bp` toggles, synthetic preview and bounded read-only diagnostics. |
| [Main.lua](../Main.lua) | Event registration, native frame hooks, `queueRefresh` and `refreshAuraToken`; scoped immediate and one-shot settling passes. |

## Event routing

| Trigger | Path / owner |
| --- | --- |
| `ADDON_LOADED` | Apply defaults; install native frame hooks when `Blizzard_UnitFrame` becomes available. |
| `PLAYER_LOGIN`, `PLAYER_ENTERING_WORLD` | Retry formatter epoch, build hosts, refresh pet art, publish derived snapshots, then queue current-token settling. |
| `UNIT_AURA` | Note secondary delta, publish permitted evidence, refresh the affected token; reserve one post-native-layout check when a clock needs it. |
| `PLAYER_TARGET_CHANGED`, `PLAYER_FOCUS_CHANGED` | Immediate forced refresh with binding invalidation for that token; then one deferred settling pass. Refresh the associated ToT/ToF independently. |
| `LOSS_OF_CONTROL_ADDED`, `LOSS_OF_CONTROL_UPDATE` | Read the current recipient of each matching host with `R.GetSchoolInterrupt`; hand that observation into `R.Refresh`. Never borrow Target's result for Focus. |
| Native `UnitFrame_SetUnit`, Focus portrait update, party pool/layout hooks | Observe completed native operations and queue reconciliation. Recycled frames must pass ownership checks before displaying saved work. |
| `PLAYER_REGEN_ENABLED` | Retry formatter epoch, complete queued host work, force current evidence refresh and recover timer presentation without rewriting every unchanged hidden clock. |
| `UI_SCALE_CHANGED`, `DISPLAY_SIZE_CHANGED` | Explicit presentation verification, including hidden preallocated labels. |

Other unit-state, form, pet and roster events remain scoped to supported hosts; follow their registration and handler in `Main.lua`. The queue re-reads the current token and does not poll continuously.

## Trace one Target aura update

1. The `UNIT_AURA` handler calls `R.NoteSecondaryAuraEvent` with the delta, calls `R.PublishAuraEvent`, then invokes `refreshAuraToken`. A removal of an unrelated instance can leave a held pair valid. Removal of a winner or an aura used to link two interrupt reports requires rechecking it. [Event routing](../Main.lua) · [Delta handling](../SecondaryPortrait.lua)
2. `R.Refresh` checks that the host still belongs to the native frame. `R.UpdateHost` reconciles recipient interrupt state, runs readable aura helpers, and enables the appropriate native containers. Its `exactReads` table shares per-filter observations within that update. Blizzard's native slots can display a protected effect even when its spell ID is unavailable to Lua. [Host and main portrait](../AuraEngine.lua)
3. `R.ReconcileSecondaryPortrait` asks `R.GetReadableSecondaryAura` for the runner, reason, and primary, in that return order. A fresh verified pair can reuse the existing art and clock. When a read becomes restricted in combat, `retainCombatPositive` checks the prior pair's identity, current competitors, and expiry. `R.UpdateNativeSecondProbe` then decides whether the clipped second native button can show through. [Public election](../SecondaryPortrait.lua) · [Native fallback](../NativeSecondProbe.lua)

## Find a change and its tests

| Question | Source | Regression tests |
| --- | --- | --- |
| Why do the countdown digits move? | [PortraitTimerSpacing.lua](../PortraitTimerSpacing.lua) prepares fixed glyph regions and binds the current native clock. [Core.lua](../Core.lua) preserves the 90-second inclusive cutoff and decimal preference. Trace `R.AttachPortraitAuraClock` separately from public cooldown setter hooks; see [timer lifecycle](TIMER_LIFECYCLE.md). | [Fixed timer contract](../tests/portrait-timer-spacing.lua) · [Formatting boundaries](../tests/decimal-threshold.lua) |
| Why does first Target/Focus setup pause or remain incomplete? | `prepareGroupTree`, `makeButton`, `currentConstruction`, `scheduleConstruction` in [NativeSecondProbe.lua](../NativeSecondProbe.lua). Inspect `pendingButtons`, allocation receipts and `probe.groups`/`ready`; a registered native group alone is not completion. | [Ten-button allocation, deferred construction and swallowed initializer failure](../tests/native-second-probe.lua) |
| Why does combat exit repeat presentation work? | `R.ApplyPresentation`, `alignVisibleCountdown`, `R.RetryPostAuraLayouts` in [AuraEngine.lua](../AuraEngine.lua), `R.ApplyNativeSecondPresentation` in [NativeSecondProbe.lua](../NativeSecondProbe.lua), and combat-exit routing in [Main.lua](../Main.lua). Separate a changed clock/preference from an unchanged layout verification. | [Presentation reuse and late layouts](../tests/portrait-restoration.lua) · [Binding reuse](../tests/portrait-timer-spacing.lua) |
| Why does a spell win? | Find its numeric ID in [Spells.lua](../Spells.lua), then follow its category into `R.TIERS` and `R.CandidateFilters` in [Priority.lua](../Priority.lua). `candidateRank` applies those rules to readable candidates in [SecondaryPortrait.lua](../SecondaryPortrait.lua). | [Priority ordering](../tests/priority-overhaul.lua) · [Filter membership](../tests/secondary-filter-proof.lua) |
| Why did Kick appear or expire? | Follow `LOSS_OF_CONTROL_ADDED` or `LOSS_OF_CONTROL_UPDATE` to `R.GetSchoolInterrupt` in [Interrupts.lua](../Interrupts.lua). It reads active `SCHOOL_INTERRUPT` rows for the recipient, combines corroborated observations, and elects distinct effects before resolving their clocks. `updateSchoolInterrupt` owns the main presenter and expiry wake in [AuraEngine.lua](../AuraEngine.lua). | [Interrupt evidence](../tests/interrupt-evidence.lua) · [Secondary ordering](../tests/interrupt-secondary.lua) · [Target and Focus overlap](../tests/secondary-ownership.lua) |
| Why did the badge fall back? | Check `R.SecondaryOwnerVisible` and `R.ExactFilterAllowed` in [Core.lua](../Core.lua), then `knownRibbonMismatch` in [NativeSecondProbe.lua](../NativeSecondProbe.lua). The public badge covers Player, Target, Focus, and regular party portraits. The native runner-up ribbon covers Player, Target, and Focus. | [Public ownership and clocks](../tests/secondary-ownership.lua) · [Native ribbon](../tests/native-second-probe.lua) |
| Who owns form or pet artwork? | `R.ResolveWarriorStance` supplies Warrior stance evidence in [StanceState.lua](../StanceState.lua). `R.ResolveObservedPetSecondaryArt` verifies family art and the recipient GUID in [PetPortraits.lua](../PetPortraits.lua). `R.UpdatePetSecondaryFallback` manages its display in [PetSecondary.lua](../PetSecondary.lua). | [Stances](../tests/stance-state.lua) · [Pet fallback](../tests/pet-secondary.lua) |
| What can reach bjarkiCC? | [EvidencePublisher.lua](../EvidencePublisher.lua) publishes readable helpful observations on verified hostile player recipients. `R.PublishDerivedSnapshot` handles target-of-target and focus-of-focus first sightings. [SharedEvidence.lua](../SharedEvidence.lua) validates records and provides bounded replay through `BjarkiEvidenceV1`. A secure portrait image alone supplies no publishable spell ID. | [Derived evidence](../tests/derived-evidence.lua) · [Recovery](../tests/pending-evidence-recovery.lua) |

## Binding and verification

Target and Focus tokens can change occupants. Party member frames can be recycled. `hostStillCurrent` and `nativeUnitTokenMatches` check the physical owner. A player alias can borrow player-only evidence only while `UnitIsUnit` positively confirms it. A binding change requires a fresh clock even when the new recipient would show the same icon and digits. During teardown, `R.DestroyHost` retains unfinished restoration work for retry. [Host lifecycle](../AuraEngine.lua) · [Interrupt acquisition](../Interrupts.lua) · [Restoration tests](../tests/portrait-restoration.lua)

The [verification tool](../tools/verify.py) and [package workflow](../.github/workflows/package-addon.yml) syntax-check the 15 runtime modules and run all 35 test scripts on Lua 5.1 and 5.4. These tests verify modeled election results, requested native writes, refused setters, and simulated event order. A package/content check verifies distribution contents. Neither proves protected-client visibility, taint safety in every client state, final on-screen timer placement or live frame time. Use [testing](TESTING.md) for commands and the live acceptance matrix.
