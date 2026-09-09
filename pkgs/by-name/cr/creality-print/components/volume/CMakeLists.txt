cmake_minimum_required(VERSION 3.15)
project(CrealityVolume LANGUAGES CXX)
include(GNUInstallDirs)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
list(APPEND CMAKE_MODULE_PATH "${OpenVDB_CMAKE_PATH}")
find_package(OpenVDB REQUIRED COMPONENTS openvdb)
find_package(Eigen3 REQUIRED)
find_package(cereal CONFIG REQUIRED)

include(version.inc)
set(AUTOMATION_TOOL OFF)
set(AUTO_CONVERT_3MF OFF)
set(GUI_SIMPLE ON)
configure_file(src/libslic3r/libslic3r_version.h.in
    src/libslic3r/libslic3r_version.h @ONLY)

add_library(creality_volume STATIC src/libslic3r/OpenVDBUtils.cpp)
target_compile_options(creality_volume PRIVATE -fsigned-char)
target_compile_definitions(creality_volume PRIVATE
    BOOST_LOG_DYN_LINK BOOST_ALLOW_DEPRECATED_HEADERS
    USE_TBB TBB_USE_CAPTURED_EXCEPTION=0)
target_include_directories(creality_volume PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/src"
    "${CMAKE_CURRENT_BINARY_DIR}/src/libslic3r")
target_link_libraries(creality_volume PRIVATE
    OpenVDB::openvdb Eigen3::Eigen cereal::cereal)

# Slic3r supplies the mesh callbacks when the final executable is linked
install(TARGETS creality_volume EXPORT CrealityVolumeTargets
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})
install(EXPORT CrealityVolumeTargets FILE volume.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/CrealityPrint)
