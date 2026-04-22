module fgof_screen_types
  implicit none
  private

  type, public :: screen_style
    integer :: fg = -1
    integer :: bg = -1
    logical :: bold = .false.
    logical :: dim = .false.
    logical :: italic = .false.
    logical :: underline = .false.
    logical :: inverse = .false.
  end type screen_style

  type, public :: screen_cell
    character(len=1) :: glyph = " "
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

end module fgof_screen_types
