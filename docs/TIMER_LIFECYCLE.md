# Portrait timer ownership and lifecycle

This is the **0.1.249 recovery** contract. The native preallocated second-aura clocks no longer use fixed six-cell bindings; the main and readable-secondary clocks still do. It preserves the fixed-font timer work and explains the .246 deferred construction and .247 initializer recovery. For module/event navigation, see the [code map](CODE_MAP.md); for commands and acceptance checks, see [testing](TESTING.md).

## Who owns the clock and the pixels

| Presenter | Clock source | Addon responsibility |
| --- | --- | --- |
| Native primary aura button | Native aura duration owned and updated by the client | Configure its icon/cooldown receiver and attach the public duration-bar bridge. Do not inspect private aura fields. |
| Native second aura button | Native aura duration inside the secondary container | Configure native cooldown artwork and the capped 60s native formatter. Do **not** install six extra glyph bindings or a hidden StatusBar bridge per preallocated native-secondary button. Native groups still select and update actual occurrences. |
| Readable aura projection / public secondary badge | Verified current occurrence passed through the public cooldown setters | Bind the correct occurrence, clear a stale clock, and preserve recipient/election proof. |
| School-interrupt presenter | Native duration object when accepted; otherwise corroborated public timing | `R.SetSchoolInterruptClock` installs that clock. If neither works, accept art-only presentation only after clearing old digits succeeds. |
| Race, Ghost, stance/form or pet-family fallback | No invented aura duration | Show only supported artwork/state and clear prior timed presentation. |

The client owns the native aura duration and its updates. `PortraitTimerSpacing.lua` owns the addon-created glyph cells and their native `DurationTextBinding` receivers. `AuraEngine.lua`, `SecondaryPortrait.lua` and `NativeSecondProbe.lua` own the presenters that decide which clock belongs on which portrait. A visible native icon does not make its hidden identity or countdown readable to Lua.

## Fixed cells and the 60-second policy

`R.ApplyCountdownFormat` tries fixed cells first, a capped native formatter second, and hidden numbers last. It never deliberately falls back to an uncapped stock number. Icon and swipe clocks remain separate from number visibility.

`R.GetCountdownFormatter` uses tenths below ten seconds when `/bp decimals` is enabled, truncated whole seconds through **sixty inclusive**, then empty text. It checks public constants to select a cutoff just above 60 at the native API's supported precision. At 60 seconds, the next binary64 value is `60+2^-47` and the next binary32 value is `60+2^-18`; using the previous 30-second increments would incorrectly suppress exactly 60. Native decimal rounding is preserved, including `10.0` just below the transition; it is not an addon approximation of remaining time.

`R.ApplyPortraitTimer` prepares six fixed-position cells using the existing final label's font file, size, flags, effective/text scale, color and shadow. Secondary labels use `GameFontNormalSmall` through `R.ApplySecondaryCountdownFont`; primary labels keep their host-specific styling and placement. The decimal separator and single whole digit use the center cell; two-digit whole seconds use their own compact positions. Lua samples public constants to build/verify native glyph rules, and native bindings render the live clock. It does not read displayed text or the live private remaining value.

For eligible native **primary** buttons (not the lightweight native SECOND fallback), `R.AttachPortraitAuraClock` registers an addon-owned hidden StatusBar with `button:SetDurationBar(bar, {})`, then obtains the opaque duration object through `bar:GetTimerDuration()`. A separate synthetic public duration probe verifies that transport retains a mutable reference. The live aura duration is passed to bindings without calling its numeric getters. Private native clock updates can bypass public `Cooldown:SetCooldown` hooks, which is why those hooks alone are insufficient.

For public projections, hooks on `SetCooldownFromDurationObject`, `SetCooldown` and `Clear` update or revoke the cell binding. Numeric clock construction requires readable finite public values. On failure, the cell group is hidden/deactivated before ordinary capped formatting can return; this prevents mixed old/new digits. The same clock, formatter and style are reused when unchanged. Preference changes, explicit verification and a new formatter retry epoch can revisit failed or fallback presentation.

## Deferred native second construction and .247 recovery

The native second path is best effort for Player, Target and Focus when a complete public second election cannot be presented. It is not a secure global runner-up identity API. Each group contributes at most two display slots, but the native frame provider can preallocate ten buttons per group. With the current 62 plans, the modeled full tree therefore allocates 620 cooldowns and up to 3,720 fixed-cell bindings per host. These are allocation counts, not live timing measurements.

1. `R.CreateNativeSecondProbe` publishes the probe's owner before partial work begins. `prepareGroupTree` keeps its clip hidden and its container disabled while building.
2. One shared `C_Timer.After(.01, ...)` queue processes at most one group per callback. Tickets require the current host, enabled settings and a visible supported owner. Combat pauses construction without self-polling; rejected or synchronous scheduling cannot drain it recursively.
3. `makeButton` stores completed allocations in a `parts` record: icon, mask, border and cooldown, plus receipts that the mask was attached and the cooldown listed. These records describe addon initialization work, not aura membership or native protected frame contents.
4. The client can catch initializer exceptions and still successfully register the group. The addon therefore retains a failed initializer in `probe.pendingButtons`. Neither `probe.groups` nor tree readiness can advance while that list is nonempty.
5. A later forced safe update retries unfinished recipients in the already-registered group. It reuses the same artwork, mask and cooldown instead of accumulating replacements. A normal aura update does not spin failed construction; repeated failure at the same group quarantines the probe until its release/reuse lifecycle resets it.
6. Only a completed tree sets `probe.ready`. The completion callback invokes `R.Refresh(host.unit, true)` to obtain current recipient evidence and eligibility. Binding then uses a valid unit string and `SetEnabled(true)` before the clip can be shown. A Target/Focus change during construction cannot authorize the old recipient.

Release cancels construction tickets and hides the viewport. A failed hide retains the current owner for retry. A hidden probe can be pooled with an unfinished disable, but the next owner must complete that disable before rebinding. `SetUnit(nil)` is not a valid pool reset. Unfinished initialization records remain with the pooled probe so the new owner can finish them safely.

## Target/Focus school-interrupt lifecycle

`Main.lua` handles `LOSS_OF_CONTROL_ADDED` and `LOSS_OF_CONTROL_UPDATE` by querying each matching host's current recipient. `R.GetSchoolInterrupt` reads landed `SCHOOL_INTERRUPT` rows, elects distinct effects and resolves their clocks. A spell ID, aura instance, recipient token and timing record supply different evidence. Positively linked duplicate reports share one rank; equal artwork alone is insufficient.

`updateSchoolInterrupt` in `AuraEngine.lua` owns the primary lockout presenter, recipient invalidation and expiry wake. `SecondaryPortrait.lua` integrates the runner into the readable election and owns its secondary clock. A current player alias may use player-only evidence only while `UnitIsUnit` confirms that relationship. Target and Focus are read independently.

On target/focus binding changes, the immediate refresh invalidates the old recipient and one deferred pass checks the settled token. Clock identity matters even when two recipients would show the same icon and digits. Removed aura occurrences or bridge links can invalidate a retained pair despite later unreadable lists. Expiry wakes reconcile current state and can promote a surviving effect; stale host/ticket work cannot paint a replaced host. A native aura-only ribbon must not bypass an active lockout's rank without sufficient current evidence.

## Evidence boundary

The [fixed-cell test](../tests/portrait-timer-spacing.lua) models private native duration mutation that bypasses public setters, refusal/recovery, binding reuse, decimal preferences and native single/double precision. The [native-second test](../tests/native-second-probe.lua) models ten-button preallocation, interrupted construction, swallowed initializer errors, pool reuse and current-recipient completion. [Interrupt ownership](../tests/secondary-ownership.lua) covers Target and Focus, linked effects and clock replacement; [restoration tests](../tests/portrait-restoration.lua) exercise layout/reuse work.

Those checks establish the modeled source behavior. The .247 initializer failure was injected; it was not established as the cause of the reported live hitch. Exact client glyph placement, protected execution, mutable duration transport on the installed client and the effect on frame time still require a live Forever retest. [Current verification limits](../KNOWN_ISSUES.md)
