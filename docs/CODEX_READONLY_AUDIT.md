# Codex deep audit handoff — v0.1.224 (READ ONLY)

**Prepared 2026-11-09.** Repo: [bjoern-janson/bjarkiPortraits](https://github.com/bjoern-janson/bjarkiPortraits). Target: `feat/secondary-portrait-p1`, runtime `0.1.224-hostile-helpful-combat-fallback-test`. Last runtime source change: `6936bb84f8e20fd48acefabbcc6701eab18c26ab`.

## Task to paste into Codex

> Perform a rigorous, multi-pass, **READ-ONLY forensic bug audit** of bjarkiPortraits 0.1.224, development branch `feat/secondary-portrait-p1`. Spend substantial reasoning effort finding source-supported, repeatable bugs and test blind spots—especially combat/secret aura handoffs, the native second-portrait renderer, event timing, recycling, and protected-frame safety. Read `AGENTS.md` and `docs/CODEX_READONLY_AUDIT.md` first. You may inspect source/history/upstream Forever APIs and run existing *non-writing* Lua tests. **Do not edit or create files, commit, push, open PRs/issues, switch branches, install packages or change any external state.** Deliver prioritized findings **in your final answer only**, each with source `file:line`, a reproducible trigger, alternative hypotheses, narrowly scoped proposed fix and regression tests that would be written only after separate approval. Show start/end git status. No speculative minimum bug quota.

## Mandatory baseline & truth hierarchy

1. Run `git rev-parse --abbrev-ref HEAD`, `git rev-parse HEAD`, `git status --porcelain`. If wrong branch/version, STOP (do not checkout). Source version is `Core.lua` / both `.toc`, not the later docs-only commit SHA.
2. Read `README.md`, `ARCHITECTURE.md`, `KNOWN_ISSUES.md`, `docs/TESTING.md` and `docs/PRIORITIES.md`.
3. Inspect actual `Spells.lua`, `Priority.lua`, `SecondaryPortrait.lua`, `NativeSecondProbe.lua`, `AuraEngine.lua`, `Main.lua`, `Core.lua`, `StanceState.lua`, `SharedEvidence.lua`, `EvidencePublisher.lua`, `PetPortraits.lua`, `PetSecondary.lua`, `Commands.lua`. Check both TOC load orders (13 modules). Historical `docs/SECONDARY_PORTRAIT_PLAN.md` includes superseded experiments; code wins.
4. Cross-check suspicious native assumptions against **Gethe/wow-ui-source, forever branch**, primarily `Blizzard_AuraContainer/Blizzard_CustomAuraContainer.lua`, `Blizzard_ManagedAuraContainer.lua`, `Blizzard_AuraContainerGroups.lua`, `Blizzard_AuraContainerUtil.lua`, and `Blizzard_FrameXMLUtil/AuraUtil.lua`. Don't infer that Retail behaves identically.

## Known incidents: reproduce *mechanism*, not just screenshot

| Build(s) | Symptom | Existing source-level attempted repair | What's NOT proven |
| --- | --- | --- | --- |
| 0.1.188–190 | Multiple buffs but race instead of second aura | `SecondaryPortrait.lua` was initialized before `Priority.lua` in TOC; fixed order and lazy tier init | Earlier green mock tests used wrong module order |
| 0.1.191 | Ghost first; Boosted Rest should be second | Static Ghost is primary witness; bottom harmful is eligible when readable | Restricted combat still denies private identities |
| 0.1.194–217 | NPC Wendigo with two debuffs no secondary; friendly player multiple buffs still race | Native second ribbon, first-time `SetEnabled(true)`, removal of false `not-two-presentable` veto | Screenshot cannot reveal all candidate filters |
| 0.1.215–216 | Rend from former mob appearing on untagged Coyote/boar | `SetUnit(nil)` was invalid; reset through `SetEnabled(false)`; positive GUID handoff | Live combat swaps still may hide until safe rebind |
| 0.1.221–222 | Same purple paw in primary and small circle after combat start | Scope `HostileHelpful` and disjoin native semantic groups; public same-ID dedup | Screenshot does not prove numeric spell or instance IDs |
| 0.1.223–224 | Secondary vanished after Fear possibly ended; Coyote still had other debuffs | Defer optional HostileHelpful activation without hiding active native harmful groups | Missing `/bp secondary debug target` / actual IDs means exact cause unknown |
| 0.1.223 | Square icon border peeking through circle | 2/64 ordinary aura UV crop; local PetFrame retains 3/64 | Source tests cannot certify pixels at every UI scale |

Separate **observed live issue**, **source-confirmed defect**, **modeled regression** and **unverified hypothesis**. Don't treat a fix history entry as universal live proof or assume an old screenshot is still broken.

## Six independent investigation passes

### Pass 1 — Main vs second aura correctness
Inspect `SecondaryPortrait.lua` `collectCurrentAuras`, `candidateRank`, `compareCandidates`, `tryGetAuraStart`, `R.GetReadableSecondaryAura`, `R.ReconcileSecondaryPortrait`. Build a mental truth table for two/three distinct exact auras, one spell with multiple instance IDs, semantic overlap, nameplate-only, inaccessibly filtered spells, timed vs permanent, same-tier ties, and recency. Compare the *actual main presenter* from `AuraEngine.lua` against claimed public first priority; special Ghost, Stance/Form, target NPC helpful/hostile and player aliases must not break first/second correspondence.

### Pass 2 — Native secure groups & false runner-up
Inspect `NativeSecondProbe.lua` `groupPlans`, group sort/layout and two-cell clipping. Blizzard evaluates groups **independently**: can one aura own two group frames? Check overlapping `Important`, `BigDef`, `ExternalDef`, `CrowdControl`, `PriorityDebuff`, `SmallFriendlyHarmful`, `HostileHelpful`, all 62 exact/semantic ranks, and whether negative filters actually work under Forever secret restrictions. Inspect group setup initial enabled state, 80 group cap, disabled groups, duplicate groups and pooled reuse. The native second cell is presentation, not a public API to inspect or infer secure winner IDs.

### Pass 3 — Combat, Fear removal, events & one-shot timers
Follow `Main.lua` `UNIT_AURA` → `R.NoteSecondaryAuraEvent` → `R.Refresh` → `AuraEngine.UpdateHost` → public election/native fallback. Attack `onlyUnrelatedRemovals` and `retainCombatPositive`: Fear expires, primary expires, second expires, only a third unrelated aura removed, a full/secret update, unit swap, time expiry, stale callback/generation. Determine when the known positive can continue versus **must** be revoked. Inspect `PLAYER_REGEN_ENABLED`, queued updates and missed event/recovery paths. Don't keep an expired Fear to make a badge look populated; don't hide two remaining real effects just because optional helpful group cannot be enabled midcombat.

### Pass 4 — Protected data & unit-frame lifecycle
Check `R.CanAccess`, `R.ReadAuraField`, `R.SafeBool`, `R.SafeString`, relation tri-state, `UnitGUID` and `UnitIsUnit`. Audit every protected setter, `pcall` failure, native `SetUnit` / `SetEnabled` / `UpdateAllAuras` and `SetAuraGroupEnabled` in and out of lockdown. Exercise target→target same token new GUID, Target↔Focus same self, hostile→friendly and friendly→hostile, party frame pooling, Hunter/Warlock pets, no race for NPCs, Blizzard PetFrame, ToT/ToF, disabled state. Inspect native restoration after disabling, frames changing ownership, and taint risk.

### Pass 5 — Performance, evidence bus & presentation
Verify bounded 48 per-polarity scans, bounded native filter probes, 80-group limit, coalesced queues, cleanup after host destruction, timers with `C_Timer.After` and no unbounded updates. Check `SharedEvidence.lua` and `EvidencePublisher.lua` for positive-only facts, identity/generation safety and unintended authority for hidden auras. Check timer decimal threshold strictly below 10, 60s visibility, black/white color/font, image masks, UV 2/64 (PetFrame 3/64), race atlas tile coordinates, current 50/41/30 and 40/33/24 geometry.

### Pass 6 — Adversarial audit OF tests
This matters greatly: v0.1.190 load-order passed wrong-order mocks, v0.1.216 needed realistic string-only `SetUnit` behavior, v0.1.217 needed first-build `SetEnabled(true)`. Challenge mocks that assume native groups are exclusive, identity flags always readable, combat writes succeed, repeated unit-token setting refreshes, protected layout never changes or accessible AuraData implies native eligibility. Cross-check `tests/native-second-probe.lua` against upstream `AuraContainerGroups`, `tests/secondary-aura-election.lua` against actual priority order, and `tests/secondary-load-order.lua` against TOCs. A model not capable of reproducing true secure behavior must be labeled as such.

## Suggested non-mutating checks

Start/end: `git status --porcelain` and `git rev-parse HEAD`. Only if Lua interpreters already exist, follow the explicit tests in `.github/workflows/package-addon.yml` using `luac5.1 -p` / `luac5.4 -p` and `lua5.1 tests/<existing-script>.lua` / `lua5.4 ...`; confirm tests are non-writing before executing. Do **not** invoke packaging, output redirection to repo files, code generators, installers, `git clean`, `git reset` or `git stash`. In-memory `lua -e` experiments are fine. Do not claim a sandbox simulation is live-client proof.

## Required Codex response

- **Audit identity:** branch, version, HEAD, initial/final working-tree state, concrete tests run and results, native source references.
- **Executive summary:** most important independent findings; P0–P3 severity counts, confidence, and highest-risk test-model gaps; no minimum bug quota.
- **Each finding:** ID; P0/P1/P2/P3; confidence and status (`source-confirmed` / `modeled` / `hypothesis` / `live only`); exact `path:line`; before→event→after state/identity/permission path; expected vs actual; minimal non-mutating reproducible proof; alternative explanation and attempt to falsify; smallest proposed fix for a **later authorized implementation**; tests to add later; effect on priorities, taint or visual stability.
- **Second independent skeptical pass** on each P0/P1, downgrading speculative findings instead of padding the result.
- **Prioritized authorized-fix plan** (no applied patch), separated from live-only uncertainties. No unrequested priority, artwork or layout redesign.
- **No-change statement** with final Git status. Do not claim to have implemented any fix or to have seen actual in-game secrets.
