program test_screen_diff
  use fgof_screen, only : &
    allocate_screen, &
    clear_screen_diff, &
    clear_screen_style, &
    diff_screen, &
    put_glyph, &
    resize_screen, &
    set_cursor
  use fgof_screen_types, only : screen_buffer, screen_diff, screen_style
  implicit none

  type(screen_buffer) :: previous
  type(screen_buffer) :: current
  type(screen_diff) :: diff
  type(screen_style) :: style

  diff = clear_screen_diff()
  if (diff%changed) error stop "screen diff should start unchanged"
  if (diff%damage%active) error stop "screen diff damage should start inactive"
  if (diff%damage%changed_cells /= 0) error stop "screen diff should start with zero changed cells"

  previous = allocate_screen(4, 3)
  current = allocate_screen(4, 3)

  diff = diff_screen(previous, current)
  if (diff%changed) error stop "identical screens should not diff as changed"
  if (diff%damage%active) error stop "identical screens should not report damage"

  style = clear_screen_style()
  style%fg = 42
  call put_glyph(current, 2, 3, "X", style)
  diff = diff_screen(previous, current)
  if (.not. diff%changed) error stop "single-cell change should mark diff changed"
  if (.not. diff%damage%active) error stop "single-cell change should produce damage"
  if (diff%damage%changed_cells /= 1) error stop "single-cell change should count one changed cell"
  if (diff%damage%row_first /= 2 .or. diff%damage%row_last /= 2) error stop "single-cell change should preserve row damage bounds"
  if (diff%damage%col_first /= 3 .or. diff%damage%col_last /= 3) error stop "single-cell change should preserve column damage bounds"

  call put_glyph(current, 1, 1, "A")
  diff = diff_screen(previous, current)
  if (diff%damage%changed_cells /= 2) error stop "two changed cells should count both changes"
  if (diff%damage%row_first /= 1 .or. diff%damage%row_last /= 2) error stop "multiple changes should expand row damage bounds"
  if (diff%damage%col_first /= 1 .or. diff%damage%col_last /= 3) error stop "multiple changes should expand column damage bounds"

  current = previous
  call set_cursor(current, 3, 4)
  diff = diff_screen(previous, current)
  if (.not. diff%changed) error stop "cursor movement should mark the diff changed"
  if (.not. diff%cursor_changed) error stop "cursor movement should be reported explicitly"
  if (diff%damage%active) error stop "cursor movement alone should not mark cell damage"

  current = previous
  current%cursor_visible = .false.
  diff = diff_screen(previous, current)
  if (.not. diff%cursor_visibility_changed) error stop "cursor visibility changes should be reported explicitly"

  current = previous
  call resize_screen(current, 5, 3)
  diff = diff_screen(previous, current)
  if (.not. diff%size_changed) error stop "screen resize should mark size changes"
  if (.not. diff%damage%active) error stop "screen growth should produce damage"
  if (diff%damage%changed_cells /= 3) error stop "screen growth should count new cells as changed"
  if (diff%damage%row_first /= 1 .or. diff%damage%row_last /= 3) error stop "screen growth should bound rows over the grown area"
  if (diff%damage%col_first /= 5 .or. diff%damage%col_last /= 5) error stop "screen growth should bound columns over the grown area"
end program test_screen_diff
