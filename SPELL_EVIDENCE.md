# Spell additions, 2026-10-02

Records read directly in ForeverDB's rendered database, which identifies its
source as client extraction from **1.60.1.70170**, extracted October 2.
These are client-data checks, not observations of applied auras in a live fight.

| Family | Applied spell IDs, ranks in order | Evidence | Election |
| --- | --- | --- | --- |
| Demoralizing Shout | 1160, 6190, 11554, 11555, 11556 | [Spell effects and all-rank links](https://foreverdb.net/spell/1160): attack-power aura; 45-second duration | Demoralizing, 185 |
| Demoralizing Roar | 99, 1735, 9490, 9747, 9898 | [Spell effects and all-rank links](https://foreverdb.net/spell/99): attack-power aura; 30-second duration | Same Demoralizing election, below DoTs at 190 |
| Raptor Punch | 6114 | [Spell effects and buff tooltip](https://foreverdb.net/spell/6114): two stat auras, Intellect +4 / Stamina -5, five minutes | Existing WellFed, 110 |

Raptor Punch is persistent food-buff presentation, not the active eating/drinking
recovery lane. Item 5342 is not an aura identity. No spell-name scan is introduced.
The higher player ranks are included as verified data, even if above the beta cap.

The existing verified taunt set is unchanged and unioned with `debuffs_other`
before creating the LowDebuff container (200), the lane that owns Faerie Fire.
One native AuraInstanceID election therefore resolves ties between both families.

No new NPC variants are admitted on name equality. Future corpus entries must
record applied ID, effects, duration, source/build, and any live observation
separately. Existing UNKNOWN/completeness findings remain conditional.
