macro(SDL_Platform_OverrideOptionDefaults)
  set(SDL_PTHREADS_DEFAULT ON)
  set(SDL_SHARED_AVAILABLE OFF)
  set(SDL_LOADSO_DEFAULT OFF)
  set(CMAKE_DISABLE_PRECOMPILE_HEADERS ON)
endmacro()

macro(SDL_Platform_ExtraOptions)
endmacro()

macro(SDL_Platform_Checks)
  CheckO_CLOEXEC()

  if(SDL_MISC)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/misc/riscos/*.c")
    set(HAVE_SDL_MISC TRUE)
  endif()

  if(SDL_VIDEO)
    set(SDL_VIDEO_DRIVER_RISCOS 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/video/riscos/*.c")
    set(HAVE_SDL_VIDEO TRUE)
  endif()

  if(SDL_FILESYSTEM)
    set(SDL_FILESYSTEM_RISCOS 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/filesystem/riscos/*.c")
    set(HAVE_SDL_FILESYSTEM TRUE)
  endif()

  if(SDL_TIMERS)
    set(SDL_TIMER_UNIX 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/timer/unix/*.c")
    set(HAVE_SDL_TIMERS TRUE)

    if(SDL_CLOCK_GETTIME)
      set(HAVE_CLOCK_GETTIME 1)
    endif()
  endif()

  CheckPTHREAD()

  if(SDL_AUDIO)
    CheckOSS()
  endif()
endmacro()
