cmake_minimum_required(VERSION 3.15)
project(CrealityVideo LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
include(GNUInstallDirs)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}")
find_package(FFmpeg REQUIRED)
find_package(Threads REQUIRED)

# Keep the RTSP decoder independent of the optional metartc WebRTC backend
add_library(webrtc_video STATIC RTSPDecoder.cpp)
target_link_libraries(webrtc_video PUBLIC
    FFmpeg::avformat FFmpeg::avcodec FFmpeg::avutil FFmpeg::swresample
    FFmpeg::swscale FFmpeg::avfilter Threads::Threads)
target_include_directories(webrtc_video PUBLIC "$<INSTALL_INTERFACE:include/video>")
install(TARGETS webrtc_video EXPORT CrealityVideoTargets
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})
install(FILES RTSPDecoder.h DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/video)
install(EXPORT CrealityVideoTargets DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/CrealityVideo)
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/CrealityVideoConfig.cmake" [=[
include(CMakeFindDependencyMacro)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")
find_dependency(FFmpeg)
find_dependency(Threads)
include("${CMAKE_CURRENT_LIST_DIR}/CrealityVideoTargets.cmake")
]=])
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/CrealityVideoConfig.cmake" FindFFmpeg.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/CrealityVideo)
