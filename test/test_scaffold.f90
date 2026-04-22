program test_scaffold
  use fgof_screen, only : &
    allocate_screen, &
    clear_screen_buffer, &
    clear_screen_cell, &
    clear_screen_size, &
    clear_screen_style, &
    fill_screen
  use fgof_screen_types, only : screen_buffer, screen_cell, screen_size, screen_style
  implicit none

  type(screen_style) :: style
  type(screen_cell) :: cell
  type(screen_size) :: size_value
  type(screen_buffer) :: buffer

  style = clear_screen_style()
  if (style%fg /= -1) error stop "screen style should start with default foreground"
  if (style%bg /= -1) error stop "screen style should start with default background"
  if (style%bold) error stop "screen style should start non-bold"
  if (style%underline) error stop "screen style should start non-underlined"

  cell = clear_screen_cell()
  if (cell%glyph /= " ") error stop "screen cell should start blank"
  if (cell%style%fg /= -1) error stop "screen cell should carry cleared style"

  size_value = clear_screen_size()
  if (size_value%width /= 0) error stop "screen size should start at zero width"
  if (size_value%height /= 0) error stop "screen size should start at zero height"

  buffer = clear_screen_buffer()
  if (buffer%size%width /= 0) error stop "screen buffer should start at zero width"
  if (buffer%size%height /= 0) error stop "screen buffer should start at zero height"
  if (allocated(buffer%cells)) error stop "screen buffer should not allocate cells by default"
  if (.not. buffer%cursor_visible) error stop "screen buffer cursor should start visible"

  buffer = allocate_screen(4, 2)
  if (buffer%size%width /= 4) error stop "allocated screen should record width"
  if (buffer%size%height /= 2) error stop "allocated screen should record height"
  if (.not. allocated(buffer%cells)) error stop "allocated screen should allocate cells"
  if (size(buffer%cells, 1) /= 2) error stop "allocated screen should use height as first dimension"
  if (size(buffer%cells, 2) /= 4) error stop "allocated screen should use width as second dimension"
  if (buffer%cells(1, 1)%glyph /= " ") error stop "allocated screen should start with blank cells"

  style = clear_screen_style()
  style%fg = 33
  style%bold = .true.
  call fill_screen(buffer, "#", style)
  if (buffer%cells(2, 4)%glyph /= "#") error stop "fill_screen should update all glyphs"
  if (buffer%cells(2, 4)%style%fg /= 33) error stop "fill_screen should apply style"
  if (.not. buffer%cells(2, 4)%style%bold) error stop "fill_screen should preserve style flags"
end program test_scaffold
