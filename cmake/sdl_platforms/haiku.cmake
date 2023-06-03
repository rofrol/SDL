macro(SDL_Platform_OverrideOptionDefaults)
  set(SDL_PTHREADS_DEFAULT ON)

  set(SDL_CLOCK_GETTIME_DEFAULT ON)
endmacro()

macro(SDL_Platform_ExtraOptions)
endmacro()

macro(SDL_Platform_Checks)
  CheckDLOPEN()
  CheckO_CLOEXEC()

  if(SDL_AUDIO)
    set(SDL_AUDIO_DRIVER_HAIKU 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/audio/haiku/*.cc")
    set(HAVE_SDL_AUDIO TRUE)
  endif()

  if(SDL_JOYSTICK)
    set(SDL_JOYSTICK_HAIKU 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/joystick/haiku/*.cc")
    set(HAVE_SDL_JOYSTICK TRUE)
  endif()

  if(SDL_MISC)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/misc/haiku/*.cc")
    set(HAVE_SDL_MISC TRUE)
  endif()

  if(SDL_VIDEO)
    set(SDL_VIDEO_DRIVER_HAIKU 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/video/haiku/*.cc")
    set(HAVE_SDL_VIDEO TRUE)

    if(SDL_OPENGL)
      # TODO: Use FIND_PACKAGE(OpenGL) instead
      set(SDL_VIDEO_OPENGL 1)
      set(SDL_VIDEO_OPENGL_HAIKU 1)
      set(SDL_VIDEO_RENDER_OGL 1)
      sdl_link_dependency(opengl LIBS GL)
      set(HAVE_OPENGL TRUE)
    endif()
  endif()

  if(SDL_FILESYSTEM)
    set(SDL_FILESYSTEM_HAIKU 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/filesystem/haiku/*.cc")
    set(HAVE_SDL_FILESYSTEM TRUE)
  endif()

  if(SDL_TIMERS)
    set(SDL_TIMER_HAIKU 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/timer/haiku/*.c")
    set(HAVE_SDL_TIMERS TRUE)
  endif()

  if(SDL_POWER)
    set(SDL_POWER_HAIKU 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/power/haiku/*.c")
    set(HAVE_SDL_POWER TRUE)
  endif()

  if(SDL_LOCALE)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/locale/haiku/*.cc")
    set(HAVE_SDL_LOCALE TRUE)
  endif()

  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/core/haiku/*.cc")

  CheckPTHREAD()
  sdl_link_dependency(base LIBS root be media game device textencoding)
endmacro()
