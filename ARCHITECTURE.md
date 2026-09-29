# Architecture and inferred Forever aura model

This document describes the current **bjarkiPortraits v0.1.23-clean** source and, more importantly, what the development process appears to have revealed about WoW: Forever's aura/UI model. Live-tested observations are identified separately from the v0.1.23 surgical hardening changes that still require in-client regression confirmation.

There are three different kinds of statement here:

1. **Upstream engine evidence** — behavior visible in Blizzard's AuraContainer UI source.
2. **Forever live evidence** — behavior observed directly in the client while testing this addon.
3. **Addon policy** — choices bjarkiPortraits makes on top of those constraints.

Forever may diverge from upstream FrameXML, so live behavior wins whenever the two disagree.

---

## 1. The core difficulty: aura information has multiple visibility regimes

A naive portrait addon could do:

```text
read every aura
→ compare spell IDs
→ choose winner
→ draw icon
```

Forever does not always allow that.

Depending on the unit relation and state, addon Lua may receive:

- a fully readable aura object;
- a readable aura object with some unreadable/secret fields;
- an inaccessible value;
- or no exact identity that addon Lua may legally inspect.

At the same time, Blizzard's secure `AuraContainer` machinery can still evaluate some properties internally.

So bjarkiPortraits is fundamentally a **two-plane system**:

```text
READABLE LUA PLANE
exact spell ID, timing, auraInstanceID when accessible

SECURE AURACONTAINER PLANE
Blizzard filters/sorts protected aura state internally
without exposing protected identity to addon Lua
```

The addon tries to use the strongest justified plane available, and abstains rather than inventing identity when access disappears.

---

## 2. Unit tokens are relationships, not permanent entities

The addon tracks:

```text
player
target
focus
targettarget
focustarget
```

A token such as `targettarget` is not an object identity. It means “the current target of the current target.” Its referent can change whenever the outer relationship changes.

That is why `AuraEngine.lua` does not assume a host remains correct forever. `hostStillCurrent()` resolves the Blizzard portrait/frame again and compares it with the cached host.

This matters especially for the small derived frames.

### The ToT/FoT disappearance investigation

During development, ToT and FoT appeared to have been destroyed by addon changes. Eventually we disabled the addon entirely and found the native Blizzard frames were still hidden.

The objects existed, alpha was 1, but `IsShown()` was false. The decisive discovery was:

```text
showTargetOfTarget = 0
```

On this Forever build, `/console showTargetOfTarget 1` did not restore it. Out of combat:

```lua
C_CVar.SetCVar("showTargetOfTarget", "1")
```

did restore them.

That falsified an important earlier hypothesis: the current visual primitive itself was not what had permanently removed the frames.

---

## 3. The visual primitive that actually works

The live-tested rendering model is empirical rather than theoretically “clean.”

For each tracked portrait:

1. Record the portrait's original parent and anchor points.
2. Create an addon-owned frame one strata step below the native parent.
3. Reparent the native portrait into that lower layer while preserving its geometry.
4. Create the aura anchor in the same lower layer.
5. Create one secure AuraContainer for each priority lane.
6. Leave Blizzard's surrounding ring/chrome in its native higher layer.

Conceptually:

```text
Blizzard ring / chrome / frame
─────────────────────────────
highest active aura
native portrait
─────────────────────────────
bjarkiPortraits lower layer
```

That is why the aura looks like it **becomes the portrait**, instead of a square sticker covering the frame.

On host teardown, the original parent and anchor points are restored.

### ToT/FoT tuning

The small frames use the same primitive with only optical corrections:

```text
targettarget icon: +2 px X
targettarget timer: 0, -1

focustarget icon: +1 px X
focustarget timer: +1, -1
```

Their countdown font is reduced by two points.

These values are presentation constants, not aura-selection rules.

---

## 4. Blizzard explicitly distinguishes identity filtering from metadata filtering

The most important upstream source is:

```text
Blizzard_AuraContainer/Blizzard_AuraContainerUtil.lua
```

Two functions are especially informative:

- `CanApplyIdentityCandidateFilters()`
- `DoesAuraPassCandidateFilters()`

The engine treats `includeSpellIDs` / `excludeSpellIDs` as **identity filters**.

The general relation rule is approximately:

```text
HELPFUL identity
    normally filterable on self/group/assistable units
    not normally filterable on hostile/non-assistable units

HARMFUL identity
    normally filterable on hostile/non-assistable units
    not normally filterable on friendly/assistable units

NeverSecret spell
    exempt from that identity restriction
```

This explains two observations that initially looked like bugs:

```text
enemy Prowl
    helpful on hostile unit
    exact spell-ID path may be unavailable

Chilled on yourself
    harmful on friendly/self unit
    exact spell-ID path may be unavailable
```

### Metadata filters survive where identity filters do not

The same AuraContainer code evaluates other candidate fields outside that identity gate, including things such as:

- dispel type;
- maximum duration;
- `isFromPlayerOrPlayerPet`;
- `isRoleAura`;
- `isPriorityAura`;
- `isStealable`;
- nameplate visibility flags;
- processed aura type.

That is why a secure signature can continue working in combat even when the addon is no longer allowed to know the exact spell ID.

---

## 5. Secret/inaccessible is a third state

The addon treats inaccessible data as neither false nor absent.

`Core.lua` wraps access through:

```text
IsSecret
CanAccess
SafeBool
SafeString
ReadAuraField
```

The policy is:

```text
inaccessible ≠ false
inaccessible ≠ nil evidence of absence
inaccessible ⇒ do not make an exact-identity claim
```

This is important because a common addon mistake is:

```lua
if not protectedValue then ...
```

which silently turns “I am not allowed to know” into “false.”

bjarkiPortraits instead tries to hand control back to a secure lane.

---

## 6. Exact lanes and semantic lanes

`Priority.lua` defines 45 lanes.

### Exact lane

An exact lane has an explicit spell set:

```lua
exact(key, filter, level, helpful, spellIDs, allowNeverSecret)
```

Its secure candidate filter is essentially:

```lua
{ includeSpellIDs = spellIDs }
```

when the relation allows identity filtering.

### Semantic lane

A semantic lane says “match this safe shape,” not “match this exact ID”:

```lua
semantic(key, filter, level, candidateFilters)
```

Examples include Blizzard classifications such as Crowd Control / Big Defensive and our Frost Armor / Chilled combat signatures.

This distinction is fundamental:

```text
exact lane:
    "this is spell 6136"

semantic lane:
    "this is a harmful Magic aura <=5.1 sec with these safe flags"
```

The second is weaker evidence, but it is legal/useful when exact identity is sealed.

---

## 7. One conceptual priority should be one candidate pool

Separate AuraContainers at the same frame level do **not** magically create one globally ordered same-tier set.

So when effects really share a priority, bjarkiPortraits unions them into one exact set.

Example:

```text
Paladin auras
Demon Skin
Demon Armor
```

all share the same `PaladinAura` candidate pool.

Likewise Food/Drink now shares one pool with:

- Cannibalize;
- Evocation.

Innervate is one level above that pool, and Rapid Regeneration belongs to Utility.

This means same-tier recency is decided **inside one container**, not by an accident of sibling frame ordering.

---

## 8. Secure recency and why refreshes are special

Secure exact lanes use:

```text
AuraContainerSortMethod.AuraInstanceIDOnly
AuraContainerSortDirection.Reverse
```

So newer aura instances normally replace older aura instances in the same pool.

But refreshing an existing aura can preserve the same `auraInstanceID`.

That is why BaselineClass has an additional readable arbitration rule.

---

## 9. BaselineClass: latest application or refresh wins

For class-maintenance buffs, the desired rule is:

> if two buffs share the tier, whichever was applied or refreshed most recently wins.

When all competing aura timing is readable:

```text
appliedAt = expirationTime - duration
```

The largest `appliedAt` wins, with `auraInstanceID` as tie-breaker.

If timing is not readable for every candidate, the addon falls back to newest `auraInstanceID` across the candidate set rather than favoring only the subset whose timing happened to be readable.

If identity itself becomes unavailable, the readable BaselineClass overlay abstains and the secure BaselineClass container remains underneath.

This is what restores behavior like:

```text
Arcane Intellect active
→ cast Mark of the Wild
→ Mark wins

later refresh Arcane Intellect
→ Intellect wins
```

---

## 10. Hostile helpful effects

Helpful auras on hostile units sit on the wrong side of the exact-ID relation boundary.

### When identity is readable

`scanReadableHostileHelpful()` directly scans the helpful stream and accepts only spell IDs that already belong to tracked helpful categories.

Winner selection is:

1. highest priority;
2. newest auraInstanceID within that priority.

That prevents a random visible NPC maintenance buff from winning merely because it exists.

### When hostile-player identity is unreadable

For hostile players, `HostileHelpful` is a broad secure fallback lane. It is enabled only when the readable hostile path is unavailable.

That is less exact than the readable whitelist, but it preserves some visibility through Blizzard's secure machinery.

### Hostile NPCs

NPCs motivated a narrower strategy: identify specific important effects out of combat, then construct secure metadata signatures that still work when combat seals their identity.

---

## 11. Frost Armor and Chilled: the clearest live experiment

The Scarlet Initiate test produced unusually clean evidence.

### Out of combat

The target's helpful stream was readable:

```text
Frost Armor spellID = 12544
```

The debuff applied to the player was readable:

```text
Chilled spellID = 6136
```

### Secrecy classification

The client reported all tested relevant Frost Armor and Chilled IDs as:

```text
NeverSecret = false
```

So an exact cross-relation spell-ID filter cannot be relied on in combat.

### In combat

The readable exact identity disappeared, but secure metadata filtering still worked.

#### Chilled signature

The working semantic lane is:

```text
HARMFUL
Magic
maximum duration <= 5.1 sec
nameplateShowPersonal = true
not from player/player pet
priority = Slows
```

That is now confirmed working in combat.

#### Frost Armor signature

The working semantic lane is:

```text
HELPFUL
Magic
maximum duration <= 1800.1 sec
not from player/player pet
priority = SelfState
```

An earlier signature also required `isStealable=true`. The secure lane failed to match the live NPC cast. Removing only that predicate made Frost Armor work in combat.

That is a useful example of how the addon is being developed: **live falsification removes unsupported predicates**.

### Current v0.1.23 semantic gating

The semantic signatures are no longer left enabled in parallel with stronger evidence.

The current order is:

```text
Frost Armor
    readable exact hostile-helpful identity when available
    → hostile-NPC semantic signature only after readable identity disappears

Chilled
    secure exact identity when relation permits
    → readable exact Slows witness when available
    → semantic signature only when both stronger paths are unavailable

Weakened Soul
    secure exact identity when relation permits
    → short-harmful semantic fallback only where exact harmful identity is relation-gated
```

This does not make the semantic signatures equivalent to exact identity. It narrows when their equivalence classes are allowed to compete, reducing collision surface while preserving the live-tested combat fallback design.

---

## 12. Why semantic signatures can collide

Once exact identity is unavailable, the addon is matching an equivalence class.

For example:

```text
HELPFUL + Magic + <=30 min + non-player source
```

is not logically equivalent to “Frost Armor 12544.”

The risk is reduced by combining multiple safe features:

- helpful vs harmful;
- dispel type;
- duration bound;
- source flags;
- nameplate flags;
- priority/context.

But another aura could still share the same tuple.

So the correct interpretation is:

> this hidden aura satisfies the secure signature assigned to this priority lane.

Not:

> the addon secretly recovered the protected spell ID.

If a collision is observed, the right fix is to add another **safe discriminator** or tighten lane context — not to infer protected identity from forbidden data.

---

## 13. Readable exception surfaces

Some policies cannot be expressed by a single secure exact container, so the addon creates small readable overlays when the evidence is directly accessible.

Current examples include:

- BaselineClass refresh-aware recency;
- friendly/self Slows exact fallback;
- Resurrection Sickness;
- Welcoming Campfire;
- tracked hostile helpful selection.

These readable overlays sit just above their corresponding secure priority level. Higher-priority lanes still outrank them.

The secure layer is kept underneath wherever possible, so loss of readable access does not necessarily mean loss of display.

---

## 14. Countdown presentation

Each aura button owns a Blizzard `CooldownFrameTemplate`.

Current formatting:

```text
under 10 sec: one decimal
10–60 sec: integer
over 60 sec: numeric text hidden
```

Bling and edge are disabled. Swipe is off by default.

The small ToT/FoT timer font is reduced by two points and optically offset separately.

---

## 15. Pet portrait foundations are deliberately separate

`PetPortraits.lua` is presentation-only.

It does not own:

- AuraContainer truth;
- priority;
- secret-value policy.

It only provides underlying pet artwork on:

```text
PetFrame
target
focus
```

It intentionally does not operate on ToT/FoT.

Hunter pets are recognized from readable creature-family information and use family artwork where available. Warlock demons map to summon-spell artwork.

The local Hunter fallback can use `GetPetActionInfo()`; the current implementation uses the actual return positions `name, texture, isToken, ...`, which fixed an earlier pet-texture bug.

---

## 16. Event and combat lifecycle

`Main.lua` uses targeted events:

```text
PLAYER_LOGIN / PLAYER_ENTERING_WORLD
    build hosts

PLAYER_TARGET_CHANGED
    refresh target + targettarget

PLAYER_FOCUS_CHANGED
    refresh focus + focustarget

UNIT_TARGET
    refresh affected derived token

UNIT_AURA / UNIT_FACTION / UNIT_FLAGS / UNIT_CONNECTION
    refresh matching tracked unit

UNIT_PET / PET_BAR_UPDATE
    refresh local pet artwork
```

New secure hosts are not built during combat lockdown. Structural teardown/reparent restoration is also deferred out of combat. If reconciliation is required, the queued build/rebuild runs on `PLAYER_REGEN_ENABLED`.

Enabled Blizzard AuraContainers process `UNIT_AURA` internally. bjarkiPortraits therefore does not force a second full `UpdateAllAuras()` pass for ordinary aura events. Explicit full refreshes remain for target/focus/derived-token and relation lifecycle changes where the unit token's referent or identity-filter authorization can change.

Existing Blizzard AuraContainers can still process their secure aura state while combat is active.

---

## 17. Debugging: rendering vs admission

Two commands intentionally answer different questions.

### `/bp test`

Tests the visual surface:

> Can the addon resolve the portrait and draw an icon/timer there?

It says nothing about whether a real aura is admitted correctly.

### `/bp debug`

Tests the policy state:

- host exists;
- portrait exists;
- number of containers;
- reparented state;
- hostile-unit/player relation;
- exact helpful authority;
- hostile readability and winner;
- BaselineClass readability/winner/timing;
- Slows readability/winner;
- Resurrection Sickness readable state;
- Welcoming Campfire readable state.

This separation was crucial: several bugs occurred where `/bp test` worked perfectly while real aura admission was wrong.

---

## 18. Current priority spine

Higher numbers visually outrank lower numbers.

```text
10   Plainsrunning
20   Boosted Rest
30   Campfire Nearby
40   Welcoming Campfire
50   Travel Utility
60   Paladin Auras + Demon Skin/Armor
70   Blood Pact
80   Scrolls
90   BaselineClass
100  Camp Benefits
110  Well Fed
120  Thorns
130  Elemental Shields
150  Self State + Frost Armor semantic band
160  Mobility
170  Lone Wolf
180  Hunter's Mark
190  DoTs
200  low debuffs
210  Seals
220  Slows + Chilled semantic band
230  Weakened Soul
238  generic priority debuff
240  Forbearance
241  Resurrection Sickness
242  Honorless Target
250  Power Word: Shield
260  Food / Drink / Cannibalize / Evocation
261  Innervate
270  Utility / Rapid Regeneration
279  Blizzard Important
280  Offensive
288  External Defensive
289  Big Defensive
290  Defensive
300  Roots
309  Blizzard Crowd Control
310  explicit Control
320  Stuns
330  Immunities
```

There are 45 implementation lanes because some conceptual priorities have both exact and semantic mechanisms.

---

## 19. What the addon deliberately does not assume

The current discipline is:

```text
inaccessible aura      ≠ absent aura
secret boolean         ≠ false
same icon/effect       ≠ same spell ID
same frame level       ≠ globally ordered sibling containers
safe signature         ≠ exact identity
upstream FrameXML      ≠ guaranteed Forever behavior
```

And one more lesson from the ToT/FoT saga:

```text
correlation with an addon change ≠ proof the addon caused the native frame state
```

The CVar incident mattered because we had repeatedly redesigned working portrait geometry around a false causal hypothesis.

---

## 20. The architecture in one ladder

The current system can be summarized as:

```text
1. exact readable evidence, when accessible
        ↓
2. secure exact AuraContainer, when relation permits identity filtering
        ↓
3. secure semantic signature, when identity is sealed but safe metadata remains
        ↓
4. abstain rather than invent protected identity
```

That hybrid design is not accidental complexity. It is a response to the game exposing **different epistemic surfaces for the same aura depending on relation and combat state**.

The strongest parts of the addon are where each transition in that ladder is explicit.

The main current weakness is that the new NPC semantic signatures are broader in code than their motivating live context. That is worth hardening later, but only with regression tests that preserve the now-confirmed Frost Armor and Chilled combat behavior.

---

## Upstream source references used for the model

The key upstream UI-source mirror is `Gethe/wow-ui-source`, especially:

- `Interface/AddOns/Blizzard_AuraContainer/Blizzard_AuraContainerUtil.lua`
  - `CanApplyIdentityCandidateFilters`
  - `DoesAuraPassCandidateFilters`
  - AuraContainer sort comparators
- `Interface/AddOns/Blizzard_AuraContainer/Blizzard_CustomAuraContainer.lua`
  - candidate-filter validation and secure custom-container plumbing

Those sources explain the general mechanism. The actual Forever client and live tests remain authoritative for this project.


## 21. Post-v0.1.17 deltas

The core secrecy/secure-container model above remains the architecture. Later live-tested changes add:

- a lower-layer local PetFrame family foundation so Blizzard chrome remains on top;
- a secure generic harmful lane for readably assistable ToT/FoT where exact harmful identity is relation-gated;
- direct `GetPlayerAuraBySpellID(1229739)` lookup for Welcoming Campfire before indexed scanning;
- Elemental Blessing in the same actual priority-10 pool as Plainsrunning;
- Walk on Air in Utility;
- v0.1.23 fallback repair for Welcoming Campfire, semantic-lane gating, canonical priority data, combat-safe structural teardown, and event-path refresh discipline.

These are incremental policy/data/lifecycle changes, not a replacement of the two-plane readable/secure model.
