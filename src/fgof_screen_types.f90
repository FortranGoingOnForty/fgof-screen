module fgof_screen_types
  implicit none
  private

  type, public :: screen_style
    integer :: fg = -1
    integer :: bg = -1
    logical :: fg_truecolor = .false.
    logical :: bg_truecolor = .false.
    integer :: fg_rgb(3) = [0, 0, 0]
    integer :: bg_rgb(3) = [0, 0, 0]
    logical :: bold = .false.
    logical :: dim = .false.
    logical :: italic = .false.
    logical :: underline = .false.
    logical :: inverse = .false.
    logical :: strikethrough = .false.
  end type screen_style

  type, public :: screen_cell
    character(len=:), allocatable :: glyph
    type(screen_style) :: style
  end type screen_cell

  type, public :: screen_size
    integer :: width = 0
    integer :: height = 0
  end type screen_size

  type, public :: screen_buffer
    type(screen_size) :: size
    integer :: cursor_row = 1
    integer :: cursor_col = 1
    logical :: cursor_visible = .true.
    type(screen_cell), allocatable :: cells(:, :)
  end type screen_buffer

  type, public :: screen_damage
    logical :: active = .false.
    integer :: row_first = 0
    integer :: row_last = 0
    integer :: col_first = 0
    integer :: col_last = 0
    integer :: changed_cells = 0
  end type screen_damage

  type, public :: screen_diff
    logical :: changed = .false.
    logical :: size_changed = .false.
    logical :: cursor_changed = .false.
    logical :: cursor_visibility_changed = .false.
    type(screen_size) :: previous_size
    type(screen_size) :: current_size
    type(screen_damage) :: damage
  end type screen_diff

end module fgof_screen_types
