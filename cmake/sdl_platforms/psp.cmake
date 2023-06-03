macro(SDL_Platform_OverrideOptionDefaults)
  set(SDL_SHARED_AVAILABLE OFF)
  set(SDL_LOADSO_DEFAULT OFF)
endmacro()

macro(SDL_Platform_ExtraOptions)
endmacro()


macro(SDL_Platform_Checks)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/core/psp/*.c")

  if(SDL_AUDIO)
    set(SDL_AUDIO_DRIVER_PSP 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/audio/psp/*.c")
    set(HAVE_SDL_AUDIO TRUE)
  endif()
  if(SDL_FILESYSTEM)
    set(SDL_FILESYSTEM_PSP 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/filesystem/psp/*.c")
    set(HAVE_SDL_FILESYSTEM TRUE)
  endif()
  if(SDL_JOYSTICK)
    set(SDL_JOYSTICK_PSP 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/joystick/psp/*.c")
    set(HAVE_SDL_JOYSTICK TRUE)
  endif()
  if(SDL_POWER)
    set(SDL_POWER_PSP 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/power/psp/*.c")
    set(HAVE_SDL_POWER TRUE)
  endif()
  if(SDL_THREADS)
    set(SDL_THREAD_PSP 1)
    sdl_glob_sources(
      "${SDL3_SOURCE_DIR}/src/thread/generic/SDL_systls.c"
      "${SDL3_SOURCE_DIR}/src/thread/generic/SDL_sysrwlock.c"
      "${SDL3_SOURCE_DIR}/src/thread/psp/*.c"
    )
    set(HAVE_SDL_THREADS TRUE)
  endif()
  if(SDL_TIMERS)
    set(SDL_TIMER_PSP 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/timer/psp/*.c")
    set(HAVE_SDL_TIMERS TRUE)
  endif()
  if(SDL_VIDEO)
    set(SDL_VIDEO_DRIVER_PSP 1)
    set(SDL_VIDEO_RENDER_PSP 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/video/psp/*.c")
    set(SDL_VIDEO_OPENGL 1)
    set(HAVE_SDL_VIDEO TRUE)
  endif()
  sdl_link_dependency(base
    LIBS
    GL
    pspvram
    pspaudio
    pspvfpu
    pspdisplay
    pspgu
    pspge
    psphprm
    pspctrl
    psppower
  )
endmacro()
