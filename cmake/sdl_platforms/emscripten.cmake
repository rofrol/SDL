macro(SDL_Platform_OverrideOptionDefaults)
  # Emscripten pthreads work, but you need to have a non-pthread fallback build
  #  for systems without support. It's not currently enough to not use
  #  pthread functions in a pthread-build; it won't start up on unsupported
  #  browsers. As such, you have to explicitly enable it on Emscripten builds
  #  for the time being. This default with change to ON once this becomes
  #  commonly supported in browsers or the Emscripten teams makes a single
  #  binary work everywhere.
  set(SDL_PTHREADS_DEFAULT OFF)

  # Set up default values for the currently supported set of subsystems:
  # Emscripten/Javascript does not have assembly support, a dynamic library
  # loading architecture, or low-level CPU inspection.

  # SDL_THREADS_DEFAULT now defaults to ON, but pthread support might be disabled by default.
  # !!! FIXME: most of these subsystems should default to ON if there are dummy implementations to be used.

  set(SDL_ASSEMBLY_DEFAULT OFF)
  set(SDL_SHARED_AVAILABLE OFF)
  set(SDL_ATOMIC_DEFAULT OFF)
  set(SDL_LOADSO_DEFAULT OFF)
  set(SDL_CPUINFO_DEFAULT OFF)
endmacro()

macro(SDL_Platform_ExtraOptions)
endmacro()

macro(SDL_Platform_Checks)
  # Hide noisy warnings that intend to aid mostly during initial stages of porting a new
  # project. Uncomment at will for verbose cross-compiling -I/../ path info.
  sdl_compile_options(PRIVATE "-Wno-warn-absolute-paths")

  if(SDL_MISC)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/misc/emscripten/*.c")
    set(HAVE_SDL_MISC TRUE)
  endif()
  if(SDL_AUDIO)
    set(SDL_AUDIO_DRIVER_EMSCRIPTEN 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/audio/emscripten/*.c")
    set(HAVE_SDL_AUDIO TRUE)
  endif()
  if(SDL_FILESYSTEM)
    set(SDL_FILESYSTEM_EMSCRIPTEN 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/filesystem/emscripten/*.c")
    set(HAVE_SDL_FILESYSTEM TRUE)
  endif()
  if(SDL_JOYSTICK)
    set(SDL_JOYSTICK_EMSCRIPTEN 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/joystick/emscripten/*.c")
    set(HAVE_SDL_JOYSTICK TRUE)
  endif()
  if(SDL_POWER)
    set(SDL_POWER_EMSCRIPTEN 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/power/emscripten/*.c")
    set(HAVE_SDL_POWER TRUE)
  endif()
  if(SDL_LOCALE)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/locale/emscripten/*.c")
    set(HAVE_SDL_LOCALE TRUE)
  endif()
  if(SDL_TIMERS)
    set(SDL_TIMER_UNIX 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/timer/unix/*.c")
    set(HAVE_SDL_TIMERS TRUE)

    if(SDL_CLOCK_GETTIME)
      set(HAVE_CLOCK_GETTIME 1)
    endif()
  endif()
  if(SDL_VIDEO)
    set(SDL_VIDEO_DRIVER_EMSCRIPTEN 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/video/emscripten/*.c")
    set(HAVE_SDL_VIDEO TRUE)

    #enable gles
    if(SDL_OPENGLES)
      set(SDL_VIDEO_OPENGL_EGL 1)
      set(HAVE_OPENGLES TRUE)
      set(SDL_VIDEO_OPENGL_ES2 1)
      set(SDL_VIDEO_RENDER_OGL_ES2 1)
    endif()
  endif()

  CheckPTHREAD()

  if(HAVE_LIBUNWIND_H)
    list(APPEND EXTRA_TEST_LIBS unwind)
  endif()
endmacro()
