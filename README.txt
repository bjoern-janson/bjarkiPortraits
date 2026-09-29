bjarkiPortraits 0.1.8-clean

Fresh runtime. The established spell-ID catalog is retained as data, but the
portrait engine was rebuilt from an empty implementation.

Visual contract:
- Blizzard frame chrome stays untouched in its native layer.
- The native portrait and secure aura replacement share one deliberately lower
  layer, so the aura reads as the portrait rather than as a sticker over it.
- Blizzard's own portrait mask is reused directly.
- ToT/FoT use the same primitive as the large frames, with only their accepted
  optical icon/timer offsets.
- Pet foundations are target/focus/PetFrame presentation only; they never run
  on ToT/FoT and have no access to AuraContainer state.

Commands: /bp help


v0.1.1-clean
- Fixes hostile helpful relation gating: exact helpful spell-ID tiers are never enabled on hostile players.
- Restores opposite-faction helpful aura support with a two-path design:
  readable hostile identities use the tracked whitelist directly; restricted identities fall back to Blizzard's secure HELPFUL stream.
- Keeps portrait geometry, masks, parents, strata, timer offsets, and pet portrait layout unchanged from v0.1.0-clean.
- /bp debug now reports hostilePlayer, exactHelpful, hostileReadable, hostileCount, and hostileSpell.


v0.1.2-clean
- Adds an exact readable fallback for Resurrection Sickness (15007) on self/friendly units when Forever relation-gates the secure harmful spell-ID filter.
- The secure exact ResSickness tier remains authoritative wherever it is legal.
- No portrait geometry, mask, parent, strata, timer, pet portrait, or hostile-helpful logic changed from v0.1.1-clean.


v0.1.3-clean
- Fixes the v0.1.2 ToT/FoT regression.
- Resurrection Sickness readable fallback surfaces are now created only for player/target/focus.
- Target-of-target and focus-target host construction is restored to the v0.1.1 structure.
- No portrait geometry, masks, strata, timer offsets, hostile-helpful logic, or spell priorities changed.


v0.1.7-clean
- Fixes the actual ToT/FoT disappearance mechanism: native small-frame portraits are no longer reparented or reanchored.
- ToT/FoT secure aura hosts are children of Blizzard's native derived unit frames.
- The native TextureFrame chrome is kept above the PTF priority stack and its original frame level is restored on teardown.
- Large player/target/focus portrait behavior and v0.1.1 hostile-aura policy are unchanged.
- Resurrection Sickness readable fallback remains limited to player/target/focus.


v0.1.7-clean
- ToT/FoT visual repair only: adds an addon-owned circular icon mask when the current client exposes no native PortraitMask.
- Clones Blizzard's existing ToT/FoT chrome texture into an addon-owned top overlay so the native ring sits visually above portrait auras.
- No native ToT/FoT portrait, chrome, parent, points, visibility, or frame level is mutated.
- Aura admission/priority logic is unchanged from v0.1.4.


v0.1.8-clean
- Restores BaselineClass same-tier recency: the most recently applied or refreshed
  readable class buff replaces older buffs in the same tier.
- Uses application time (expirationTime - duration) only when timing is readable
  for every competing BaselineClass aura; otherwise falls back to newest
  auraInstanceID across the complete tier.
- If aura identity/timing becomes restricted, the readable override abstains and
  the secure BaselineClass AuraContainer remains authoritative.
- No portrait geometry, ToT/FoT offsets, masks, parents, strata, chrome, pet
  portraits, hostile-helpful policy, or spell priorities changed from 0.1.7.
