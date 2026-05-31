program test_screen_render_ansi
  use fgof_screen, only : &
    allocate_screen, &
    clear_screen_style, &
    render_cursor_ansi, &
    render_screen_ansi, &
    render_screen_diff_ansi, &
    put_glyph, &
    resize_screen, &
    set_cursor
  use fgof_screen_types, only : screen_buffer, screen_style
  implicit none

  type(screen_buffer) :: previous
  type(screen_buffer) :: current
  type(screen_style) :: style
  character(len=:), allocatable :: rendered
  character(len=:), allocatable :: expected
  character(len=:), allocatable :: esc

  esc = achar(27) // "["

  previous = allocate_screen(2, 2)
  call put_glyph(previous, 1, 1, "A")
  call put_glyph(previous, 1, 2, "B")
  call put_glyph(previous, 2, 1, "C")
  call put_glyph(previous, 2, 2, "D")
  call set_cursor(previous, 2, 1)

  expected = esc // "?25l" // esc // "2J" // esc // "H" // &
             esc // "1;1H" // "AB" // esc // "2;1H" // "CD" // &
             esc // "0m" // esc // "2;1H" // esc // "?25h"
  rendered = render_screen_ansi(previous)
  if (rendered /= expected) error stop "render_screen_ansi should use explicit row addressing for full-frame repaints"

  current = allocate_screen(2, 1)
  call put_glyph(current, 1, 1, "┌")
  call put_glyph(current, 1, 2, "─")
  expected = esc // "?25l" // esc // "2J" // esc // "H" // &
             esc // "1;1H" // "┌─" // esc // "0m" // esc // "1;1H" // esc // "?25h"
  rendered = render_screen_ansi(current)
  if (rendered /= expected) error stop "render_screen_ansi should preserve UTF-8 glyph bytes"

  style = clear_screen_style()
  style%fg = 33
  style%bold = .true.
  current = allocate_screen(2, 1)
  call put_glyph(current, 1, 1, "X", style)
  current%cursor_visible = .false.
  expected = esc // "0m" // esc // "1m" // esc // "38;5;33m" // "X" // esc // "0m" // " " // esc // "0m" // esc // "?25l"
  rendered = render_screen_ansi(current)
  if (index(rendered, expected) == 0) error stop "render_screen_ansi should emit ANSI style codes and final hidden-cursor state"

  rendered = render_cursor_ansi(previous)
  expected = esc // "2;1H" // esc // "?25h"
  if (rendered /= expected) error stop "render_cursor_ansi should move to the buffer cursor and show it"

  previous = allocate_screen(3, 1)
  call put_glyph(previous, 1, 1, "A")
  call put_glyph(previous, 1, 2, "B")
  call put_glyph(previous, 1, 3, "C")
  current = previous
  call put_glyph(current, 1, 2, "X")
  call set_cursor(current, 1, 2)
  rendered = render_screen_diff_ansi(previous, current)
  expected = esc // "?25l" // esc // "1;2H" // "X" // esc // "0m" // esc // "1;2H" // esc // "?25h"
  if (rendered /= expected) error stop "render_screen_diff_ansi should redraw changed cells and restore cursor state"

  current = previous
  call resize_screen(current, 2, 1)
  rendered = render_screen_diff_ansi(previous, current)
  expected = esc // "?25l" // esc // "1;3H" // " " // esc // "0m" // esc // "1;1H" // esc // "?25h"
  if (rendered /= expected) error stop "render_screen_diff_ansi should blank removed cells after shrink"
end program test_screen_render_ansi
