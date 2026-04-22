module fgof_screen
  use fgof_screen_types, only : screen_buffer, screen_cell, screen_size, screen_style
  implicit none
  private

  public :: &
    allocate_screen, &
    clear_screen, &
    clear_screen_buffer, &
    clear_screen_cell, &
    clear_screen_size, &
    clear_screen_style, &
    fill_screen, &
    put_cell, &
    put_glyph, &
    resize_screen, &
    set_cursor, &
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
    call clear_screen(buffer)
    call clamp_cursor(buffer)
  end function allocate_screen

  subroutine resize_screen(buffer, width, height)
    type(screen_buffer), intent(inout) :: buffer
    integer, intent(in) :: width
    integer, intent(in) :: height
    type(screen_cell), allocatable :: grown(:, :)
    integer :: copy_height
    integer :: copy_width

    if (width <= 0 .or. height <= 0) then
      if (allocated(buffer%cells)) deallocate(buffer%cells)
      buffer%size = clear_screen_size()
      call clamp_cursor(buffer)
      return
    end if

    allocate(grown(height, width))
    grown = clear_screen_cell()

    if (allocated(buffer%cells)) then
      copy_height = min(size(buffer%cells, 1), height)
      copy_width = min(size(buffer%cells, 2), width)
      if (copy_height > 0 .and. copy_width > 0) then
        grown(:copy_height, :copy_width) = buffer%cells(:copy_height, :copy_width)
      end if
      deallocate(buffer%cells)
    end if

    call move_alloc(grown, buffer%cells)
    buffer%size%width = width
    buffer%size%height = height
    call clamp_cursor(buffer)
  end subroutine resize_screen

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

  subroutine clear_screen(buffer, style)
    type(screen_buffer), intent(inout) :: buffer
    type(screen_style), intent(in), optional :: style

    call fill_screen(buffer, " ", style)
  end subroutine clear_screen

  subroutine put_cell(buffer, row, col, cell)
    type(screen_buffer), intent(inout) :: buffer
    integer, intent(in) :: row
    integer, intent(in) :: col
    type(screen_cell), intent(in) :: cell

    if (.not. screen_index_in_bounds(buffer, row, col)) return
    buffer%cells(row, col) = cell
  end subroutine put_cell

  subroutine put_glyph(buffer, row, col, glyph, style)
    type(screen_buffer), intent(inout) :: buffer
    integer, intent(in) :: row
    integer, intent(in) :: col
    character(len=*), intent(in) :: glyph
    type(screen_style), intent(in), optional :: style
    type(screen_cell) :: cell

    if (.not. screen_index_in_bounds(buffer, row, col)) return

    cell = buffer%cells(row, col)
    if (len(glyph) > 0) cell%glyph = glyph(1:1)
    if (present(style)) cell%style = style
    call put_cell(buffer, row, col, cell)
  end subroutine put_glyph

  subroutine set_cursor(buffer, row, col)
    type(screen_buffer), intent(inout) :: buffer
    integer, intent(in) :: row
    integer, intent(in) :: col

    buffer%cursor_row = row
    buffer%cursor_col = col
    call clamp_cursor(buffer)
  end subroutine set_cursor

  logical function screen_index_in_bounds(buffer, row, col) result(in_bounds)
    type(screen_buffer), intent(in) :: buffer
    integer, intent(in) :: row
    integer, intent(in) :: col

    in_bounds = allocated(buffer%cells)
    if (.not. in_bounds) return

    in_bounds = row >= 1 .and. row <= size(buffer%cells, 1) .and. &
                col >= 1 .and. col <= size(buffer%cells, 2)
  end function screen_index_in_bounds

  subroutine clamp_cursor(buffer)
    type(screen_buffer), intent(inout) :: buffer

    if (.not. allocated(buffer%cells)) then
      buffer%cursor_row = 1
      buffer%cursor_col = 1
      return
    end if

    buffer%cursor_row = max(1, min(buffer%cursor_row, size(buffer%cells, 1)))
    buffer%cursor_col = max(1, min(buffer%cursor_col, size(buffer%cells, 2)))
  end subroutine clamp_cursor

end module fgof_screen
