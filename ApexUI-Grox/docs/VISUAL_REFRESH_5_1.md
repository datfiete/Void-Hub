# CyberUI visual refresh 5.1

This pass focuses on the design system instead of changing the public element API.

## Design goals
- Keep the dark violet CyberUI identity while improving readability.
- Make background, panel, and control surfaces visually distinct.
- Reduce the default visual footprint so content gets more space.
- Introduce semantic tokens for focus, disabled text, and overlays.

## Updated defaults
- Window: 900 × 590 (previously 920 × 600)
- Sidebar: 196 px (previously 202 px)
- Top bar: 64 px (previously 72 px)
- Element height: 42 px (previously 44 px)
- Corner radii: 12 px / 8 px (previously 14 px / 10 px)
- Padding and gap: 16 px / 10 px (previously 18 px / 12 px)

## Compatibility
- Existing style names and public element APIs are unchanged.
- The `Meng` theme alias remains available.
- `Deep` keeps its own compact sizing.
- New semantic theme tokens are additive.

## Verification note
This was statically reviewed only. Please verify all style presets, scaling, and layout variants in Roblox Studio before release.
