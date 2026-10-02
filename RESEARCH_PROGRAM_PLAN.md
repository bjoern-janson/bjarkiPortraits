# Research-program integration plan

## Status

This is a development handoff for **bjarkiPortraits** while the wider research
program is being re-parsed repository by repository with Astra.

Do **not** implement the research-program integration yet merely because this
document exists. Finish the full research-program digestion first, preserve the
reports, then use the final synthesis to decide which ideas earn promotion into
addon engineering.

The addon must remain functionally pristine.

---

## 1. Primary constraint: runtime austerity

Research richness belongs **outside** the runtime unless a concept earns its
place by solving a concrete addon problem.

A research concept may enter runtime only if it does at least one of:

1. eliminates a demonstrated failure mode;
2. improves correctness under WoW: Forever's secrecy/protection model;
3. simplifies an existing mechanism;
4. enables a useful behavior that cannot be expressed as cleanly otherwise.

Do not add abstractions, state, events, allocations, indirection, polling,
framework layers, or terminology to the live addon merely because they map
nicely onto the research program.

Target:

```text
rich offline reasoning
        ↓
small verified invariant
        ↓
boring/fast runtime implementation
```

The ideal integration makes the runtime smaller, clearer, or more correct.

---

## 2. Preserve the Astra deep-parse corpus in this repository

Each research repository is receiving an Astra deep-parse report. Preserve
those reports verbatim under:

```text
research/
  deep-parse/
    <repository>.md
```

The reports are evidence/state-reconstruction artifacts, not rewritten
summaries. Do not silently normalize or merge away distinctions found by the
individual parses.

After the full ~65-repository pass is complete, add an index/manifest that can
record, where available:

- repository name;
- review date;
- source branch/tip identities inspected;
- report file;
- report SHA-256;
- maturity/evidence status extracted by the final synthesis.

Suggested derived artifacts, **after** the full digestion:

```text
research/
  README.md
  deep-parse/
    ...
  synthesis/
    PROGRAM.md
    CLAIM_GRAPH.json
    MATURITY.json
    OPEN_FRONTS.md
    REDUNDANCY.md
    EVIDENCE_LEDGER.md
```

Do not pre-commit the final ontology before Astra has seen the complete corpus.

---

## 3. Full-digestion gate

The next conceptual step is the **whole-program Astra digestion**.

Its job is not to praise, unify, or preserve every idea. It should identify:

- which claims survived scrutiny;
- which concepts were absorbed or superseded;
- which repositories are active, supporting, historical, redundant, or
  unresolved;
- which distinctions recur independently across projects;
- which abstractions have empirical/mechanical support versus only conceptual
  appeal;
- which missing bridge or apparatus is most information-bearing to build next.

Only after that synthesis should research concepts be deliberately promoted
into bjarkiPortraits/bjarkiUI.

Repeated convergence across independent research lines and independent addon
engineering is especially interesting. Treat such recurrence as a reason to
inspect closely, not as proof.

---

## 4. Candidate research → addon intersections

These are **candidates to evaluate after the full digestion**, not mandatory
features.

### 4.1 UNKNOWN is not FALSE

Already a live bjarkiPortraits invariant.

Secret, inaccessible, relation-gated, or unanswered values must remain UNKNOWN
rather than being collapsed into absence.

Preserve this unless stronger evidence justifies a narrower rule.

### 4.2 Typed evidence / authority

The addon already separates several things that older addon code often
collapses:

```text
observable
!= identity-readable
!= authorized for exact filtering
!= sufficient for a semantic inference
```

Potential future work: make these boundaries easier to audit without adding
runtime object bloat. Prefer compile-time/static structure over dynamic
frameworks.

### 4.3 Signature-relative mechanical equivalence

The NPC aura corpus should not equate effects merely because they share a
localized name or icon.

A candidate equivalence claim should be explicitly relative to the behavior
needed by the addon, e.g. movement slow / root / stun / defensive state, with
only the mechanical dimensions required for portrait classification.

```text
Aura A ==_sigma Aura B
```

does not mean the spells are globally identical.

This is likely an **offline corpus principle**, with the verified consequence
compiled to ordinary ID-set membership in `Spells.lua`.

### 4.4 Provenance and reopening

Rich source records may retain:

- candidate spell/effect;
- claimed family;
- evidence/observation basis;
- scope of the claim;
- provenance;
- conditions that should reopen the classification.

Runtime should still receive the compressed result, e.g.

```lua
SLOWS[spellID] = true
```

rather than carrying provenance machinery in combat.

### 4.5 Jurisdiction / mutation scope

bjarkiUI and bjarkiPortraits may benefit from static or test-time declarations
of which modules are allowed to mutate which Blizzard surfaces.

Goal: catch indirect mutation-scope leakage through helpers without introducing
runtime permission machinery.

This is primarily a tooling/test idea.

### 4.6 Decision traces / falsification traces

Debug mode may benefit from a bounded explanation of an election:

```text
unit=target
winner=ROOT_EXACT
evidence=secure/readable/state-witness
authority=<status>
priority=<n>
suppressed=<...>
reason=<...>
```

Only implement if it materially improves diagnosis and can remain debug-only,
event-driven, and cheap.

The purpose is to preserve the causal path from evidence to rendered icon,
rather than reverse-engineering meaning from the final pixel.

### 4.7 Correction-capable development loop

When live Forever behavior contradicts an offline corpus assumption, prefer:

```text
compiled claim
→ live contradiction
→ diagnostic/reopen
→ offline review
→ regenerated runtime data
```

over silent runtime self-modification.

Reality should be able to force a claim back open without making the combat
runtime into a learning system.

---

## 5. NPC aura corpus remains the main concrete addon project

Current concrete project remains the offline NPC mechanical-equivalence corpus:

1. canonical tracked family;
2. candidate Forever/NPC IDs;
3. verify applied aura ID and relevant mechanics;
4. record provenance and scope offline;
5. alias verified equivalents into `Spells.lua`;
6. keep runtime lookup as simple set membership;
7. separately respect relation/secrecy authority.

Do not use localized name equality as mechanical proof.

The research program may improve the **method used to build and audit this
corpus**. It should not make the live aura engine academically elaborate.

---

## 6. What not to do

- Do not resurrect PortraitTimersForever architecture.
- Do not turn bjarkiPortraits into a generic epistemic/research framework.
- Do not add research vocabulary to runtime code unless it clarifies an actual
  invariant.
- Do not add runtime provenance databases.
- Do not add polling to support research instrumentation.
- Do not let debug/audit facilities taint combat-critical paths.
- Do not force every research concept into the addon.
- Do not treat recurrence between research and engineering as proof of a
  universal principle.
- Do not choose the final integration architecture before the full Astra
  digestion is complete.

---

## 7. Expected post-digestion decision

After Astra finishes the whole-program synthesis:

1. compare the strongest surviving research invariants against the failure
   modes independently discovered in bjarkiPortraits/bjarkiUI;
2. identify genuine structural overlap;
3. select only overlaps that improve the addons;
4. implement them primarily in offline tooling, tests, corpus structure, or
   compile-time generation;
5. keep the shipped Lua minimal;
6. benchmark/inspect for regressions in taint, event frequency, allocations,
   combat safety, and visual behavior.

If no research idea improves the addon, leave the runtime alone.

That outcome is valid.

---

## 8. Guiding compression

```text
~65-repo research corpus
        ↓
Astra whole-program digestion
        ↓
surviving/recurrent invariants
        ↓
offline audit / corpus / tooling
        ↓
minimal compiled runtime consequences
        ↓
functionally pristine addon
```

The point is not to demonstrate the research program *inside* World of
Warcraft.

The point is to see whether ideas that survive abstract scrutiny also produce
better engineering when exposed to a hostile, partially observable,
relation-dependent, frequently changing real software environment.


---

## 9. Why this unusual integration exists

### 9.1 Product ambition: **Lange & Söhne × Taco Bell**

The ambition for **bjarkiPortraits** and **bjarkiUI** is not merely to make
useful addons.

The explicit development doctrine is:

> **Lange & Söhne × Taco Bell**

The two halves are intentionally extreme and complementary.

**Lange & Söhne** means the output standard:

- coding beauty — small, legible, principled, unsurprising code;
- PvP competitiveness — maximum useful signal with minimum perceptual cost;
- functionality — robust behavior across the ugly edge cases of the real client;
- native presentation — the result should feel like Blizzard implemented the
  interface correctly in the first place;
- failure discipline — unavailable evidence degrades safely rather than being
  converted into invented certainty;
- craftsmanship all the way down — 1 px geometry, stale frame state, wrong
  colors, duplicated timers, priority collisions, and similar "small" defects
  are real defects;
- internals should remain worth inspecting even when users never see them.

**Taco Bell** means the production/execution standard:

- standardized workflows;
- aggressive elimination of unnecessary choices;
- reusable proven patterns;
- offline preprocessing and generation where possible;
- tiny hot paths;
- cheap iteration;
- fast packaging and verification;
- do difficult reasoning once, then turn the answer into machinery so the same
  class of work does not need to be handcrafted repeatedly.

The synthesis is:

```text
haute-horlogerie reasoning upstream
        ↓
compressed invariant
        ↓
fast-food execution downstream
```

or more simply:

```text
deep design
    ↓
compressed execution
```

The goal is **not** to rush by lowering standards.

The goal is to rush by making the production system faster while preserving an
extremely high output standard.

A useful test for future changes is:

> Does this move complexity upstream and leave execution simpler?

If yes, it is probably aligned with the doctrine.

If it moves complexity into combat-time Lua, adds generalized framework
machinery, or forces runtime to carry the whole explanation around with it, it
is probably not.

A successful implementation should often make the engineering disappear.
Players should mostly notice that the addon feels exact.

### 9.2 Functional division between the two addons

A useful working distinction is:

**bjarkiPortraits = epistemic precision**

> Given the legally observable state of a unit, what is the single most
> important thing the player should know right now?

**bjarkiUI = interface precision**

> How should Blizzard's existing information surfaces be presented so that
> perception and action are not fighting unnecessary UI friction?

This is not a mandatory ontology. Preserve it only while it continues to
clarify real responsibilities.

### 9.3 The research program is subordinate to the artifact

The desired direction is:

```text
deep reasoning
    ↓
better invariant
    ↓
simpler implementation
    ↓
better competitive information
```

not:

```text
research concept
    ↓
more abstraction
    ↓
more addon code
```

If a theoretically elegant idea adds runtime complexity without paying for
itself in correctness, simplicity, maintainability, or PvP utility, reject it.

The addon is not a research demo.

### 9.4 The outward discovery chain

There is, however, a deliberate second-order goal.

If the addons become unusually good, technically sophisticated on inspection,
and competitively respected, outside observers may naturally ask:

```text
Why is this addon unusually clean/reliable?
        ↓
What design principles produced it?
        ↓
Where did those principles come from?
        ↓
What is the broader research program?
        ↓
Do any of these ideas matter for AI safety?
```

The intended chain is therefore:

```text
competitive artifact
        ↓
engineering curiosity
        ↓
design principles
        ↓
general research questions
        ↓
AI-safety research
```

Crucially, the artifact must earn attention **before** the larger interpretation
is requested.

Do not optimize the addon for rhetorical promotion of the research program.
Do not plaster AI-safety terminology over the user-facing project. That would
weaken both the addon and the evidence value of any genuine convergence.

A preferable external reaction would be:

> "I do not know whether the broader AI-safety generalization is right, but this
> evidence/authority distinction is clearly useful engineering."

That is a stronger result than agreement produced by branding.

### 9.5 Why the apparent topic switch is intentional

Astra will encounter a long sequence of abstract research repositories and then
a World of Warcraft addon concerned with portrait auras, Frostbolt variants,
secret values, taint, unit relations, reused Blizzard frames, and pixel-level
presentation.

The discontinuity is real and intentional.

Do not assume the addon is merely a joke, distraction, or metaphorical
appendix. It is a separate engineering project that independently encountered
problems such as:

- incomplete and secret observations;
- UNKNOWN versus FALSE;
- relation-dependent access;
- observation versus identity;
- identity versus authority to infer;
- stale state carried through reused objects;
- scope-limited mutation;
- provenance of hardcoded classifications;
- reality contradicting compiled assumptions;
- preserving diagnostic traces rather than inferring causes from endpoints.

These overlaps emerged under practical client pressure, not because the addon
was originally designed to instantiate the research program.

That makes the comparison interesting.

It does **not** make the similarities automatically deep.

### 9.6 The cross-domain test

After completing the full research-program digestion, explicitly ask:

1. Which principles appear independently in the abstract research and in addon
   engineering?
2. Are they structurally the same, or only linguistically/analogically similar?
3. Does applying the research-derived formulation actually improve the addon?
4. Can the improvement be expressed with *less* or equally simple runtime code?
5. Does the addon expose counterexamples that should weaken or revise the
   abstract research principle?
6. Would an engineer with no interest in AI safety still regard the principle
   as useful?

Treat independent recurrence as **evidence worth investigating**, not proof of a
universal law.

The strongest outcome would be a principle that:

- survived hostile review in the research corpus;
- was independently rediscovered under WoW engineering pressure;
- removes or prevents a concrete addon failure;
- admits a clean implementation;
- remains intelligible/useful without requiring belief in the larger theory.

### 9.7 The addon can challenge the research too

The direction of influence is bidirectional.

Do not only ask:

> How can the research improve the addon?

Also ask:

> Which research ideas fail when forced into an adversarial, partially
> observable, permission-constrained production environment?

WoW: Forever provides unusually concrete pressure:

- APIs can expose information incompletely;
- secrecy rules can vary by relation;
- protected values can taint innocent-looking operations;
- Blizzard can rewrite internal behavior;
- frame objects are reused;
- observed behavior can contradict documentation or historical assumptions;
- performance and combat safety impose hard costs on abstraction.

If a broad research principle cannot survive translation into this environment
without becoming vague, bloated, or exception-ridden, that should count against
the principle.

### 9.8 Preserve the asymmetry between rich source and tiny executable consequence

The preferred architecture is:

```text
research report / observation / provenance / reopening conditions
        ↓
offline audit or compiler
        ↓
verified narrow claim
        ↓
minimal runtime consequence
```

Example:

```text
rich evidence that NPC spell 123456 is equivalent to the tracked Frostbolt
slow for the dimensions relevant to portrait classification
        ↓
offline verification
        ↓
SLOWS[123456] = true
```

The shipped addon should not carry the entire argument.

### 9.9 Personal-repository permission

This is a personal repository. It is acceptable for the repository itself to
look unusual.

The `research/` tree may contain dozens of Astra reports and a substantial
research-program synthesis even though the shipped addon remains tiny.

Judge cleanliness at the **execution/package boundary**, not by requiring the
Git repository to resemble a conventional public addon distribution.

The research corpus must remain outside the `.toc` load graph and must impose
zero runtime cost.

### 9.10 Instruction to Astra after full digestion

When the whole-program parse is complete:

- do not flatter the research program;
- do not force a synthesis;
- do not assume the addon validates the research;
- do not assume similarities are meaningful because terminology can be mapped;
- identify the strongest genuine overlaps and the strongest disanalogies;
- propose concrete addon changes only where they improve the **Lange & Söhne × Taco Bell** standard;
- prefer offline tooling/tests/data generation over runtime machinery;
- allow the addon to falsify or narrow research ideas;
- preserve the possibility that the correct result is **no runtime integration**.

The desired endpoint is not "AI safety implemented in WoW."

It is:

> Two functionally pristine competitive addons whose engineering can stand on
> its own, with any connection to the broader research program earned through
> independently useful design principles.

---

## 10. Current concrete addon backlog for Astra

These are **explicit user-requested product changes** to carry into the next
Astra implementation pass. They are not research-derived requirements and they
do not need to wait for a grand conceptual synthesis merely to be recorded.
Implement them only with the same source-discipline used elsewhere in this
document: inspect the current runtime first, preserve native ownership where
possible, and do not invent client contracts.

The current source checkpoints to reason from are:

- **bjarkiPortraits**: `0.1.59-local`
- **bjarkiUI**: `0.2.57-local`

The October 2 deep parses identified additional confirmed/conditional defects.
Those findings should be considered alongside this backlog rather than
overwritten by it.

### 10.1 bjarkiUI requests

#### Fix the ToT / ToF wrong-health-color bug

Target-of-target and focus-target are reusable Blizzard frames. The intended
invariant is that their health color always reflects the **current referent**,
not the unit that previously occupied the frame.

Requirements:

- reproduce the wrong-color case in the real client if possible;
- identify the final native writer/rebind sequence before changing code;
- re-derive the full health presentation after the referent is finalized;
- preserve player class color, pet green, NPC/reaction/tap state, and the
  current uniform health/power bar visual language;
- do not solve stale color by polling;
- do not broaden hooks to unrelated unit frames.

The existing `UnitFrame_Update` post-hook is intended to solve this class of
problem, so treat a surviving bug as evidence that the hook timing, frame
identity, resolver, or a later native writer is still wrong. Diagnose the
actual final writer rather than adding another unconditional repaint.

#### Add deterministic group-frame sorting

For the raid-style party/group frame presentation, use a stable order with the
player at the bottom.

Desired order:

```text
party1
party2
party3
party4
player
```

For smaller groups, preserve the same relative rule: party members remain in
ascending party-token order and the player is always last/bottom.

Requirements:

- use the native compact/raid-style party frame system rather than constructing
  a replacement party-frame addon;
- preserve Blizzard frame reuse and group membership behavior;
- avoid per-frame polling;
- verify joins/leaves, group conversion, reload, zoning, and Edit Mode/layout
  changes;
- do not reorder full raid groups unless that follows from the explicitly
  selected raid-style party-frame surface and is intended.

#### Add a small movement-speed and duel-flag distance display below the PRD

Add a compact information line immediately below the Personal Resource Display
containing:

- current movement speed;
- current distance in yards from the duel flag when that measurement is
  meaningfully available.

Design requirements:

- visually subordinate to the PRD; small, native-looking, low-clutter text;
- do not fabricate precision the client does not expose;
- duel-flag distance should disappear or degrade cleanly when no relevant duel
  flag can be identified;
- prefer native events/state changes for movement speed;
- if exact flag distance genuinely requires periodic sampling, justify the
  minimum bounded cadence and isolate it to the duel-active lifetime rather
  than introducing a permanent addon-wide polling loop;
- secret/protected/inaccessible coordinates or distance evidence remain
  UNKNOWN, not zero;
- verify behavior when a duel starts, flag becomes available/unavailable,
  player moves, duel ends, player dies, zones, or reloads.

This feature should remain presentation-only. Do not create gameplay state from
an inferred duel object if the client cannot identify one reliably.

### 10.2 bjarkiPortraits requests

#### Remove decimal timer text

Portrait timers should use integer seconds only.

Current desired behavior:

- retain the current **60-second** numeric timer cutoff;
- remove the sub-10-second one-decimal format;
- do not show decimal countdown text anywhere in normal portrait-timer
  presentation;
- reconcile/remove the old `showDecimals` setting and `/bp decimals` command
  if they no longer have a meaningful supported behavior, rather than leaving a
  dead option that claims to work;
- preserve native cooldown progression and avoid addon-owned timer arithmetic.

#### Put all taunts at the Faerie Fire tier

Taunts should no longer live in a separate "just above DoTs" priority band.

Desired policy:

> **all verified taunt auras share Faerie Fire's display priority.**

Where technically possible, equal-priority harmful effects that are intended
to be behaviorally equivalent for portrait election should share the **same
actual lane/election surface**, not merely the same numeric frame level.

Requirements:

- identify the current Faerie Fire category/lane from source rather than
  hardcoding a stale priority number from documentation;
- move the verified taunt aura family into that same presentation tier;
- preserve exact-ID disjointness;
- do not add threat-only abilities that apply no aura;
- continue verifying Forever/NPC variants by applied aura ID/mechanics rather
  than spell-name equality alone.

#### Add Demoralizing Shout and Demoralizing Roar below the DoT tier

Track the Warrior and Druid demoralizing debuff families:

- Demoralizing Shout
- Demoralizing Roar

Their portrait priority should be **below DoTs**.

Requirements:

- verify all relevant classic/Forever ranks and the actual applied aura IDs;
- give them one coherent exact harmful family/lane;
- keep them below the current DoT tier in display priority;
- do not assume localized-name equality proves mechanical identity;
- include NPC/mechanically equivalent variants only when the evidence standard
  used by the NPC corpus supports them.

#### Add Raptor Punch to the food-buff family

Track **Raptor Punch** at the same presentation priority/election family as the
current food/well-fed-style buff requested by the user.

Before adding it:

- identify the actual Forever spell/aura ID;
- verify that the tracked aura is the persistent buff the user means, not only
  an activation/consumable spell ID;
- place the verified aura in the existing food-buff category/lane rather than
  creating a new priority surface;
- preserve equal-priority recency behavior already used by that lane.

### 10.3 Keep the deep-parse defects in scope

Do not let the feature backlog displace the concrete defects found by the
October 2 audit.

In particular, bjarkiPortraits should still close the confirmed global-off
lifecycle:

- `/bp off` must prevent later events from recreating portrait hosts;
- local pet artwork must also obey the global enabled state;
- off -> event -> still off must become a repeatable regression check;
- preserve known false values in diagnostics rather than collapsing them to
  nil.

The readable-stream completeness, direct-Utility UNKNOWN, inaccessible
instance-ordering, UI unknown-creature, and UI tap-color findings remain
**contract questions unless/until live Forever behavior establishes the
relevant input combinations**. Do not silently "fix" them by assuming stronger
client contracts or by making broad runtime changes.

### 10.4 Acceptance discipline for this backlog

For every requested change:

1. identify the current native/addon writer that owns the behavior;
2. state the smallest invariant that would satisfy the request;
3. implement at that ownership boundary;
4. keep hot-path/runtime cost flat or justify any increase;
5. compile/check the changed Lua;
6. preserve existing static invariants and source custody;
7. distinguish offline/mock evidence from real-client validation;
8. leave a concise architecture note when the change teaches a reusable
   ownership/evidence lesson.

Do not combine unrelated requests into one large runtime abstraction merely
because they arrived in one backlog.

