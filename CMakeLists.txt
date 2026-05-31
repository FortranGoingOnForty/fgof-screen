cmake_minimum_required(VERSION 3.25)

project(fgof_screen VERSION 0.1.0 LANGUAGES Fortran)

add_library(fgof_screen
  src/fgof_screen_types.f90
  src/fgof_screen.f90
)
add_library(fgof::screen ALIAS fgof_screen)

set_target_properties(fgof_screen PROPERTIES
  Fortran_MODULE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/mod"
)

target_include_directories(fgof_screen PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/mod>
)

target_compile_options(fgof_screen PRIVATE
  $<$<COMPILE_LANG_AND_ID:Fortran,GNU>:-std=f2018 -Wall -Wextra -Wpedantic -Werror>
)
