include(FeatureSummary)
set_package_properties(PulseAudio PROPERTIES
    URL "https://www.freedesktop.org/wiki/Software/PulseAudio/"
    DESCRIPTION "sound server system for POSIX OSes"
)

set(PulseAudio_PKG_CONFIG_SPEC libpulse-simple)

find_package(PkgConfig QUIET)
pkg_check_modules(PC_PulseAudio QUIET ${PulseAudio_PKG_CONFIG_SPEC})

find_library(PulseAudio_LIBRARY
    NAMES pulse-simple
    HINTS ${PC_PulseAudio_LIBRARY_DIRS}
)

find_path(PulseAudio_INCLUDE_PATH
    NAMES pulse/pulseaudio.h
    HINTS ${PC_PulseAudio_INCLUDE_DIRS}
)

if(PC_PulseAudio_FOUND)
    include("${CMAKE_CURRENT_LIST_DIR}/PkgConfigHelper.cmake")
    get_flags_from_pkg_config("${PulseAudio_LIBRARY}" "PC_PulseAudio" "_PulseAudio")
endif()

set(PulseAudio_INCLUDE_DIRS "${_PulseAudio_include_dirs}" CACHE STRING "Extra include dirs of PulseAudio")

set(PulseAudio_COMPILE_OPTIONS "${_PulseAudio_compile_options}" CACHE STRING "Extra compile options of PulseAudio")

set(PulseAudio_LINK_LIBRARIES "${_PulseAudio_link_libraries}" CACHE STRING "Extra link libraries of PulseAudio")

set(PulseAudio_LINK_OPTIONS "${_PulseAudio_link_options}" CACHE STRING "Extra link flags of PulseAudio")

set(PulseAudio_LINK_DIRECTORIES "${_PulseAudio_link_directories}" CACHE PATH "Extra link directories of PulseAudio")

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(PulseAudio
    REQUIRED_VARS
        PulseAudio_LIBRARY PulseAudio_INCLUDE_PATH
)

if(PulseAudio_FOUND)
    if(NOT TARGET PulseAudio::PulseAudio)
        add_library(PulseAudio::PulseAudio UNKNOWN IMPORTED)
        set_target_properties(PulseAudio::PulseAudio PROPERTIES
            IMPORTED_LOCATION "${PulseAudio_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${PulseAudio_INCLUDE_PATH};${PulseAudio_INCLUDE_DIRS}"
            INTERFACE_COMPILE_OPTIONS "${PulseAudio_COMPILE_OPTIONS}"
            INTERFACE_LINK_LIBRARIES "${PulseAudio_LINK_LIBRARIES}"
            INTERFACE_LINK_OPTIONS "${PulseAudio_LINK_OPTIONS}"
            INTERFACE_LINK_DIRECTORIES "${PulseAudio_LINK_DIRECTORIES}"
        )
    endif()
endif()
