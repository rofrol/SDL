macro(SDL_Platform_PreConfigureOptions)
  set(SDL_PTHREADS_DEFAULT ON)
  set(SDL_HIDAPI_LIBUSB_AVAILABLE TRUE)
  set(SDL_CLOCK_GETTIME_DEFAULT ON)
  set(SDL_OPENGL_AVAILABLE ON)
  set(SDL_OPENGLES_AVAILABLE ON)
endmacro()

macro(SDL_Platform_ExtraOptions)
endmacro()

macro(SDL_Platform_Features)

  enable_language(CXX)
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

  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/misc/haiku/*.cc")
  set(HAVE_SDL_MISC TRUE)

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

  set(SDL_FILESYSTEM_HAIKU 1)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/filesystem/haiku/*.cc")
  set(HAVE_SDL_FILESYSTEM TRUE)

  set(SDL_FSOPS_POSIX 1)
  sdl_sources("${SDL3_SOURCE_DIR}/src/filesystem/posix/SDL_sysfsops.c")
  set(HAVE_SDL_FSOPS TRUE)

  set(SDL_TIME_UNIX 1)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/time/unix/*.c")
  set(HAVE_SDL_TIME TRUE)

  set(SDL_TIMER_HAIKU 1)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/timer/haiku/*.c")
  set(HAVE_SDL_TIMERS TRUE)

  if(SDL_POWER)
    set(SDL_POWER_HAIKU 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/power/haiku/*.c")
    set(HAVE_SDL_POWER TRUE)
  endif()

  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/locale/haiku/*.cc")
  set(HAVE_SDL_LOCALE TRUE)

  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/core/haiku/*.cc")

  CheckPTHREAD()
  sdl_link_dependency(base LIBS root be media game device textencoding tracker)

  if(SDL_DIALOG)
    sdl_sources(
      "${SDL3_SOURCE_DIR}/src/dialog/SDL_dialog_utils.c"
      "${SDL3_SOURCE_DIR}/src/dialog/haiku/SDL_haikudialog.cc"
    )
    set(HAVE_SDL_DIALOG TRUE)
  endif()
endmacro()

macro(SDL_Platform_InstallExtras)
endmacro()
