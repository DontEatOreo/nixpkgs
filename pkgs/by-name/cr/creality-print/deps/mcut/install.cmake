
# The bundled CMake project leaves its installation rules commented out
include(GNUInstallDirs)
target_include_directories(mcut PUBLIC "$<INSTALL_INTERFACE:include>")
install(TARGETS mcut EXPORT MCUTTargets ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})
install(DIRECTORY include/mcut DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
install(EXPORT MCUTTargets DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/MCUT)
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/MCUTConfig.cmake" [=[
include(CMakeFindDependencyMacro)
find_dependency(Threads)
include("${CMAKE_CURRENT_LIST_DIR}/MCUTTargets.cmake")
]=])
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/MCUTConfig.cmake"
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/MCUT)
