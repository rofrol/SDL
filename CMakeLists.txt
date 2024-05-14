cmake_minimum_required(VERSION 3.16)

if(CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_CURRENT_BINARY_DIR)
  message(FATAL_ERROR "Prevented in-tree build. Please create a build directory outside of the SDL source code and run \"cmake -S ${CMAKE_SOURCE_DIR} -B .\" from there")
endif()

# MSVC runtime library flags are selected by an abstraction.
set(CMAKE_POLICY_DEFAULT_CMP0091 NEW)

# See docs/release_checklist.md
project(SDL3 LANGUAGES C VERSION "3.1.2")

if(CMAKE_SOURCE_DIR STREQUAL PROJECT_SOURCE_DIR)
  set(SDL3_SUBPROJECT OFF)
else()
  set(SDL3_SUBPROJECT ON)
endif()

# CMake 3.0 expands the "if(${A})" in "set(OFF 1);set(A OFF);if(${A})" to "if(1)"
# CMake 3.24+ emits a warning when not set.
unset(OFF)
unset(ON)
if(POLICY CMP0054)
  cmake_policy(SET CMP0054 NEW)
endif()

include(CheckLibraryExists)
include(CheckIncludeFile)
include(CheckLanguage)
include(CheckSymbolExists)
include(CheckCSourceCompiles)
include(CheckCSourceRuns)
include(CheckCCompilerFlag)
include(CheckCXXCompilerFlag)
include(CheckStructHasMember)
include(CMakeDependentOption)
include(CMakeParseArguments)
include(CMakePushCheckState)
include(GNUInstallDirs)

if(NOT DEFINED OpenGL_GL_PREFERENCE)
  set(OpenGL_GL_PREFERENCE GLVND)
endif()

find_package(PkgConfig)

list(APPEND CMAKE_MODULE_PATH "${SDL3_SOURCE_DIR}/cmake")
include("${SDL3_SOURCE_DIR}/cmake/macros.cmake")
include("${SDL3_SOURCE_DIR}/cmake/sdlchecks.cmake")
include("${SDL3_SOURCE_DIR}/cmake/sdlcompilers.cmake")
include("${SDL3_SOURCE_DIR}/cmake/sdlmanpages.cmake")
include("${SDL3_SOURCE_DIR}/cmake/sdlplatform.cmake")
include("${SDL3_SOURCE_DIR}/cmake/sdltargets.cmake")
include("${SDL3_SOURCE_DIR}/cmake/CheckCPUArchitecture.cmake")
include("${SDL3_SOURCE_DIR}/cmake/GetGitRevisionDescription.cmake")
include("${SDL3_SOURCE_DIR}/cmake/3rdparty.cmake")

SDL_DetectCompiler()
SDL_DetectCPUArchitecture()
SDL_DetectCMakePlatform()

if(NOT DEFINED SDL_CMAKE_PLATFORM_FILE)
  set(SDL_CMAKE_PLATFORM_FILE "${SDL3_SOURCE_DIR}/cmake/sdl_platforms/${SDL_CMAKE_PLATFORM_FILENAME_DEFAULT}.cmake")
endif()
message(STATUS "SDL_CMAKE_PLATFORM_FILE=${SDL_CMAKE_PLATFORM_FILE}")
include("${SDL_CMAKE_PLATFORM_FILE}")

# Increment this if there is an incompatible change - but if that happens,
# we should rename the library from SDL3 to SDL4, at which point this would
# reset to 0 anyway.
set(SDL_SO_VERSION_MAJOR "0")
set(SDL_SO_VERSION_MINOR "${PROJECT_VERSION_MINOR}")
set(SDL_SO_VERSION_PATCH "${PROJECT_VERSION_PATCH}")
set(SDL_SO_VERSION "${SDL_SO_VERSION_MAJOR}.${SDL_SO_VERSION_MINOR}.${SDL_SO_VERSION_PATCH}")

if(PROJECT_VERSION_MINOR MATCHES "[02468]$")
  math(EXPR SDL_DYLIB_COMPAT_VERSION_MAJOR "100 * ${PROJECT_VERSION_MINOR} + 1")
  set(SDL_DYLIB_COMPAT_VERSION_MINOR "0")
  math(EXPR SDL_DYLIB_CURRENT_VERSION_MAJOR "${SDL_DYLIB_COMPAT_VERSION_MAJOR}")
  set(SDL_DYLIB_CURRENT_VERSION_MINOR "${PROJECT_VERSION_PATCH}")
else()
  math(EXPR SDL_DYLIB_COMPAT_VERSION_MAJOR "100 * ${PROJECT_VERSION_MINOR} + ${PROJECT_VERSION_PATCH} + 1")
  set(SDL_DYLIB_COMPAT_VERSION_MINOR "0")
  math(EXPR SDL_DYLIB_CURRENT_VERSION_MAJOR "${SDL_DYLIB_COMPAT_VERSION_MAJOR}")
  set(SDL_DYLIB_CURRENT_VERSION_MINOR "0")
endif()
set(SDL_DYLIB_CURRENT_VERSION_PATCH "0")
set(SDL_DYLIB_COMPAT_VERSION_PATCH "0")

set(SDL_DYLIB_CURRENT_VERSION "${SDL_DYLIB_CURRENT_VERSION_MAJOR}.${SDL_DYLIB_CURRENT_VERSION_MINOR}.${SDL_DYLIB_CURRENT_VERSION_PATCH}")
set(SDL_DYLIB_COMPAT_VERSION "${SDL_DYLIB_COMPAT_VERSION_MAJOR}.${SDL_DYLIB_COMPAT_VERSION_MINOR}.${SDL_DYLIB_COMPAT_VERSION_PATCH}")

message(DEBUG "SDL_SO_VERSION=${SDL_SO_VERSION} SDL_DYLIB_CURRENT_VERSION=${SDL_DYLIB_CURRENT_VERSION} SDL_DYLIB_COMPAT_VERSION=${SDL_DYLIB_COMPAT_VERSION}")

set(SDL_FRAMEWORK_VERSION "A")

set(SDL_CHECK_REQUIRED_INCLUDES "" CACHE STRING "Extra includes (for CMAKE_REQUIRED_INCLUDES)")
set(SDL_CHECK_REQUIRED_LINK_OPTIONS "" CACHE STRING "Extra link options (for CMAKE_REQUIRED_LINK_OPTIONS)")
mark_as_advanced(SDL_CHECK_REQUIRED_INCLUDES SDL_CHECK_REQUIRED_LINK_OPTIONS)

string(APPEND CMAKE_REQUIRED_FLAGS " -D_GNU_SOURCE=1")
list(APPEND CMAKE_REQUIRED_INCLUDES ${SDL_CHECK_REQUIRED_INCLUDES})
list(APPEND CMAKE_REQUIRED_LINK_OPTIONS ${SDL_CHECK_REQUIRED_LINK_OPTIONS})

# Don't mistake macOS for unix
if(UNIX AND NOT ANDROID AND NOT APPLE AND NOT RISCOS)
  set(UNIX_SYS ON)
else()
  set(UNIX_SYS OFF)
endif()

if(UNIX OR APPLE)
  set(UNIX_OR_MAC_SYS ON)
else()
  set(UNIX_OR_MAC_SYS OFF)
endif()

set(SDL_PTHREADS_DEFAULT OFF)
set(SDL_CLOCK_GETTIME_DEFAULT OFF)

set(SDL_OPENGL_AVAILABLE OFF)
set(SDL_OPENGLES_AVAILABLE OFF)
set(SDL_VULKAN_AVAILABLE OFF)

# The hidraw support doesn't catch Xbox, PS4 and Nintendo controllers,
#  so we'll just use libusb when it's available. libusb does not support iOS,
#  so we default to yes on iOS.
set(SDL_HIDAPI_LIBUSB_AVAILABLE OFF)

set(SDL_ASSEMBLY_DEFAULT OFF)
if(USE_CLANG OR USE_GCC OR USE_INTELCC OR MSVC_VERSION GREATER 1400)
  set(SDL_ASSEMBLY_DEFAULT ON)
endif()

set(SDL_GCC_ATOMICS_DEFAULT OFF)
if(USE_GCC OR USE_CLANG OR USE_INTELCC OR USE_QCC)
  set(SDL_GCC_ATOMICS_DEFAULT ON)
endif()

# Default option knobs
set(SDL_LIBC_DEFAULT ON)
set(SDL_SYSTEM_ICONV_DEFAULT ON)

if(MSVC)
  dep_option(SDL_STATIC_VCRT "Use /MT for static VC runtimes" ON "NOT WINDOWS_STORE" OFF)
  if(SDL_STATIC_VCRT)
    if(NOT DEFINED CMAKE_MSVC_RUNTIME_LIBRARY)
      set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
    endif()
    foreach(flag_var
        CMAKE_C_FLAGS CMAKE_C_FLAGS_DEBUG CMAKE_C_FLAGS_RELEASE
        CMAKE_C_FLAGS_MINSIZEREL CMAKE_C_FLAGS_RELWITHDEBINFO)
      if(${flag_var} MATCHES "/MD")
        string(REGEX REPLACE "/MD" "/MT" ${flag_var} "${${flag_var}}")
      endif()
    endforeach()
  endif()

  if(NOT SDL_LIBC)
    # Make sure /RTC1 is disabled, otherwise it will use functions from the CRT
    foreach(flag_var
        CMAKE_C_FLAGS CMAKE_C_FLAGS_DEBUG CMAKE_C_FLAGS_RELEASE
        CMAKE_C_FLAGS_MINSIZEREL CMAKE_C_FLAGS_RELWITHDEBINFO)
      string(REGEX REPLACE "/RTC(su|[1su])" "" ${flag_var} "${${flag_var}}")
    endforeach(flag_var)
  endif()

  if(MSVC_CLANG)
    # clang-cl treats /W4 as '-Wall -Wextra' -- we don't need -Wextra
    foreach(flag_var
        CMAKE_C_FLAGS CMAKE_C_FLAGS_DEBUG CMAKE_C_FLAGS_RELEASE
        CMAKE_C_FLAGS_MINSIZEREL CMAKE_C_FLAGS_RELWITHDEBINFO)
      string(REGEX REPLACE "/W4" "/W3" ${flag_var} "${${flag_var}}")
    endforeach(flag_var)
  endif()
endif()

set(SDL_SHARED_DEFAULT ON)
set(SDL_STATIC_DEFAULT ON)

set(SDL_SHARED_AVAILABLE ON)
set(SDL_STATIC_AVAILABLE ON)

if((RISCOS OR UNIX_SYS) AND NOT (LINUX OR NETBSD OR OPENBSD))
  set(SDL_OSS_DEFAULT ON)
else()
  set(SDL_OSS_DEFAULT OFF)
endif()

SDL_Platform_PreConfigureOptions()
# Beyond this point, *_DEFAULT and *_AVAILABLE variables can be used

if(SDL_SHARED_DEFAULT AND SDL_STATIC_DEFAULT AND SDL_SHARED_AVAILABLE)
  if(DEFINED BUILD_SHARED_LIBS)
    # When defined, use BUILD_SHARED_LIBS as default
    if(BUILD_SHARED_LIBS)
      set(SDL_STATIC_DEFAULT OFF)
    else()
      set(SDL_SHARED_DEFAULT OFF)
    endif()
  else()
    # Default to just building the shared library
    set(SDL_STATIC_DEFAULT OFF)
  endif()
endif()

set(SDL_SUBSYSTEMS )

macro(define_sdl_subsystem _name)
  cmake_parse_arguments("_ds" "" "" "DEPS" ${ARGN})
  string(TOUPPER ${_name} _uname)
  if(NOT DEFINED SDL_${_uname}_DEFAULT)
    set(SDL_${_uname}_DEFAULT ON)
  endif()
  if(_ds_DEPS)
    cmake_dependent_option(SDL_${_uname} "Enable the ${_name} subsystem" "${SDL_${_uname}_DEFAULT}" "${_ds_DEPS}" OFF)
  else()
    option(SDL_${_uname} "Enable the ${_name} subsystem" "${SDL_${_uname}_DEFAULT}")
  endif()
  list(APPEND SDL_SUBSYSTEMS "${_name}")
endmacro()

define_sdl_subsystem(Audio)
define_sdl_subsystem(Video)
define_sdl_subsystem(Render DEPS SDL_VIDEO)
define_sdl_subsystem(Camera DEPS SDL_VIDEO)
define_sdl_subsystem(Joystick)
define_sdl_subsystem(Haptic)
define_sdl_subsystem(Hidapi)
define_sdl_subsystem(Power)
define_sdl_subsystem(Sensor)
define_sdl_subsystem(Dialog)

cmake_dependent_option(SDL_FRAMEWORK "Build SDL libraries as Apple Framework" OFF "APPLE" OFF)
if(SDL_FRAMEWORK)
  set(SDL_STATIC_AVAILABLE FALSE)
endif()

if(UNIX AND NOT ANDROID AND NOT RISCOS AND NOT SDL_FRAMEWORK)
  set(SDL_RPATH_DEFAULT ON)
else()
  set(SDL_RPATH_DEFAULT OFF)
endif()

# Allow some projects to be built conditionally.
set_option(SDL_DISABLE_INSTALL    "Disable installation of SDL3" ${SDL3_SUBPROJECT})
cmake_dependent_option(SDL_DISABLE_INSTALL_CPACK "Create binary SDL3 archive using CPack" ${SDL3_SUBPROJECT} "NOT SDL_DISABLE_INSTALL" ON)
cmake_dependent_option(SDL_DISABLE_INSTALL_DOCS "Install docs for SDL3" ON "NOT SDL_DISABLE_INSTALL;NOT SDL_FRAMEWORK" ON)
set_option(SDL_DISABLE_UNINSTALL  "Disable uninstallation of SDL3" OFF)

option_string(SDL_ASSERTIONS "Enable internal sanity checks (auto/disabled/release/enabled/paranoid)" "auto")
set_option(SDL_ASSEMBLY            "Enable assembly routines" ${SDL_ASSEMBLY_DEFAULT})
dep_option(SDL_AVX                 "Use AVX assembly routines" ON "SDL_ASSEMBLY;SDL_CPU_X86 OR SDL_CPU_X64" OFF)
dep_option(SDL_AVX2                "Use AVX2 assembly routines" ON "SDL_ASSEMBLY;SDL_CPU_X86 OR SDL_CPU_X64" OFF)
dep_option(SDL_AVX512F             "Use AVX512F assembly routines" ON "SDL_ASSEMBLY;SDL_CPU_X86 OR SDL_CPU_X64" OFF)
dep_option(SDL_SSE                 "Use SSE assembly routines" ON "SDL_ASSEMBLY;SDL_CPU_X86 OR SDL_CPU_X64" OFF)
dep_option(SDL_SSE2                "Use SSE2 assembly routines" ON "SDL_ASSEMBLY;SDL_CPU_X86 OR SDL_CPU_X64" OFF)
dep_option(SDL_SSE3                "Use SSE3 assembly routines" ON "SDL_ASSEMBLY;SDL_CPU_X86 OR SDL_CPU_X64" OFF)
dep_option(SDL_SSE4_1              "Use SSE4.1 assembly routines" ON "SDL_ASSEMBLY;SDL_CPU_X86 OR SDL_CPU_X64" OFF)
dep_option(SDL_SSE4_2              "Use SSE4.2 assembly routines" ON "SDL_ASSEMBLY;SDL_CPU_X86 OR SDL_CPU_X64" OFF)
dep_option(SDL_MMX                 "Use MMX assembly routines" ON "SDL_ASSEMBLY;SDL_CPU_X86 OR SDL_CPU_X64" OFF)
dep_option(SDL_ALTIVEC             "Use Altivec assembly routines" ON "SDL_ASSEMBLY;SDL_CPU_POWERPC32 OR SDL_CPU_POWERPC64" OFF)
dep_option(SDL_ARMSIMD             "Use SIMD assembly blitters on ARM" OFF "SDL_ASSEMBLY;SDL_CPU_ARM32" OFF)
dep_option(SDL_ARMNEON             "Use NEON assembly routines" ON "SDL_ASSEMBLY;SDL_CPU_ARM32 OR SDL_CPU_ARM64" OFF)
dep_option(SDL_ARMNEON_BLITTERS    "Use NEON assembly blitters on ARM32" OFF "SDL_VIDEO;SDL_ASSEMBLY;SDL_ARMNEON;SDL_CPU_ARM32" OFF)
dep_option(SDL_LSX                 "Use LSX assembly routines" ON "SDL_ASSEMBLY;SDL_CPU_LOONGARCH64" OFF)
dep_option(SDL_LASX                "Use LASX assembly routines" ON "SDL_ASSEMBLY;SDL_CPU_LOONGARCH64" OFF)

set_option(SDL_LIBC                "Use the system C library" ${SDL_LIBC_DEFAULT})
set_option(SDL_SYSTEM_ICONV        "Use iconv() from system-installed libraries" ${SDL_SYSTEM_ICONV_DEFAULT})
set_option(SDL_LIBICONV            "Prefer iconv() from libiconv, if available, over libc version" OFF)
set_option(SDL_GCC_ATOMICS         "Use gcc builtin atomics" ${SDL_GCC_ATOMICS_DEFAULT})
dep_option(SDL_DBUS                "Enable D-Bus support" ON "${UNIX_SYS}" OFF)
dep_option(SDL_DISKAUDIO           "Support the disk writer audio driver" ON "SDL_AUDIO" OFF)
dep_option(SDL_DUMMYAUDIO          "Support the dummy audio driver" ON "SDL_AUDIO" OFF)
dep_option(SDL_DUMMYVIDEO          "Use dummy video driver" ON "SDL_VIDEO" OFF)
dep_option(SDL_IBUS                "Enable IBus support" ON "${UNIX_SYS}" OFF)
dep_option(SDL_OPENGL              "Include OpenGL support" ON "SDL_VIDEO;SDL_OPENGL_AVAILABLE" OFF)
dep_option(SDL_OPENGLES            "Include OpenGL ES support" ON "SDL_VIDEO;SDL_OPENGLES_AVAILABLE" OFF)
set_option(SDL_PTHREADS            "Use POSIX threads for multi-threading" ${SDL_PTHREADS_DEFAULT})
dep_option(SDL_PTHREADS_SEM        "Use pthread semaphores" ON "SDL_PTHREADS" OFF)
dep_option(SDL_OSS                 "Support the OSS audio API" ${SDL_OSS_DEFAULT} "UNIX_SYS OR RISCOS;SDL_AUDIO" OFF)
dep_option(SDL_ALSA                "Support the ALSA audio API" ${UNIX_SYS} "SDL_AUDIO" OFF)
dep_option(SDL_ALSA_SHARED         "Dynamically load ALSA audio support" ON "SDL_ALSA" OFF)
dep_option(SDL_JACK                "Support the JACK audio API" ${UNIX_SYS} "SDL_AUDIO" OFF)
dep_option(SDL_JACK_SHARED         "Dynamically load JACK audio support" ON "SDL_JACK" OFF)
set_option(SDL_PIPEWIRE            "Use Pipewire audio" ${UNIX_SYS})
dep_option(SDL_PIPEWIRE_SHARED     "Dynamically load Pipewire support" ON "SDL_PIPEWIRE" OFF)
dep_option(SDL_PULSEAUDIO          "Use PulseAudio" ${UNIX_SYS} "SDL_AUDIO" OFF)
dep_option(SDL_PULSEAUDIO_SHARED   "Dynamically load PulseAudio support" ON "SDL_PULSEAUDIO" OFF)
dep_option(SDL_SNDIO               "Support the sndio audio API" ${UNIX_SYS} "SDL_AUDIO" OFF)
dep_option(SDL_SNDIO_SHARED        "Dynamically load the sndio audio API" ON "SDL_SNDIO" OFF)
set_option(SDL_RPATH               "Use an rpath when linking SDL" ${SDL_RPATH_DEFAULT})
set_option(SDL_CLOCK_GETTIME       "Use clock_gettime() instead of gettimeofday()" ${SDL_CLOCK_GETTIME_DEFAULT})
dep_option(SDL_X11                 "Use X11 video driver" ${UNIX_SYS} "SDL_VIDEO" OFF)
dep_option(SDL_X11_SHARED          "Dynamically load X11 support" ON "SDL_X11" OFF)
set(SDL_X11_OPTIONS Xcursor Xdbe XInput Xfixes Xrandr Xscrnsaver XShape)
foreach(_SUB ${SDL_X11_OPTIONS})
  string(TOUPPER "SDL_X11_${_SUB}" _OPT)
  dep_option(${_OPT}               "Enable ${_SUB} support" ON "SDL_X11" OFF)
endforeach()
dep_option(SDL_WAYLAND             "Use Wayland video driver" ${UNIX_SYS} "SDL_VIDEO" OFF)
dep_option(SDL_WAYLAND_SHARED      "Dynamically load Wayland support" ON "SDL_WAYLAND" OFF)
dep_option(SDL_WAYLAND_LIBDECOR    "Use client-side window decorations on Wayland" ON "SDL_WAYLAND" OFF)
dep_option(SDL_WAYLAND_LIBDECOR_SHARED     "Dynamically load libdecor support" ON "SDL_WAYLAND_LIBDECOR;SDL_WAYLAND_SHARED" OFF)
dep_option(SDL_RPI                 "Use Raspberry Pi video driver" ON "SDL_VIDEO;UNIX_SYS;SDL_CPU_ARM32 OR SDL_CPU_ARM64" OFF)
dep_option(SDL_ROCKCHIP            "Use ROCKCHIP Hardware Acceleration video driver" ON "SDL_VIDEO;UNIX_SYS;SDL_CPU_ARM32 OR SDL_CPU_ARM64" OFF)
dep_option(SDL_COCOA               "Use Cocoa video driver" ON "APPLE" OFF)
dep_option(SDL_DIRECTX             "Use DirectX for Windows audio/video" ON "SDL_AUDIO OR SDL_VIDEO;WINDOWS" OFF)
dep_option(SDL_XINPUT              "Use Xinput for Windows" ON "WINDOWS" OFF)
dep_option(SDL_WASAPI              "Use the Windows WASAPI audio driver" ON "WINDOWS;SDL_AUDIO" OFF)
dep_option(SDL_RENDER_D3D          "Enable the Direct3D render driver" ON "SDL_RENDER" OFF)
dep_option(SDL_RENDER_METAL        "Enable the Metal render driver" ON "SDL_RENDER;APPLE" OFF)
dep_option(SDL_VIVANTE             "Use Vivante EGL video driver" ON "${UNIX_SYS};SDL_CPU_ARM32" OFF)
dep_option(SDL_VULKAN              "Enable Vulkan support" ON "SDL_VIDEO;SDL_VULKAN_AVAILABLE" OFF)
dep_option(SDL_RENDER_VULKAN       "Enable the Vulkan render driver" ON "SDL_RENDER;SDL_VULKAN" OFF)
dep_option(SDL_METAL               "Enable Metal support" ON "APPLE" OFF)
dep_option(SDL_KMSDRM              "Use KMS DRM video driver" ${UNIX_SYS} "SDL_VIDEO" OFF)
dep_option(SDL_KMSDRM_SHARED       "Dynamically load KMS DRM support" ON "SDL_KMSDRM" OFF)
set_option(SDL_OFFSCREEN           "Use offscreen video driver" ON)
dep_option(SDL_DUMMYCAMERA         "Support the dummy camera driver" ON SDL_CAMERA OFF)
option_string(SDL_BACKGROUNDING_SIGNAL "number to use for magic backgrounding signal or 'OFF'" OFF)
option_string(SDL_FOREGROUNDING_SIGNAL "number to use for magic foregrounding signal or 'OFF'" OFF)
dep_option(SDL_HIDAPI              "Enable the HIDAPI subsystem" ON "NOT VISIONOS" OFF)
dep_option(SDL_HIDAPI_LIBUSB       "Use libusb for low level joystick drivers" ON SDL_HIDAPI_LIBUSB_AVAILABLE OFF)
dep_option(SDL_HIDAPI_LIBUSB_SHARED "Dynamically load libusb support" ON SDL_HIDAPI_LIBUSB OFF)
dep_option(SDL_HIDAPI_JOYSTICK     "Use HIDAPI for low level joystick drivers" ON SDL_HIDAPI OFF)
dep_option(SDL_VIRTUAL_JOYSTICK    "Enable the virtual-joystick driver" ON SDL_HIDAPI OFF)
set_option(SDL_LIBUDEV             "Enable libudev support" ON)
set_option(SDL_ASAN                "Use AddressSanitizer to detect memory errors" OFF)
set_option(SDL_CCACHE              "Use Ccache to speed up build" OFF)
set_option(SDL_CLANG_TIDY          "Run clang-tidy static analysis" OFF)

set(SDL_VENDOR_INFO "" CACHE STRING "Vendor name and/or version to add to SDL_REVISION")

cmake_dependent_option(SDL_SHARED "Build a shared version of the library" ${SDL_SHARED_DEFAULT} ${SDL_SHARED_AVAILABLE} OFF)
cmake_dependent_option(SDL_STATIC "Build a static version of the library" ${SDL_STATIC_DEFAULT} ${SDL_STATIC_AVAILABLE} OFF)
option(SDL_TEST_LIBRARY   "Build the SDL3_test library" ON)

dep_option(SDL_STATIC_PIC      "Static version of the library should be built with Position Independent Code" "${CMAKE_POSITION_INDEPENDENT_CODE}" "SDL_STATIC" OFF)
dep_option(SDL_TESTS           "Build the test directory" OFF SDL_TEST_LIBRARY OFF)
dep_option(SDL_INSTALL_TESTS   "Install test-cases" OFF "NOT SDL_DISABLE_INSTALL;NOT SDL_FRAMEWORK;NOT WINDOWS_STORE" OFF)
dep_option(SDL_TESTS_LINK_SHARED "link tests to shared SDL library" "${SDL_SHARED}" "SDL_SHARED;SDL_STATIC" "${SDL_SHARED}")
set(SDL_TESTS_TIMEOUT_MULTIPLIER "1" CACHE STRING "Timeout multiplier to account for really slow machines")

SDL_Platform_ExtraOptions()

set(HAVE_STATIC_PIC "${SDL_STATIC_PIC}")

if(NOT (SDL_SHARED OR SDL_STATIC))
  message(FATAL_ERROR "SDL_SHARED and SDL_STATIC cannot both be disabled")
endif()

if(SDL_SHARED)
  add_library(SDL3-shared SHARED)
  add_library(SDL3::SDL3-shared ALIAS SDL3-shared)
  SDL_AddCommonCompilerFlags(SDL3-shared)
  if ("c_std_99" IN_LIST CMAKE_C_COMPILE_FEATURES)
    target_compile_features(SDL3-shared PRIVATE c_std_99)
  else()
    message(WARNING "target_compile_features does not know c_std_99 for C compiler")
  endif()
endif()

if(SDL_STATIC)
  add_library(SDL3-static STATIC)
  add_library(SDL3::SDL3-static ALIAS SDL3-static)
  SDL_AddCommonCompilerFlags(SDL3-static)
  if ("c_std_99" IN_LIST CMAKE_C_COMPILE_FEATURES)
    target_compile_features(SDL3-static PRIVATE c_std_99)
  else()
    message(WARNING "target_compile_features does not know c_std_99 for C compiler")
  endif()
endif()

if(SDL_TEST_LIBRARY)
  add_library(SDL3_test STATIC)
  add_library(SDL3::SDL3_test ALIAS SDL3_test)
  SDL_AddCommonCompilerFlags(SDL3_test)
endif()

# Make sure SDL3::SDL3 always exists
if(TARGET SDL3::SDL3-shared)
  add_library(SDL3::SDL3 ALIAS SDL3-shared)
else()
  add_library(SDL3::SDL3 ALIAS SDL3-static)
endif()

sdl_pc_link_options("-lSDL3")

# Enable large file support on 32-bit glibc, so that we can access files
# with large inode numbers
check_symbol_exists("__GLIBC__" "stdlib.h" LIBC_IS_GLIBC)
if (LIBC_IS_GLIBC AND CMAKE_SIZEOF_VOID_P EQUAL 4)
  # Enable large file support on 32-bit glibc, so that we can access files with large inode numbers
  sdl_compile_definitions(PRIVATE "_FILE_OFFSET_BITS=64")
  # Enable 64-bit time_t on 32-bit glibc, so that time stamps remain correct beyond January 2038
  sdl_compile_definitions(PRIVATE "_TIME_BITS=64")
endif()

if(WINDOWS_STORE)
  sdl_compile_definitions(PRIVATE "SDL_BUILDING_WINRT=1")
  sdl_compile_options(PRIVATE "-ZW")
endif()

check_linker_supports_version_file(HAVE_WL_VERSION_SCRIPT)
if(HAVE_WL_VERSION_SCRIPT)
  sdl_shared_link_options("-Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/src/dynapi/SDL_dynapi.sym")
else()
  if((LINUX AND LIBC_IS_GLIBC) OR ANDROID)
    message(FATAL_ERROR "Linker does not support '-Wl,--version-script=xxx.sym'. This is required on the current host platform (${SDL_CMAKE_PLATFORM}).")
  endif()
endif()

if(CYGWIN)
  # We build SDL on cygwin without the UNIX emulation layer
  sdl_include_directories(PUBLIC SYSTEM "/usr/include/mingw")
  cmake_push_check_state()
  string(APPEND CMAKE_REQUIRED_FLAGS " -mno-cygwin")
  check_c_source_compiles("int main(int argc, char **argv) { return 0; }"
    HAVE_GCC_NO_CYGWIN)
  cmake_pop_check_state()
  if(HAVE_GCC_NO_CYGWIN)
    sdl_shared_link_options("-mno-cygwin")
  endif()
endif()

# General includes
sdl_compile_definitions(PRIVATE "USING_GENERATED_CONFIG_H")
sdl_include_directories(
  PRIVATE
    "${SDL3_BINARY_DIR}/include-config-$<LOWER_CASE:$<CONFIG>>"
    "${SDL3_BINARY_DIR}/include"
    "${SDL3_SOURCE_DIR}/include"
)
# Note: The clang toolset for Visual Studio does not support the '-idirafter' option.
if(USE_GCC OR USE_INTELCC OR (USE_CLANG AND NOT MSVC_CLANG))
  sdl_compile_options(NO_EXPORT PRIVATE "$<BUILD_INTERFACE:-idirafter${SDL3_SOURCE_DIR}/src/video/khronos>")
else()
  sdl_include_directories(NO_EXPORT SYSTEM PRIVATE "$<BUILD_INTERFACE:${SDL3_SOURCE_DIR}/src/video/khronos>")
endif()

# General source files
sdl_glob_sources(
  "${SDL3_SOURCE_DIR}/src/*.c"
  "${SDL3_SOURCE_DIR}/src/atomic/*.c"
  "${SDL3_SOURCE_DIR}/src/audio/*.c"
  "${SDL3_SOURCE_DIR}/src/camera/*.c"
  "${SDL3_SOURCE_DIR}/src/core/*.c"
  "${SDL3_SOURCE_DIR}/src/cpuinfo/*.c"
  "${SDL3_SOURCE_DIR}/src/dynapi/*.c"
  "${SDL3_SOURCE_DIR}/src/events/*.c"
  "${SDL3_SOURCE_DIR}/src/file/*.c"
  "${SDL3_SOURCE_DIR}/src/filesystem/*.c"
  "${SDL3_SOURCE_DIR}/src/joystick/*.c"
  "${SDL3_SOURCE_DIR}/src/haptic/*.c"
  "${SDL3_SOURCE_DIR}/src/hidapi/*.c"
  "${SDL3_SOURCE_DIR}/src/libm/*.c"
  "${SDL3_SOURCE_DIR}/src/locale/*.c"
  "${SDL3_SOURCE_DIR}/src/main/*.c"
  "${SDL3_SOURCE_DIR}/src/misc/*.c"
  "${SDL3_SOURCE_DIR}/src/power/*.c"
  "${SDL3_SOURCE_DIR}/src/render/*.c"
  "${SDL3_SOURCE_DIR}/src/render/*/*.c"
  "${SDL3_SOURCE_DIR}/src/sensor/*.c"
  "${SDL3_SOURCE_DIR}/src/stdlib/*.c"
  "${SDL3_SOURCE_DIR}/src/storage/*.c"
  "${SDL3_SOURCE_DIR}/src/thread/*.c"
  "${SDL3_SOURCE_DIR}/src/time/*.c"
  "${SDL3_SOURCE_DIR}/src/timer/*.c"
  "${SDL3_SOURCE_DIR}/src/video/*.c"
  "${SDL3_SOURCE_DIR}/src/video/yuv2rgb/*.c"
)
if(MSVC AND TARGET SDL3-shared)
  if(SDL_CPU_X64)
    enable_language(ASM_MASM)
    set(asm_src "${SDL3_SOURCE_DIR}/src/stdlib/SDL_mslibc_x64.masm")
    target_compile_options(SDL3-shared PRIVATE "$<$<COMPILE_LANGUAGE:ASM_MASM>:/nologo>")
    set_property(SOURCE "${asm_src}" PROPERTY LANGUAGE "ASM_MASM")
    target_sources(SDL3-shared PRIVATE "${asm_src}")
  elseif(SDL_CPU_ARM32 OR SDL_CPU_ARM64)
    # FIXME: ARM assembler (armasm.exe/armasm64.exe) is NOT ASM_MASM, and does currently not work with CMake
    # (https://gitlab.kitware.com/cmake/cmake/-/issues/18912)
  endif()
endif()

if(USE_INTELCC)
  # warning #39: division by zero
  # warning #239: floating point underflow
  # warning #264: floating-point value does not fit in required floating-point type
  set_property(SOURCE "${SDL3_SOURCE_DIR}/src/libm/e_exp.c" APPEND_STRING PROPERTY COMPILE_FLAGS " -wd239 -wd264")
  set_property(SOURCE "${SDL3_SOURCE_DIR}/src/libm/e_log.c" APPEND_STRING PROPERTY COMPILE_FLAGS " -wd39")
  set_property(SOURCE "${SDL3_SOURCE_DIR}/src/libm/e_log10.c" APPEND_STRING PROPERTY COMPILE_FLAGS " -wd39")
  set_property(SOURCE
    "${SDL3_SOURCE_DIR}/src/libm/e_exp.c"
    "${SDL3_SOURCE_DIR}/src/libm/e_log.c"
    "${SDL3_SOURCE_DIR}/src/libm/e_log10.c"
    PROPERTY SKIP_PRECOMPILE_HEADERS 1)
endif()

set(SDL_DEFAULT_ASSERT_LEVEL_CONFIGURED 1)
if(SDL_ASSERTIONS MATCHES "^(auto|)$")
  # Do nada - use optimization settings to determine the assertion level
  set(SDL_DEFAULT_ASSERT_LEVEL )
  set(SDL_DEFAULT_ASSERT_LEVEL_CONFIGURED 0)
elseif(SDL_ASSERTIONS MATCHES "^(disabled|0)$")
  set(SDL_DEFAULT_ASSERT_LEVEL 0)
elseif(SDL_ASSERTIONS MATCHES "^(release|1)$")
  set(SDL_DEFAULT_ASSERT_LEVEL 1)
elseif(SDL_ASSERTIONS MATCHES "^(enabled|2)$")
  set(SDL_DEFAULT_ASSERT_LEVEL 2)
elseif(SDL_ASSERTIONS MATCHES "^(paranoid|3)$")
  set(SDL_DEFAULT_ASSERT_LEVEL 3)
else()
  message(FATAL_ERROR "unknown assertion level")
endif()
set(HAVE_ASSERTIONS ${SDL_ASSERTIONS})

if(NOT SDL_BACKGROUNDING_SIGNAL STREQUAL "OFF")
  sdl_compile_definitions(PRIVATE "SDL_BACKGROUNDING_SIGNAL=${SDL_BACKGROUNDING_SIGNAL}")
endif()

if(NOT SDL_FOREGROUNDING_SIGNAL STREQUAL "OFF")
  sdl_compile_definitions(PRIVATE "SDL_FOREGROUNDING_SIGNAL=${SDL_FOREGROUNDING_SIGNAL}")
endif()

# Compiler option evaluation
if(USE_GCC OR USE_CLANG OR USE_INTELCC OR USE_QCC)
  if(SDL_GCC_ATOMICS)
    check_c_source_compiles("int main(int argc, char **argv) {
        int a;
        void *x, *y, *z;
        __sync_lock_test_and_set(&a, 4);
        __sync_lock_test_and_set(&x, y);
        __sync_fetch_and_add(&a, 1);
        __sync_bool_compare_and_swap(&a, 5, 10);
        __sync_bool_compare_and_swap(&x, y, z);
        return 0; }" COMPILER_SUPPORTS_GCC_ATOMICS)
    set(HAVE_GCC_ATOMICS ${COMPILER_SUPPORTS_GCC_ATOMICS})
    if(NOT HAVE_GCC_ATOMICS)
      check_c_source_compiles("int main(int argc, char **argv) {
          int a;
          __sync_lock_test_and_set(&a, 1);
          __sync_lock_release(&a);
          return 0; }" COMPILER_SUPPORTS_SYNC_LOCK_TEST_AND_SET)
      set(HAVE_GCC_SYNC_LOCK_TEST_AND_SET ${COMPILER_SUPPORTS_SYNC_LOCK_TEST_AND_SET})
    endif()
  endif()

  cmake_push_check_state()
  string(APPEND CMAKE_REQUIRED_FLAGS " -fvisibility=hidden -Werror")
  check_c_source_compiles("
      #if !defined(__GNUC__) || __GNUC__ < 4
      #error SDL only uses visibility attributes in GCC 4 or newer
      #endif
      __attribute__((visibility(\"default\"))) int foo(void);
      __attribute__((visibility(\"hidden\")))  int bar(void);
      int foo(void) { return 0; }
      int bar(void) { return 1; }
      int main(void) { return 0; }" HAVE_GCC_FVISIBILITY)
  cmake_pop_check_state()

  if(APPLE)
    check_c_compiler_flag(-Wno-error=deprecated-declarations COMPILER_SUPPORTS_WNO_ERROR_DEPRECATED_DECLARATIONS)
    if(COMPILER_SUPPORTS_WNO_ERROR_DEPRECATED_DECLARATIONS)
      sdl_compile_options(PRIVATE "-Wno-error=deprecated-declarations")
    endif()
  endif()

  if(APPLE)
    check_linker_flag(C "-Wl,-undefined,error" LINKER_SUPPORTS_WL_UNDEFINED_ERROR)
    if(LINKER_SUPPORTS_WL_UNDEFINED_ERROR)
      sdl_shared_link_options("-Wl,-undefined,error")
    endif()
  elseif(NOT OPENBSD)
    cmake_push_check_state()
    check_linker_flag(C "-Wl,--no-undefined" LINKER_SUPPORTS_WL_NO_UNDEFINED)
    #FIXME: originally this if had an additional "AND NOT (USE_CLANG AND WINDOWS)"
    if(LINKER_SUPPORTS_WL_NO_UNDEFINED)
      sdl_shared_link_options("-Wl,--no-undefined")
    endif()
  endif()
endif()

if(MSVC)
  sdl_compile_definitions(
    PRIVATE
      "_CRT_SECURE_NO_DEPRECATE"
      "_CRT_NONSTDC_NO_DEPRECATE"
      "_CRT_SECURE_NO_WARNINGS"
  )

  # CET support was added in VS 2019 16.7
  if(MSVC_VERSION GREATER 1926 AND CMAKE_GENERATOR_PLATFORM MATCHES "Win32|x64")
    # Mark SDL3.dll as compatible with Control-flow Enforcement Technology (CET)
    sdl_shared_link_options("-CETCOMPAT")
  endif()
endif()

if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  # Due to a limitation of Microsoft's LTO implementation, LTO must be disabled for memcpy and memset.
  # The same applies to various functions normally belonging in the C library (for x86 architecture).
  set_property(SOURCE "${SDL3_SOURCE_DIR}/src/stdlib/SDL_mslibc.c" APPEND_STRING PROPERTY COMPILE_FLAGS " /GL-")
endif()

if(SDL_ASSEMBLY)
  set(HAVE_ASSEMBLY TRUE)

  if(SDL_MMX)
    cmake_push_check_state()
    if(USE_GCC OR USE_CLANG OR USE_INTELCC)
      string(APPEND CMAKE_REQUIRED_FLAGS " -mmmx")
    endif()
    check_c_source_compiles("
      #include <mmintrin.h>
      void ints_add(int *dest, int *a, int *b, unsigned size) {
        for (; size >= 2; size -= 2, dest += 2, a += 2, b += 2) {
          *(__m64*)dest = _mm_add_pi32(*(__m64*)a, *(__m64*)b);
        }
      }
      int main(int argc, char *argv[]) {
        ints_add((int*)0, (int*)0, (int*)0, 0);
        return 0;
      }" COMPILER_SUPPORTS_MMX)
    cmake_pop_check_state()
    if(COMPILER_SUPPORTS_MMX)
      set(HAVE_MMX TRUE)
    endif()
  endif()
  if(SDL_SSE)
    cmake_push_check_state()
    if(USE_GCC OR USE_CLANG OR USE_INTELCC)
      string(APPEND CMAKE_REQUIRED_FLAGS " -msse")
    endif()
    check_c_source_compiles("
      #include <xmmintrin.h>
      void floats_add(float *dest, float *a, float *b, unsigned size) {
        for (; size >= 4; size -= 4, dest += 4, a += 4, b += 4) {
          _mm_storeu_ps(dest, _mm_add_ps(_mm_loadu_ps(a), _mm_loadu_ps (b)));
        }
      }
      int main(int argc, char **argv) {
        floats_add((float*)0, (float*)0, (float*)0, 0);
        return 0;
      }" COMPILER_SUPPORTS_SSE)
    cmake_pop_check_state()
    if(COMPILER_SUPPORTS_SSE)
      set(HAVE_SSE TRUE)
    endif()
  endif()
  if(SDL_SSE2)
    cmake_push_check_state()
    if(USE_GCC OR USE_CLANG OR USE_INTELCC)
      string(APPEND CMAKE_REQUIRED_FLAGS " -msse2")
    endif()
    check_c_source_compiles("
      #include <emmintrin.h>
      void doubles_add(double *dest, double *a, double *b, unsigned size) {
        for (; size >= 4; size -= 4, dest += 4, a += 4, b += 4) {
          _mm_store_pd(dest, _mm_add_pd(_mm_loadu_pd(a), _mm_loadu_pd(b)));
        }
      }
      int main(int argc, char **argv) {
        doubles_add((double*)0, (double*)0, (double*)0, 0);
        return 0;
      }" COMPILER_SUPPORTS_SSE2)
    cmake_pop_check_state()
    if(COMPILER_SUPPORTS_SSE2)
      set(HAVE_SSE2 TRUE)
    endif()
  endif()
  if(SDL_SSE3)
    cmake_push_check_state()
    if(USE_GCC OR USE_CLANG OR USE_INTELCC)
      string(APPEND CMAKE_REQUIRED_FLAGS " -msse3")
    endif()
    check_c_source_compiles("
      #include <pmmintrin.h>
      void ints_add(int *dest, int *a, int *b, unsigned size) {
        for (; size >= 4; size -= 4, dest += 4, a += 4, b += 4) {
          _mm_storeu_si128((__m128i*)dest, _mm_add_epi32(_mm_lddqu_si128((__m128i*)a), _mm_lddqu_si128((__m128i*)b)));
        }
      }
      int main(int argc, char **argv) {
        ints_add((int*)0, (int*)0, (int*)0, 0);
        return 0;
      }" COMPILER_SUPPORTS_SSE3)
    cmake_pop_check_state()
    if(COMPILER_SUPPORTS_SSE3)
      set(HAVE_SSE3 TRUE)
    endif()
  endif()
  if(SDL_SSE4_1)
    cmake_push_check_state()
    if(USE_GCC OR USE_CLANG OR USE_INTELCC)
      string(APPEND CMAKE_REQUIRED_FLAGS " -msse4.1")
    endif()
    check_c_source_compiles("
      #include <smmintrin.h>
      void ints_mul(int *dest, int *a, int *b, unsigned size) {
        for (; size >= 4; size -= 4, dest += 4, a += 4, b += 4) {
          _mm_storeu_si128((__m128i*)dest, _mm_mullo_epi32(_mm_lddqu_si128((__m128i*)a), _mm_lddqu_si128((__m128i*)b)));
        }
      }
      int main(int argc, char **argv) {
        ints_mul((int*)0, (int*)0, (int*)0, 0);
        return 0;
      }" COMPILER_SUPPORTS_SSE4_1)
    cmake_pop_check_state()
    if(COMPILER_SUPPORTS_SSE4_1)
      set(HAVE_SSE4_1 TRUE)
    endif()
  endif()
  if(SDL_SSE4_2)
    cmake_push_check_state()
    if(USE_GCC OR USE_CLANG OR USE_INTELCC)
      string(APPEND CMAKE_REQUIRED_FLAGS " -msse4.2")
    endif()
    check_c_source_compiles("
      #include <nmmintrin.h>
      unsigned calc_crc32c(const char *text, unsigned len) {
          unsigned crc32c = ~0;
          for (; len >= 4; len -= 4, text += 4) {
            crc32c = (unsigned)_mm_crc32_u32(crc32c, *(unsigned*)text);
          }
          return crc32c;
      }
      int main(int argc, char **argv) {
        calc_crc32c(\"SDL_SSE4\",8);
        return 0;
      }" COMPILER_SUPPORTS_SSE4_2)
    cmake_pop_check_state()
    if(COMPILER_SUPPORTS_SSE4_2)
      set(HAVE_SSE4_2 TRUE)
    endif()
  endif()
  if(SDL_AVX)
    cmake_push_check_state()
    if(USE_GCC OR USE_CLANG OR USE_INTELCC)
      string(APPEND CMAKE_REQUIRED_FLAGS " -mavx")
    endif()
    check_c_source_compiles("
      #include <immintrin.h>
      void floats_add(float *dest, float *a, float *b, unsigned size) {
        for (; size >= 8; size -= 8, dest += 8, a += 8, b += 8) {
          _mm256_storeu_ps(dest, _mm256_add_ps(_mm256_loadu_ps(a), _mm256_loadu_ps(b)));
        }
      }
      int main(int argc, char **argv) {
        floats_add((float*)0, (float*)0, (float*)0, 0);
        return 0;
      }" COMPILER_SUPPORTS_AVX)
    cmake_pop_check_state()
    if(COMPILER_SUPPORTS_AVX)
      set(HAVE_AVX TRUE)
    endif()
  endif()
  if(SDL_AVX2)
    cmake_push_check_state()
    if(USE_GCC OR USE_CLANG OR USE_INTELCC)
      string(APPEND CMAKE_REQUIRED_FLAGS " -mavx2")
    endif()
    check_c_source_compiles("
      #include <immintrin.h>
      void ints_add(int *dest, int *a, int *b, unsigned size) {
        for (; size >= 8; size -= 8, dest += 8, a += 8, b += 8) {
          _mm256_storeu_si256((__m256i*)dest, _mm256_add_epi32(_mm256_loadu_si256((__m256i*)a), _mm256_loadu_si256((__m256i*)b)));
        }
      }
      int main(int argc, char **argv) {
        ints_add((int*)0, (int*)0, (int*)0, 0);
        return 0;
      }" COMPILER_SUPPORTS_AVX2)
    cmake_pop_check_state()
    if(COMPILER_SUPPORTS_AVX2)
      set(HAVE_AVX2 TRUE)
    endif()
  endif()
  if(SDL_AVX512F)
    cmake_push_check_state()
    if(USE_GCC OR USE_CLANG OR USE_INTELCC)
      string(APPEND CMAKE_REQUIRED_FLAGS " -mavx512f")
    endif()
    check_c_source_compiles("
      #include <immintrin.h>
      void floats_add(float *dest, float *a, float *b, unsigned size) {
        for (; size >= 16; size -= 16, dest += 16, a += 16, b += 16) {
          _mm512_storeu_ps(dest, _mm512_add_ps(_mm512_loadu_ps(a), _mm512_loadu_ps(b)));
        }
      }
      int main(int argc, char **argv) {
        floats_add((float*)0, (float*)0, (float*)0, 0);
        return 0;
      }" COMPILER_SUPPORTS_AVX512F)
    cmake_pop_check_state()
    if(COMPILER_SUPPORTS_AVX512F)
      set(HAVE_AVX512F TRUE)
    endif()
  endif()

  if(USE_GCC OR USE_CLANG)
    # TODO: Those all seem to be quite GCC specific - needs to be
    # reworked for better compiler support

    if(SDL_ALTIVEC)
      cmake_push_check_state()
      string(APPEND CMAKE_REQUIRED_FLAGS " -maltivec")
      check_c_source_compiles("
          #include <altivec.h>
          vector unsigned int vzero() {
              return vec_splat_u32(0);
          }
          int main(int argc, char **argv) { return 0; }" COMPILER_SUPPORTS_ALTIVEC)
      cmake_pop_check_state()
      if(COMPILER_SUPPORTS_ALTIVEC)
        set(HAVE_ALTIVEC TRUE)
        set(SDL_ALTIVEC_BLITTERS 1)
        sdl_compile_options(PRIVATE "-maltivec")
        set_property(SOURCE "${SDL3_SOURCE_DIR}/src/video/SDL_blit_N.c" APPEND PROPERTY COMPILE_DEFINITIONS "SDL_ENABLE_ALTIVEC")
        set_property(SOURCE "${SDL3_SOURCE_DIR}/src/video/SDL_blit_N.c" PROPERTY SKIP_PRECOMPILE_HEADERS 1)
      endif()
    endif()

    if(SDL_LSX)
      cmake_push_check_state()
      string(APPEND CMAKE_REQUIRED_FLAGS " -mlsx")
      check_c_source_compiles("
          #ifndef __loongarch_sx
          #error Assembler CPP flag not enabled
          #endif
          int main(int argc, char **argv) { return 0; }" COMPILER_SUPPORTS_LSX)
      check_include_file("lsxintrin.h" HAVE_LSXINTRIN_H)
      cmake_pop_check_state()

      if(COMPILER_SUPPORTS_LSX AND HAVE_LSXINTRIN_H)
        set_property(SOURCE "${SDL3_SOURCE_DIR}/src/video/yuv2rgb/yuv_rgb_lsx.c" APPEND PROPERTY COMPILE_OPTIONS "-mlsx")
        set(HAVE_LSX TRUE)
      endif()
    endif()

    if(SDL_LASX)
      cmake_push_check_state()
      string(APPEND CMAKE_REQUIRED_FLAGS " -mlasx")
      check_c_source_compiles("
          #ifndef __loongarch_asx
          #error Assembler CPP flag not enabled
          #endif
          int main(int argc, char **argv) { return 0; }" COMPILER_SUPPORTS_LASX)
      check_include_file("lasxintrin.h" HAVE_LASXINTRIN_H)
      cmake_pop_check_state()
      if(COMPILER_SUPPORTS_LASX AND HAVE_LASXINTRIN_H)
        set(HAVE_LASX TRUE)
      endif()
    endif()

    if(SDL_ARMSIMD)
      cmake_push_check_state()
      string(APPEND CMAKE_REQUIRED_FLAGS " -x assembler-with-cpp")
      list(APPEND CMAKE_REQUIRED_LINK_OPTIONS -x none)
      check_c_source_compiles("
        .text
        .arch armv6
        .object_arch armv4
        .arm
        .altmacro
        #ifndef __ARM_EABI__
        #error EABI is required (to be sure that calling conventions are compatible)
        #endif
        main:
        .global main
        pld [r0]
        uqadd8 r0, r0, r0
      " ARMSIMD_FOUND)
      cmake_pop_check_state()

      if(ARMSIMD_FOUND)
        set(HAVE_ARMSIMD TRUE)
        set(SDL_ARM_SIMD_BLITTERS 1)
        enable_language(ASM)
        sdl_glob_sources("${SDL3_SOURCE_DIR}/src/video/arm/pixman-arm-simd*.S")
        set_property(SOURCE ${ARMSIMD_SOURCES} APPEND PROPERTY COMPILE_OPTIONS -x assembler-with-cpp)
        set(WARN_ABOUT_ARM_SIMD_ASM_MIT TRUE)
      endif()
    endif()

    if(SDL_ARMNEON_BLITTERS)
      cmake_push_check_state()
      string(APPEND CMAKE_REQUIRED_FLAGS " -x assembler-with-cpp")
      list(APPEND CMAKE_REQUIRED_LINK_OPTIONS -x none)
      check_c_source_compiles("
        .text
        .fpu neon
        .arch armv7a
        .object_arch armv4
        .eabi_attribute 10, 0
        .arm
        .altmacro
        #ifndef __ARM_EABI__
        #error EABI is required (to be sure that calling conventions are compatible)
        #endif
        main:
        .global main
        pld [r0]
        vmovn.u16 d0, q0
      " COMPILER_SUPPORTS_ARMNEON_ASSEMBLY)
      cmake_pop_check_state()
      if(COMPILER_SUPPORTS_ARMNEON_ASSEMBLY)
        set(HAVE_ARMNEON_BLITTERS TRUE)
        set(SDL_ARM_NEON_BLITTERS 1)
        enable_language(ASM)
        sdl_glob_sources("${SDL3_SOURCE_DIR}/src/video/arm/pixman-arm-neon*.S")
        set_property(SOURCE ${ARMNEON_SOURCES} APPEND PROPERTY COMPILE_OPTIONS -x assembler-with-cpp)
        set(WARN_ABOUT_ARM_NEON_ASM_MIT TRUE)
      endif()
    endif()

    if(SDL_ARMNEON)
      check_c_source_compiles("
        #include <arm_neon.h>
        void floats_add(float *dest, float *a, float *b, unsigned size) {
          for (; size >= 4; size -= 4, dest += 4, a += 4, b += 4) {
            vst1q_f32(dest, vaddq_f32(vld1q_f32(a), vld1q_f32(b)));
          }
        }
        int main(int argc, char *argv[]) {
          floats_add((float*)0, (float*)0, (float*)0, 0);
          return 0;
         }" COMPILER_SUPPORTS_ARMNEON)

      if(COMPILER_SUPPORTS_ARMNEON)
        set(HAVE_ARMNEON TRUE)
      endif()
    endif()
  endif()
endif()

if(NOT HAVE_MMX)
  set(SDL_DISABLE_MMX 1)
endif()

if(NOT HAVE_SSE)
  set(SDL_DISABLE_SSE 1)
endif()

if(NOT HAVE_SSE2)
  set(SDL_DISABLE_SSE2 1)
endif()

if(NOT HAVE_SSE3)
  set(SDL_DISABLE_SSE3 1)
endif()

if(NOT HAVE_SSE4_1)
  set(SDL_DISABLE_SSE4_1 1)
endif()

if(NOT HAVE_SSE4_2)
  set(SDL_DISABLE_SSE4_2 1)
endif()

if(NOT HAVE_AVX)
  set(SDL_DISABLE_AVX 1)
endif()

if(NOT HAVE_AVX2)
  set(SDL_DISABLE_AVX2 1)
endif()

if(NOT HAVE_AVX512F)
  set(SDL_DISABLE_AVX512F 1)
endif()

if(NOT HAVE_LSX)
  set(SDL_DISABLE_LSX 1)
endif()

if(NOT HAVE_LASX)
  set(SDL_DISABLE_LASX 1)
endif()

if(NOT HAVE_ARMNEON)
  set(SDL_DISABLE_NEON 1)
endif()

set(SDL_DISABLE_ALLOCA 0)
check_include_file("alloca.h" "HAVE_ALLOCA_H")
if(MSVC)
  check_include_file("malloc.h" "HAVE_MALLOC")
  check_symbol_exists("_alloca" "malloc.h" _ALLOCA_IN_MALLOC_H)
  if(NOT HAVE_ALLOCA_H AND NOT _ALLOCA_IN_MALLOC_H)
    set(SDL_DISABLE_ALLOCA 1)
  endif()
endif()

# TODO: Can't deactivate on FreeBSD? w/o LIBC, SDL_stdinc.h can't define anything.
if(SDL_LIBC)
  set(available_headers)
  set(HAVE_LIBC TRUE)
  set(headers_to_check
    float.h
    iconv.h
    inttypes.h
    limits.h
    malloc.h
    math.h
    memory.h
    signal.h
    stdarg.h
    stddef.h
    stdint.h
    stdio.h
    stdlib.h
    string.h
    strings.h
    sys/types.h
    time.h
    wchar.h
  )
  foreach(_HEADER IN LISTS headers_to_check)
    string(TOUPPER "${_HEADER}" HEADER_IDENTIFIER)
    string(REGEX REPLACE "[./]" "_" HEADER_IDENTIFIER "${HEADER_IDENTIFIER}")
    set(LIBC_HAS_VAR "LIBC_HAS_${HEADER_IDENTIFIER}")
    check_include_file("${_HEADER}" "${LIBC_HAS_VAR}")
    set(HAVE_${HEADER_IDENTIFIER} ${${LIBC_HAS_VAR}})
    if(HAVE_${HEADER_IDENTIFIER})
      list(APPEND available_headers "${_HEADER}")
    endif()
  endforeach()

  set(symbols_to_check
    abs acos acosf asin asinf atan atan2 atan2f atanf atof atoi
    bcopy
    calloc ceil ceilf copysign copysignf cos cosf
    _Exit exp expf
    fabs fabsf floor floorf fmod fmodf fopen64 free fseeko fseeko64
    getenv
    _i64toa index itoa
    log log10 log10f logf lround lroundf _ltoa
    malloc memcmp memcpy memmove memset modf modff
    pow powf putenv
    realloc rindex round roundf
    scalbn scalbnf setenv sin sinf sqr sqrt sqrtf sscanf strchr
    strcmp strlcat strlcpy strlen strncmp strnlen
    strrchr strstr strnstr strtod strtok_r strtol strtoll strtoul strtoull
    tan tanf trunc truncf
    unsetenv
    vsnprintf vsscanf
    wcsnlen wcscmp wcsdup wcslcat wcslcpy wcslen wcsncmp wcsstr wcstol
  )
  if(WINDOWS)
    list(APPEND symbols_to_check
      _strrev _ui64toa _uitoa _ultoa _wcsdup
    )
  else()
    list(APPEND symbols_to_check
        strcasestr
    )
  endif()
  check_library_exists(m pow "" HAVE_LIBM)
  cmake_push_check_state()
  if(HAVE_LIBM)
    sdl_link_dependency(math LIBS m)
    list(APPEND CMAKE_REQUIRED_LIBRARIES m)
  endif()
  foreach(_FN IN LISTS symbols_to_check)
    string(TOUPPER ${_FN} _UPPER)
    set(LIBC_HAS_VAR "LIBC_HAS_${_UPPER}")
    check_symbol_exists("${_FN}" "${available_headers}" ${LIBC_HAS_VAR})
    set(HAVE_${_UPPER} ${${LIBC_HAS_VAR}})
  endforeach()
  cmake_pop_check_state()

  if(NOT WINDOWS)
    check_symbol_exists(getpagesize "unistd.h" HAVE_GETPAGESIZE)
    check_symbol_exists(sigaction "signal.h" HAVE_SIGACTION)
    check_symbol_exists(setjmp "setjmp.h" HAVE_SETJMP)
    check_symbol_exists(nanosleep "time.h" HAVE_NANOSLEEP)
    check_symbol_exists(gmtime_r "time.h" HAVE_GMTIME_R)
    check_symbol_exists(localtime_r "time.h" HAVE_LOCALTIME_R)
    check_symbol_exists(nl_langinfo "langinfo.h" HAVE_NL_LANGINFO)
    check_symbol_exists(sysconf "unistd.h" HAVE_SYSCONF)
    check_symbol_exists(sysctlbyname "sys/types.h;sys/sysctl.h" HAVE_SYSCTLBYNAME)
    check_symbol_exists(getauxval "sys/auxv.h" HAVE_GETAUXVAL)
    check_symbol_exists(elf_aux_info "sys/auxv.h" HAVE_ELF_AUX_INFO)
    check_symbol_exists(poll "poll.h" HAVE_POLL)
    check_symbol_exists(memfd_create "sys/mman.h" HAVE_MEMFD_CREATE)
    check_symbol_exists(posix_fallocate "fcntl.h" HAVE_POSIX_FALLOCATE)

    if(SDL_SYSTEM_ICONV)
      check_c_source_compiles("
        #define LIBICONV_PLUG 1 /* in case libiconv header is in include path */
        #include <stddef.h>
        #include <iconv.h>
        int main(int argc, char **argv) {
            return !iconv_open(NULL,NULL);
        }" ICONV_IN_LIBC)

      cmake_push_check_state()
      list(APPEND CMAKE_REQUIRED_LIBRARIES iconv)
      check_c_source_compiles("
        #include <stddef.h>
        #include <iconv.h>
        int main(int argc, char **argv) {
            return !iconv_open(NULL,NULL);
        }" ICONV_IN_LIBICONV)
      cmake_pop_check_state()

      if(ICONV_IN_LIBC OR ICONV_IN_LIBICONV)
        set(HAVE_ICONV 1)
        set(HAVE_SYSTEM_ICONV TRUE)
        if(ICONV_IN_LIBICONV AND (SDL_LIBICONV OR (NOT ICONV_IN_LIBC)))
          sdl_link_dependency(iconv LIBS iconv)
          set(SDL_USE_LIBICONV 1)
          set(HAVE_LIBICONV TRUE)
        endif()
      endif()
    endif()

    check_struct_has_member("struct sigaction" "sa_sigaction" "signal.h" HAVE_SA_SIGACTION)
    check_struct_has_member("struct stat" "st_mtim" "sys/stat.h" HAVE_ST_MTIM)
  endif()
else()
  set(headers
    stdarg.h
    stddef.h
    stdint.h
  )
  foreach(_HEADER ${headers})
    string(TOUPPER "${_HEADER}" HEADER_IDENTIFIER)
    string(REGEX REPLACE "[./]" "_" HEADER_IDENTIFIER "${HEADER_IDENTIFIER}")
    set(LIBC_HAS_VAR "LIBC_HAS_${HEADER_IDENTIFIER}")
    check_include_file("${_HEADER}" "${LIBC_HAS_VAR}")
    set(HAVE_${HEADER_IDENTIFIER} ${${LIBC_HAS_VAR}})
  endforeach()

  if(MSVC AND USE_CLANG)
    check_c_compiler_flag("/Q_no-use-libirc" HAS_Q_NO_USE_LIBIRC)
  endif()
endif()


# Enable/disable various subsystems of the SDL library
foreach(_SUB ${SDL_SUBSYSTEMS})
  string(TOUPPER ${_SUB} _OPT)
  if(NOT SDL_${_OPT})
    set(SDL_${_OPT}_DISABLED 1)
  endif()
endforeach()
if(SDL_HAPTIC)
  if(NOT SDL_JOYSTICK)
    # Haptic requires some private functions from the joystick subsystem.
    message(FATAL_ERROR "SDL_HAPTIC requires SDL_JOYSTICK, which is not enabled")
  endif()
endif()


# General SDL subsystem options, valid for all platforms
if(SDL_AUDIO)
  # CheckDummyAudio/CheckDiskAudio - valid for all platforms
  if(SDL_DUMMYAUDIO)
    set(SDL_AUDIO_DRIVER_DUMMY 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/audio/dummy/*.c")
    set(HAVE_DUMMYAUDIO TRUE)
    set(HAVE_SDL_AUDIO TRUE)
  endif()
  if(SDL_DISKAUDIO)
    set(SDL_AUDIO_DRIVER_DISK 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/audio/disk/*.c")
    set(HAVE_DISKAUDIO TRUE)
    set(HAVE_SDL_AUDIO TRUE)
  endif()
endif()

if(SDL_CAMERA)
  # CheckDummyCamera/CheckDiskCamera - valid for all platforms
  if(SDL_DUMMYCAMERA)
    set(SDL_CAMERA_DRIVER_DUMMY 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/camera/dummy/*.c")
    set(HAVE_DUMMYCAMERA TRUE)
    set(HAVE_SDL_CAMERA TRUE)
  endif()
  # !!! FIXME: for later.
  #if(SDL_DISKCAMERA)
  #  set(SDL_CAMERA_DRIVER_DISK 1)
  #  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/camera/disk/*.c")
  #  set(HAVE_DISKCAMERA TRUE)
  #  set(HAVE_SDL_CAMERA TRUE)
  #endif()
endif()

if(UNIX OR APPLE)
  # Relevant for Unix/Darwin only
  set(DYNAPI_NEEDS_DLOPEN 1)
  CheckDLOPEN()
  if(HAVE_DLOPEN)
    set(SDL_LOADSO_DLOPEN 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/loadso/dlopen/*.c")
    set(HAVE_SDL_LOADSO TRUE)
  endif()
endif()

if(UNIX OR APPLE OR HAIKU OR RISCOS)
  CheckO_CLOEXEC()
endif()

if(SDL_JOYSTICK)
  if(SDL_VIRTUAL_JOYSTICK)
    set(HAVE_VIRTUAL_JOYSTICK TRUE)
    set(SDL_JOYSTICK_VIRTUAL 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/joystick/virtual/*.c")
  endif()
endif()

if(SDL_VIDEO)
  if(SDL_DUMMYVIDEO)
    set(SDL_VIDEO_DRIVER_DUMMY 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/video/dummy/*.c")
    set(HAVE_DUMMYVIDEO TRUE)
    set(HAVE_SDL_VIDEO TRUE)
  endif()
endif()

SDL_Platform_Features()

# Platform-independent options

if(SDL_VIDEO)
  if(SDL_OFFSCREEN AND SDL_VIDEO_OPENGL_EGL)
    set(SDL_VIDEO_DRIVER_OFFSCREEN 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/video/offscreen/*.c")
    set(HAVE_OFFSCREEN TRUE)
    set(HAVE_SDL_VIDEO TRUE)
  endif()
endif()

# Dummies
# configure.ac does it differently:
# if not have X
#   if enable_X {  SDL_X_DISABLED = 1 }
#   [add dummy sources]
# so it always adds a dummy, without checking, if it was actually requested.
# This leads to missing internal references on building, since the
# src/X/*.c does not get included.
if(NOT HAVE_SDL_AUDIO)
  set(SDL_AUDIO_DRIVER_DUMMY 1)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/audio/dummy/*.c")
endif()
if(NOT HAVE_SDL_VIDEO)
  set(SDL_VIDEO_DRIVER_DUMMY 1)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/video/dummy/*.c")
endif()
if(NOT HAVE_SDL_JOYSTICK)
  set(SDL_JOYSTICK_DUMMY 1)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/joystick/dummy/*.c")
endif()
if(NOT HAVE_SDL_HAPTIC)
  set(SDL_HAPTIC_DUMMY 1)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/haptic/dummy/*.c")
endif()
if(NOT HAVE_SDL_SENSORS)
  set(SDL_SENSOR_DUMMY 1)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/sensor/dummy/*.c")
endif()
if(NOT HAVE_SDL_LOADSO)
  set(SDL_LOADSO_DUMMY 1)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/loadso/dummy/*.c")
endif()
if(NOT HAVE_SDL_FILESYSTEM)
  set(SDL_FILESYSTEM_DUMMY 1)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/filesystem/dummy/*.c")
endif()
if(NOT HAVE_SDL_STORAGE)
  set(SDL_STORAGE_GENERIC 1)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/storage/generic/*.c")
endif()
if(NOT HAVE_SDL_FSOPS)
  set(SDL_FSOPS_DUMMY 1)
  sdl_sources("${SDL3_SOURCE_DIR}/src/filesystem/dummy/SDL_sysfsops.c")
endif()
if(NOT HAVE_SDL_LOCALE)
  set(SDL_LOCALE_DUMMY 1)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/locale/dummy/*.c")
endif()
if(NOT HAVE_SDL_MISC)
  set(SDL_MISC_DUMMY 1)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/misc/dummy/*.c")
endif()
if(NOT HAVE_SDL_DIALOG)
  set(SDL_DIALOG_DUMMY 1)
  sdl_sources(${SDL3_SOURCE_DIR}/src/dialog/dummy/SDL_dummydialog.c)
endif()
if(NOT HAVE_CAMERA)
  set(SDL_CAMERA_DRIVER_DUMMY 1)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/camera/dummy/*.c")
endif()

# We always need to have threads and timers around
if(NOT HAVE_SDL_THREADS)
  # The emscripten platform has been carefully vetted to work without threads
  if(EMSCRIPTEN)
    set(SDL_THREADS_DISABLED 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/thread/generic/*.c")
  else()
    message(FATAL_ERROR "Threads are needed by many SDL subsystems and may not be disabled")
  endif()
endif()
if(NOT HAVE_SDL_TIMERS)
  message(FATAL_ERROR "Timers are needed by many SDL subsystems and may not be disabled")
endif()

# Most platforms use this.
if(NOT HAVE_SDL_MAIN_CALLBACKS)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/main/generic/*.c")
endif()

# config variables may contain generator expression, so we need to generate SDL_build_config.h in 2 steps:
# 1. replace all `#cmakedefine`'s and `@abc@`
configure_file("${SDL3_SOURCE_DIR}/include/build_config/SDL_build_config.h.cmake"
  "${SDL3_BINARY_DIR}/SDL_build_config.h.intermediate")
# 2. generate SDL_build_config.h in an build_type-dependent folder (which should be first in the include search path)
file(GENERATE
  OUTPUT "${SDL3_BINARY_DIR}/include-config-$<LOWER_CASE:$<CONFIG>>/build_config/SDL_build_config.h"
  INPUT "${SDL3_BINARY_DIR}/SDL_build_config.h.intermediate"
)

file(GLOB SDL3_INCLUDE_FILES "${SDL3_SOURCE_DIR}/include/SDL3/*.h")
file(GLOB SDL3_TEST_INCLUDE_FILES "${SDL3_SOURCE_DIR}/include/SDL3/SDL_test*.h")
foreach(_hdr IN LISTS SDL3_INCLUDE_FILES)
  if(_hdr MATCHES ".*SDL_revision\\.h" OR _hdr MATCHES ".*SDL_test.*\\.h")
    list(REMOVE_ITEM SDL3_INCLUDE_FILES "${_hdr}")
  endif()
endforeach()

set(SDL_REVISION "" CACHE STRING "Custom SDL revision (overrides SDL_REVISION_SUFFIX)")
if(NOT SDL_REVISION)
  set(SDL_REVISION_SUFFIX "" CACHE STRING "Suffix for the SDL revision")
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/VERSION.txt")
    # If VERSION.txt exists, it contains the SDL version
    file(READ "${CMAKE_CURRENT_SOURCE_DIR}/VERSION.txt" SDL_REVISION_CENTER)
    string(STRIP "${SDL_REVISION_CENTER}" SDL_REVISION_CENTER)
  else()
    # If VERSION does not exist, use git to calculate a version
    git_describe(SDL_REVISION_CENTER)
    if(NOT SDL_REVISION_CENTER)
      set(SDL_REVISION_CENTER "${SDL3_VERSION}-no-vcs")
    endif()
  endif()
  set(SDL_REVISION "SDL-${SDL_REVISION_CENTER}${SDL_REVISION_SUFFIX}")
endif()

execute_process(COMMAND "${CMAKE_COMMAND}" -E make_directory "${SDL3_BINARY_DIR}/include/SDL3")
configure_file(include/build_config/SDL_revision.h.cmake include/SDL3/SDL_revision.h @ONLY)
list(APPEND SDL3_INCLUDE_FILES "${SDL3_BINARY_DIR}/include/SDL3/SDL_revision.h")

if(SDL_FRAMEWORK)
  # With Apple frameworks, headers in the PUBLIC_HEADER property also need to be added as sources
  list(APPEND SDL3_INCLUDE_FILES ${SDL3_TEST_INCLUDE_FILES})
  sdl_sources(${SDL3_INCLUDE_FILES})
endif()

if((CMAKE_STATIC_LIBRARY_PREFIX STREQUAL "" AND CMAKE_STATIC_LIBRARY_SUFFIX STREQUAL ".lib") OR SDL_FRAMEWORK)
  # - Avoid conflict between the dll import library and the static library
  # - Create SDL3-static Apple Framework
  set(sdl_static_libname "SDL3-static")
else()
  set(sdl_static_libname "SDL3")
endif()

macro(check_add_debug_flag FLAG SUFFIX)
  check_c_compiler_flag(${FLAG} HAS_C_FLAG_${SUFFIX})
  if(HAS_C_FLAG_${SUFFIX})
    string(APPEND CMAKE_C_FLAGS_DEBUG " ${FLAG}")
  endif()

  check_cxx_compiler_flag(${FLAG} HAS_CXX_${SUFFIX})
  if(HAS_CXX_${SUFFIX})
    string(APPEND CMAKE_CXX_FLAGS_DEBUG " ${FLAG}")
  endif()
endmacro()

macro(asan_check_add_debug_flag ASAN_FLAG)
  check_add_debug_flag("-fsanitize=${ASAN_FLAG}" "${ASAN_FLAG}")
  if(HAS_C_${ASAN_FLAG} OR HAS_CXX_${ASAN_FLAG})
    set(HAVE_ASAN ON)
  endif()
endmacro()

macro(asan_check_add_debug_flag2 ASAN_FLAG)
  # for some sanitize flags we have to manipulate the CMAKE_REQUIRED_LIBRARIES:
  # http://cmake.3232098.n2.nabble.com/CHECK-CXX-COMPILER-FLAG-doesn-t-give-correct-result-for-fsanitize-address-tp7600216p7600217.html

  set(FLAG "-fsanitize=${ASAN_FLAG}")

  cmake_push_check_state()
  list(APPEND CMAKE_REQUIRED_LIBRARIES ${FLAG} asan)
  check_c_compiler_flag (${FLAG} HAS_C_FLAG_${ASAN_FLAG})
  check_cxx_compiler_flag (${FLAG} HAS_CXX_FLAG_${ASAN_FLAG})
  cmake_pop_check_state()

  if (HAS_C_FLAG_${ASAN_FLAG})
    string(APPEND CMAKE_C_FLAGS_DEBUG " ${FLAG}")
  endif()

  if (HAS_CXX_${ASAN_FLAG})
    string(APPEND CMAKE_CXX_FLAGS_DEBUG " ${FLAG}")
  endif()

  if(HAS_C_${ASAN_FLAG} OR HAS_CXX_${ASAN_FLAG})
    set(HAVE_ASAN ON)
  endif()
endmacro()

# enable AddressSanitizer if supported
if(SDL_ASAN)
  asan_check_add_debug_flag2("address")
  asan_check_add_debug_flag("bool")
  asan_check_add_debug_flag("bounds")
  asan_check_add_debug_flag("enum")
  asan_check_add_debug_flag("float-cast-overflow")
  asan_check_add_debug_flag("float-divide-by-zero")
  asan_check_add_debug_flag("nonnull-attribute")
  asan_check_add_debug_flag("returns-nonnull-attribute")
  asan_check_add_debug_flag("signed-integer-overflow")
  asan_check_add_debug_flag("undefined")
  asan_check_add_debug_flag("vla-bound")
  asan_check_add_debug_flag("leak")
  # The object size sanitizer has no effect on unoptimized builds on Clang,
  # but causes warnings.
  if(NOT USE_CLANG OR CMAKE_BUILD_TYPE STREQUAL "")
    asan_check_add_debug_flag("object-size")
  endif()
endif()

if(SDL_CCACHE)
  find_program(CCACHE_BINARY ccache)
  if(CCACHE_BINARY)
    set(CMAKE_C_COMPILER_LAUNCHER ${CCACHE_BINARY})
    set(CMAKE_CXX_COMPILER_LAUNCHER ${CCACHE_BINARY})
    set(CMAKE_OBJC_COMPILER_LAUNCHER ${CCACHE_BINARY})
    set(HAVE_CCACHE ON)
  else()
    set(HAVE_CCACHE OFF)
  endif()
else()
  set(HAVE_CCACHE OFF)
endif()

if(SDL_CLANG_TIDY)
  cmake_minimum_required(VERSION 3.6)
  find_program(CLANG_TIDY_BINARY clang-tidy)

  if(CLANG_TIDY_BINARY)
    set(HAVE_CLANG_TIDY ON)
    get_clang_tidy_ignored_files(CLANG_TIDY_IGNORED_FILES)
    set(CLANG_TIDY_COMMAND "${CLANG_TIDY_BINARY}" "-extra-arg=-Wno-unknown-warning-option" "--line-filter=[${CLANG_TIDY_IGNORED_FILES}]")
    if(SDL_WERROR)
      list(APPEND CLANG_TIDY_COMMAND "--warnings-as-errors=*")
    endif()
    set(CMAKE_C_CLANG_TIDY ${CLANG_TIDY_COMMAND})
    set(CMAKE_CXX_CLANG_TIDY ${CLANG_TIDY_COMMAND})
    set(CMAKE_OBJC_CLANG_TIDY ${CLANG_TIDY_COMMAND})
    get_property(shared_sources TARGET SDL3-collector PROPERTY INTERFACE_SOURCES)
    set_source_files_properties(${shared_sources} PROPERTIES SKIP_PRECOMPILE_HEADERS TRUE)
    file(GLOB STDLIB_SOURCES "${SDL3_SOURCE_DIR}/src/stdlib/*.c")
    set_property(SOURCE ${STDLIB_SOURCES} APPEND PROPERTY COMPILE_DEFINITIONS "SDL_DISABLE_ANALYZE_MACROS")
  else()
    set(HAVE_CLANG_TIDY OFF)
  endif()
endif()

if(SDL_TESTS)
  set(HAVE_TESTS ON)
endif()

if(CMAKE_SIZEOF_VOID_P EQUAL 8)
  set(ARCH_64 TRUE)
else()
  set(ARCH_64 FALSE)
endif()

if(APPLE)
  cmake_push_check_state(RESET)
  check_c_compiler_flag(-fobjc-arc COMPILER_SUPPORTS_FOBJC_ARC)
  cmake_pop_check_state()
  if(NOT COMPILER_SUPPORTS_FOBJC_ARC)
    message(FATAL_ERROR "Compiler does not support -fobjc-arc: this is required on Apple platforms")
  endif()
  sdl_compile_options(PRIVATE "-fobjc-arc")
endif()

if(PS2)
  sdl_compile_options(PRIVATE "-Wno-error=declaration-after-statement")
endif()

if(NOT SDL_LIBC)
  if(MSVC)
    set(saved_CMAKE_TRY_COMPILE_TARGET_TYPE "${CMAKE_TRY_COMPILE_TARGET_TYPE}")
    cmake_push_check_state(RESET)
    set(CMAKE_TRY_COMPILE_TARGET_TYPE "STATIC_LIBRARY")
    check_c_compiler_flag("/Zl" COMPILER_SUPPORTS_Zl)
    cmake_pop_check_state()
    set(CMAKE_TRY_COMPILE_TARGET_TYPE "${saved_CMAKE_TRY_COMPILE_TARGET_TYPE}")
    if(COMPILER_SUPPORTS_Zl)
      # /Zl omits the default C runtime library name from the .obj file.
      sdl_compile_options(PRIVATE "$<$<OR:$<COMPILE_LANGUAGE:C>,$<COMPILE_LANGUAGE:CXX>>:/Zl>")
      if(TARGET SDL3_test)
        target_compile_options(SDL3_test PRIVATE "/Zl")
      endif()
    endif()
  endif()
endif()

if(APPLE)
  get_property(sources TARGET SDL3-collector PROPERTY INTERFACE_SOURCES)
  foreach(SOURCE_FILE IN LISTS sources)
    get_filename_component(FILE_EXTENSION ${SOURCE_FILE} EXT)
    if(FILE_EXTENSION STREQUAL ".m")
      set_property(SOURCE ${SOURCE_FILE} APPEND_STRING PROPERTY COMPILE_FLAGS " -x objective-c")
    endif()
    if(NOT FILE_EXTENSION STREQUAL ".c" AND NOT FILE_EXTENSION STREQUAL ".cpp")
      set_property(SOURCE ${SOURCE_FILE} PROPERTY SKIP_PRECOMPILE_HEADERS 1)
    endif()
  endforeach()
endif()

# Disable precompiled headers on SDL_dynapi.c to avoid applying dynapi overrides
set_source_files_properties(src/dynapi/SDL_dynapi.c PROPERTIES SKIP_PRECOMPILE_HEADERS 1)

set(SDL_FRAMEWORK_RESOURCES
  Xcode/SDL/pkg-support/resources/ReadMe.txt
  LICENSE.txt
)
if(SDL_FRAMEWORK)
  sdl_sources(${SDL_FRAMEWORK_RESOURCES})
endif()

add_library(SDL3_Headers INTERFACE)
add_library(SDL3::Headers ALIAS SDL3_Headers)
set_property(TARGET SDL3_Headers PROPERTY EXPORT_NAME "Headers")
target_include_directories(SDL3_Headers
  INTERFACE
    "$<BUILD_INTERFACE:${SDL3_BINARY_DIR}/include>"
    "$<BUILD_INTERFACE:${SDL3_SOURCE_DIR}/include>"
    "$<BUILD_INTERFACE:${SDL3_SOURCE_DIR}/include/SDL3>"
)
if(SDL_FRAMEWORK)
  target_include_directories(SDL3_Headers
    INTERFACE
      "$<INSTALL_INTERFACE:$<INSTALL_PREFIX>/SDL3.framework/Headers>"
  )
  # Add `-F <parent folder of SDL3.framework>` to make sure `#include "SDL3/..."` works.
  target_compile_options(SDL3_Headers
    INTERFACE
      "$<INSTALL_INTERFACE:SHELL:-F $<INSTALL_PREFIX>>"
  )
else()
  target_include_directories(SDL3_Headers
    INTERFACE
      "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>"
      "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/SDL3>"
  )
endif()

if(SDL_SHARED)
  set_target_properties(SDL3-shared PROPERTIES
    OUTPUT_NAME "SDL3"
    POSITION_INDEPENDENT_CODE TRUE
    LINK_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/src/dynapi/SDL_dynapi.sym"
    INTERFACE_LINK_DEPENDS "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src/dynapi/SDL_dynapi.sym>"
    WINDOWS_EXPORT_ALL_SYMBOLS FALSE
    DEFINE_SYMBOL "DLL_EXPORT"
  )
  if(HAVE_GCC_FVISIBILITY)
    set_target_properties(SDL3-shared PROPERTIES
      C_VISIBILITY_PRESET "hidden"
      CXX_VISIBILITY_PRESET "hidden"
      OBJC_VISIBILITY_PRESET "hidden"
    )
  endif()
  if(NOT SDL_LIBC)
    if(MSVC AND (NOT MSVC_CLANG AND NOT WINDOWS_STORE))
      # Don't try to link with the default set of libraries.
      # Note: The clang toolset for Visual Studio does not support /NODEFAULTLIB.
      target_link_options(SDL3-shared PRIVATE "/NODEFAULTLIB")
      if(SDL_CPU_ARM32)
        # linking to msvcrt.lib avoid unresolved external symbols
        # (__rt_sdiv, __rt_udiv, __rt_sdiv64, _rt_udiv64, __dtou64, __u64tod, __i64tos)
        target_link_libraries(SDL3-shared PRIVATE msvcrt.lib)
      endif()
    endif()
    if(HAS_Q_NO_USE_LIBIRC)
      target_compile_options(SDL3-shared PRIVATE /Q_no-use-libirc)
    endif()
  endif()
  if(APPLE)
    # 3.17 is required for MACHO_COMPATIBILITY_VERSION and MACHO_CURRENT_VERSION
    cmake_minimum_required(VERSION 3.17)
  endif()
  set_target_properties(SDL3-shared PROPERTIES
    MACOSX_RPATH TRUE
    FRAMEWORK "${SDL_FRAMEWORK}"
    VERSION "${SDL_SO_VERSION}"
    SOVERSION "${SDL_SO_VERSION_MAJOR}"
    MACHO_COMPATIBILITY_VERSION "${SDL_DYLIB_COMPAT_VERSION}"
    MACHO_CURRENT_VERSION "${SDL_DYLIB_CURRENT_VERSION}"
  )
  if(SDL_FRAMEWORK)
    set_target_properties(SDL3-shared PROPERTIES
      PUBLIC_HEADER "${SDL3_INCLUDE_FILES}"
      FRAMEWORK_VERSION "${SDL_FRAMEWORK_VERSION}"
      MACOSX_FRAMEWORK_IDENTIFIER "org.libsdl.SDL3"
      RESOURCE "${SDL_FRAMEWORK_RESOURCES}"
    )
  endif()
  target_link_libraries(SDL3-shared PRIVATE ${SDL_CMAKE_DEPENDS})
  target_include_directories(SDL3-shared
    PRIVATE
      "$<BUILD_INTERFACE:${SDL3_BINARY_DIR}/include-config-$<LOWER_CASE:$<CONFIG>>>"
      "$<BUILD_INTERFACE:${SDL3_SOURCE_DIR}/src>"
  )
  target_link_libraries(SDL3-shared PUBLIC $<TARGET_NAME:SDL3::Headers>)
  if(MINGW OR CYGWIN)
    target_link_options(SDL3-shared PRIVATE -static-libgcc)
  endif()
  # Use `Compatible Interface Properties` to:
  # - allow consumers to enforce a shared/static library
  # - block linking to SDL libraries of different major version
  set_property(TARGET SDL3-shared APPEND PROPERTY COMPATIBLE_INTERFACE_BOOL SDL3_SHARED)
  set_property(TARGET SDL3-shared PROPERTY INTERFACE_SDL3_SHARED TRUE)
  set_property(TARGET SDL3-shared APPEND PROPERTY COMPATIBLE_INTERFACE_STRING "SDL_VERSION")
  set_property(TARGET SDL3-shared PROPERTY INTERFACE_SDL_VERSION "SDL${SDL3_VERSION_MAJOR}")
  if(NOT CMAKE_VERSION VERSION_LESS "3.16")
    target_precompile_headers(SDL3-shared PRIVATE "$<$<OR:$<COMPILE_LANGUAGE:C>,$<COMPILE_LANGUAGE:CXX>>:${PROJECT_SOURCE_DIR}/src/SDL_internal.h>")
  endif()
endif()

if(SDL_STATIC)
  set_target_properties(SDL3-static PROPERTIES
    OUTPUT_NAME "${sdl_static_libname}"
    POSITION_INDEPENDENT_CODE "${SDL_STATIC_PIC}"
  )
  target_compile_definitions(SDL3-static PRIVATE SDL_STATIC_LIB)
  target_link_libraries(SDL3-static PRIVATE ${SDL_CMAKE_DEPENDS})
  target_include_directories(SDL3-static
    PRIVATE
      "$<BUILD_INTERFACE:${SDL3_BINARY_DIR}/include-config-$<LOWER_CASE:$<CONFIG>>>"
      "$<BUILD_INTERFACE:${SDL3_SOURCE_DIR}/src>"
  )
  target_link_libraries(SDL3-static PUBLIC $<TARGET_NAME:SDL3::Headers>)
  # Use `Compatible Interface Properties` to:
  # - allow consumers to enforce a shared/static library
  # - block linking to SDL libraries of different major version
  set_property(TARGET SDL3-static APPEND PROPERTY COMPATIBLE_INTERFACE_BOOL SDL3_SHARED)
  set_property(TARGET SDL3-static PROPERTY INTERFACE_SDL3_SHARED FALSE)
  set_property(TARGET SDL3-static APPEND PROPERTY COMPATIBLE_INTERFACE_STRING "SDL_VERSION")
  set_property(TARGET SDL3-static PROPERTY INTERFACE_SDL_VERSION "SDL${SDL3_VERSION_MAJOR}")
  if(NOT CMAKE_VERSION VERSION_LESS "3.16")
    target_precompile_headers(SDL3-static PRIVATE "$<$<OR:$<COMPILE_LANGUAGE:C>,$<COMPILE_LANGUAGE:CXX>>:${PROJECT_SOURCE_DIR}/src/SDL_internal.h>")
  endif()
endif()

sdl_compile_definitions(
  PRIVATE
    "SDL_BUILD_MAJOR_VERSION=${PROJECT_VERSION_MAJOR}"
    "SDL_BUILD_MINOR_VERSION=${PROJECT_VERSION_MINOR}"
    "SDL_BUILD_MICRO_VERSION=${PROJECT_VERSION_PATCH}"
)

##### Tests #####

if(SDL_TEST_LIBRARY)
  file(GLOB TEST_SOURCES "${SDL3_SOURCE_DIR}/src/test/*.c")
  target_sources(SDL3_test PRIVATE ${TEST_SOURCES})
  if(APPLE)
    set_target_properties(SDL3_test PROPERTIES
      FRAMEWORK "${SDL_FRAMEWORK}"
    )
    if(SDL_FRAMEWORK)
      set_target_properties(SDL3_test PROPERTIES
        FRAMEWORK_VERSION "${SDL_FRAMEWORK_VERSION}"
        MACOSX_FRAMEWORK_IDENTIFIER "org.libsdl.SDL3_test"
        RESOURCE "${SDL_FRAMEWORK_RESOURCES}"
      )
    endif()
  endif()
  target_link_libraries(SDL3_test PUBLIC $<TARGET_NAME:SDL3::Headers>)
  # FIXME: get rid of EXTRA_TEST_LIBS variable
  target_link_libraries(SDL3_test PRIVATE ${EXTRA_TEST_LIBS})
  set_property(TARGET SDL3_test APPEND PROPERTY COMPATIBLE_INTERFACE_STRING "SDL_VERSION")
  set_property(TARGET SDL3_test PROPERTY INTERFACE_SDL_VERSION "SDL${SDL3_VERSION_MAJOR}")
endif()

##### Configure installation folders #####

if(WINDOWS AND NOT MINGW)
  set(SDL_INSTALL_CMAKEDIR_ROOT_DEFAULT "cmake")
else()
  set(SDL_INSTALL_CMAKEDIR_ROOT_DEFAULT "${CMAKE_INSTALL_LIBDIR}/cmake")
endif()
set(SDL_INSTALL_CMAKEDIR_ROOT "${SDL_INSTALL_CMAKEDIR_ROOT_DEFAULT}" CACHE STRING "Root folder where to install SDL3Config.cmake related files (SDL3 subfolder for MSVC projects)")

if(FREEBSD)
  # FreeBSD uses ${PREFIX}/libdata/pkgconfig
  set(SDL_PKGCONFIG_INSTALLDIR "libdata/pkgconfig")
else()
  set(SDL_PKGCONFIG_INSTALLDIR "${CMAKE_INSTALL_LIBDIR}/pkgconfig")
endif()

if(WINDOWS AND NOT MINGW)
  set(SDL_INSTALL_CMAKEDIR "${SDL_INSTALL_CMAKEDIR_ROOT}")
  set(SDL_INSTALL_LICENSEDIR "licenses/SDL3")
  set(SDL_INSTALL_HEADERSDIR "${CMAKE_INSTALL_INCLUDEDIR}/SDL3")
elseif(SDL_FRAMEWORK)
  set(SDL_INSTALL_CMAKEDIR "SDL3.framework/Versions/${SDL_FRAMEWORK_VERSION}/Resources/CMake")
  set(SDL_INSTALL_LICENSEDIR "Resources")
  set(SDL_INSTALL_HEADERSDIR "Headers")
else()
  set(SDL_INSTALL_CMAKEDIR "${SDL_INSTALL_CMAKEDIR_ROOT}/SDL3")
  set(SDL_INSTALL_LICENSEDIR "${CMAKE_INSTALL_DATAROOTDIR}/licenses/${PROJECT_NAME}")
  set(SDL_INSTALL_HEADERSDIR "${CMAKE_INSTALL_INCLUDEDIR}/SDL3")
endif()

if(SDL_FRAMEWORK)
  set(SDL_SDL_INSTALL_RESOURCEDIR "SDL3.framework/Resources")
  set(SDL_SDL_INSTALL_CMAKEDIR "${SDL_SDL_INSTALL_RESOURCEDIR}/CMake")
  set(SDL_SDL_INSTALL_REAL_RESOURCEDIR "SDL3.framework/Versions/${SDL_FRAMEWORK_VERSION}/Resources")
  set(SDL_SDL_INSTALL_REAL_CMAKEDIR "${SDL_SDL_INSTALL_REAL_RESOURCEDIR}/CMake")

  set(SDL_SDLtest_INSTALL_RESOURCEDIR "SDL3_test.framework/Resources")
  set(SDL_SDLtest_INSTALL_CMAKEDIR "${SDL_SDLtest_INSTALL_RESOURCEDIR}/CMake")
  set(SDL_SDLtest_INSTALL_CMAKEFILENAME "SDL3_testConfig.cmake")
else()
  set(SDL_SDL_INSTALL_RESOURCEDIR ".")
  set(SDL_SDL_INSTALL_CMAKEDIR ${SDL_INSTALL_CMAKEDIR})
  set(SDL_SDL_INSTALL_REAL_CMAKEDIR ${SDL_INSTALL_CMAKEDIR})

  # Install SDL3*Targets.cmake files in lib/cmake/SDL3
  set(SDL_SDLstatic_INSTALL_RESOURCEDIR ".")
  set(SDL_SDLstatic_INSTALL_CMAKEDIR "${SDL_SDL_INSTALL_CMAKEDIR}")
  set(SDL_SDLstatic_INSTALL_CMAKEFILENAME "SDL3staticTargets.cmake")

  set(SDL_SDLtest_INSTALL_RESOURCEDIR ".")
  set(SDL_SDLtest_INSTALL_CMAKEDIR "${SDL_SDL_INSTALL_CMAKEDIR}")
  set(SDL_SDLtest_INSTALL_CMAKEFILENAME "SDL3testTargets.cmake")
endif()

export(TARGETS SDL3_Headers NAMESPACE "SDL3::" FILE "SDL3headersTargets.cmake")

if(SDL_SHARED)
  export(TARGETS SDL3-shared NAMESPACE "SDL3::" FILE "SDL3sharedTargets.cmake")
endif()

if(SDL_STATIC)
  export(TARGETS SDL3-static NAMESPACE "SDL3::" FILE "SDL3staticTargets.cmake")
endif()

if(SDL_TEST_LIBRARY)
  export(TARGETS SDL3_test NAMESPACE "SDL3::" FILE "SDL3testTargets.cmake")
endif()

sdl_cmake_config_find_pkg_config_commands(SDL_FIND_PKG_CONFIG_COMMANDS
  COLLECTOR SDL3-collector
  CONFIG_COMPONENT_FOUND_NAME SDL3_SDL3-static_FOUND
)
sdl_cmake_config_find_pkg_config_commands(SDL_TEST_FIND_PKG_CONFIG_COMMANDS
  COLLECTOR SDL3_test-collector
  CONFIG_COMPONENT_FOUND_NAME SDL3_SDL3_test_FOUND
)

include(CMakePackageConfigHelpers)
configure_package_config_file(cmake/SDL3Config.cmake.in SDL3Config.cmake
  NO_SET_AND_CHECK_MACRO
  PATH_VARS CMAKE_INSTALL_PREFIX
  INSTALL_DESTINATION "${SDL_SDL_INSTALL_CMAKEDIR}"
)
write_basic_package_version_file("${CMAKE_CURRENT_BINARY_DIR}/SDL3ConfigVersion.cmake"
  COMPATIBILITY AnyNewerVersion
)

sdl_cmake_config_required_modules(sdl_cmake_modules)
if(sdl_cmake_modules)
  execute_process(COMMAND ${CMAKE_COMMAND} -E copy_if_different ${sdl_cmake_modules} "${SDL3_BINARY_DIR}")
endif()

if(NOT SDL_DISABLE_INSTALL)

  ##### sdl3.pc #####
  configure_sdl3_pc()
  if(NOT SDL_FRAMEWORK)
    install(FILES ${SDL3_BINARY_DIR}/sdl3.pc DESTINATION "${SDL_PKGCONFIG_INSTALLDIR}")
  endif()

  ##### Installation targets #####()

  install(TARGETS SDL3_Headers EXPORT SDL3headersTargets)

  if(SDL_SHARED)
    install(TARGETS SDL3-shared EXPORT SDL3sharedTargets
      PUBLIC_HEADER DESTINATION "${SDL_INSTALL_HEADERSDIR}"
      ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
      LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
      RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
      FRAMEWORK DESTINATION "."
      RESOURCE DESTINATION "${SDL_SDL_INSTALL_RESOURCEDIR}"
    )
    if(MSVC)
      SDL_install_pdb(SDL3-shared "${CMAKE_INSTALL_BINDIR}")
    endif()
  endif()

  if(SDL_STATIC)
    install(TARGETS SDL3-static EXPORT SDL3staticTargets
      ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
      FRAMEWORK DESTINATION "."
      RESOURCE DESTINATION "${SDL_SDLstatic_INSTALL_RESOURCEDIR}"
    )
    if(MSVC)
      SDL_install_pdb(SDL3-static "${CMAKE_INSTALL_LIBDIR}")
    endif()
  endif()

  if(SDL_TEST_LIBRARY)
    install(TARGETS SDL3_test EXPORT SDL3testTargets
      ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
      FRAMEWORK DESTINATION "."
      RESOURCE DESTINATION "${SDL_SDLtest_INSTALL_RESOURCEDIR}"
    )
    if(MSVC)
      SDL_install_pdb(SDL3_test "${CMAKE_INSTALL_LIBDIR}")
    endif()
  endif()

  ##### Install CMake Targets #####

  install(EXPORT SDL3headersTargets
    FILE "SDL3headersTargets.cmake"
    NAMESPACE SDL3::
    DESTINATION "${SDL_SDL_INSTALL_CMAKEDIR}"
  )

  if(SDL_SHARED)
    install(EXPORT SDL3sharedTargets
      FILE "SDL3sharedTargets.cmake"
      NAMESPACE SDL3::
      DESTINATION "${SDL_SDL_INSTALL_CMAKEDIR}"
    )
  endif()

  if(SDL_STATIC)
    install(EXPORT SDL3staticTargets
      FILE "${SDL_SDLstatic_INSTALL_CMAKEFILENAME}"
      NAMESPACE SDL3::
      DESTINATION "${SDL_SDLstatic_INSTALL_CMAKEDIR}"
    )
  endif()

  if(SDL_TEST_LIBRARY)
    install(EXPORT SDL3testTargets
      FILE "${SDL_SDLtest_INSTALL_CMAKEFILENAME}"
      NAMESPACE SDL3::
      DESTINATION "${SDL_SDLtest_INSTALL_CMAKEDIR}"
    )
  endif()

  install(FILES
      ${CMAKE_CURRENT_BINARY_DIR}/SDL3Config.cmake
      ${CMAKE_CURRENT_BINARY_DIR}/SDL3ConfigVersion.cmake
      ${sdl_cmake_modules}
    DESTINATION "${SDL_SDL_INSTALL_REAL_CMAKEDIR}"
  )

  if(NOT SDL_FRAMEWORK)
    install(FILES ${SDL3_INCLUDE_FILES}
      DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/SDL3"
    )
    if(SDL_TEST_LIBRARY)
      install(FILES ${SDL3_TEST_INCLUDE_FILES}
        DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/SDL3"
      )
    endif()

    install(FILES "LICENSE.txt" DESTINATION "${SDL_INSTALL_LICENSEDIR}")
  endif()

  if(NOT SDL_DISABLE_INSTALL_CPACK)
    if(SDL_FRAMEWORK)
      set(CPACK_GENERATOR "DragNDrop")
    elseif(MSVC)
      set(CPACK_GENERATOR "ZIP")
    else()
      set(CPACK_GENERATOR "TGZ")
    endif()
    configure_file(cmake/CPackProjectConfig.cmake.in CPackProjectConfig.cmake @ONLY)
    set(CPACK_PROJECT_CONFIG_FILE "${SDL3_BINARY_DIR}/CPackProjectConfig.cmake")
    # CPACK_SOURCE_PACKAGE_FILE_NAME must end with "-src" (so we can block creating a source archive)
    set(CPACK_SOURCE_PACKAGE_FILE_NAME "SDL${PROJECT_VERSION_MAJOR}-${PROJECT_VERSION}-src")
    set(CPACK_PACKAGE_DIRECTORY "${CMAKE_BINARY_DIR}/dist")
    include(CPack)
  endif()

  if(NOT SDL_DISABLE_INSTALL_DOCS)
    SDL_generate_manpages(
      HEADERS_DIR "${PROJECT_SOURCE_DIR}/include/SDL3"
      SYMBOL "SDL_Init"
      WIKIHEADERS_PL_PATH "${CMAKE_CURRENT_SOURCE_DIR}/build-scripts/wikiheaders.pl"
      REVISION "${SDL_REVISION}"
    )
  endif()
endif()

SDL_Platform_InstallExtras()

##### Uninstall target #####

if(NOT SDL_DISABLE_UNINSTALL)
  if(NOT TARGET uninstall)
    configure_file(cmake/cmake_uninstall.cmake.in cmake_uninstall.cmake IMMEDIATE @ONLY)

    add_custom_target(uninstall
        COMMAND ${CMAKE_COMMAND} -P "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake")
  endif()
endif()

##### Tests subproject (must appear after the install/uninstall targets) #####

if(SDL_TESTS)
  set(HAVE_TESTS ON)
  enable_testing()
  add_subdirectory(test)
endif()

##### Fix Objective C builds #####
string(APPEND CMAKE_OBJC_FLAGS " ${CMAKE_C_FLAGS}")

SDL_PrintSummary()
debug_show_sdl_deps()
