# bjarkiPortraits

A native-styled portrait-aura addon for **WoW: Forever**, displaying the highest-priority eligible, positively observed aura or state on Blizzard's portrait regions.

**Experimental branch:** `0.1.196-auto-native-second-test` (2026-11-08), built on 0.1.178. No slash commands are needed for normal installation or testing. The native runner-up ribbon initializes automatically on the first eligible hostile-NPC Target while out of combat; other units retain the existing readable secondary. The secure rendering mechanism still requires live in-game verification.

## Install

Install the **`bjarkiPortraits`** folder in your game's `Interface/AddOns/` directory, with the twelve `.lua` modules and both `.toc` manifests directly inside the folder. Enable the addon and `/reload`. Blizzard's in-game unit-frame settings still control whether ToT/ToF and regular party frames are visible.

## 0.1.196 — automatic native secondary; no in-game setup

No `/bp native2 on`, `/bp native2 status`, or other in-game
setup is required. With the addon installed, simply target a hostile
NPC out of combat: `AuraEngine.UpdateHost` recognizes the NPC, then
creates the native ribbon on demand. It remains available as you
enter combat or switch targets. If the first eligible target appears
*during* combat, setup is deferred until an ordinary out-of-combat
refresh; no manual retry is needed.

The old `nativeSecondProbe` saved toggle is ignored. The existing
`secondaryPortrait` and global addon enabled preferences remain
respected. On other unit types, established readable election and
race fallbacks remain unchanged.

**Workflow preference:** Features should work automatically with
sensible defaults. Avoid new slash commands for enabling, configuration
or normal testing. Existing diagnostic commands are optional
troubleshooting tools, not required setup.

The native ribbon still requires live client verification of sorting,
clipping and exact runner-up identity. The 0.1.195 instructions below
are historical.

## 0.1.195 — experimental secure-native second-place ribbon

**Reason for the experiment:** A real Kobold with two debuff icons and a
working primary portrait returned `reason=inaccessible-index` with
`hostile=true player=false playerReadable=true nativeHarm=true writes=0`.
The addon is blocked before any Lua top-two ranking: Blizzard's native
portrait can process the auras, while `C_UnitAuras.GetAuraDataByIndex`
is unreadable. More public-reader permission relaxations would be
irrelevant to that failure.

**New mechanism (opt-in):** One separate `CustomAuraContainer` on Target
contains native `AddAuraGroup` groups ordered by the existing
`R.TIERS` priority levels (`layoutIndex`), each with
`maxFrameCount=2` and the *same native filters and sorting*. The
native engine lays out its buttons in that order. A fixed 37-pixel
noninteractive clip window hides the first cell and permits the second
cell to display its own 22-pixel masked icon, native countdown, and
Totem-style 30-pixel border. No protected button state, aura ID, or
secret container width is read by addon Lua. This is a **visual
projection** of a native-ordered strip, not a secret-data extractor.

Historical 0.1.195 instructions used explicit `/bp native2`
commands. **Superseded by 0.1.196:** simply target a hostile NPC
out of combat to initialize the ribbon automatically.

- **Only Target hostile NPCs** can display the prototype. No player,
  party, pet, Focus or ToT/ToF behavior changes. In 0.1.196 it
  initializes automatically when first needed out of combat.
- It adds no priority tiers or spell categories. Known exact IDs are
  made disjoint across exact groups; both generic fallbacks explicitly
  exclude known exact IDs, and the harmful generic also excludes
  priority debuffs to reduce double-presentation.
- **Outstanding feasibility tests:** Native group flow across 63
  separate priorities, correct fixed-window clipping, same-lane second
  aura, potential semantic-filter overlap/deduplication, protected
  frame visibility during combat, and construction performance.
  Static Ghost/form winners are not represented in this NPC-only probe.
- This opt-in proof is **not** yet a production replacement for
  `SecondaryPortrait.lua`. The native primary remains fully intact,
  and disabling the probe frees the added view without changing priorities.

Source evidence: Forever
[CustomAuraContainer](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_AuraContainer/Blizzard_CustomAuraContainer.lua)
exposes `AddAuraGroup` with `layoutIndex`, `maxFrameCount`, and
native sorted flow; [AuraContainerGroups](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_AuraContainer/Blizzard_AuraContainerGroups.lua)
assigns the group's first N current aura frames under secure ownership.
The Lua inbound-shape regression
`tests/native-second-probe.lua` verifies the proposed wiring, **not**
the live secure frame layout or actual second-place identity.

## 0.1.194: harmful NPC election from current public evidence

A live Kobold Tunneler Target screenshot again showed two Blizzard debuff
icons and a main portrait aura, but no secondary circle. Those native
pixels do not prove that both aura identities are available to addon Lua.

Two independent source gates were unnecessarily stronger than the
secondary reader's existing evidence requirements:

1. Hostile NPCs previously needed the **separate HELPFUL-only helper**
   to finish and elect its own helpful winner *before* the secondary
   reader attempted its own full helpful-and-harmful snapshot. That
   helper can be inconclusive even when a complete current union
   proves a **harmful primary** above the helpful effects. Positively
   identified non-player Target/Focus NPCs can now run that independent
   full read directly. Hostile players still require the stricter
   independently verified first-place presenter.
2. The final main harmful native slot check required a directly
   readable `IsEnabled()`. When that native getter is protected,
   the addon can now use its own `_bjarkiAppliedShown == true`,
   recorded only after successful native `SetEnabled` **and**
   `SetShown` calls. A known false or missing previous state still
   fails closed, and the current candidate's exact public identity,
   filter, rank and native container must all independently match.

The real-tier hostile NPC regression verifies both routes and their
negative controls on Lua 5.1 and 5.4. This does **not** reveal secure
native winner identities or bypass an unreadable current aura list.
If this client hides the harmful identities, the NPC secondary stays
hidden. To diagnose the actual remaining gate, target the NPC and run
`/bp secondary debug target` in its current visible state.

## 0.1.193: combat continuity and last-drop diagnostics

Entering combat still returned a visible player's secondary portrait to the
race icon in the live 0.1.192 screenshot even while the native aura icons
remained visible. No client `secondReason` was supplied, so this screenshot
does not establish whether the blocker was secrecy, a native write failure,
or an aura event.

This test build repairs three **independently reproducible code paths**:

1. `UNIT_AURA` previously marked the last positive secondary stale on *every*
   event. It now preserves the candidate only when a guarded public event
   delta proves **solely the removal of unrelated aura-instance IDs**.
   Full updates, additions, updates, secret/unknown payloads, removal of
   either the primary or secondary instance, and expiry still invalidate.
2. Native tier `SetEnabled` / `SetShown` calls are skipped on unchanged,
   previously successful container states; explicitly forced refreshes and
   actual state changes are still executed. This avoids redundant combat
   writes while preserving main portrait behavior and failure guards.
3. If a new complete election positively identifies the **same** timed
   second aura during combat, reuse the existing texture and cooldown rather
   than rewriting them through possibly protected frame APIs. Its current
   instance, spell, tier, existing expiry, unit identity, and mutation
   boundary must still pass.

The existing `/bp secondary debug player` command now reports
`auraEvent` and, if a previous aura badge fell back to race, a
`lastDrop` line with its exact stored failure reason, previous spell,
event dirty state and native write-failure count. This records evidence
for a future live report without inspecting protected auras in chat.

Lua 5.1/5.4 mock tests cover unrelated removal retention, relevant
primary removal invalidation, new aura invalidation, unchanged-combat
no-write behavior, and protected native setter avoidance. **This remains
a live-client test build**, not a guarantee of a secondary where the
current aura information is truly secret.

## 0.1.192: combat Boosted Rest and NPC harmful projection

In the screenshots, Boosted Rest (1229451) is the primary portrait
out of combat but should become **secondary** if a higher-priority effect
takes first place. The prior secondary reader admitted this self/friendly
HARMFUL status only when Ghost was the primary. It now also admits the
currently readable, verified occurrence during ordinary combat; its
level **0** and required ordinary HARMFUL membership are unchanged.
If the current list or identity is genuinely secret, this change does
not fabricate a secondary portrait.

The hostile NPC harmful path no longer insists on broad exact-ID permission
when an independently enabled native generic harmful container exists.
It still requires the current public aura lists, a positively identified NPC,
a proven native first-place harmful slot, and ranked second occurrence.
Hostile players receive no new privilege, and no private native winner
is read. Both changes have regression cases; live combat rendering still
needs confirmation against 0.1.192.

## Confirmed 0.1.188–0.1.189 secondary regression (fixed in 0.1.190)

**Root cause, reproduced with the actual addon source and the game's manifest order:** `SecondaryPortrait.lua` constructed the sorted `rankTiers` list at **module load**, before `Priority.lua` had populated `R.TIERS`. This initialized a permanently **empty** rank list on the live client, regardless of how many buffs were visible. Consequently `secondReason=not-two-presentable` and race fallback were inevitable after v0.1.188, even though prior offline tests passed (they loaded `Priority.lua` first).

Both manifests now load **`Priority.lua` before `SecondaryPortrait.lua`**, and the secondary ranking table is **lazily cached from the populated source** (with an explicit `tiers-not-ready` failure rather than silently treating every spell as unranked). The original production-order reproduction changes from `second=nil reason=not-two-presentable` to `second=1126 reason=verified-readable` for Thorns (120) + Mark of the Wild (90). `tests/secondary-load-order.lua` tests both manifest orders and the deliberately broken order, so this cannot silently regress. All numeric tier levels and the native primary portrait are unchanged.

## Ghost as the main state; lower harmful auras as the secondary (0.1.191)

A **positively presented** Ghost is a static primary at its existing Immunity-relative frame level, rather than a reason to suppress the secondary circle. If a complete current public harmful aura list contains Boosted Rest (spell **1229451**, priority **0**), it can be shown in the small circle under Ghost, with its real timer. Other existing priority-0 harmful effects remain in their original lane. Duplicate Ghost debuffs (8326, 9036, 1278162) are not counted as additional effects when the static main Ghost presenter already owns them.

The exact lower harmful aura still needs a readable current instance ID, matching native polarity membership, and an eligible friendly unit; an inaccessible spell cannot be guessed. A verified Ghost state alone returns the usual race fallback in the secondary circle. Equal-level native ties (e.g. Waiting to Resurrect at level 332) remain unproven rather than arbitrarily ranked. No primary portrait, numeric tier, or protected API permission has changed.

## Supported portraits

The **same one-aura priority engine** is used for **player, pet, target, focus, target-of-target, target-of-focus and regular party1–party4** (ten unit tokens). PetFrame retains its pet-family artwork as the baseline. Party portraits follow Blizzard's pooled frames and ignore Edit Mode placeholders; raid-style party/raid frames are not covered.

Native unit-frame chrome and spell icons remain the visual foundation. **The main portrait now falls back to Blizzard’s own class icon or 3D model**, according to the game setting. Verified player-race artwork appears in a **small Totem-style secondary circle** on Player, Target, Focus and regular party frames, anchored to the **outer top corners** (player/party upper-left; target/focus upper-right) and drawn **above** native frame artwork, away from rested-Z and party-leader indicators. **ToT, ToF and PetFrame have no secondary circle**; their main portrait aura systems remain unchanged. Where a complete public aura scan and native filter probes are readable, the circle can instead present the second-ranked **distinct** active aura with a native countdown. Unknown, partial, restricted, or indeterminate reads ordinarily fall back to race/hidden. During combat, an **already verified timed** second aura can remain visible if the new read becomes inaccessible without an aura mutation. This last-positive display is revoked on the first UNIT_AURA event without a successful re-election, at its known expiry, or when the unit identity changes. Skyborne still requires a verified face atlas. PetFrame retains one full primary aura system without a secondary circle.

**PetFrame icon edge cleanup (0.1.186):** The local 37px pet portrait uses a tighter `3/64` source-image crop (previously `1/64`) to keep a square spell-icon rim from peeking through the top of its round aperture. This applies to both pet-family fallback artwork and every aura layer via one shared function. The circular Blizzard bezel, portrait image position, and all other frame crops remain unchanged. Verify the visual result on different pets in game.

**NPC secondary debuffs (0.1.188–0.1.189):** Hostile NPCs on Target or Focus can now use the small circle when a complete, readable public aura snapshot contains two distinct, rankable harmful effects and the projected first-place native harmful slot is positively enabled. This covers categorized harmful effects such as Hamstring > Rend and, where higher semantic filters are readable, the existing generic harmful fallback. The NPC path requires positively proven **non-player** identity, complete helpful and harmful lists, and successful native slot writes. A lower-priority helpful aura no longer vetoes a harmful first-place effect; all present auras must still be ranked and the harmful native main slot positively enabled. It is **not** granted to hostile players, and does **not** read a forbidden native winner. A creature with fewer than two eligible auras (or unreadable data) has **no made-up race or creature icon**; its second circle remains hidden.

**Ordinary native-filter proof (0.1.189):** Some publicly readable auras lack the optional `isNameplateOnly` field. When that field and the per-instance native filter oracle cannot decide whether an aura belongs to a plain HELPFUL/HARMFUL exact lane, the secondary election uses one **bounded same-polarity public indexed scan** to establish matching current `auraInstanceID + spellId`. A positive ordinary filtered membership is sufficient; inaccessible, duplicate and contradictory identity stays unknown. This does **not** bypass combat secrecy or infer unseen auras. Use `/bp secondary debug player` or `/bp secondary debug target` for a concise two-line current election reason without refreshing the portrait.

## Current priority examples

- **Priority 0, absolute bottom:** Shiny Silver Coin (applied **helpful** aura 1321323, +30 Fishing for 30 minutes) in `BottomHelpful`; Boosted Rest (1229451), Tricked or Treated (24755) and both harmful Tamed effects (19685/19686) remain in `BoostedRest`. The helpful/harmful native filters require **two slots at the same numeric priority**, not another priority tier.
- **Gathering 1:** Find Herbs, Find Minerals, Find Treasure. **Tracking 3:** sensing buffs, Sapta Sight, Hunting Kobolds. **Campfire Nearby 4** and **Violet Flames 5**.
- **Seal 210** includes Poised; **Offensive 280** includes Rushing Charge and Savagery; harmful **Control 310** includes Polymorph, while helpful **ControlHelpful 310** covers Frog Form.

See `Priority.lua` and `Spells.lua` for the complete, authoritative levels. Same-tier native order is reverse aura-instance ID; a refreshed buff does not always count as “last applied”. A 3,599-second native `SmallFriendlyHarmful` duration guard prevents Boosted Rest promotion, but also restricts other long/permanent generic harmful effects.

Use `/bp help` for commands, `/bp inspect <unit>` for eligible observed auras, `/bp layout <unit>` and `/bp pets debug pet` for presentation diagnostics. The `/bp secondary on|off` command controls the badge without changing the main portrait. `/bp layout player` reports `secondSpell`, `secondTier`, and `secondReason` for debugging fallback; v0.1.183 also reports the displayed hostile-main spell, tier, aura-instance identity and whether its helpful list completed. This helps distinguish blocked target reads from mismatched first-place evidence. `/bp test` still previews a **synthetic** icon for geometry checks. `/bp decimals` controls decimal countdowns strictly below ten seconds.

## Secondary aura prototype — bounded readable path

**[Design and acceptance plan](docs/SECONDARY_PORTRAIT_PLAN.md)** records the full objective and native API limitations. Version 0.1.180 adds a *conservative* public aura election, independent of the unchanged secure main portrait: complete helpful/harmful indexed lists (up to 48 entries each), verified occurrence IDs, native per-tier filter checks, and bounded probe work (192 per refresh). It understands same-tier native ID order, the three application-time tiers, exact/semantic priorities, and refuses ambiguous equal-level lanes or unavailable timing. It now runs on positively readable **friendly units** and on **targeted hostile units only when their complete public aura evidence and the independently displayed first-place portrait agree**. An independently proven stance/form may also be first when its rank exceeds every readable aura. The client can still withhold hostile aura data, so this does not guarantee a second icon in PvP or restricted combat. For known exact auras, their membership in a completed compatible native polarity scan can prove native eligibility without the extra `IsAuraFilteredOutByInstanceID` lookup; nameplate-only mismatches still require negative checks. Unclassified/semantic aura eligibility still requires the native filter oracle. The 0.1.182 fix preserves an explicitly readable **false** hostile relation as friendly, instead of treating it as unknown. In 0.1.184, the optional combat hold is labeled `secondReason=combat-positive-retained:<reason>` to distinguish last-positive evidence from a current election; it never guesses a new effect while aura data is secret. It falls back to race when any required evidence is absent. **Universal combat/hostile coverage is still not guaranteed; no secure global second-winner API has been discovered.** The NPC harmful projection is a bounded public-data prediction of the native first-place winner, **not direct access to the secure rendered primary**; if one is withheld, it fails closed. The synthetic `/bp test` remains distinct from live evidence.

### Static form / stance ordering (0.1.185)

A positively displayed Warrior stance or Druid form is a **static candidate at priority 149**, not an automatic first-place winner. When a stronger aura is first, the form can be the second portrait without a fabricated cooldown; if two auras are stronger, the true second aura remains second. When the form outranks every aura, the highest-ranked aura is second. For example, **Welcoming Campfire (257) → Battle Stance (149) → Camp Benefits (90)** shows Battle Stance in the small circle, not race or Camp Benefits. These are source/regression expectations, not yet confirmed for every live-client state.

## Documentation and tests

- [Architecture](ARCHITECTURE.md) — source ownership and chronological build changes, including v0.1.173–0.1.178 in section 35.
- [Known issues](KNOWN_ISSUES.md) — current live-verification boundaries and outstanding aura-order issues.
- [Package workflow](.github/workflows/package-addon.yml) — Lua 5.1/5.4 syntax checks, regression scripts, and an installable CI artifact.

This project uses event-driven/native aura systems and conservative evidence permissions, not an unrestricted Lua spell scan on every rendered frame.
