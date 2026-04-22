module fgof_screen
  use fgof_screen_types, only : &
    screen_buffer, &
    screen_cell, &
    screen_damage, &
    screen_diff, &
    screen_size, &
    screen_style
  implicit none
  private

  public :: &
    allocate_screen, &
    clear_screen, &
    clear_screen_buffer, &
    clear_screen_cell, &
    clear_screen_damage, &
    clear_screen_diff, &
    clear_screen_size, &
    clear_screen_style, &
    diff_screen, &
    fill_screen, &
    put_cell, &
    put_glyph, &
    render_cursor_ansi, &
    render_screen_ansi, &
    render_screen_diff_ansi, &
    resize_screen, &
    set_cursor, &
    screen_buffer, &
    screen_cell, &
    screen_damage, &
    screen_diff, &
    screen_size, &
    screen_style

contains

  function clear_screen_style() result(style)
    type(screen_style) :: style

    style%fg = -1
    style%bg = -1
    style%bold = .false.
    style%dim = .false.
    style%italic = .false.
    style%underline = .false.
    style%inverse = .false.
  end function clear_screen_style

  function clear_screen_cell() result(cell)
    type(screen_cell) :: cell

    cell%glyph = " "
    cell%style = clear_screen_style()
  end function clear_screen_cell

  function clear_screen_size() result(size_value)
    type(screen_size) :: size_value

    size_value%width = 0
    size_value%height = 0
  end function clear_screen_size

  function clear_screen_damage() result(damage)
    type(screen_damage) :: damage

    damage%active = .false.
    damage%row_first = 0
    damage%row_last = 0
    damage%col_first = 0
    damage%col_last = 0
    damage%changed_cells = 0
  end function clear_screen_damage

  function clear_screen_diff() result(diff)
    type(screen_diff) :: diff

    diff%changed = .false.
    diff%size_changed = .false.
    diff%cursor_changed = .false.
    diff%cursor_visibility_changed = .false.
    diff%previous_size = clear_screen_size()
    diff%current_size = clear_screen_size()
    diff%damage = clear_screen_damage()
  end function clear_screen_diff

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

  function diff_screen(previous, current) result(diff)
    type(screen_buffer), intent(in) :: previous
    type(screen_buffer), intent(in) :: current
    type(screen_diff) :: diff
    integer :: max_rows
    integer :: max_cols
    integer :: row
    integer :: col

    diff = clear_screen_diff()
    diff%previous_size = previous%size
    diff%current_size = current%size
    diff%size_changed = .not. screen_sizes_equal(previous%size, current%size)
    diff%cursor_changed = previous%cursor_row /= current%cursor_row .or. &
                          previous%cursor_col /= current%cursor_col
    diff%cursor_visibility_changed = previous%cursor_visible .neqv. current%cursor_visible

    max_rows = max(previous%size%height, current%size%height)
    max_cols = max(previous%size%width, current%size%width)

    do row = 1, max_rows
      do col = 1, max_cols
        if (screen_cell_changed(previous, current, row, col)) then
          call record_damage(diff%damage, row, col)
        end if
      end do
    end do

    diff%changed = diff%damage%active .or. diff%size_changed .or. &
                   diff%cursor_changed .or. diff%cursor_visibility_changed
  end function diff_screen

  function render_screen_ansi(buffer) result(output)
    type(screen_buffer), intent(in) :: buffer
    character(len=:), allocatable :: output
    integer :: row

    output = hide_cursor_ansi() // clear_screen_ansi()

    if (allocated(buffer%cells)) then
      do row = 1, size(buffer%cells, 1)
        output = output // render_current_row_ansi(buffer, row, 1, size(buffer%cells, 2))
        if (row < size(buffer%cells, 1)) output = output // new_line("a")
      end do
    end if

    output = output // reset_style_ansi() // render_cursor_ansi(buffer)
  end function render_screen_ansi

  function render_screen_diff_ansi(previous, current) result(output)
    type(screen_buffer), intent(in) :: previous
    type(screen_buffer), intent(in) :: current
    character(len=:), allocatable :: output
    type(screen_diff) :: diff
    integer :: row

    diff = diff_screen(previous, current)
    if (.not. diff%changed) then
      output = ""
      return
    end if

    output = ""
    if (diff%damage%active) then
      output = hide_cursor_ansi()
      do row = diff%damage%row_first, diff%damage%row_last
        output = output // move_cursor_ansi(row, diff%damage%col_first)
        output = output // render_diff_row_ansi(previous, current, row, diff%damage%col_first, diff%damage%col_last)
      end do
      output = output // reset_style_ansi()
    end if

    output = output // render_cursor_ansi(current)
  end function render_screen_diff_ansi

  function render_cursor_ansi(buffer) result(output)
    type(screen_buffer), intent(in) :: buffer
    character(len=:), allocatable :: output

    if (buffer%cursor_visible) then
      output = move_cursor_ansi(buffer%cursor_row, buffer%cursor_col) // show_cursor_ansi()
    else
      output = hide_cursor_ansi()
    end if
  end function render_cursor_ansi

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

  logical function screen_cell_changed(previous, current, row, col) result(changed)
    type(screen_buffer), intent(in) :: previous
    type(screen_buffer), intent(in) :: current
    integer, intent(in) :: row
    integer, intent(in) :: col

    changed = screen_index_in_bounds(previous, row, col) .neqv. &
              screen_index_in_bounds(current, row, col)
    if (changed) return

    changed = .not. screen_cells_equal(screen_cell_at(previous, row, col), &
                                       screen_cell_at(current, row, col))
  end function screen_cell_changed

  function screen_cell_at(buffer, row, col) result(cell)
    type(screen_buffer), intent(in) :: buffer
    integer, intent(in) :: row
    integer, intent(in) :: col
    type(screen_cell) :: cell

    cell = clear_screen_cell()
    if (.not. screen_index_in_bounds(buffer, row, col)) return
    cell = buffer%cells(row, col)
  end function screen_cell_at

  logical function screen_cells_equal(left, right) result(equal)
    type(screen_cell), intent(in) :: left
    type(screen_cell), intent(in) :: right

    equal = left%glyph == right%glyph .and. screen_styles_equal(left%style, right%style)
  end function screen_cells_equal

  logical function screen_styles_equal(left, right) result(equal)
    type(screen_style), intent(in) :: left
    type(screen_style), intent(in) :: right

    equal = left%fg == right%fg .and. &
            left%bg == right%bg .and. &
            left%bold .eqv. right%bold .and. &
            left%dim .eqv. right%dim .and. &
            left%italic .eqv. right%italic .and. &
            left%underline .eqv. right%underline .and. &
            left%inverse .eqv. right%inverse
  end function screen_styles_equal

  logical function screen_sizes_equal(left, right) result(equal)
    type(screen_size), intent(in) :: left
    type(screen_size), intent(in) :: right

    equal = left%width == right%width .and. left%height == right%height
  end function screen_sizes_equal

  subroutine record_damage(damage, row, col)
    type(screen_damage), intent(inout) :: damage
    integer, intent(in) :: row
    integer, intent(in) :: col

    if (.not. damage%active) then
      damage%active = .true.
      damage%row_first = row
      damage%row_last = row
      damage%col_first = col
      damage%col_last = col
    else
      damage%row_first = min(damage%row_first, row)
      damage%row_last = max(damage%row_last, row)
      damage%col_first = min(damage%col_first, col)
      damage%col_last = max(damage%col_last, col)
    end if

    damage%changed_cells = damage%changed_cells + 1
  end subroutine record_damage

  function render_current_row_ansi(buffer, row, col_first, col_last) result(output)
    type(screen_buffer), intent(in) :: buffer
    integer, intent(in) :: row
    integer, intent(in) :: col_first
    integer, intent(in) :: col_last
    character(len=:), allocatable :: output
    type(screen_cell) :: cell
    character(len=:), allocatable :: current_key
    character(len=:), allocatable :: cell_key
    integer :: col

    output = ""
    current_key = ""

    do col = col_first, col_last
      cell = buffer%cells(row, col)
      cell_key = style_key(cell%style)
      if (cell_key /= current_key) then
        if (len(cell_key) > 0) then
          output = output // style_ansi(cell%style)
        else if (len(current_key) > 0) then
          output = output // reset_style_ansi()
        end if
        current_key = cell_key
      end if
      output = output // cell%glyph
    end do

    if (len(current_key) > 0) then
      output = output // reset_style_ansi()
    end if
  end function render_current_row_ansi

  function render_diff_row_ansi(previous, current, row, col_first, col_last) result(output)
    type(screen_buffer), intent(in) :: previous
    type(screen_buffer), intent(in) :: current
    integer, intent(in) :: row
    integer, intent(in) :: col_first
    integer, intent(in) :: col_last
    character(len=:), allocatable :: output
    type(screen_cell) :: cell
    character(len=:), allocatable :: current_key
    character(len=:), allocatable :: cell_key
    integer :: col

    output = ""
    current_key = ""

    do col = col_first, col_last
      cell = screen_cell_for_diff(previous, current, row, col)
      cell_key = style_key(cell%style)
      if (cell_key /= current_key) then
        if (len(cell_key) > 0) then
          output = output // style_ansi(cell%style)
        else if (len(current_key) > 0) then
          output = output // reset_style_ansi()
        end if
        current_key = cell_key
      end if
      output = output // cell%glyph
    end do

    if (len(current_key) > 0) then
      output = output // reset_style_ansi()
    end if
  end function render_diff_row_ansi

  function screen_cell_for_diff(previous, current, row, col) result(cell)
    type(screen_buffer), intent(in) :: previous
    type(screen_buffer), intent(in) :: current
    integer, intent(in) :: row
    integer, intent(in) :: col
    type(screen_cell) :: cell

    cell = clear_screen_cell()
    if (screen_index_in_bounds(current, row, col)) then
      cell = current%cells(row, col)
      return
    end if

    if (screen_index_in_bounds(previous, row, col)) then
      cell = clear_screen_cell()
    end if
  end function screen_cell_for_diff

  logical function style_is_default(style) result(is_default)
    type(screen_style), intent(in) :: style

    is_default = style%fg < 0 .and. style%bg < 0 .and. &
                 (.not. style%bold) .and. (.not. style%dim) .and. &
                 (.not. style%italic) .and. (.not. style%underline) .and. &
                 (.not. style%inverse)
  end function style_is_default

  function style_key(style) result(key)
    type(screen_style), intent(in) :: style
    character(len=:), allocatable :: key

    if (style_is_default(style)) then
      key = ""
      return
    end if

    key = integer_text(style%fg) // ":" // integer_text(style%bg) // ":" // &
          merge("1", "0", style%bold) // ":" // merge("1", "0", style%dim) // ":" // &
          merge("1", "0", style%italic) // ":" // merge("1", "0", style%underline) // ":" // &
          merge("1", "0", style%inverse)
  end function style_key

  function style_ansi(style) result(output)
    type(screen_style), intent(in) :: style
    character(len=:), allocatable :: output

    output = reset_style_ansi()
    if (style%bold) output = output // sgr_parameter("1")
    if (style%dim) output = output // sgr_parameter("2")
    if (style%italic) output = output // sgr_parameter("3")
    if (style%underline) output = output // sgr_parameter("4")
    if (style%inverse) output = output // sgr_parameter("7")
    if (style%fg >= 0) output = output // sgr_parameter("38;5;" // integer_text(style%fg))
    if (style%bg >= 0) output = output // sgr_parameter("48;5;" // integer_text(style%bg))
  end function style_ansi

  function sgr_parameter(parameter) result(output)
    character(len=*), intent(in) :: parameter
    character(len=:), allocatable :: output

    output = csi() // parameter // "m"
  end function sgr_parameter

  function reset_style_ansi() result(output)
    character(len=:), allocatable :: output

    output = csi() // "0m"
  end function reset_style_ansi

  function clear_screen_ansi() result(output)
    character(len=:), allocatable :: output

    output = csi() // "2J" // csi() // "H"
  end function clear_screen_ansi

  function move_cursor_ansi(row, col) result(output)
    integer, intent(in) :: row
    integer, intent(in) :: col
    character(len=:), allocatable :: output

    output = csi() // integer_text(max(1, row)) // ";" // integer_text(max(1, col)) // "H"
  end function move_cursor_ansi

  function hide_cursor_ansi() result(output)
    character(len=:), allocatable :: output

    output = csi() // "?25l"
  end function hide_cursor_ansi

  function show_cursor_ansi() result(output)
    character(len=:), allocatable :: output

    output = csi() // "?25h"
  end function show_cursor_ansi

  function csi() result(output)
    character(len=:), allocatable :: output

    output = achar(27) // "["
  end function csi

  function integer_text(value) result(text)
    integer, intent(in) :: value
    character(len=:), allocatable :: text
    character(len=32) :: scratch

    write(scratch, "(i0)") value
    text = trim(scratch)
  end function integer_text

end module fgof_screen
