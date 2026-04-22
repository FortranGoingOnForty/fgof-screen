program full_render_demo
  use fgof_screen, only : allocate_screen, clear_screen_style, put_glyph, render_screen_ansi, set_cursor
  use fgof_screen_types, only : screen_buffer, screen_style
  implicit none

  type(screen_buffer) :: buffer
  type(screen_style) :: style
  character(len=:), allocatable :: rendered
  integer :: bytes

  buffer = allocate_screen(4, 2)
  style = clear_screen_style()
  style%fg = 39
  style%bold = .true.

  call put_glyph(buffer, 1, 1, "F", style)
  call put_glyph(buffer, 1, 2, "G", style)
  call put_glyph(buffer, 2, 1, "O")
  call put_glyph(buffer, 2, 2, "F")
  call set_cursor(buffer, 2, 3)

  rendered = render_screen_ansi(buffer)
  bytes = len(rendered)
  write(*, "(a, i0)") "full-bytes=", bytes
end program full_render_demo
