include(FeatureSummary)
set_package_properties(LibDecor PROPERTIES
    URL "https://gitlab.freedesktop.org/libdecor/libdecor"
    DESCRIPTION "client-side decorations library for Wayland client"
)

set(LibDecor_PKG_CONFIG_SPEC libdecor-0)

find_package(PkgConfig QUIET)
pkg_check_modules(PC_LibDecor QUIET ${LibDecor_PKG_CONFIG_SPEC})

find_library(LibDecor_LIBRARY
    NAMES decor-0
    HINTS ${PC_LibDecor_LIBRARY_DIRS}
)

find_path(LibDecor_INCLUDE_PATH
    NAMES libdecor.h
    PATH_SUFFIXES libdecor-0
    HINTS ${PC_LibDecor_INCLUDE_DIRS}
)

if(PC_LibDecor_FOUND)
    include("${CMAKE_CURRENT_LIST_DIR}/PkgConfigHelper.cmake")
    get_flags_from_pkg_config("${LibDecor_LIBRARY}" "PC_LibDecor" "_LibDecor")
endif()

set(LibDecor_INCLUDE_DIRS "${_LibDecor_include_dirs}" CACHE STRING "Extra include dirs of libDecor")

set(LibDecor_COMPILE_OPTIONS "${_LibDecor_compile_options}" CACHE STRING "Extra compile options of libDecor")

set(LibDecor_LINK_LIBRARIES "${_LibDecor_link_libraries}" CACHE STRING "Extra link libraries of libDecor")

set(LibDecor_LINK_OPTIONS "${_LibDecor_link_options}" CACHE STRING "Extra link flags of libDecor")

set(LibDecor_LINK_DIRECTORIES "${_LibDecor_link_directories}" CACHE PATH "Extra link directories of libDecor")

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(LibDecor
    REQUIRED_VARS LibDecor_LIBRARY LibDecor_INCLUDE_PATH
)

if(LibDecor_FOUND)
    if(NOT TARGET LibDecor::LibDecor)
        add_library(LibDecor::LibDecor UNKNOWN IMPORTED)
        set_target_properties(LibDecor::LibDecor PROPERTIES
            IMPORTED_LOCATION "${LibDecor_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${LibDecor_INCLUDE_PATH};${LibDecor_INCLUDE_DIRS}"
            INTERFACE_COMPILE_OPTIONS "${LibDecor_COMPILE_OPTIONS}"
            INTERFACE_LINK_LIBRARIES "${LibDecor_LINK_LIBRARIES}"
            INTERFACE_LINK_OPTIONS "${LibDecor_LINK_OPTIONS}"
            INTERFACE_LINK_DIRECTORIES "${LibDecor_LINK_DIRECTORIES}"
            )
    endif()
endif()
