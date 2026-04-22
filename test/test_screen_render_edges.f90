program test_screen_render_edges
  use fgof_screen, only : &
    allocate_screen, &
    render_screen_ansi, &
    render_screen_diff_ansi, &
    set_cursor
  use fgof_screen_types, only : screen_buffer
  implicit none

  type(screen_buffer) :: previous
  type(screen_buffer) :: current
  character(len=:), allocatable :: rendered
  character(len=:), allocatable :: esc
  character(len=:), allocatable :: expected

  esc = achar(27) // "["

  previous = allocate_screen(0, 0)
  rendered = render_screen_ansi(previous)
  expected = esc // "?25l" // esc // "2J" // esc // "H" // esc // "0m" // esc // "1;1H" // esc // "?25h"
  if (rendered /= expected) error stop "empty full render should still clear, reset style, and restore cursor state"

  current = allocate_screen(2, 2)
  previous = current
  rendered = render_screen_diff_ansi(previous, current)
  if (rendered /= "") error stop "identical screens should produce an empty diff render"

  call set_cursor(current, 2, 2)
  rendered = render_screen_diff_ansi(previous, current)
  expected = esc // "2;2H" // esc // "?25h"
  if (rendered /= expected) error stop "cursor-only diffs should render only final cursor output"

  current = previous
  current%cursor_visible = .false.
  rendered = render_screen_diff_ansi(previous, current)
  expected = esc // "?25l"
  if (rendered /= expected) error stop "cursor-visibility-only diffs should render only the visibility change"
end program test_screen_render_edges
