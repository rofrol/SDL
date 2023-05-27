include(FeatureSummary)
set_package_properties(LibInotify PROPERTIES
    URL "https://github.com/libinotify-kqueue/libinotify-kqueue"
    DESCRIPTION "inotify shim for BSD"
)

set(LibInotify_PKG_CONFIG_SPEC libinotify)

find_package(PkgConfig QUIET)
pkg_check_modules(PC_LibInotify QUIET ${LibInotify_PKG_CONFIG_SPEC})

find_library(LibInotify_LIBRARY
    NAMES inotify
    HINTS ${PC_LibInotify_LIBRARY_DIRS}
)

find_path(LibInotify_INCLUDE_PATH
    NAMES sys/inotify.h
    HINTS ${PC_LibInotify_INCLUDE_DIRS}
)

if(PC_LibInotify_FOUND)
    include("${CMAKE_CURRENT_LIST_DIR}/PkgConfigHelper.cmake")
    get_flags_from_pkg_config("${LibInotify_LIBRARY}" "PC_LibInotify" "_LibInotify")
endif()

set(LibInotify_INCLUDE_DIRS "${_LibInotify_include_dirs}" CACHE STRING "Extra include dirs of libjack")

set(LibInotify_COMPILE_OPTIONS "${_LibInotify_compile_options}" CACHE STRING "Extra compile options of libjack")

set(LibInotify_LINK_LIBRARIES "${_LibInotify_link_libraries}" CACHE STRING "Extra link libraries of libjack")

set(LibInotify_LINK_OPTIONS "${_LibInotify_link_options}" CACHE STRING "Extra link flags of libjack")

set(LibInotify_LINK_DIRECTORIES "${_LibInotify_link_directories}" CACHE PATH "Extra link directories of libjack")

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(LibInotify
    REQUIRED_VARS LibInotify_LIBRARY LibInotify_INCLUDE_PATH
)

if(LibInotify_FOUND)
    if(NOT TARGET LibInotify::LibInotify)
        add_library(LibInotify::LibInotify UNKNOWN IMPORTED)
        set_target_properties(LibInotify::LibInotify PROPERTIES
            IMPORTED_LOCATION "${LibInotify_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${LibInotify_INCLUDE_PATH};${LibInotify_INCLUDE_DIRS}"
            INTERFACE_COMPILE_OPTIONS "${LibInotify_COMPILE_OPTIONS}"
            INTERFACE_LINK_LIBRARIES "${LibInotify_LINK_LIBRARIES}"
            INTERFACE_LINK_OPTIONS "${LibInotify_LINK_OPTIONS}"
            INTERFACE_LINK_DIRECTORIES "${LibInotify_LINK_DIRECTORIES}"
            )
    endif()
endif()
