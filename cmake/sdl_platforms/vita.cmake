macro(SDL_Platform_PreConfigureOptions)
  set(SDL_SHARED_AVAILABLE OFF)
  set(SDL_LOADSO_DEFAULT OFF)
  set(SDL_SHARED_AVAILABLE OFF)
  set(SDL_OPENGL_AVAILABLE ON)
  set(SDL_OPENGLES_AVAILABLE ON)
endmacro()

macro(SDL_Platform_ExtraOptions)
  set_option(VIDEO_VITA_PIB  "Build with PSVita piglet gles2 support" OFF)
  set_option(VIDEO_VITA_PVR  "Build with PSVita PVR gles/gles2 support" OFF)
endmacro()

macro(SDL_Platform_Features)
  # SDL_spinlock.c Needs to be compiled in ARM mode.
  cmake_push_check_state()
  string(APPEND CMAKE_REQUIRED_FLAGS " -Werror=unused-command-line-argument")
  check_c_compiler_flag(-marm HAVE_ARM_MODE)
  cmake_pop_check_state()
  if(HAVE_ARM_MODE)
    set_property(SOURCE "${SDL3_SOURCE_DIR}/src/atomic/SDL_spinlock.c" APPEND_STRING PROPERTY COMPILE_FLAGS " -marm")
  endif()

  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/misc/vita/*.c")
  set(HAVE_SDL_MISC TRUE)

  if(SDL_AUDIO)
    set(SDL_AUDIO_DRIVER_VITA 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/audio/vita/*.c")
    set(HAVE_SDL_AUDIO TRUE)
  endif()

  set(SDL_FILESYSTEM_VITA 1)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/filesystem/vita/*.c")
  set(HAVE_SDL_FILESYSTEM TRUE)

  # !!! FIXME: do we need a FSops implementation for this?

  if(SDL_JOYSTICK)
    set(SDL_JOYSTICK_VITA 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/joystick/vita/*.c")
    set(HAVE_SDL_JOYSTICK TRUE)
  endif()

  if(SDL_POWER)
    set(SDL_POWER_VITA 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/power/vita/*.c")
    set(HAVE_SDL_POWER TRUE)
  endif()

  set(SDL_THREAD_VITA 1)
  sdl_sources(
    "${SDL3_SOURCE_DIR}/src/thread/vita/SDL_sysmutex.c"
    "${SDL3_SOURCE_DIR}/src/thread/vita/SDL_syssem.c"
    "${SDL3_SOURCE_DIR}/src/thread/vita/SDL_systhread.c"
    "${SDL3_SOURCE_DIR}/src/thread/generic/SDL_syscond.c"
    "${SDL3_SOURCE_DIR}/src/thread/generic/SDL_sysrwlock.c"
    "${SDL3_SOURCE_DIR}/src/thread/generic/SDL_systls.c"
  )
  set(HAVE_SDL_THREADS TRUE)

  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/locale/vita/*.c")
  set(HAVE_SDL_LOCALE TRUE)

  set(SDL_TIME_VITA 1)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/time/vita/*.c")
  set(HAVE_SDL_TIME TRUE)

  set(SDL_TIMER_VITA 1)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/timer/vita/*.c")
  set(HAVE_SDL_TIMERS TRUE)

  if(SDL_SENSOR)
    set(SDL_SENSOR_VITA 1)
    set(HAVE_SDL_SENSORS TRUE)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/sensor/vita/*.c")
  endif()

  if(SDL_VIDEO)
    set(SDL_VIDEO_DRIVER_VITA 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/video/vita/*.c")
    set(HAVE_SDL_VIDEO TRUE)

    if(VIDEO_VITA_PIB)
      check_include_file(pib.h HAVE_PIGS_IN_BLANKET_H)

      if(HAVE_PIGS_IN_BLANKET_H)
        set(SDL_VIDEO_OPENGL_ES2 1)
        sdl_link_dependency(pib
          LIBS
            pib
            libScePiglet_stub_weak
            taihen_stub_weak
            SceShaccCg_stub_weak
        )
        set(HAVE_VIDEO_VITA_PIB ON)
        set(SDL_VIDEO_VITA_PIB 1)
      else()
        set(HAVE_VIDEO_VITA_PIB OFF)
      endif()
    endif()

    if(VIDEO_VITA_PVR)
      check_include_file(gpu_es4/psp2_pvr_hint.h HAVE_PVR_H)
      if(HAVE_PVR_H)
        sdl_compile_definitions(PRIVATE "__psp2__")
        set(SDL_VIDEO_OPENGL_EGL 1)
        set(HAVE_OPENGLES TRUE)
        set(SDL_VIDEO_OPENGL_ES 1)
        set(SDL_VIDEO_OPENGL_ES2 1)
        set(SDL_VIDEO_RENDER_OGL_ES2 1)

        sdl_link_dependency(pvr
          LIBS
            libgpu_es4_ext_stub_weak
            libIMGEGL_stub_weak
            SceIme_stub
        )

        set(HAVE_VIDEO_VITA_PVR ON)
        set(SDL_VIDEO_VITA_PVR 1)

        if(SDL_OPENGL)
          check_include_file(gl4esinit.h HAVE_GL4ES_H)
          if(HAVE_GL4ES_H)
            set(HAVE_OPENGL TRUE)
            set(SDL_VIDEO_OPENGL 1)
            set(SDL_VIDEO_RENDER_OGL 1)
            sdl_link_dependency(opengl LIBS libGL_stub)
            set(SDL_VIDEO_VITA_PVR_OGL 1)
          endif()
        endif()

      else()
        set(HAVE_VIDEO_VITA_PVR OFF)
      endif()
    endif()

    set(SDL_VIDEO_RENDER_VITA_GXM 1)
    sdl_link_dependency(base
      LIBS
        SceGxm_stub
        SceDisplay_stub
        SceCtrl_stub
        SceAppMgr_stub
        SceAppUtil_stub
        SceAudio_stub
        SceAudioIn_stub
        SceSysmodule_stub
        SceDisplay_stub
        SceCtrl_stub
        SceIofilemgr_stub
        SceCommonDialog_stub
        SceTouch_stub
        SceHid_stub
        SceMotion_stub
        ScePower_stub
        SceProcessmgr_stub
    )
  endif()

  sdl_compile_definitions(PRIVATE "__VITA__")
endmacro()

macro(SDL_Platform_InstallExtras)
endmacro()
