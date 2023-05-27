include(FeatureSummary)
set_package_properties(LibUSB PROPERTIES
    URL "https://libusb.info/"
    DESCRIPTION "library that provides generic access to USB devices"
)

set(LibUSB_PKG_CONFIG_SPEC libusb-1.0)

find_package(PkgConfig QUIET)
pkg_check_modules(PC_LibUSB QUIET ${LibUSB_PKG_CONFIG_SPEC})

find_library(LibUSB_LIBRARY
    NAMES usb-1.0 libusb-1.0 usb libusb
    HINTS ${PC_LibUSB_LIBRARY_DIRS}
)

find_path(LibUSB_INCLUDE_PATH
    NAMES libusb.h
    HINTS ${PC_LibUSB_INCLUDE_DIRS}
)

if(PC_LibUSB_FOUND)
    include("${CMAKE_CURRENT_LIST_DIR}/PkgConfigHelper.cmake")
    get_flags_from_pkg_config("${LibUSB_LIBRARY}" "PC_LibUSB" "_LibUSB")
endif()

set(LibUSB_INCLUDE_DIRS "${_LibUSB_include_dirs}" CACHE STRING "Extra include dirs of libusb")

set(LibUSB_COMPILE_OPTIONS "${_LibUSB_compile_options}" CACHE STRING "Extra compile options of libusb")

set(LibUSB_LINK_LIBRARIES "${_LibUSB_link_libraries}" CACHE STRING "Extra link libraries of libusb")

set(LibUSB_LINK_OPTIONS "${_LibUSB_link_options}" CACHE STRING "Extra link flags of libusb")

set(LibUSB_LINK_DIRECTORIES "${_LibUSB_link_directories}" CACHE PATH "Extra link directories of libusb")

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(LibUSB
    REQUIRED_VARS LibUSB_LIBRARY LibUSB_INCLUDE_PATH
)

if(LibUSB_FOUND)
    if(NOT TARGET LibUSB::LibUSB)
        add_library(LibUSB::LibUSB UNKNOWN IMPORTED)
        set_target_properties(LibUSB::LibUSB PROPERTIES
            IMPORTED_LOCATION "${LibUSB_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${LibUSB_INCLUDE_PATH};${LibUSB_INCLUDE_DIRS}"
            INTERFACE_COMPILE_OPTIONS "${LibUSB_COMPILE_OPTIONS}"
            INTERFACE_LINK_LIBRARIES "${LibUSB_LINK_LIBRARIES}"
            INTERFACE_LINK_OPTIONS "${LibUSB_LINK_OPTIONS}"
            INTERFACE_LINK_DIRECTORIES "${LibUSB_LINK_DIRECTORIES}"
            )
    endif()
endif()
