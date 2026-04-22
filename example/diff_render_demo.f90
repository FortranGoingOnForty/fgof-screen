program diff_render_demo
  use fgof_screen, only : allocate_screen, diff_screen, put_glyph, render_screen_diff_ansi, set_cursor
  use fgof_screen_types, only : screen_buffer, screen_diff
  implicit none

  type(screen_buffer) :: previous
  type(screen_buffer) :: current
  type(screen_diff) :: diff
  character(len=:), allocatable :: rendered

  previous = allocate_screen(3, 1)
  call put_glyph(previous, 1, 1, "A")
  call put_glyph(previous, 1, 2, "B")
  call put_glyph(previous, 1, 3, "C")

  current = previous
  call put_glyph(current, 1, 2, "X")
  call set_cursor(current, 1, 2)

  diff = diff_screen(previous, current)
  rendered = render_screen_diff_ansi(previous, current)

  write(*, "(a, i0)") "damage-cells=", diff%damage%changed_cells
  write(*, "(a, i0)") "diff-bytes=", len(rendered)
end program diff_render_demo
