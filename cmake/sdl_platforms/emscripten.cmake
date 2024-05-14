macro(SDL_Platform_PreConfigureOptions)
  # Emscripten pthreads work, but you need to have a non-pthread fallback build
  #  for systems without support. It's not currently enough to not use
  #  pthread functions in a pthread-build; it won't start up on unsupported
  #  browsers. As such, you have to explicitly enable it on Emscripten builds
  #  for the time being. This default with change to ON once this becomes
  #  commonly supported in browsers or the Emscripten teams makes a single
  #  binary work everywhere.
  set(SDL_PTHREADS_DEFAULT OFF)
  set(SDL_OPENGL_AVAILABLE ON)
  set(SDL_OPENGLES_AVAILABLE ON)

  set(SDL_HIDAPI_LIBUSB_AVAILABLE TRUE)
  set(SDL_ASSEMBLY_DEFAULT OFF)
  set(SDL_SHARED_AVAILABLE OFF)
  set(SDL_ATOMIC_DEFAULT OFF)
  set(SDL_LOADSO_DEFAULT OFF)
  set(SDL_CPUINFO_DEFAULT OFF)
endmacro()

macro(SDL_Platform_ExtraOptions)
endmacro()

macro(SDL_Platform_Features)
  # Hide noisy warnings that intend to aid mostly during initial stages of porting a new
  # project. Uncomment at will for verbose cross-compiling -I/../ path info.
  sdl_compile_options(PRIVATE "-Wno-warn-absolute-paths")

  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/main/emscripten/*.c")
  set(HAVE_SDL_MAIN_CALLBACKS TRUE)

  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/misc/emscripten/*.c")
  set(HAVE_SDL_MISC TRUE)

  if(SDL_AUDIO)
    set(SDL_AUDIO_DRIVER_EMSCRIPTEN 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/audio/emscripten/*.c")
    set(HAVE_SDL_AUDIO TRUE)
  endif()

  set(SDL_FILESYSTEM_EMSCRIPTEN 1)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/filesystem/emscripten/*.c")
  set(HAVE_SDL_FILESYSTEM TRUE)

  set(SDL_FSOPS_POSIX 1)
  sdl_sources("${SDL3_SOURCE_DIR}/src/filesystem/posix/SDL_sysfsops.c")
  set(HAVE_SDL_FSOPS TRUE)

  if(SDL_CAMERA)
    set(SDL_CAMERA_DRIVER_EMSCRIPTEN 1)
    set(HAVE_CAMERA TRUE)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/camera/emscripten/*.c")
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

  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/locale/emscripten/*.c")
  set(HAVE_SDL_LOCALE TRUE)

  set(SDL_TIME_UNIX 1)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/time/unix/*.c")
  set(HAVE_SDL_TIME TRUE)

  set(SDL_TIMER_UNIX 1)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/timer/unix/*.c")
  set(HAVE_SDL_TIMERS TRUE)

  if(SDL_CLOCK_GETTIME)
    set(HAVE_CLOCK_GETTIME 1)
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
  CheckLibUnwind()
endmacro()

macro(SDL_Platform_InstallExtras)
endmacro()
