# Vaxorin ESP Builder v3

Updated visual ESP editor and world renderer.

## Editor fixes
- Added a real Back button.
- Added Import next to Save/Export.
- Converted remaining German UI labels/descriptions to English.
- Preview element selection now uses dedicated hitboxes so clicking text selects only that element.
- Dragging and resizing use the selected element's own bounds.
- Preview positioning uses the same design-space anchor model as the world renderer.
- Added more component types: Corner Box, Filled Box, Health %, Head Marker, Skeleton, Team, Class, and State.
- Added a Full preset containing a broader set of elements.

## Renderer fixes
- Uses the same design-space transform as the editor.
- Added Filled Box, Corner Box, Head Marker, and Skeleton rendering.
- Skeleton supports both R15-style and R6-style part names.
- Tracer start position follows its editor coordinates instead of being hard-coded to the target box bottom.
- Removed the old viewport-visibility gate that could incorrectly suppress valid projected bounds.
- Default maximum distance is 5000 studs when no value is supplied; an explicit `MaxDistance` still wins.

The renderer is intended for Roblox experiences/projects where you control the rendering context.
