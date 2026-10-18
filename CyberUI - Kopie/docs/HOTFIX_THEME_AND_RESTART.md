# CyberUI hotfix — theme refresh and clean restart

## Fixes in this pass

- Favorite stars now refresh their color and transparency when the theme changes.
- Progress tracks and Stat surfaces use the active theme's background/border colors.
- IconButton hover handlers read the current theme at interaction time instead of retaining stale theme colors.
- Chart value colors are refreshed consistently, including explicitly configured colors.
- Re-executing the library shuts down active toggle callbacks before destroying the previous UI. Active saved toggle flags are written as `false` before the next run loads configuration.
- The previous library is destroyed before the new library loads its config, avoiding a stale `true` config value being hydrated into the new UI.
- Queued toggle callbacks and `FireOnLoad` callbacks are ignored if the library has been destroyed or the toggle state has changed before they run.

## Important behavior

On library restart, active toggle-backed features are deliberately turned off. This is intended to stop loops/connections started by toggle callbacks. A callback must correctly handle `Callback(false)` and clean up its own external connections/tasks. The library cannot automatically stop arbitrary tasks that a feature callback starts without retaining or honoring a cancellation handle.

## Manual verification checklist (Roblox Studio)

1. Switch between every available theme and verify favorite stars, Progress, Stat, Chart, Badge, Status, Notice, and IconButton.
2. Turn on a callback-backed `Auto...` toggle, run the UI again, and verify the previous callback receives `false` and the new toggle starts off.
3. Rapidly turn a toggle on/off or restart immediately after enabling it; verify a queued stale callback does not re-enable it.
4. Confirm normal toggles and config save/load still behave as intended.
5. Test with a callback that starts a loop and ensure its `false` branch actually cancels the loop.
