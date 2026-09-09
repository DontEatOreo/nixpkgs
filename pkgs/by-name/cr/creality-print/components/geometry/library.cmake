# Use the same version header and target definition as the full project
set(AUTOMATION_TOOL OFF)
set(AUTO_CONVERT_3MF OFF)
set(GUI_SIMPLE ON)
configure_file(libslic3r_version.h.in libslic3r_version.h @ONLY)
include(geometry.cmake)
