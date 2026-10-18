# CyberUI quality audit — Chart / Config / Favorites

## Changes in this pass

### `src/Core/Config.lua`
- `Get()` now supports both legacy flat dotted keys (for example `Flags.Aim.Enabled`) and nested-table reads, without breaking existing config files.
- `Load()` validates the decoded root type and protects decoding as well as JSON parsing, so malformed tagged values fail safely rather than escaping the loader.
- `SetLocation()` sanitizes both folder and file names and ignores empty overrides.
- Failed reads/decodes now emit a warning with the config path.

### `src/Elements/Chart.lua`
- Added `Suffix` to `ChartOptions`, matching the existing runtime behavior.
- Sanitized `Bars`, `Max`, and `Height` inputs against non-numeric and non-finite values.
- Clamped chart dimensions to sensible bounds.
- Formatted whole numbers without decimals and trimmed trailing zeros from decimal values.
- Prevented `NaN` / infinite samples from corrupting the display.
- Chart scaling now uses absolute magnitude, so negative samples don't force every bar to the minimum height. The displayed numeric value remains signed.

### `src/init.lua` and `src/Core/Window.lua`
- Favorites are now loaded from configuration when config saving is enabled.
- Adding/removing a favorite updates the saved `Favorites` table and queues an autosave when autosave is enabled.
- Saved favorites are validated before being restored.
- Window destruction is idempotent, destroys the weather layer/connection, clears the GUI reference, and unregisters the window from the library.
- Library-wide destruction iterates a snapshot so windows can safely unregister themselves during cleanup.

## Validation status

This environment does not include Roblox Studio or a Luau runtime, so I could not execute the UI or run Roblox integration tests. These changes were statically reviewed; please run the manual checks below in Studio / your supported runtime before publishing.

## Manual regression checklist

1. Start with no config file; UI should still open and default values should remain usable.
2. Save config, restart, and verify toggle values restore.
3. Load a malformed JSON file; loading should return `false` and warn instead of crashing the UI.
4. Load legacy config containing flat keys such as `Flags.SomeToggle`; values should still hydrate.
5. Read a nested config key using `Get("Flags.SomeToggle")` when the stored data is nested.
6. Favorite a toggle, save/restart, and verify the favorite is still listed.
7. Unfavorite a toggle, save/restart, and verify it stays removed.
8. Create a chart with `Suffix = " ms"`, then push `0`, a decimal, a negative value, `NaN`-like input, and a very large value; the UI should remain stable.
9. Test chart options with missing, non-numeric, or extreme `Bars`, `Height`, and `Max` values.
10. Close/destroy the window twice; cleanup should be safe, the weather layer should disappear, and the library should not retain a stale window reference.
11. Destroy a library with multiple windows and verify all windows are cleaned up.


## Visual refresh follow-up

### `src/Core/Theme.lua`
- Refined the default Vaxorin palette with clearer surface separation and calmer border contrast.
- Tightened default corner radii, control height, window dimensions, sidebar width, and spacing for a more compact dashboard.
- Added semantic `Focus`, `DisabledText`, and `Overlay` theme tokens so future components can use shared states rather than hard-coded colors.

### `src/Core/Tab.lua`
- Removed a duplicate `Tween` module import.

### Validation
- Checked that all files in the project archive remain readable and that the ZIP can be rebuilt.
- A Luau interpreter / Roblox Studio is not available in this environment, so runtime and visual regression checks remain manual.
