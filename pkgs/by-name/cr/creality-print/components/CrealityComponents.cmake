# Reuse upstream's target definitions and export their complete link interfaces
set(creality_vendor_directories
    admesh boost clipper clipper2 miniz minilzo glu-libtess qhull Shiny
    semver libigl qoi)
set(creality_vendor_targets
    admesh nowide clipper Clipper2 miniz miniz_static minilzo minilzo_static
    glu-libtess qhullstatic qhull Shiny semver libigl qoi)
set(creality_gui_vendor_directories glad imgui imguizmo hidapi)
set(creality_gui_vendor_targets glad imgui imguizmo hidapi)
set(creality_geometry_targets libslic3r_cgal)
set(creality_engine_targets libnest2d libslic3r)
set(creality_gui_targets libslic3r_gui)

macro(creality_import_volume)
    # Upstream's FindEigen3 module supplies variables, not this exported target
    find_package(Eigen3 CONFIG REQUIRED)
    include("${CREALITY_VOLUME_DIR}/lib/cmake/CrealityPrint/volume.cmake")
    # The adapter calls back into the engine; express the static-library cycle
    # so CMake repeats the archives when linking the final executable
    set_property(TARGET creality_volume APPEND PROPERTY
        INTERFACE_LINK_LIBRARIES libslic3r)
endmacro()

macro(creality_add_subdirectory directory)
    if(CREALITY_VENDOR_DIR AND "${directory}" IN_LIST creality_vendor_directories)
        if(NOT TARGET admesh)
            include("${CREALITY_VENDOR_DIR}/lib/cmake/CrealityPrint/vendor.cmake")
        endif()
    elseif(CREALITY_GUI_VENDOR_DIR AND "${directory}" IN_LIST creality_gui_vendor_directories)
        if(NOT TARGET glad)
            include("${CREALITY_GUI_VENDOR_DIR}/lib/cmake/CrealityPrint/gui_vendor.cmake")
        endif()
    elseif("${directory}" STREQUAL "mcut")
        find_package(MCUT CONFIG REQUIRED)
    elseif("${directory}" STREQUAL "video" AND NOT SLIC3R_GUI)
        # The slicing engine does not use camera decoding
    elseif(CREALITY_VIDEO_DIR AND "${directory}" STREQUAL "video")
        find_package(CrealityVideo CONFIG REQUIRED
            PATHS "${CREALITY_VIDEO_DIR}/lib/cmake/CrealityVideo" NO_DEFAULT_PATH)
    elseif(CREALITY_ENGINE_DIR AND "${directory}" MATCHES "^(libnest2d|libslic3r)$")
        if(NOT TARGET libslic3r)
            # These dependencies are normally discovered in libslic3r's build
            find_package(CGAL REQUIRED)
            find_package(OpenCV REQUIRED COMPONENTS core imgproc)
            find_package(OpenCASCADE REQUIRED)
            find_package(JPEG REQUIRED)
            find_package(Freetype REQUIRED)
            creality_import_volume()
            include("${CREALITY_GEOMETRY_DIR}/lib/cmake/CrealityPrint/geometry.cmake")
            # Match upstream: rounding options belong to the CGAL objects only
            get_target_property(_creality_cgal_options CGAL INTERFACE_COMPILE_OPTIONS)
            if(_creality_cgal_options)
                list(FILTER _creality_cgal_options EXCLUDE REGEX frounding-math)
                set_property(TARGET CGAL PROPERTY INTERFACE_COMPILE_OPTIONS "${_creality_cgal_options}")
            endif()
            include("${CREALITY_ENGINE_DIR}/lib/cmake/CrealityPrint/engine.cmake")
            file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/libslic3r")
            configure_file(
                "${CREALITY_ENGINE_DIR}/include/libslic3r/libslic3r_version.h"
                "${CMAKE_CURRENT_BINARY_DIR}/libslic3r/libslic3r_version.h" COPYONLY)
        endif()
    elseif(CREALITY_GUI_DIR AND "${directory}" STREQUAL "slic3r")
        include("${CREALITY_GUI_DIR}/lib/cmake/CrealityPrint/gui.cmake")
    elseif("${directory}" STREQUAL "hints")
        # hintsToPot is a developer tool, not part of the installed application
        add_subdirectory("${directory}" EXCLUDE_FROM_ALL)
    else()
        add_subdirectory("${directory}")
    endif()
endmacro()

# Export installed targets instead of rewriting CMake's build-tree exports.
# Preserve upstream's usage requirements and install their public include trees.
function(creality_export_targets component)
    include(GNUInstallDirs)
    foreach(target IN LISTS ARGN)
        foreach(property INTERFACE_INCLUDE_DIRECTORIES INTERFACE_SYSTEM_INCLUDE_DIRECTORIES)
            get_target_property(includes "${target}" "${property}")
            if(includes)
                set(installed_includes)
                foreach(directory IN LISTS includes)
                    foreach(root "${CMAKE_BINARY_DIR}/src" "${CMAKE_SOURCE_DIR}/src")
                        string(FIND "${directory}/" "${root}/" position)
                        if(position EQUAL 0)
                            file(RELATIVE_PATH relative "${root}" "${directory}")
                            set(destination "${CMAKE_INSTALL_INCLUDEDIR}/${relative}")
                            # Generated headers are installed separately below.
                            if(property STREQUAL "INTERFACE_INCLUDE_DIRECTORIES"
                                    AND root STREQUAL "${CMAKE_SOURCE_DIR}/src")
                                install(DIRECTORY "${directory}/" DESTINATION "${destination}"
                                    COMPONENT "creality-${component}"
                                    PATTERN "CMakeFiles" EXCLUDE)
                            endif()
                            set(directory "$<BUILD_INTERFACE:${directory}>;$<INSTALL_INTERFACE:${destination}>")
                            break()
                        endif()
                    endforeach()
                    list(APPEND installed_includes "${directory}")
                endforeach()
                set_property(TARGET "${target}" PROPERTY
                    "${property}" "${installed_includes}")
            endif()
        endforeach()
    endforeach()
    install(TARGETS ${ARGN} EXPORT "Creality${component}Targets"
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT "creality-${component}")
    install(EXPORT "Creality${component}Targets" FILE "${component}.cmake"
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/CrealityPrint
        COMPONENT "creality-${component}")
endfunction()

function(creality_export_components)
    if(CREALITY_COMPONENT STREQUAL "application")
        return()
    endif()
    # Register shared interfaces in their own export set to preserve references
    # between sets. Consumers already define them, so only install our component.
    set(common_targets ${ARGN})
    foreach(target boost_libs boost_headeronly tbb_libs libcurl openvdb_libs webrtc_video)
        if(TARGET "${target}")
            get_target_property(imported "${target}" IMPORTED)
            if(NOT imported)
                list(APPEND common_targets "${target}")
            endif()
        endif()
    endforeach()
    if(common_targets)
        creality_export_targets(common ${common_targets})
    endif()
    foreach(component vendor gui_vendor geometry engine gui)
        string(TOUPPER "${component}" upper_component)
        list(GET creality_${component}_targets 0 first_target)
        if(TARGET "${first_target}" AND NOT CREALITY_${upper_component}_DIR)
            get_target_property(imported "${first_target}" IMPORTED)
            if(NOT imported)
                creality_export_targets("${component}" ${creality_${component}_targets})
            endif()
        endif()
    endforeach()
    add_custom_target(creality_component)
    foreach(target IN LISTS creality_${CREALITY_COMPONENT}_targets)
        get_target_property(type "${target}" TYPE)
        if(type STREQUAL "STATIC_LIBRARY")
            add_dependencies(creality_component "${target}")
        endif()
    endforeach()
    include(GNUInstallDirs)
    install(DIRECTORY "${CMAKE_BINARY_DIR}/src/"
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR} COMPONENT "creality-${CREALITY_COMPONENT}"
        FILES_MATCHING PATTERN "*.h" PATTERN "CMakeFiles" EXCLUDE)
    install(FILES "${CMAKE_SOURCE_DIR}/LICENSE.txt"
        DESTINATION ${CMAKE_INSTALL_DATADIR}/licenses/creality-print
        COMPONENT "creality-${CREALITY_COMPONENT}")
    # Upstream also installs executables and unrelated libraries.
    add_custom_target(creality-install
        COMMAND "${CMAKE_COMMAND}" --install "${CMAKE_BINARY_DIR}"
            --component "creality-${CREALITY_COMPONENT}"
        VERBATIM)
endfunction()
