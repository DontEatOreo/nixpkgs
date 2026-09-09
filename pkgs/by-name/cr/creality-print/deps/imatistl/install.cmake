# Creality's build defines the sources and kernel; add its public dependencies
# and the installation rules needed by the system-library consumer.
target_link_libraries(ImatiSTL PUBLIC CGAL::CGAL)
target_compile_definitions(ImatiSTL PUBLIC
    IS64BITPLATFORM USE_HYBRID_KERNEL USE_CGAL_LAZYNT)

include(GNUInstallDirs)
install(TARGETS ImatiSTL ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})
install(DIRECTORY include/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
install(FILES gpl-3.0.txt DESTINATION ${CMAKE_INSTALL_DATADIR}/licenses/imatistl)
