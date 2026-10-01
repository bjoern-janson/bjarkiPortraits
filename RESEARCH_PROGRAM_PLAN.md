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
