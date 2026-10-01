# bjarkiPortraits Architecture

> Engineering notes for **WoW: Forever**.
>
> This document records the architecture, security/taint constraints, priority
> model, Blizzard implementation details, performance findings, failure modes,
> and live-test lessons behind bjarkiPortraits.
>
> Reference runtime: **0.1.56-local**.

---

## 1. Purpose

bjarkiPortraits overlays one prioritized aura icon on Blizzard portrait surfaces
for:

- `player`
- `target`
- `focus`
- `targettarget`
- `focustarget`

It also provides optional pet-family portrait foundations for the local PetFrame
and observed player pets.

The addon is deliberately **not** a general aura frame. Its job is to compress
combat state into one high-signal portrait slot while preserving Blizzard's
native unit frames, chrome, portrait masks, cooldown machinery, and protected
state model.

The core design target is:

> **Show the highest-priority legally observable state without pretending that
> inaccessible aura identity is absence.**

That sentence drives most of the architecture.

---

## 2. File responsibilities

### `Core.lua`

Owns shared runtime primitives:

- version/runtime table
- tracked-unit list
- SavedVariables defaults
- secret/accessibility helpers
- player/hostile relation helpers
- NeverSecret queries
- exact-filter authorization policy
- portrait discovery
- point capture/restore
- numeric timer formatter

### `Spells.lua`

The spell/aura corpus.

This is the semantic inventory: explicit spell IDs grouped into conceptual
families such as roots, stuns, slows, class buffs, defensives, food/drink,
DoTs, immunities, and special Forever mechanics.

### `Priority.lua`

Turns spell families into **runtime lanes**.

A lane has:

- a stable key
- Blizzard aura filter string
- priority level
- helpful/harmful polarity where exact
- exact spell-ID set, or
- semantic candidate filters

This file is the policy boundary between the corpus and the engine.

### `AuraEngine.lua`

Owns portrait hosts, Blizzard `CustomAuraContainer` instances, readable scans,
secure/readable arbitration, icon placement, cooldown presentation, and
state-derived witnesses.

### `PetPortraits.lua`

Adds family/class visual foundations for player pets while preserving native
portrait chrome and ownership semantics.

### `Main.lua`

Owns lifecycle and unit-scoped event wiring.

### `Commands.lua`

Debug/test/toggle surface. `/bp debug` exposes the engine's evidence state and
is intentionally useful for diagnosing secrecy/relation problems.

---

## 3. The two-plane aura model

Forever cannot be treated like old Classic aura Lua.

An aura may be visible to the player while some of its fields, especially
identity, are inaccessible to addon Lua or unavailable for a particular
relation.

bjarkiPortraits therefore uses two evidence planes.

### Plane A: readable Lua evidence

When Blizzard exposes aura fields to Lua, the addon can inspect things such as:

- spell ID
- duration
- expiration time
- dispel type
- source flags
- aura instance ID
- priority metadata

Readable evidence is used for:

- exact readable witnesses
- recency elections
- special state interpretation
- relation-aware fallback suppression
- diagnostics

### Plane B: Blizzard-managed secure aura selection

`CustomAuraContainer` and candidate filters allow Blizzard to make selection
choices using information the addon may not itself be allowed to inspect.

The addon supplies:

- filter strings
- candidate filters
- exact spell-ID sets where authorized
- priority lane geometry

Blizzard owns the protected parse and decides what can legally match.

### Why both planes exist

Readable Lua alone misses protected identities.

Secure filtering alone cannot always tell the addon *why* something matched,
and relation restrictions can make an exact whitelist unavailable on one unit
while valid on another.

The engine therefore treats the two planes as complementary evidence sources,
not interchangeable APIs.

---

## 4. UNKNOWN is not false

This is the most important correctness rule in the addon.

If a value is secret, inaccessible, missing because of relation rules, or an API
cannot safely answer, the result is **UNKNOWN**.

UNKNOWN must not silently become:

- false
- zero
- nil-as-absence
- "not a player"
- "not hostile"
- "aura not present"

`Core.lua` centralizes this discipline with:

- `R.IsSecret`
- `R.CanAccess`
- `R.SafeBool`
- `R.SafeString`
- `R.ReadAuraField`

The rule is especially important before:

- boolean branching
- arithmetic
- string matching
- table indexing
- identity inference

Historical failures in Forever showed that even an apparently harmless boolean
check can become a taint boundary when the value is secret.

---

## 5. Relation-aware exact identity

Exact spell-ID filtering is not universally legal.

`R.ExactFilterAllowed(unit, helpful, spellIDs, allowNeverSecret)` encodes the
current conservative policy.

Broadly:

- helpful auras on self are allowed
- helpful auras on controlled/group/assistable units can be allowed
- harmful auras on non-assistable units can be allowed
- the opposite relation fails closed
- an all-NeverSecret exact set can bypass the ordinary relation test when the
  lane explicitly opts into that policy

A subtle bug fixed earlier is worth preserving in documentation:

```lua
helpful and assist or not assist
```

is **not** a safe spelling of the policy. If `helpful == true` and
`assist == false`, Lua falls through to `not assist` and returns true, thereby
authorizing hostile helpful identity by accident.

The current implementation uses explicit branches.

---

## 6. NeverSecret: useful, but the current gate is conservative

`C_Secrets.GetSpellAuraSecrecy(spellID)` can identify a spell as
`Enum.SecrecyLevel.NeverSecret`.

bjarkiPortraits caches only known answers. UNKNOWN is not cached as false.

The current helper `R.SetIsNeverSecret(spellIDs)` requires **every** member of an
exact family to be NeverSecret before granting the family-level bypass.

### Important architectural finding

Blizzard's own `AuraContainerUtil.CanApplyIdentityCandidateFilters` evaluates
identity permission **per aura**, not necessarily as one binary property of the
whole whitelist.

That means a mixed family can contain:

- members whose identity is legally matchable,
- members whose identity is not,

without requiring the entire slot to be conceptually discarded.

The current whole-family gate is therefore intentionally conservative but not
maximally expressive.

Future refactoring should consider a relation authority model such as:

- COMPLETE
- PARTIAL
- NONE

rather than a single boolean.

This becomes particularly important before large NPC/mechanical-equivalence ID
expansion.

---

## 7. Priority lanes are the runtime unit

The spell taxonomy and runtime lane topology are separate concepts.

A conceptual category can overlap another category in `Spells.lua`, but the
**exact runtime lane sets must not accidentally overlap** unless the overlap is
intentional and has a single owner.

Example:

- stuns are conceptually crowd control
- the runtime `Stun` lane owns stun IDs at priority 320
- `Control` is built as `interrupts ∪ (cc - stuns)` at priority 310

This prevents one exact spell from existing in two sibling secure lanes where
frame/update order could determine the winner.

### Current priority spine

Lower number = lower priority.

| Level | Lane | Notes |
|---:|---|---|
| 0 | CampfireNearby | absolute bottom |
| 1 | BoostedRest | harmful camp/rest state |
| 2 | SmallFriendlyHarmful | broad derived-friendly fallback |
| 10 | Plainsrunning | includes Elemental Blessing |
| 50 | TravelUtility | travel effects |
| 59 | RighteousFury | dedicated baseline |
| 60 | PaladinAura | Paladin auras + warlock armor family |
| 70 | BloodPact | dedicated class baseline |
| 80 | Scrolls | scroll buffs |
| 90 | BaselineClass | class buffs + Camp Benefits |
| 110 | WellFed | includes Minor Troll's Blood Elixir family additions |
| 120 | Thorns | dedicated lane |
| 130 | ElementalShield | Lightning Shield family |
| 150 | SelfState | other self states + Frost Armor |
| 150 | FrostArmorSignature | hostile-NPC semantic fallback |
| 150 | HostileHelpful | protected hostile-helpful fallback |
| 160 | Mobility | Ghost Wolf/Cheetah family |
| 170 | LoneWolf | dedicated |
| 180 | HuntersMark | below DoTs |
| 190 | DoTs | damage-over-time family |
| 200 | LowDebuff | Curse of Weakness/Faerie Fire-style low debuffs |
| 210 | Seal | Paladin seals |
| 220 | Slows | explicit slows |
| 220 | ChilledSignature | semantic Chilled fallback |
| 228 | WeakenedSoulFallback | broad semantic fallback |
| 229 | RecentlyBandaged | exact harmful lane |
| 230 | WeakenedSoul | exact |
| 238 | PriorityDebuff | Blizzard priority-aura semantic lane |
| 240 | Forbearance | exact |
| 241 | ResSickness | exact + readable fallback path |
| 242 | HonorlessTarget | exact helpful |
| 250 | Shield | Power Word: Shield family |
| 260 | FoodDrink | food, drink, first aid/bandage channels |
| 261 | Innervate | dedicated |
| 270 | Utility | includes Welcoming Campfire |
| 279 | Important | Blizzard IMPORTANT semantic lane |
| 280 | Offensive | offensive cooldowns |
| 288 | ExternalDef | Blizzard external defensive semantic lane |
| 289 | BigDef | Blizzard big defensive semantic lane |
| 290 | Defensive | explicit defensives, including Shatter Curse |
| 300 | Roots | exact roots |
| 309 | CrowdControl | Blizzard CC semantic lane |
| 310 | Control | interrupts + non-stun explicit CC |
| 320 | Stun | exact stuns |
| 330 | ImmunityHarmful | Ghost/death harmful family |
| 330 | Immunity | helpful immunities |

The table documents intent, not a promise that every lane is available on every
relation. Relation/secrecy authority still governs exact matching.

---

## 8. Equal-priority effects need one election surface

If two categories truly share priority, they should generally share one actual
runtime lane.

Why:

Two sibling containers at the same priority can both produce buttons. Their
relative outcome can then depend on frame/container update order rather than an
explicit recency rule.

Examples already consolidated:

- Welcoming Campfire shares the `Utility` lane
- Elemental Blessing shares `Plainsrunning`
- Camp Benefits shares `BaselineClass`

Within one lane, reverse `AuraInstanceID` ordering provides the intended recent
winner.

---

## 9. Secure container architecture

The current implementation creates one `CustomAuraContainer` per runtime lane
per host.

With ~46 lanes and 5 hosts this is roughly **230 managed containers**.

This works and has been carefully stabilized, but it is not the end-state
architecture.

### Important Blizzard-source finding

A single `CustomAuraContainer` supports multiple AuraSlots.

`ManagedAuraContainer` can deduplicate parse filters **within the same
container**.

The current lane set uses only a small number of distinct filter strings,
roughly these families:

1. `HELPFUL`
2. `HARMFUL`
3. `HELPFUL|INCLUDE_NAME_PLATE_ONLY`
4. `HARMFUL|INCLUDE_NAME_PLATE_ONLY`
5. `HELPFUL|IMPORTANT|!BIG_DEFENSIVE|!EXTERNAL_DEFENSIVE`
6. `HELPFUL|EXTERNAL_DEFENSIVE`
7. `HELPFUL|BIG_DEFENSIVE`
8. `HARMFUL|CROWD_CONTROL`

### Safer future consolidation

A conservative next architecture is:

> **one container per filter-string cohort per host**

That would reduce ~230 containers to roughly ~40 while preserving lane identity
as separate AuraSlots.

Only after that is proven should a one-container-per-host design be considered.

### Why consolidation matters

Each visible/enabled managed container participates in Blizzard update paths,
including UNIT_AURA handling/private-aura machinery and internal dirty-phase
work.

The addon itself has no OnUpdate loop, but Blizzard's managed containers still
have lifecycle cost.

---

## 10. Do not churn slot state

Blizzard's `CustomAuraContainerSharedMixin:SetAuraSlotEnabled` can trigger a full
`UpdateAllAuras()` path even when the desired semantic state appears unchanged
from the addon's point of view.

Therefore future multi-slot consolidation should cache desired slot enabled
states and call the API only on actual transitions.

By contrast, `AuraContainerSharedMixin:SetEnabled(enabled)` is internally
guarded against redundant same-state calls.

Historical concern that repeated same-state `SetEnabled` itself caused rebuild
churn was incorrect.

The expensive operations to watch are:

- forced `UpdateAllAuras()`
- unnecessary slot toggles
- needless managed-container count

---

## 11. Readable scans: current shape and future snapshot design

Several special mechanisms perform readable aura walks with different filters.

Examples include:

- BaselineClass recency
- Utility/Welcoming Campfire arbitration
- hostile helpful fallback
- Slows
- Boosted Rest
- Resurrection Sickness
- readable exact witnesses

This is correct but creates repeated walks over overlapping aura surfaces.

### Future optimization

For each host update, snapshot each required filter exactly once, then derive all
readable mechanisms from those snapshots.

However, do **not** merge filter domains just because they sound similar.

In particular:

- `HARMFUL`
- `HARMFUL|INCLUDE_NAME_PLATE_ONLY`

must remain distinct until equivalence is proven for the relevant Forever APIs.

A snapshot refactor must preserve completeness/UNKNOWN semantics, not merely
reduce loops.

---

## 12. Host lifecycle and portrait layering

The addon targets native Blizzard portraits rather than building replacement
unit frames.

For a normal host, the construction pattern is:

1. discover the native portrait/mask/frame
2. capture the portrait's original parent and points
3. create an addon layer at a safe strata/frame-level below native chrome
4. reparent the portrait while preserving geometry
5. create the aura anchor/button surfaces in that layer
6. leave the native ring/chrome above the addon layer
7. restore original parent/points during teardown

This architecture exists because earlier direct layout approaches caused
`UntrustedLayoutScriptExecution` and other protected-layout failures.

### Non-negotiable lesson

Do not casually replace this with broad `SetAllPoints`/reanchor behavior on
protected native frames.

The visual result may look trivial while the protected-layout dependency is not.

---

## 13. Combat-time structural mutation

Structural host teardown/rebuild is avoided during combat.

If a rebuild is needed while protected state is active, queue it for
`PLAYER_REGEN_ENABLED`.

Presentation refresh is preferred over structural reconstruction whenever
possible.

This is an anti-taint rule, not just an optimization.

---

## 14. Timer presentation

The numeric timer cutoff is currently **60 seconds**.

With decimals enabled:

- below 10s: one decimal place
- 10s through 60s: whole seconds
- above 60s: no numeric text

With decimals disabled:

- 0 through 60s: whole seconds
- above 60s: no numeric text

The cooldown surface can still exist for longer effects; the numeric text is the
part intentionally suppressed.

The timer cutoff has been tested at both 45s and 60s. The current conclusion is
that 60s retains useful medium-duration combat information without turning long
buffs into persistent text clutter.

ToT/ToF use smaller timer typography than the large player/target/focus
portraits.

---

## 15. Readable exact witnesses

Some states deserve a readable exact path in addition to secure filtering.

This is useful when:

- the secure lane is relation-gated
- exact identity is readable in the current context
- a semantic fallback would otherwise be too broad

The preferred evidence ladder is:

> secure exact → readable exact witness → semantic fallback

Slows are closer to this ideal than some older mechanisms.

Weakened Soul remains an example where the semantic fallback is necessarily
weaker and should be treated cautiously.

---

## 16. Semantic fallbacks are bounded claims

A semantic lane does not mean "this is definitely spell X."

It means the observed safe metadata satisfies a deliberately bounded signature.

Examples:

### Frost Armor signature

For hostile NPCs where spell identity disappears, a 30-minute Magic,
spellstealable helpful aura can serve as a combat-safe presentation fallback.

### Chilled signature

The Frost Armor proc path can hide the exact `Chilled` identity while exposing a
short harmful Magic aura with the expected nameplate/source metadata.

### SmallFriendlyHarmful

On ToT/FoT, exact harmful identity may be unavailable for friendly derived
units. A broad "some harmful state exists" lane is therefore permitted only at
very low priority so every known tracked state outranks it.

### Rule

Semantic metadata is evidence for a **presentation class**, not permission to
invent a spell identity.

---

## 17. Hostile helpful auras and opposite faction visibility

Helpful aura identity on hostile/opposite-faction units is one of the most
important secrecy/relation edge cases.

When readable identity is available, bjarkiPortraits prefers explicit tracked
spell families.

When identities become sealed, `HostileHelpful` provides a deliberately broad
secure surface.

This mechanism must not be interpreted as proving the underlying buff identity.

The long-running "opposite faction aura visibility" problem is therefore partly
an information-authority problem, not merely a missing spell-ID list.

---

## 18. Utility/Welcoming Campfire arbitration

Welcoming Campfire originally behaved badly when treated as an independent
special case at the same priority as Utility.

The current design treats Utility as one actual lane and computes a readable
Utility winner using the same reverse AuraInstanceID recency principle.

A readable direct Welcoming Campfire witness suppresses secure Utility only when
Campfire is actually the readable Utility winner.

This prevents a readable lower-recency special aura from incorrectly masking a
newer utility effect.

General lesson:

> A special-case witness that shares a priority must participate in the whole
> lane's election, not merely prove its own presence.

---

## 19. BaselineClass recency

Baseline class buffs and Camp Benefits share a lane.

Readable arbitration tracks the latest eligible aura rather than depending on
which sibling mechanism refreshed last.

The engine records diagnostics such as:

- winner spell ID
- timing readability
- timing source
- applied-at estimate

This exists because "last applied should win" is a semantic requirement, not a
frame-order preference.

---

## 20. Recently Bandaged

`Recently Bandaged` is a harmful state and belongs just below Weakened Soul.

Current priorities:

- WeakenedSoulFallback: 228
- RecentlyBandaged: 229
- WeakenedSoul: 230

The exact aura is spell `11196`.

A readable exact path exists because self/friendly harmful exact secure identity
can be relation-gated.

Bandage/First Aid **channels** belong separately in FoodDrink at priority 260.
The channel and `Recently Bandaged` debuff are intentionally distinct states.

---

## 21. Ghost/death state

Ghost exposed a particularly clean architectural lesson.

Simply adding Ghost spell IDs to a harmful exact Immunity lane did not make the
player portrait show Ghost.

Why:

- Ghost is harmful
- the player is assistable/self
- exact harmful identity can be denied by relation policy

So the exact lane could be valid data yet unavailable on the relation where it
mattered most.

### Current solution

Use `UnitIsGhost(unit)` as the authoritative readable state witness.

When true:

- render the canonical Ghost icon
- place it at Immunity priority 330
- do not fabricate a duration/timer

Lifecycle refreshes include:

- `PLAYER_DEAD`
- `PLAYER_ALIVE`
- `PLAYER_UNGHOST`

Known Ghost-family IDs remain in the harmful Immunity corpus as backup where
exact identity is legal.

General lesson:

> If the game exposes a direct state predicate that exactly answers the semantic
> question, prefer it over forcing a relation-gated aura identity path.

---

## 22. State witness vs aura witness

The Ghost fix suggests a useful taxonomy for future mechanisms.

### Aura witness

Evidence comes from the aura system:

- exact readable aura
- secure exact slot
- semantic aura metadata

### State witness

Evidence comes from an independent unit/game state API:

- `UnitIsGhost`
- potentially other direct state predicates where Blizzard exposes them

A state witness should not be rewritten as a fake aura scan merely to fit one
engine abstraction.

The presentation layer can accept both, provided priority and teardown semantics
remain explicit.

---

## 23. NPC aura coverage: the expansion plan

Hand-adding one NPC spell ID at a time is not a scalable architecture.

The intended long-term approach is an **offline mechanical-equivalence corpus**.

For each canonical tracked effect:

1. start from the player/canonical spell family
2. discover candidate Forever spell IDs
3. verify which spell/aura is actually applied
4. compare meaningful mechanics, not name alone
5. alias verified equivalents into the existing conceptual family
6. keep runtime lookup as ordinary exact set membership

Examples of families suitable for this approach:

- Faerie Fire
- Frostbolt/Chilled slow families
- Entangling Roots
- stuns
- crowd control
- shields
- DoTs
- defensives
- utility buffs

### Why names are insufficient

NPC abilities frequently reuse names while differing in:

- applied aura ID
- duration
- dispel type
- mechanic
- magnitude
- secondary effect

The cast spell can also differ from the aura spell it applies.

Therefore:

> **same name ≠ same mechanical family**

### Runtime performance goal

The expansion should happen offline or during corpus construction, not by
searching the spell database during combat.

A large verified hash/set of spell IDs is cheap. Runtime discovery is not the
plan.

---

## 24. NPC expansion and secrecy interact

Adding more exact IDs does not automatically make more relations observable.

A family with 100 mechanically equivalent IDs still faces:

- NeverSecret rules
- helpful/harmful relation authority
- readable identity availability
- secure candidate-filter legality

This is why the future PARTIAL/COMPLETE/NONE authority model matters before
mechanical-equivalence expansion becomes large.

The corpus answers:

> "Which IDs mean this mechanic?"

The evidence engine separately answers:

> "Which of those identities may be observed here?"

Do not conflate the two.

---

## 25. Pet portrait foundations

Pet artwork is presentation-only and must not imply identity without evidence.

### Local pet

`UnitIsUnit(unit, "pet")` is positive ownership evidence.

The local pet foundation is drawn:

- above the native BACKGROUND portrait
- below Blizzard's BORDER chrome
- with the native mask when available

### Other players' pets

Prefer `UnitIsOtherPlayersPet` when the client exposes it.

Only fall back to `UnitPlayerControlled` on clients where the positive pet API
is absent.

Why:

A merely player-controlled unit can be charmed or mind-controlled. That is not
enough evidence for pet-family artwork.

### Family classification

Pet family is resolved only when readable. Hunter and Warlock families map to
appropriate foundation spell/art textures.

Secret/inaccessible texture results are rejected rather than coerced.

---

## 26. Pet portrait update scope

Observed pet portrait classification is **not** recomputed on every UNIT_AURA.

It is updated on state/relation/rebinding events that can actually change the
referent.

This matters in dense areas because aura traffic is much noisier than pet
identity changes.

General rule:

> Do not attach identity classification to an unrelated high-frequency event
> merely because that event is convenient.

---

## 27. Unit/frame event scoping

`Main.lua` uses narrow registrations where possible.

The tracked portrait unit set is fixed and small.

For unit-state events such as:

- `UNIT_AURA`
- `UNIT_FACTION`
- `UNIT_FLAGS`
- `UNIT_CONNECTION`

registration is scoped to the units the addon actually owns.

`UNIT_TARGET` is registered only for:

- `target`
- `focus`

because:

- `PLAYER_TARGET_CHANGED` owns the outer target transition
- `PLAYER_FOCUS_CHANGED` owns the outer focus transition
- only target/focus changing *their own* target can rebind ToT/FoT

`UNIT_PET` is registered only for `player`.

This avoids feeding dense-hub unrelated traffic into addon Lua.

---

## 28. Unit existence is evidence too

Hosts for ToT/FoT can exist as frame objects even when the corresponding unit
does not currently exist.

The engine therefore distinguishes:

- host object exists
- unit exists
- unit existence was readable

A prebuilt frame is not evidence that an aura-processing subject exists.

For nonexistent target/focus/derived units, the aura-processing base is false
until `UnitExists` is readable/true.

---

## 29. Player identity fallback

`UnitIsPlayer` can itself become protected in some contexts.

When that happens, a readable GUID type can supply positive evidence:

- `Player-...` => player
- readable non-player GUID => not player

But an inaccessible/missing GUID remains UNKNOWN.

`UnitPlayerControlled` is **not** used as a player-identity fallback because pets
and other controlled creatures satisfy it without being players.

This is an example of avoiding an attractive but semantically weaker proxy.

---

## 30. Cooldown/timer rendering

The addon uses Blizzard cooldown primitives rather than maintaining a custom
countdown loop.

No addon-owned `OnUpdate` is used for timer text.

Earlier attempts to hook protected cooldown scripts such as `OnShow` caused
blocked-action behavior. The current architecture avoids that pattern.

The portrait timer system is intentionally declarative:

- Blizzard owns cooldown progression
- bjarkiPortraits supplies formatter/presentation rules

---

## 31. Taint history that must not be repeated

Several failures from the earlier PortraitTimersForever iterations define the
current boundaries.

### `SetAllPoints` / protected anchoring

Produced `UntrustedLayoutScriptExecution` in native frame relationships.

Current response: controlled portrait reparenting/layering with point capture
and restoration.

### Cooldown `HookScript("OnShow")`

Blocked in protected paths.

Current response: configure cooldown presentation without attaching unsafe
script hooks.

### Secret TextStatusBar numbers

Arithmetic/inspection of protected values produced strong taint.

Current response: validate accessibility before any branch or arithmetic.

### `unitAuraUpdateInfo.isFullUpdate`

A secret boolean caused tainted boolean evaluation.

Current invariant:

> Never read `unitAuraUpdateInfo.isFullUpdate` in addon Lua.

### Nil-call regression

Earlier code paths assumed optional client functions existed.

Current style prefers explicit capability checks and `pcall` around version-
sensitive APIs.

---

## 32. Test mode and debug mode

`/bp test` is a visual construction test, not proof that all live aura authority
paths are correct.

`/bp debug` is the semantic diagnostic surface.

Useful fields include:

- host existence
- unit existence/readability
- container count
- reparenting status
- hostile/player relation state
- exact helpful/harmful authority
- small-friendly fallback state
- hostile-helpful completeness
- baseline winner/timing
- slows witness
- Resurrection Sickness witness
- Utility winner
- Welcoming Campfire witness

When a screenshot says "the icon isn't showing," the right diagnostic question
is often not "is the spell ID in Spells.lua?" but:

> **Which evidence plane had authority for this relation, and what did it know?**

---

## 33. Current visual invariants

The portrait presentation has been tuned at pixel scale. Preserve these unless a
new live comparison justifies changing them.

- player/target/focus portrait aura treatment is accepted
- ToT aura icon: approximately +2px X relative adjustment
- ToT timer: approximately `(0, -1)` relative adjustment
- FoT aura icon: approximately +1px X
- FoT timer: approximately `(+1, -1)`
- ToT/FoT timer font is 2 points smaller
- icon crop/zoom has been tuned away from the original over-crop
- incoming-number positioning belongs to bjarkiUI/other presentation work, not
  this addon
- focus castbar centering experiments were reverted and are not part of this
  architecture

Do not "clean up" these offsets merely because they are asymmetric. They are
optical corrections to asymmetric Blizzard art.

---

## 34. Priority changes should be data changes first

If a user asks:

> "put spell X in tier Y"

prefer a `Spells.lua`/`Priority.lua` data edit over adding a procedural branch to
`AuraEngine.lua`.

Procedural logic is warranted only when the evidence mechanism itself differs,
for example:

- Ghost state witness
- hostile identity protection
- readable recency election
- semantic fallback metadata

The engine should not become a pile of spell-name exceptions.

---

## 35. Corpus hygiene

Spell IDs are the primary exact identity key.

Comments should record human-readable names and important provenance, but names
are not runtime authority.

Before adding a candidate ID:

- verify whether it is the cast spell or applied aura
- verify polarity
- verify duration/mechanic where relevant
- check whether it duplicates another exact runtime lane
- check relation/NeverSecret implications

For bulk NPC expansion, automate these checks offline where possible.

---

## 36. Semantic-lane exclusions

Semantic Blizzard lanes such as Important/BigDef/ExternalDef/CC can overlap
explicit exact families unless exclusions are supplied.

`R.CandidateFilters` excludes known explicit spell IDs from broad semantic
surfaces where appropriate.

This prevents a known spell from being represented twice by:

- its exact lane, and
- a generic Blizzard metadata lane.

Any new exact family should be reviewed against these exclusion sets.

---

## 37. Exact-lane overlap audit

A useful static audit is:

1. enumerate every exact runtime lane
2. map each spell ID to all owning lanes
3. fail on unintended multi-owner IDs

This caught the conceptual CC/stun overlap before it could remain a runtime
ambiguity.

The audit should remain part of major taxonomy changes, especially before NPC
corpus expansion.

---

## 38. Readable timing is its own evidence dimension

Knowing *which* aura is present is not identical to knowing *when* it was
applied.

For recency arbitration, the engine tracks whether timing was readable and the
source used to derive it.

Do not silently manufacture ordering from table traversal when the semantic
requirement is "latest applied wins."

When exact application timing is unavailable, prefer Blizzard's own stable
AuraInstanceID ordering where that ordering is the lane contract.

---

## 39. 60-second timer cutoff and aura priority are independent

Priority decides **which aura wins**.

The timer formatter decides **how much numeric duration text is shown**.

A high-priority 30-minute immunity/buff can still win the portrait while showing
no numeric timer after the 60-second display threshold.

Do not lower an aura's priority merely to reduce duration-text clutter.

---

## 40. Architecture for future NPC coverage

The intended flow is:

```text
Forever spell corpus
        ↓
offline candidate discovery
        ↓
mechanical equivalence verification
        ↓
canonical conceptual families in Spells.lua
        ↓
Priority.lua lane construction
        ↓
relation/secrecy authority decision
        ↓
secure/readable/state witness arbitration
        ↓
one portrait winner
```

The key separation is:

```text
mechanical equivalence ≠ observability authority
```

A correct corpus does not authorize an observation, and an observable aura does
not prove it belongs to a canonical mechanical family.

---

## 41. What not to do for NPC auras

Do not:

- enumerate every NPC spell in runtime Lua by scanning the spell database
- match solely on localized spell name
- assume cast spell ID equals aura ID
- add a procedural `if spellName == ...` branch per screenshot
- broaden semantic filters until the desired icon happens to appear
- collapse a protected identity to "not present"

These approaches either bloat runtime work or weaken epistemic correctness.

---

## 42. Recommended NPC corpus artifact

A future generated corpus can be auditable data rather than handwritten code.

For each member, record fields such as:

- canonical family
- spell/aura ID
- source/provenance
- polarity
- duration class
- dispel type
- mechanic flags
- verification status
- NeverSecret result if known
- notes on player/NPC equivalence

The generated Lua sets can then be deterministic outputs of that corpus.

This keeps `Spells.lua` reviewable even when coverage becomes much larger.

---

## 43. Architecture debt explicitly accepted today

The current runtime is stable, but these are known areas for later improvement:

1. ~46 containers per host instead of filter-cohort containers
2. repeated readable aura walks instead of per-filter snapshots
3. whole-family NeverSecret gate instead of per-member/partial authority
4. some readable-special spell IDs duplicated as local constants rather than
   derived from the canonical corpus
5. Weakened Soul fallback is weaker than the ideal evidence ladder
6. NPC mechanical-equivalence coverage is still manually sparse

These are **known debt**, not invitations to refactor all at once.

The safe order is incremental and live-tested.

---

## 44. Refactor order if performance becomes a problem

Preferred order:

1. preserve behavior and add measurement/debug visibility
2. consolidate containers by identical filter string
3. cache AuraSlot enable state
4. snapshot readable filters once per host update
5. derive special readable sets from `Spells.lua`
6. refine exact authority to COMPLETE/PARTIAL/NONE
7. only then consider deeper container unification

Do not combine architecture cleanup with major spell-corpus expansion in the same
untested step.

---

## 45. Anti-regression checklist: security

Before shipping an engine change, verify:

- [ ] no secret value is used in a boolean test before accessibility validation
- [ ] no secret number enters arithmetic
- [ ] UNKNOWN is not cached as a permanent false secrecy result
- [ ] hostile helpful exact identity is not accidentally authorized
- [ ] friendly/self harmful exact identity is not assumed available
- [ ] `unitAuraUpdateInfo.isFullUpdate` is not read
- [ ] no combat-time protected structural rebuild was introduced

---

## 46. Anti-regression checklist: runtime topology

- [ ] exact runtime lane sets are disjoint unless explicitly intended
- [ ] equal-priority conceptual categories that need recency share one election
      surface
- [ ] broad semantic lanes exclude explicit tracked IDs where required
- [ ] ToT/FoT nonexistent units do not process auras merely because frames exist
- [ ] no new cosmetic OnUpdate loop was added
- [ ] high-frequency events use `RegisterUnitEvent` when possible
- [ ] pet classification is not attached to UNIT_AURA

---

## 47. Anti-regression checklist: visuals

- [ ] native portrait ring/chrome remains above addon art
- [ ] portrait mask remains applied
- [ ] ToT/FoT optical offsets remain intact
- [ ] timer decimals work below 10s when enabled
- [ ] numeric timer text stops after 60s
- [ ] cooldown swipe setting still toggles cleanly
- [ ] test mode does not leave stale buttons after exit
- [ ] pet foundations do not paint over native frame chrome

---

## 48. Anti-regression checklist: evidence fallbacks

For every new fallback, document:

- what exact state it claims
- which readable fields support that claim
- when it is enabled
- what stronger evidence suppresses it
- what unrelated states could satisfy the same signature

If those questions cannot be answered, the fallback is probably too broad.

---

## 49. Live-test methodology

A surprising amount of this addon was discovered through screenshot + debug
iteration rather than source inspection alone.

The preferred loop is:

1. observe a concrete missing/wrong icon
2. identify unit relation and combat state
3. run `/bp debug` if authority is unclear
4. inspect Forever Blizzard source for the owning API path
5. change the smallest mechanism
6. test the exact scenario again
7. only then generalize

A screenshot can disprove an architectural assumption even when the code looks
internally consistent.

---

## 50. Interpreting "not working"

For portrait auras, "not working" can mean several fundamentally different
things:

- ID absent from corpus
- wrong cast-vs-aura ID
- wrong polarity/filter
- exact identity not authorized on that relation
- identity secret in combat
- semantic lane excluded/suppressed
- lower-priority aura legitimately losing
- stale/rebound unit host
- nonexistent derived unit
- special readable winner arbitration choosing another aura
- direct game state should have been used instead of aura identity

Do not respond to all of these by adding more IDs.

---

## 51. Current Ghost family lesson as a template

The Ghost failure is a model debugging case:

```text
symptom:
  Ghost icon absent on player portrait

first hypothesis:
  missing Ghost aura ID

change:
  add harmful Immunity exact IDs

result:
  still absent

structural diagnosis:
  self/friendly harmful exact identity is relation-gated

better evidence source:
  UnitIsGhost(player)

final architecture:
  state witness at Immunity priority + exact lane as backup
```

This is the preferred reasoning pattern for future stubborn states.

---

## 52. Current runtime invariants

At the time of this document:

- five portrait hosts are tracked
- Ghost is state-derived on readable units and also represented in harmful
  Immunity exact data
- timer numeric cutoff is 60 seconds
- Recently Bandaged sits immediately below Weakened Soul
- Campfire Nearby is absolute bottom priority
- Boosted Rest is priority 1
- SmallFriendlyHarmful is priority 2
- Utility is one actual lane including Welcoming Campfire
- Control exact lane excludes Stuns
- pet identity prefers positive `UnitIsOtherPlayersPet`
- `UNIT_AURA` does not drive pet reclassification
- unit events are scoped narrowly
- no addon-owned OnUpdate loop exists
- inaccessible evidence remains UNKNOWN

---

## 53. Working definition of a good bjarkiPortraits change

A change is good when it:

1. improves a concrete combat-state presentation problem,
2. states exactly what evidence supports the icon,
3. respects relation/secrecy authority,
4. preserves the priority election model,
5. does not create an overlapping exact lane by accident,
6. does not add high-frequency work without need,
7. leaves native protected frame ownership intact,
8. survives live combat testing without taint.

Or more compactly:

> **Make the strongest presentation claim the evidence actually earns.**


## Priority refinements through v0.1.59

- Fear Ward is Utility 270 alongside Nature's Grasp.
- Taunt is its own harmful exact lane at 195: DoTs 190 < Taunt 195 < LowDebuff 200.
- Druid Enrage remains a distinct taxonomy family but shares the Innervate 261 runtime lane so equal-priority recency is elected on one surface.
