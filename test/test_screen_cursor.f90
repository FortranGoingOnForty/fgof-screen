program test_screen_cursor
  use fgof_screen, only : allocate_screen, resize_screen, set_cursor
  use fgof_screen_types, only : screen_buffer
  implicit none

  type(screen_buffer) :: buffer

  buffer = allocate_screen(5, 3)
  if (buffer%cursor_row /= 1) error stop "allocated screen cursor should start at row one"
  if (buffer%cursor_col /= 1) error stop "allocated screen cursor should start at column one"

  call set_cursor(buffer, 2, 4)
  if (buffer%cursor_row /= 2) error stop "set_cursor should preserve in-range row values"
  if (buffer%cursor_col /= 4) error stop "set_cursor should preserve in-range column values"

  call set_cursor(buffer, 99, 0)
  if (buffer%cursor_row /= 3) error stop "set_cursor should clamp row to screen height"
  if (buffer%cursor_col /= 1) error stop "set_cursor should clamp column to screen width bounds"

  call resize_screen(buffer, 2, 2)
  if (buffer%cursor_row /= 2) error stop "resize_screen should clamp cursor row after shrinking"
  if (buffer%cursor_col /= 1) error stop "resize_screen should preserve clamped cursor column after shrinking"

  call resize_screen(buffer, 0, 0)
  if (buffer%cursor_row /= 1) error stop "zero-sized resize should reset cursor row"
  if (buffer%cursor_col /= 1) error stop "zero-sized resize should reset cursor column"
end program test_screen_cursor
