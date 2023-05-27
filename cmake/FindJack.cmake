set(Jack_PKG_CONFIG_SPEC jack)

find_package(PkgConfig QUIET)
pkg_check_modules(PC_Jack QUIET ${Jack_PKG_CONFIG_SPEC})

find_library(Jack_LIBRARY
    NAMES jack
    HINTS ${PC_Jack_LIBRARY_DIRS}
)

find_path(Jack_INCLUDE_PATH
    NAMES jack/jack.h
    HINTS ${PC_Jack_INCLUDE_DIRS}
)

if(PC_Jack_FOUND)
    include("${CMAKE_CURRENT_LIST_DIR}/PkgConfigHelper.cmake")
    get_flags_from_pkg_config("${Jack_LIBRARY}" "PC_Jack" "_Jack")
endif()

set(Jack_INCLUDE_DIRS "${_Jack_include_dirs}" CACHE STRING "Extra include dirs of libjack")

set(Jack_COMPILE_OPTIONS "${_Jack_compile_options}" CACHE STRING "Extra compile options of libjack")

set(Jack_LINK_LIBRARIES "${_Jack_link_libraries}" CACHE STRING "Extra link libraries of libjack")

set(Jack_LINK_OPTIONS "${_Jack_link_options}" CACHE STRING "Extra link flags of libjack")

set(Jack_LINK_DIRECTORIES "${_Jack_link_directories}" CACHE PATH "Extra link directories of libjack")

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Jack
    REQUIRED_VARS Jack_LIBRARY Jack_INCLUDE_PATH
)

if(Jack_FOUND)
    if(NOT TARGET Jack::Jack)
        add_library(Jack::Jack UNKNOWN IMPORTED)
        set_target_properties(Jack::Jack PROPERTIES
            IMPORTED_LOCATION "${Jack_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${Jack_INCLUDE_PATH};${Jack_INCLUDE_DIRS}"
            INTERFACE_COMPILE_OPTIONS "${Jack_COMPILE_OPTIONS}"
            INTERFACE_LINK_LIBRARIES "${Jack_LINK_LIBRARIES}"
            INTERFACE_LINK_OPTIONS "${Jack_LINK_OPTIONS}"
            INTERFACE_LINK_DIRECTORIES "${Jack_LINK_DIRECTORIES}"
            )
    endif()
endif()
