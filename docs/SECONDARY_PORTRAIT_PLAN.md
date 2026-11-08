# Secondary portrait: two aura priorities + race identity

**Status:** P0 NATIVE-FEASIBILITY SPIKE COMPLETED, P1 VISUAL PROTOTYPE BUILT ON EXPERIMENTAL BRANCH (LIVE VISUAL VERIFICATION PENDING), P2 GLOBAL SECOND-WINNER BLOCKED  
**Baseline:** `0.1.178-bottom-harmful-consolidation-test` (2026-11-08).  
**Proposed next development milestone:** `0.1.179-secondary-portrait-prototype` (working name, not a release).  
**Source of visual direction:** 2026-11-08 in-game player-frame comparison: a tiny Blizzard Shaman Totem-like circular ring at the top corner of the main portrait.

## Prototype progress: 0.1.179-secondary-race-prototype (2026-11-08)

**P0 evidence / unresolved blocker.** Forever's [Blizzard_CustomAuraContainer.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_AuraContainer/Blizzard_CustomAuraContainer.lua) accepts fixed `AddAuraSlot` sort enums, then chooses **one** winner using `AuraContainerUtil.GetAuraSortComparator`. The supported inbound options do **not** allow an arbitrary custom rank comparator or an exclusion based on the winner of another tier. [Blizzard_AuraContainerSlots.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_AuraContainer/Blizzard_AuraContainerSlots.lua) retains candidate sets and their winner in the secure environment—not a public, untrusted combat-data channel. We cannot honestly elect a cross-tier global second while preserving primary semantics by reading those private fields or cloning 62 containers per badge. This is a **documented missing public mechanism**, not evidence that every possible future client feature is impossible.

**P1 prototype implementation.** `SecondaryPortrait.lua` creates a small, noninteractive, native Totem-style circular rim and mask on each eligible host except PetFrame. It mirrors toward the health bars and uses positively verified `ResolveRaceBaselineAtlas` identity. The large portrait no longer gets race-overlaid; when no aura wins, Blizzard’s native 3D/class-icon option is visible. The existing Skyborne fail-closed art rule is preserved. `/bp secondary on|off` enables/disables this circle; existing `/bp test` shows a deliberately **synthetic** secondary icon for screenshot calibration. The local pet keeps full primary aura priority and its pet-family foundation.

**P2 is not implemented.** There is *no global runner-up election*, live second aura or secondary countdown in 0.1.179. In ordinary play, the small circle shows only verified race identity (or hides). Do not represent it as a full two-aura release. In-game screenshots for Player/Target/Focus/ToT/ToF/party, UI scale and overlaps are still required before P1 is visually certified. The next real task is finding/validating a **supported secure top-two mechanism**; a less-complete readability-limited selection mode would need an explicit product decision.

**Regression:** `tests/secondary-portrait.lua` checks geometry, mirror, mask, native atlas UVs, teardown, recycled-unit clearing, toggle, test-only art and PetFrame exclusion. CI runs Lua 5.1 and 5.4 including the new script.

---

## 1. Product decision and scope

Preserve the current high-priority large portrait, and add **one small secondary circle** next to the top corner of each eligible Blizzard portrait. The secondary circle represents the **second-highest verified, distinct aura/state**. When no second eligible effect exists, it shows the unit's **verified race portrait** if one is available.

Race artwork is **never drawn inside the main portrait** by bjarkiPortraits after this feature. The main portrait returns to the **native Blizzard portrait**, including Blizzard's own class-icon-versus-3D-portrait option, whenever it has no eligible higher-priority aura/state.

The primary must not be weakened, delayed or misranked to make the secondary appear.

**Enabled units:** `player`, `target`, `focus`, `targettarget` (ToT), `focustarget` (ToF), `party1` through `party4` on the regular Blizzard party frames.  
**Excluded:** local `pet` and party-pet frames for this feature. PetFrame **retains** its full single-portrait aura priority engine and pet-family artwork. Raid-style party/raid frames are likewise out of scope; do not hook arbitrary CompactUnitFrames.

There should be no additional portrait-priority tier, no new spell-ID classification, no extra guessing about states, no global polling loop, no addon-config framework, and **no duplicate copy of every tier container for every host**.

## 2. Visible state contract

| Eligible effects | Main portrait | Small circle |
| --- | --- | --- |
| Zero | Native Blizzard portrait or configured class icon | Verified race portrait, else hidden |
| Exactly one | Highest-ranked effect (including eligible state witness) | Verified race portrait, else hidden |
| Two or more | Highest-ranked effect | **Second-highest verified, distinct effect** |
| Second effect unreadable / its rank unprovable | Unchanged trustworthy main portrait | Verified race if safe, else hidden |
| Unit absent, recycled, vehicle-bound, or Edit Mode placeholder | Restore/retain native content according to existing host lifecycle | Hidden; never retain the previous unit's icon |

“Race” here means the positive unit-race evidence and supported artwork of `Core.lua`; it is not an NPC-family, inferred faction, guessed race, or pet identity. In particular, the **Skyborne** art safety policy stays: use a verified face atlas or leave the badge hidden. **Never substitute Blood Elf artwork.**

**Race fallback is identity, not an aura.** It never displaces an eligible second aura, participates in rank comparisons, inherits an aura timer, or uses a spell-ID slot.

The existing priority numbers remain authoritative. Example: a stun (320) outranks a defensive (290), which outranks Offensive (280). Two effects from the same priority lane must also be eligible to occupy the two circles when their distinct identity and order are available. An unknown second winner is **not** a license to show an arbitrary lower-tier effect.

## 3. Geometry / visual language

Reference native Blizzard art: `Interface/AddOns/Blizzard_UnitFrame/Mainline/TotemFrame.xml` from `Gethe/wow-ui-source` `forever` uses **`UI-HUD-UnitFrame-TotemFrame`** for a 30 × 30 border, a 22 × 22 icon and a `CircleMask` inside a 37 × 37 template. **Use these as reference dimensions/art**, not the native interactive TotemButton itself.

- Draw an addon-owned non-clickable circle using Blizzard artwork, native spell icons and a circular icon mask; it must not inherit totem dismissal, cooldown state or callbacks.
- Proposed first pass: **30 × 30 rim / 22 × 22 image** on large portraits, scaled proportionally for compact ToT/ToF and party frames after screenshot measurements. These are **starting values, not accepted final calibration**.
- Anchor near the top edge **on the side facing the health bars**. Player / standard party portraits with bars extending right: upper-right. Target / focus portraits with bars extending left: upper-left. Verify the actual orientation of ToT/ToF from Blizzard templates instead of guessing from the unit-token name.
- Prefer fixed out-of-combat frame-template geometry or an explicit validated per-frame orientation map. Do not inspect secret health-bar fill geometry in combat to decide where the badge belongs.
- A small offset outside the existing portrait rim should visually connect the circles without obscuring the main portrait, bars, frame name, level, PvP/combat/rest indicators, party ready check, or target/focus buff rows.
- Use Blizzard's atlas UVs/texcoords as authoritative. Never overwrite them with generic icon cropping. Treat icon cropping and circle-mask alignment separately; retain existing native border and mask ownership.
- No new click region, drag handler, tooltip interception or action bindings. Optional secondary-aura tooltip can be investigated separately **only if it is safe and does not steal clicks**.
- Secondary aura cooldown uses the existing `/bp decimals` policy (**one decimal strictly below 10 seconds**), no invented duration for static witnesses. Badge numerals may need an outside/below-ring label due to size. Race badge has **no timer, swipe or glow**.
- The main portrait's current fonts, masks, timer positions, frame geometry and native interaction remain unchanged.

## 4. Election and evidence contract (hard part)

**Current implementation:** `AuraEngine.lua` creates a native `CustomAuraContainerTemplate` + `AddAuraSlot` **per priority tier per host**. Higher frame levels display over lower levels, supplemented by guarded readable and static-state witnesses. This produces **a visual winner**, not an accessible, globally ranked list of two winners. `Priority.lua` uses reverse `AuraInstanceIDOnly` inside native lanes; some complete readable tiers explicitly prefer verified application time.

The new secondary must preserve this **single source of priority truth**. Define a bounded election abstraction conceptually returning:

```text
SelectTwo(unit):
  first:  verified candidate or nil  (must agree with today's main winner)
  second: verified distinct candidate or nil
  proof:  authoritative source / readability / identity needed for each
```

Candidate identity must be a trustworthy current aura instance ID when available, or a positively established, non-fabricated state witness. Do not confuse a spell ID with an occurrence ID, and do not show the same occurrence twice because it appears through both native and readable paths.

Ordering: greater numeric priority wins; within one tier use the current source's documented native tie-break, or the complete readable application-time election **only when its evidence is sufficient**. Do not make “last applied” a promise for Tracking: aura refreshes can retain an instance ID.

**Feasibility gate before implementation:**

1. Inspect Blizzard's `CustomAuraContainer` / aura-slot native interfaces on the current Forever client. Determine whether two *distinct, globally ranked* candidates can be elected and presented securely **without querying secret data from addon Lua**. Prototype with two buffs from **the same tier** and two from different tiers.
2. Confirm that the main portrait winner can remain exactly equivalent to the existing engine while the second is selected. Include readable-helper/static-state cases, native exact lanes and semantic fallback lanes; distinguish current screenshots from true proof of candidates.
3. Keep native aura processing native. Prefer **one shared candidate/election mechanism** that can project first and second; do **not** create a duplicate 62-lane stack for secondary on every host just because the current implementation has per-tier containers.
4. When a global second winner cannot be proven under combat secrecy, **do not fake it** by taking the next-lowest visible lane, guessing cooldowns or reading forbidden button internals. Fall back to the race/empty badge while preserving the primary. If the native client fundamentally cannot provide the requested behavior, document that limitation and stop for a design decision rather than shipping a falsely described “second highest” icon.

State-derived Ghost/form/Warrior stance/resurrection witnesses must be ranked under the **existing** priority policy, not treated as incidental race art. A native container and its readable helper may refer to the same current aura: they must not consume both slots. No historic or retracted evidence may be silently promoted back to a current portrait.

## 5. Implementation boundaries

**`Priority.lua` / `Spells.lua`:** leave all exact IDs, numeric tiers and filters unchanged. Only add a *selection interface* if the client feasibility result proves it can be implemented without duplicate policy tables.

**`AuraEngine.lua`:** refactor presentation into a primary surface and optional secondary surface owned by one host. Introduce second-slot rendering/timer/mask, but keep the existing main portrait untouched until the election path is proven. Move `createRaceBaseline` / `updateRaceBaseline` artwork to the secondary-only fallback. Do not leave a hidden main race texture that can reappear during aura handoffs.

**`Core.lua`:** own badge geometry, safe race-art lookup and orientation by verified frame layout. Preserve `ResolveRaceBaselineAtlas` restrictions, including Skyborne. Respect native class-icon option instead of forcing a class atlas.

**`Main.lua`:** reuse existing bounded/event-driven unit refresh and pooled party-frame lifecycle. Do not add `OnUpdate` scans or periodic re-election. A party frame may be recycled after an aura event; check live identity before showing either portrait.

**`PetPortraits.lua`:** leave local PetFrame's one-portrait aura host and family foundation alone. Do not make the secondary race system classify demons/totems/pets as player races.

**`Commands.lua`:** extend `/bp inspect <unit>` / layout diagnostics with provenance for `first`, `second`, `badgeFallback` and evidence/access reason. If a user-facing toggle is necessary, prefer one simple `/bp secondary on|off`, off during prototype, on after live certification. Avoid a new options panel.

**Cleanup:** all badge textures, masks, cooldowns and slot assignments must be hidden/destroyed on host teardown, native portrait restoration, vehicle binding, party pool handoff, frame-scale changes or /reload. Never retain old unit GUIDs/icon textures in a recycled host.

## 6. Phased work (deliverables and exit criteria)

**P0 — Source and native feasibility spike (no user-facing feature)**  
Document actual native API primitives and guarded second-winner evidence. Produce executable test for (a) two distinct auras in different lanes, (b) two in one lane, (c) restricted hostile unit, (d) duplicate native/readable occurrence. **Exit:** a credible plan for exact top-two selection with bounded cost and preserved first winner, or an explicit blocker.

**P1 — Geometry/identity prototype**  
For `player`, `target`, `focus`: add a noninteractive secondary rim and verified race fallback. Remove race from the large portrait fallback; restore native class/3D portrait. Compare with the user screenshot. Check corner mirroring, artwork masking and countdown visibility at multiple UI scales. **Exit:** no visual collisions, stable native portrait ownership and safe Skyborne fallback.

**P2 — True second-winner presentation**  
Wire the shared, feasibility-proven election to both circles; ensure source identification, distinctness, priority correctness, same-tier ties and cleanup on expiration. **Exit:** native/readable cross-lane cases pass without guessing when access is restricted.

**P3 — Compact and party-frame rollout**  
Extend to ToT, ToF and the four normal party frames via existing host pool, with smaller artwork and independently measured anchors. PetFrame remains one portrait. **Exit:** combat-safe unit recycling, visibility, party swaps, Edit Mode, pet/vehicle handoff and frame-scale changes pass.

**P4 — Live verification and release**  
Use test mode and controlled in-game cases, not just Lua mocks. Once the primary is never regressed and two winners are credible across supported relations, enable the small badge by default. Update README/ARCHITECTURE/KNOWN_ISSUES and package. **Exit:** regression suite + live screenshots approved; document any client-imposed gaps.

## 7. Acceptance matrix / must-not-regress

- Native Blizzard character-model vs class-icon option remains respected on main when no aura is selected.
- Race artwork **only in secondary**; unknown/non-player race leaves the fallback hidden, never a guessed race icon.
- Zero, one, two, three-or-more effects elect correctly; when second is not provable, no bogus second.
- Distinct highest/second effects inside **one priority lane**, across two lanes and across native+readable sources; no duplicate aura instance on both circles.
- A 330 immunity / 320 stun / 280 offense example maintains numeric priority; exact lower-tier 0 status never jumps ahead on combat entry.
- Cast-only WotF and school-lockout assumptions remain absent; no fabricated duration for a state.
- Countdown placement and decimals below 10 seconds work independently in both circles, including nil/permanent durations.
- Player, Target, Focus orientation, compact ToT/ToF, party1–4, known races, Skyborne, pets, NPCs and unreadable identity all have appropriate fallback.
- Party member leave/join, frame pool reuse, vehicle swap, changing target/focus, corpse/ghost, combat lockdown, scale changes, disconnect/reconnect and /reload leave no stale icon.
- Primary remains clickable, context menus/targeting/health bars untouched; badge is noninteractive and cannot steal mouse.
- No per-frame periodic aura-scan, no duplicated full-tier stack; bounded work on existing lifecycle events; measure CPU/memory against `0.1.178` at 10 tracked units.
- All existing Lua 5.1 / 5.4 tests continue passing. Add new simulated tests and explicit **in-game** proofs; a static source check alone is insufficient.

## 8. Deliberately unresolved until prototype

- Can Forever's secure aura container provide a genuine second winner after global priority reconciliation across exact/semantic/readable tiers? **This determines feasibility.**
- How should a second verified static state with no timer be shown relative to a native aura in the same numeric tier?
- Exact compact badge rim/icon pixels and countdown placement require real screenshots; the Shaman border atlas is a visual starting point, not a mandated widget.
- On a target that is not positively a player, secondary fallback remains hidden rather than inventing a generic race or creature icon.

**Scope control:** this document records the agreed feature direction and technical acceptance tests. **0.1.178 has neither. Experimental 0.1.179 implements the race-only/test badge, but NOT the two-winner algorithm.** Do not silently change numeric priorities or rewrite the current native aura-election behavior while implementing visual scaffolding.
