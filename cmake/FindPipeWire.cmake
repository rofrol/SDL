include(FeatureSummary)
set_package_properties(LibInotify PROPERTIES
    URL "https://pipewire.org/"
    DESCRIPTION "server and user space API to deal with multimedia pipelines"
)

set(PipeWire_PKG_CONFIG_SPEC libpipewire-0.3>=0.3.20)

find_package(PkgConfig QUIET)
pkg_check_modules(PC_PipeWire QUIET ${PipeWire_PKG_CONFIG_SPEC})

find_library(PipeWire_LIBRARY
    NAMES pipewire-0.3
    HINTS ${PC_PipeWire_LIBRARY_DIRS}
)

find_path(PipeWire_INCLUDE_PATH
    NAMES pipewire/pipewire.h
    PATH_SUFFIXES pipewire-0.3
    HINTS ${PC_PipeWire_INCLUDE_DIRS}
)

if(PC_PipeWire_FOUND)
    include("${CMAKE_CURRENT_LIST_DIR}/PkgConfigHelper.cmake")
    get_flags_from_pkg_config("${PipeWire_LIBRARY}" "PC_PipeWire" "_PipeWire")
endif()

set(PipeWire_INCLUDE_DIRS "${_PipeWire_include_dirs}" CACHE STRING "Extra include dirs of PipeWire")

set(PipeWire_COMPILE_OPTIONS "${_PipeWire_compile_options}" CACHE STRING "Extra compile options of PipeWire")

set(PipeWire_LINK_LIBRARIES "${_PipeWire_link_libraries}" CACHE STRING "Extra link libraries of PipeWire")

set(PipeWire_LINK_OPTIONS "${_PipeWire_link_options}" CACHE STRING "Extra link flags of PipeWire")

set(PipeWire_LINK_DIRECTORIES "${_PipeWire_link_directories}" CACHE PATH "Extra link directories of PipeWire")

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(PipeWire
    REQUIRED_VARS
        PipeWire_LIBRARY PipeWire_INCLUDE_PATH
)

if(PipeWire_FOUND)
    if(NOT TARGET PipeWire::PipeWire)
        add_library(PipeWire::PipeWire UNKNOWN IMPORTED)
        set_target_properties(PipeWire::PipeWire PROPERTIES
            IMPORTED_LOCATION "${PipeWire_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${PipeWire_INCLUDE_PATH};${PipeWire_INCLUDE_DIRS}"
            INTERFACE_COMPILE_OPTIONS "${PipeWire_COMPILE_OPTIONS}"
            INTERFACE_LINK_LIBRARIES "${PipeWire_LINK_LIBRARIES}"
            INTERFACE_LINK_OPTIONS "${PipeWire_LINK_OPTIONS}"
            INTERFACE_LINK_DIRECTORIES "${PipeWire_LINK_DIRECTORIES}"
        )
    endif()
endif()
