# fgof-screen

Virtual screen buffers and diff rendering helpers for modern Fortran.

`fgof-screen` is intended to be a small, standalone library for virtual screen
state, styled cells, and render-diff workflows that terminal apps keep
rebuilding from scratch.

It is part of the [FortranGoingOnForty lib-modules](https://github.com/FortranGoingOnForty/lib-modules)
catalog, but it is intended to stand on its own as a normal `fpm` package.

Current v1 target:

- stable screen style, cell, size, and buffer types
- predictable virtual-grid allocation and fill helpers
- diffable screen-state model with damage tracking for future ANSI-first rendering
- room for a higher-level renderer without making ncurses the package identity

Future scope:

- optional adapter layers for alternate backends later
- examples and higher-level paint helpers

## Status

Sprint 04 is in place.

Tracked today:

- package layout, CI, and standalone repo setup
- foundational screen types for styles, cells, sizes, and buffers
- virtual-grid allocation, resize, fill, and clear helpers
- explicit cell writes and cursor clamping helpers
- frame diff computation with changed-cell counts and damage bounds
- explicit size, cursor, and cursor-visibility change reporting
- ANSI full-frame rendering
- ANSI diff rendering driven by the damage model
- explicit cursor-state ANSI output
- tracked example programs for full-frame and diff rendering
- render-edge coverage for empty screens and cursor-only diffs
- full-frame ANSI output with explicit row addressing
- render-time sanitization for non-printable control glyphs
- CI on macOS and Ubuntu, including direct example execution
- row-first, column-second grid semantics pinned down in tests
- focused scaffold coverage in `fpm test`

## Public API Shape

Primary modules:

- `fgof_screen`
- `fgof_screen_types`

Public types:

- `screen_style`
- `screen_cell`
- `screen_size`
- `screen_buffer`
- `screen_damage`
- `screen_diff`

Current public procedures:

- `clear_screen_style`
- `clear_screen_cell`
- `clear_screen_damage`
- `clear_screen_diff`
- `clear_screen_size`
- `clear_screen_buffer`
- `allocate_screen`
- `resize_screen`
- `fill_screen`
- `clear_screen`
- `diff_screen`
- `put_cell`
- `put_glyph`
- `render_cursor_ansi`
- `render_screen_ansi`
- `render_screen_diff_ansi`
- `set_cursor`

Current semantics:

- `screen_buffer%cells(row, col)` is the current virtual-grid layout
- `allocate_screen(width, height)` allocates a blank grid for positive sizes
- newly allocated cells start as blank-space cells with default style
- `resize_screen()` preserves overlapping content, blanks newly grown cells, and clamps the cursor into bounds
- `fill_screen()` applies a glyph and optional style across the whole allocated buffer
- `clear_screen()` is the whole-buffer blank fill helper
- `put_cell()` and `put_glyph()` update a specific `(row, col)` location without transposing the grid model
- out-of-bounds cell writes are ignored rather than clamped to another location
- `set_cursor()` keeps cursor position within the allocated grid, or resets it to `(1, 1)` when the buffer is empty
- `diff_screen(previous, current)` compares two virtual frames and reports cell damage separately from size or cursor changes
- `screen_diff%damage` uses one bounding rectangle plus a `changed_cells` count for the changed frame area
- newly added or removed visible cells from resizes count as changed damage even when their glyphs are blank
- `render_screen_ansi()` emits a whole-frame ANSI repaint with clear/home semantics, explicit row addressing, and final cursor restoration
- `render_screen_diff_ansi()` emits a damage-scoped ANSI repaint and uses blank cells to erase removed content after shrinks
- `render_cursor_ansi()` emits the final cursor move plus visibility state for a screen buffer
- ANSI row rendering tracks style transitions explicitly and resets back to default style when needed
- ANSI renderers replace ASCII control glyphs with `?` so screen cells cannot inject raw control bytes into the output stream

## Build And Test

```bash
fpm test
```

Tracked examples:

- [full_render_demo.f90](example/full_render_demo.f90)
- [diff_render_demo.f90](example/diff_render_demo.f90)

## Supported Platforms

- macOS
- Linux

## Boundaries

- intended to stay independently versioned and releasable
- focused on virtual screen state first, not full terminal control yet
- should stay useful on its own even if future prompt or TUI packages build on top

## License

MIT
