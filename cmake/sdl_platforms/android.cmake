macro(SDL_Platform_OverrideOptionDefaults)
  set(SDL_PTHREADS_DEFAULT ON)
  set(SDL_CLOCK_GETTIME_DEFAULT ON)
  set(SDL_HIDAPI_LIBUSB_AVAILABLE FALSE)
endmacro()

macro(SDL_Platform_ExtraOptions)

endmacro()

macro(SDL_Platform_Checks)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/core/android/*.c")
  sdl_sources("${ANDROID_NDK}/sources/android/cpufeatures/cpu-features.c")
  set_property(SOURCE "${ANDROID_NDK}/sources/android/cpufeatures/cpu-features.c" APPEND_STRING PROPERTY COMPILE_FLAGS " -Wno-declaration-after-statement")

  if(SDL_MISC)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/misc/android/*.c")
    set(HAVE_SDL_MISC TRUE)
  endif()

  # SDL_spinlock.c Needs to be compiled in ARM mode.
  # There seems to be no better way currently to set the ARM mode.
  # see: https://issuetracker.google.com/issues/62264618
  # Another option would be to set ARM mode to all compiled files
  cmake_push_check_state()
  string(APPEND CMAKE_REQUIRED_FLAGS " -Werror=unused-command-line-argument")
  check_c_compiler_flag(-marm HAVE_ARM_MODE)
  cmake_pop_check_state()
  if(HAVE_ARM_MODE)
    set_property(SOURCE "${SDL3_SOURCE_DIR}/src/atomic/SDL_spinlock.c" APPEND_STRING PROPERTY COMPILE_FLAGS " -marm")
    set_source_files_properties(src/atomic/SDL_spinlock.c PROPERTIES SKIP_PRECOMPILE_HEADERS 1)
  endif()

  if(SDL_AUDIO)
    set(SDL_AUDIO_DRIVER_ANDROID 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/audio/android/*.c")

    set(SDL_AUDIO_DRIVER_OPENSLES 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/audio/openslES/*.c")

    sdl_link_dependency(opensles LIBS ${ANDROID_DL_LIBRARY} OpenSLES)

    set(SDL_AUDIO_DRIVER_AAUDIO 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/audio/aaudio/*.c")

    set(HAVE_SDL_AUDIO TRUE)
  endif()
  if(SDL_FILESYSTEM)
    set(SDL_FILESYSTEM_ANDROID 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/filesystem/android/*.c")
    set(HAVE_SDL_FILESYSTEM TRUE)
  endif()
  if(SDL_HAPTIC)
    set(SDL_HAPTIC_ANDROID 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/haptic/android/*.c")
    set(HAVE_SDL_HAPTIC TRUE)
  endif()
  if(SDL_HIDAPI)
    CheckHIDAPI()
  endif()
  if(SDL_JOYSTICK)
    set(SDL_JOYSTICK_ANDROID 1)
    sdl_glob_sources(
        "${SDL3_SOURCE_DIR}/src/joystick/android/*.c"
        "${SDL3_SOURCE_DIR}/src/joystick/steam/*.c"
    )
    set(HAVE_SDL_JOYSTICK TRUE)
  endif()
  if(SDL_LOADSO)
    set(SDL_LOADSO_DLOPEN 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/loadso/dlopen/*.c")
    set(HAVE_SDL_LOADSO TRUE)
  endif()
  if(SDL_POWER)
    set(SDL_POWER_ANDROID 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/power/android/*.c")
    set(HAVE_SDL_POWER TRUE)
  endif()
  if(SDL_LOCALE)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/locale/android/*.c")
    set(HAVE_SDL_LOCALE TRUE)
  endif()
  if(SDL_TIMERS)
    set(SDL_TIMER_UNIX 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/timer/unix/*.c")
    set(HAVE_SDL_TIMERS TRUE)
  endif()
  if(SDL_SENSOR)
    set(SDL_SENSOR_ANDROID 1)
    set(HAVE_SDL_SENSORS TRUE)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/sensor/android/*.c")
  endif()
  if(SDL_VIDEO)
    set(SDL_VIDEO_DRIVER_ANDROID 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/video/android/*.c")
    set(HAVE_SDL_VIDEO TRUE)

    # Core stuff
    # find_library(ANDROID_DL_LIBRARY dl)
    # FIXME failing dlopen https://github.com/android-ndk/ndk/issues/929
    sdl_link_dependency(android_video LIBS dl log android)
    sdl_compile_definitions(PRIVATE "GL_GLEXT_PROTOTYPES")

    #enable gles
    if(SDL_OPENGLES)
      set(SDL_VIDEO_OPENGL_EGL 1)
      set(HAVE_OPENGLES TRUE)
      set(SDL_VIDEO_OPENGL_ES 1)
      set(SDL_VIDEO_OPENGL_ES2 1)
      set(SDL_VIDEO_RENDER_OGL_ES2 1)

      sdl_link_dependency(opengles LIBS GLESv1_CM GLESv2)
    endif()

    if(SDL_VULKAN)
      check_c_source_compiles("
      #if defined(__ARM_ARCH) && __ARM_ARCH < 7
      #error Vulkan doesn't work on this configuration
      #endif
      int main(int argc, char **argv) { return 0; }
      " VULKAN_PASSED_ANDROID_CHECKS)
      if(VULKAN_PASSED_ANDROID_CHECKS)
        set(SDL_VIDEO_VULKAN 1)
        set(HAVE_VULKAN TRUE)
      endif()
    endif()
  endif()

  CheckPTHREAD()
  if(SDL_CLOCK_GETTIME)
    set(HAVE_CLOCK_GETTIME 1)
  endif()

  sdl_include_directories(PRIVATE SYSTEM "${ANDROID_NDK}/sources/android/cpufeatures")
endmacro()
