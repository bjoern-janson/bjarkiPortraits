# Agent guidance — bjarkiPortraits

## Current assignment: read-only Codex forensic audit

The user wants an exhaustive diagnosis of bugs in the current development addon **without editing anything**. Follow [docs/CODEX_READONLY_AUDIT.md](docs/CODEX_READONLY_AUDIT.md).

**ZERO-WRITE RULE FOR THIS AUDIT:** Do not change, create, delete, rename, format, patch or overwrite repository files (including Lua, manifests, tests, documentation, configuration, generated reports or this AGENTS.md). Do not create branches, issues, pull requests, reviews, comments, commits, releases or artifacts. Do not push, merge, rebase, checkout, cherry-pick, stash, reset, clean or restore files. Do not install dependencies or run autofix. Keep suggestions and patch sketches **in the Codex response only**, not as written files.

Allowed: reading files and Git history, examining public Forever Blizzard UI source, static analysis, and already-existing non-mutating Lua 5.1/5.4 tests if installed. `luac -p` is parse-only; never use `luac -o`. In-memory experiments through `lua -e` or standard input may be used only without writing files. Never execute scripts known to modify the working tree. Record `git status --porcelain` and `git rev-parse HEAD` at start and finish; do not erase user-owned changes to get a clean result.

**Required checkout:** repository `bjoern-janson/bjarkiPortraits`, branch `feat/secondary-portrait-p1`, runtime `0.1.224-hostile-helpful-combat-fallback-test`. Last runtime-changing commit: `6936bb84f8e20fd48acefabbcc6701eab18c26ab`. The default `main` remains at older `0.1.178`; its code is **not** the audit target. This document preparation may advance the HEAD commit, but `Core.lua` and both TOCs must retain runtime version 0.1.224. If checkout/version mismatch: **stop and report it**, never silently switch branches.

Read the actual 13 runtime Lua modules and both TOCs. `Spells.lua` and `Priority.lua` are the source of truth for all 62 current lanes; historical documents contain superseded claims. Current guides: `README.md`, `ARCHITECTURE.md`, `KNOWN_ISSUES.md`, `docs/TESTING.md`. Long historical context: `docs/SECONDARY_PORTRAIT_PLAN.md`.

### Engineering contracts you may not recommend breaking

1. Inaccessible, protected, secret or unreadable aura values are UNKNOWN. No hidden spell-ID inference, guessed aura counts, unauthorized native button introspection, protected combat writes or taint-inducing arithmetic.
2. Main no-aura portrait is Blizzard class icon/3D. The secondary may show a genuinely different eligible effect or positive race/pet-family fallback; never manufacture an NPC race or second aura. No secondary on ToT/ToF/local PetFrame, though their main portraits work.
3. Preserve user-approved priorities and classifications (62 lanes). No unsolicited tier rebalancing. Preserve normal secondary 50px cell / 41px rim / 30px art; party 40/33/24; Player/party TOPRIGHT(-10,+12), Target/Focus TOPLEFT(+10,+12); Blizzard artwork, masks and font policies.
4. Native container lifetime: no invalid `SetUnit(nil)`, safe `SetEnabled(false/true)` pooling, GUID/target identity checks, no writing protected groups in combat. An absent/unreadable target must not inherit old debuffs.
5. CI mocks are **not proof of in-game protected client behavior**. Label all findings as source-proven, mocked-only, hypothesis or live-only. Compare critical API semantics to the Forever branch of `Gethe/wow-ui-source` instead of assuming Retail.

### Expected report

For each independent finding, give severity P0–P3, confidence and evidence status, source `path:line`, trigger/state transition, expected/actual outcome, minimal **non-writing** proof, competing explanation, precise fix plan for **later approval**, regression tests to add later, and live validation. Adversarially challenge apparent P0/P1 bugs. Give a ranked implementation queue, no minimum bug quota and no fake claims that anything was fixed. Finish with before/after working-tree status.

**Future exception:** If a future **separate, explicit** user instruction authorizes implementation, that later task may allow edits. This read-only contract applies to the present audit, not perpetually to every future coding task.
