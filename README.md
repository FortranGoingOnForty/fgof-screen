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
- diffable screen-state model for future ANSI-first rendering
- room for a higher-level renderer without making ncurses the package identity

Future scope:

- frame diff computation and damage regions
- ANSI rendering helpers and cursor-state output
- optional adapter layers for alternate backends later

## Status

Initial scaffold is in place.

Tracked today:

- package layout, CI, and standalone repo setup
- foundational screen types for styles, cells, sizes, and buffers
- basic virtual-grid allocation and fill helpers
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

Current public procedures:

- `clear_screen_style`
- `clear_screen_cell`
- `clear_screen_size`
- `clear_screen_buffer`
- `allocate_screen`
- `fill_screen`

Current semantics:

- `screen_buffer%cells(row, col)` is the current virtual-grid layout
- `allocate_screen(width, height)` allocates a blank grid for positive sizes
- newly allocated cells start as blank-space cells with default style
- `fill_screen()` applies a glyph and optional style across the whole allocated buffer

## Build And Test

```bash
fpm test
```

## Supported Platforms

- macOS
- Linux

## Boundaries

- intended to stay independently versioned and releasable
- focused on virtual screen state first, not full terminal control yet
- should stay useful on its own even if future prompt or TUI packages build on top

## License

MIT
