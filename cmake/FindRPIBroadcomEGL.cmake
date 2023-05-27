include(FeatureSummary)
set_package_properties(PulseAudio PROPERTIES
    URL "https://github.com/raspberrypi/firmware"
    DESCRIPTION "Fake brcmEGL package for RPi"
)

set(RPiBroadcomEGL_PKG_CONFIG_SPEC bcm_host brcmegl)

find_package(PkgConfig QUIET)
pkg_check_modules(PC_RPiBroadcomEGL QUIET ${RPiBroadcomEGL_PKG_CONFIG_SPEC})

set(VIDEO_RPI_INCLUDE_DIRS "/opt/vc/include" "/opt/vc/include/interface/vcos/pthreads" "/opt/vc/include/interface/vmcs_host/linux/" )
set(VIDEO_RPI_LIBRARY_DIRS "/opt/vc/lib" )
set(VIDEO_RPI_LIBRARIES bcm_host )
set(VIDEO_RPI_LDFLAGS "-Wl,-rpath,/opt/vc/lib")

find_library(RPiBroadcomEGL_LIBRARY
    NAMES brcmEGL
    HINTS ${PC_RPiBroadcomEGL_LIBRARY_DIRS}
)

find_path(RPiBroadcomEGL_INCLUDE_PATH
    NAMES bcm_host.h
    HINTS ${PC_RPiBroadcomEGL_INCLUDE_DIRS}
)

if(PC_RPiBroadcomEGL_FOUND)
    include("${CMAKE_CURRENT_LIST_DIR}/PkgConfigHelper.cmake")
    get_flags_from_pkg_config("${RPiBroadcomEGL_LIBRARY}" "PC_RPiBroadcomEGL" "_RPiBroadcomEGL")
endif()

set(RPiBroadcomEGL_INCLUDE_DIRS "${_RPiBroadcomEGL_include_dirs}" CACHE STRING "Extra include dirs of RPIBroadcomEGL")

set(RPiBroadcomEGL_COMPILE_OPTIONS "${_RPiBroadcomEGL_compile_options}" CACHE STRING "Extra compile options of RPIBroadcomEGL")

set(RPiBroadcomEGL_LINK_LIBRARIES "${_RPiBroadcomEGL_link_libraries}" CACHE STRING "Extra link libraries of RPIBroadcomEGL")

set(RPiBroadcomEGL_LINK_OPTIONS "${_RPiBroadcomEGL_link_options}" CACHE STRING "Extra link flags of RPIBroadcomEGL")

set(RPiBroadcomEGL_LINK_DIRECTORIES "${_RPiBroadcomEGL_link_directories}" CACHE PATH "Extra link directories of RPIBroadcomEGL")

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(RPiBroadcomEGL
    REQUIRED_VARS RPiBroadcomEGL_LIBRARY RPiBroadcomEGL_INCLUDE_PATH
)

if(RPiBroadcomEGL_FOUND)
    if(NOT TARGET RPiBroadcomEGL::RPiBroadcomEGL)
        add_library(RPiBroadcomEGL::RPiBroadcomEGL UNKNOWN IMPORTED)
        set_target_properties(RPiBroadcomEGL::RPiBroadcomEGL PROPERTIES
            IMPORTED_LOCATION "${RPiBroadcomEGL_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${RPiBroadcomEGL_INCLUDE_PATH};${RPiBroadcomEGL_INCLUDE_DIRS}"
            INTERFACE_COMPILE_OPTIONS "${RPiBroadcomEGL_COMPILE_OPTIONS}"
            INTERFACE_LINK_LIBRARIES "${RPiBroadcomEGL_LINK_LIBRARIES}"
            INTERFACE_LINK_OPTIONS "${RPiBroadcomEGL_LINK_OPTIONS}"
            INTERFACE_LINK_DIRECTORIES "${RPiBroadcomEGL_LINK_DIRECTORIES}"
            )
    endif()
endif()
