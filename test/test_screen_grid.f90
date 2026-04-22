program test_screen_grid
  use fgof_screen, only : allocate_screen, clear_screen, put_cell, put_glyph, resize_screen
  use fgof_screen, only : clear_screen_cell, clear_screen_style
  use fgof_screen_types, only : screen_buffer, screen_cell, screen_style
  implicit none

  type(screen_buffer) :: buffer
  type(screen_cell) :: cell
  type(screen_style) :: style

  buffer = allocate_screen(4, 3)

  style = clear_screen_style()
  style%fg = 21
  style%underline = .true.
  call put_glyph(buffer, 2, 3, "X", style)
  if (buffer%cells(2, 3)%glyph /= "X") error stop "put_glyph should target row-column order"
  if (buffer%cells(2, 3)%style%fg /= 21) error stop "put_glyph should apply style overrides"
  if (.not. buffer%cells(2, 3)%style%underline) error stop "put_glyph should preserve style flags"
  if (buffer%cells(3, 2)%glyph /= " ") error stop "put_glyph should not transpose row and column"

  cell = clear_screen_cell()
  cell%glyph = "@"
  cell%style%bg = 99
  call put_cell(buffer, 1, 4, cell)
  if (buffer%cells(1, 4)%glyph /= "@") error stop "put_cell should write exact cell values"
  if (buffer%cells(1, 4)%style%bg /= 99) error stop "put_cell should preserve exact style values"

  call resize_screen(buffer, 6, 4)
  if (buffer%cells(2, 3)%glyph /= "X") error stop "resize_screen should preserve overlapping content when growing"
  if (buffer%cells(1, 4)%glyph /= "@") error stop "resize_screen should preserve existing cells when growing"
  if (buffer%cells(4, 6)%glyph /= " ") error stop "resize_screen should blank newly added cells"

  call resize_screen(buffer, 2, 2)
  if (buffer%size%width /= 2) error stop "resize_screen should update width after shrinking"
  if (buffer%size%height /= 2) error stop "resize_screen should update height after shrinking"
  if (buffer%cells(1, 1)%glyph /= " ") error stop "resize_screen should preserve overlapping cells when shrinking"

  style = clear_screen_style()
  style%bg = 17
  call clear_screen(buffer, style)
  if (buffer%cells(2, 2)%glyph /= " ") error stop "clear_screen should blank all cells"
  if (buffer%cells(2, 2)%style%bg /= 17) error stop "clear_screen should apply the provided fill style"
end program test_screen_grid
