set(SndIO_PKG_CONFIG_SPEC sndio)

find_package(PkgConfig QUIET)
pkg_check_modules(PC_SndIO QUIET ${SndIO_PKG_CONFIG_SPEC})

find_library(SndIO_LIBRARY
    NAMES sndio
    HINTS ${PC_SndIO_LIBRARY_DIRS}
)

find_path(SndIO_INCLUDE_PATH
    NAMES sndio.h
    HINTS ${PC_SndIO_INCLUDE_DIRS}
)

if(PC_SndIO_FOUND)
    include("${CMAKE_CURRENT_LIST_DIR}/PkgConfigHelper.cmake")
    get_flags_from_pkg_config("${SndIO_LIBRARY}" "PC_SndIO" "_SndIO")
endif()

set(SndIO_INCLUDE_DIRS "${_SndIO_include_dirs}" CACHE STRING "Extra include dirs of libSndIO")

set(SndIO_COMPILE_OPTIONS "${_SndIO_compile_options}" CACHE STRING "Extra compile options of libSndIO")

set(SndIO_LINK_LIBRARIES "${_SndIO_link_libraries}" CACHE STRING "Extra link libraries of libSndIO")

set(SndIO_LINK_OPTIONS "${_SndIO_link_options}" CACHE STRING "Extra link flags of libSndIO")

set(SndIO_LINK_DIRECTORIES "${_SndIO_link_directories}" CACHE PATH "Extra link directories of libSndIO")

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(SndIO
    REQUIRED_VARS SndIO_LIBRARY SndIO_INCLUDE_PATH
)

if(SndIO_FOUND)
    if(NOT TARGET SndIO::SndIO)
        add_library(SndIO::SndIO UNKNOWN IMPORTED)
        set_target_properties(SndIO::SndIO PROPERTIES
            IMPORTED_LOCATION "${SndIO_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${SndIO_INCLUDE_PATH};${SndIO_INCLUDE_DIRS}"
            INTERFACE_COMPILE_OPTIONS "${SndIO_COMPILE_OPTIONS}"
            INTERFACE_LINK_LIBRARIES "${SndIO_LINK_LIBRARIES}"
            INTERFACE_LINK_OPTIONS "${SndIO_LINK_OPTIONS}"
            INTERFACE_LINK_DIRECTORIES "${SndIO_LINK_DIRECTORIES}"
            )
    endif()
endif()
