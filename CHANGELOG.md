# 0.1.60-local

- Integer-only native cooldown text, still suppressed above 60 seconds.
  Existing `showDecimals` values are retired and `/bp decimals` is removed.
  Unsupported/rejected native formatters hide numbers, leaving icons and native
  cooldown progression intact; they cannot silently reintroduce decimals or
  long-duration numbers.
- Verified taunts share the actual Faerie Fire/LowDebuff election at 200.
- All five player ranks each of Demoralizing Shout and Roar share one harmful
  election at 185, below DoTs at 190.
- Raptor Punch aura 6114 joins the existing persistent WellFed election at 110.
  Sources and build-specific spell evidence are in `SPELL_EVIDENCE.md`.
- Includes the prior global-off host/pet ownership and false diagnostic fixes.

The removed Taunt lane and added Demoralizing lane leave the number of native
containers unchanged. Added spells remain static set membership. No runtime
name scans, timer arithmetic, or polling were introduced.

All offline tests run in Lua 5.1 through Lupa. Live-client rendering/taint,
rank availability and aura application still need in-game confirmation. The
conditional readable-stream/UNKNOWN audit findings remain unchanged.
