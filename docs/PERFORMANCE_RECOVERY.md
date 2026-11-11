# Performance recovery — bjarkiPortraits 0.1.249

**Branch:** `rescue/low-overhead-0.1.249` · **Base:** 0.1.248 on main · **Scope:** reduce source-demonstrated excess timer allocations without feature rollback or changes to main.

## Demonstrated source-level cost

Blizzard's Forever `CustomAuraContainer` frame provider preallocates **10 button frames per group**, irrespective of how many auras are present. `NativeSecondProbe.lua` configures up to 62 ranked groups for Player, Target and Focus. The 0.1.248 implementation called `R.AttachPortraitAuraClock` and enabled `R.ApplyPortraitTimer` for **every preallocated native-secondary cooldown**. Each fixed renderer creates six native `DurationTextBinding` receivers and six FontStrings, set to minimum 0.1-second update intervals. Worst-case additional fixed receivers: 62 × 10 × 6 = **3,720 per host**, or **11,160 across three hosts**. This is a structural upper-bound calculation, not an in-game profiler measurement.

## Surgery, not rewrite

- Set `cooldown._bjarkiLightNativeSecond = true` only on native-second group button cooldowns, before formatting.
- `Core.ApplyCountdownFormat` uses Blizzard's same 60s-capped native numeric formatter for these receivers and does not construct fixed glyph cells.
- Remove `R.AttachPortraitAuraClock` on this specific path: native cooldowns already receive client-owned, possibly protected durations.
- `needsFormatterRecovery` treats the deliberate `formatter` backend as success, avoiding 620 pointless fixed-cell retries per host on a formatter-epoch change.
- Leave **primary** and **readable secondary** fixed-position glyphs untouched, along with the tier map, icon/rim geometry, combat authorization, target identity, pool state, school interrupts, and 60-second/decimal formatting.

Tradeoff: Native fallback seconds use one numeric label and may not retain perfectly fixed per-digit optical placement. This is limited to the native fallback; it does not alter the large portrait or positively readable secondary countdowns.

## Automated verification

GitHub Actions invokes `tools/verify.py`, parsing all 15 modules and running all 35 Lua regression scripts under 5.1 and 5.4, then packaging 17 runtime files. Updated `tests/native-second-probe.lua` checks the native default is cheap, no extra duration-bar bridge exists, formatter success does not trigger glyph retries, and pooled reuse stays cheap. `tests/decimal-threshold.lua` uses the **actual Core formatter** to verify the flag bypasses fixed-cell allocation while retaining the capped formatter. See the [recovery branch CI](https://github.com/bjoern-janson/bjarkiPortraits/actions/workflows/package-addon.yml?query=branch%3Arescue%2Flow-overhead-0.1.249).

The change has **no measured live FPS claim**. If needed, compare the pre-existing main build without overwriting it. No changes were made to bjarkiUI, bjarkiCC or bjarkiLearn as part of this narrow recovery.
