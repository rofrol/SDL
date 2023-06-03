macro(SDL_Platform_OverrideOptionDefaults)
  set(SDL_SHARED_AVAILABLE OFF)
  set(SDL_LOADSO_DEFAULT OFF)
endmacro()

macro(SDL_Platform_ExtraOptions)
endmacro()

macro(SDL_Platform_Checks)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/core/n3ds/*.c")

  if(SDL_AUDIO)
    set(SDL_AUDIO_DRIVER_N3DS 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/audio/n3ds/*.c")
    set(HAVE_SDL_AUDIO TRUE)
  endif()

  if(SDL_FILESYSTEM)
    set(SDL_FILESYSTEM_N3DS 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/filesystem/n3ds/*.c")
    set(HAVE_SDL_FILESYSTEM TRUE)
  endif()

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

  if(SDL_THREADS)
    set(SDL_THREAD_N3DS 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/thread/n3ds/*.c")
    sdl_sources(
      "${SDL3_SOURCE_DIR}/src/thread/generic/SDL_systls.c"
      "${SDL3_SOURCE_DIR}/src/thread/generic/SDL_sysrwlock.c"
    )
    set(HAVE_SDL_THREADS TRUE)
  endif()

  if(SDL_TIMERS)
    set(SDL_TIMER_N3DS 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/timer/n3ds/*.c")
    set(HAVE_SDL_TIMERS TRUE)
  endif()

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

  if(SDL_LOCALE)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/locale/n3ds/*.c")
    set(HAVE_SDL_LOCALE TRUE)
  endif()

  # Requires the n3ds file implementation
  if(SDL_FILE)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/file/n3ds/*.c")
    set(HAVE_SDL_FILE TRUE)
  else()
    message(FATAL_ERROR "SDL_FILE must be enabled to build on N3DS")
  endif()
endmacro()
