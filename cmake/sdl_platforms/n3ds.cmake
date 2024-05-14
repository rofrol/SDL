macro(SDL_Platform_PreConfigureOptions)
  set(SDL_SHARED_AVAILABLE OFF)
  set(SDL_LOADSO_DEFAULT OFF)
  set(SDL_SHARED_AVAILABLE OFF)
  set(SDL_OPENGL_AVAILABLE ON)
  set(SDL_OPENGLES_AVAILABLE ON)
endmacro()

macro(SDL_Platform_ExtraOptions)
endmacro()

macro(SDL_Platform_Features)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/core/n3ds/*.c")

  if(SDL_AUDIO)
    set(SDL_AUDIO_DRIVER_N3DS 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/audio/n3ds/*.c")
    set(HAVE_SDL_AUDIO TRUE)
  endif()

  set(SDL_FILESYSTEM_N3DS 1)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/filesystem/n3ds/*.c")
  set(HAVE_SDL_FILESYSTEM TRUE)

  # !!! FIXME: do we need a FSops implementation for this?

  if(SDL_JOYSTICK)
    set(SDL_JOYSTICK_N3DS 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/joystick/n3ds/*.c")
    set(HAVE_SDL_JOYSTICK TRUE)
  endif()

  if(SDL_POWER)
    set(SDL_POWER_N3DS 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/power/n3ds/*.c")
    set(HAVE_SDL_POWER TRUE)
  endif()

  set(SDL_THREAD_N3DS 1)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/thread/n3ds/*.c")
  sdl_sources(
          "${SDL3_SOURCE_DIR}/src/thread/generic/SDL_systls.c"
          "${SDL3_SOURCE_DIR}/src/thread/generic/SDL_sysrwlock.c"
  )
  set(HAVE_SDL_THREADS TRUE)

  set(SDL_TIME_N3DS 1)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/time/n3ds/*.c")
  set(HAVE_SDL_TIME TRUE)

  set(SDL_TIMER_N3DS 1)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/timer/n3ds/*.c")
  set(HAVE_SDL_TIMERS TRUE)

  set(SDL_FSOPS_POSIX 1)
  sdl_sources("${SDL3_SOURCE_DIR}/src/filesystem/posix/SDL_sysfsops.c")
  set(HAVE_SDL_FSOPS TRUE)

  if(SDL_SENSOR)
    set(SDL_SENSOR_N3DS 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/sensor/n3ds/*.c")
    set(HAVE_SDL_SENSORS TRUE)
  endif()

  if(SDL_VIDEO)
    set(SDL_VIDEO_DRIVER_N3DS 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/video/n3ds/*.c")
    set(HAVE_SDL_VIDEO TRUE)
  endif()

  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/locale/n3ds/*.c")
  set(HAVE_SDL_LOCALE TRUE)

  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/file/n3ds/*.c")
endmacro()

macro(SDL_Platform_InstallExtras)
endmacro()
