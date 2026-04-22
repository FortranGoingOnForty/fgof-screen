module fgof_screen
  use fgof_screen_types, only : screen_buffer, screen_cell, screen_size, screen_style
  implicit none
  private

  public :: &
    allocate_screen, &
    clear_screen_buffer, &
    clear_screen_cell, &
    clear_screen_size, &
    clear_screen_style, &
    fill_screen, &
    screen_buffer, &
    screen_cell, &
    screen_size, &
    screen_style

contains

  function clear_screen_style() result(style)
    type(screen_style) :: style
  end function clear_screen_style

  function clear_screen_cell() result(cell)
    type(screen_cell) :: cell

    cell%glyph = " "
    cell%style = clear_screen_style()
  end function clear_screen_cell

  function clear_screen_size() result(size_value)
    type(screen_size) :: size_value
  end function clear_screen_size

  function clear_screen_buffer() result(buffer)
    type(screen_buffer) :: buffer

    buffer%size = clear_screen_size()
    buffer%cursor_row = 1
    buffer%cursor_col = 1
    buffer%cursor_visible = .true.
  end function clear_screen_buffer

  function allocate_screen(width, height) result(buffer)
    integer, intent(in) :: width
    integer, intent(in) :: height
    type(screen_buffer) :: buffer

    buffer = clear_screen_buffer()
    if (width <= 0 .or. height <= 0) return

    buffer%size%width = width
    buffer%size%height = height
    allocate(buffer%cells(height, width))
    call fill_screen(buffer, " ")
  end function allocate_screen

  subroutine fill_screen(buffer, glyph, style)
    type(screen_buffer), intent(inout) :: buffer
    character(len=*), intent(in) :: glyph
    type(screen_style), intent(in), optional :: style
    type(screen_cell) :: fill_cell
    integer :: row
    integer :: col

    if (.not. allocated(buffer%cells)) return

    fill_cell = clear_screen_cell()
    if (len(glyph) > 0) fill_cell%glyph = glyph(1:1)
    if (present(style)) fill_cell%style = style

    do row = 1, size(buffer%cells, 1)
      do col = 1, size(buffer%cells, 2)
        buffer%cells(row, col) = fill_cell
      end do
    end do
  end subroutine fill_screen

end module fgof_screen
