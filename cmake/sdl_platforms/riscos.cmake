macro(SDL_Platform_PreConfigureOptions)
  set(SDL_PTHREADS_DEFAULT ON)
  set(SDL_SHARED_AVAILABLE OFF)
  set(SDL_LOADSO_DEFAULT OFF)
  set(CMAKE_DISABLE_PRECOMPILE_HEADERS ON)
  set(SDL_OPENGL_AVAILABLE ON)
  set(SDL_OPENGLES_AVAILABLE ON)
endmacro()

macro(SDL_Platform_ExtraOptions)
endmacro()

macro(SDL_Platform_Features)

  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/misc/riscos/*.c")
  set(HAVE_SDL_MISC TRUE)

  if(SDL_VIDEO)
    set(SDL_VIDEO_DRIVER_RISCOS 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/video/riscos/*.c")
    set(HAVE_SDL_VIDEO TRUE)
  endif()

  set(SDL_FILESYSTEM_RISCOS 1)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/filesystem/riscos/*.c")
  set(HAVE_SDL_FILESYSTEM TRUE)

  set(SDL_FSOPS_POSIX 1)
  sdl_sources("${SDL3_SOURCE_DIR}/src/filesystem/posix/SDL_sysfsops.c")
  set(HAVE_SDL_FSOPS TRUE)

  set(SDL_TIME_UNIX 1)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/time/unix/*.c")
  set(HAVE_SDL_TIME TRUE)

  set(SDL_TIMER_UNIX 1)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/timer/unix/*.c")
  set(HAVE_SDL_TIMERS TRUE)

  if(SDL_CLOCK_GETTIME)
    set(HAVE_CLOCK_GETTIME 1)
  endif()

  CheckPTHREAD()

  if(SDL_AUDIO)
    CheckOSS()
  endif()
endmacro()

macro(SDL_Platform_InstallExtras)
endmacro()
