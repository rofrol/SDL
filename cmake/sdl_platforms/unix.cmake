macro(SDL_Platform_OverrideOptionDefaults)
  if(APPLE)
    message(FATAL_ERROR "Use apple.cmake instead")
  endif()
  set(SDL_PTHREADS_DEFAULT ON)

  set(SDL_CLOCK_GETTIME_DEFAULT ON)
  # *BSD specifically uses libusb only, so we make a special case just for them.
  if(FREEBSD OR NETBSD OR OPENBSD OR BSDI)
    set(SDL_HIDAPI_LIBUSB_DEFAULT TRUE)
  endif()
endmacro()

macro(SDL_Platform_ExtraOptions)
endmacro()

macro(SDL_Platform_Checks)
  CheckDLOPEN()
  CheckO_CLOEXEC()

  if(SDL_AUDIO)
    if(NETBSD)
      set(SDL_AUDIO_DRIVER_NETBSD 1)
      sdl_glob_sources("${SDL3_SOURCE_DIR}/src/audio/netbsd/*.c")
      set(HAVE_SDL_AUDIO TRUE)
    elseif(QNX)
      set(SDL_AUDIO_DRIVER_QNX 1)
      sdl_glob_sources("${SDL3_SOURCE_DIR}/src/audio/qnx/*.c")
      sdl_link_dependency(asound LIBS asound)
      set(HAVE_SDL_AUDIO TRUE)
    endif()
    CheckOSS()
    CheckALSA()
    CheckJACK()
    CheckPipewire()
    CheckPulseAudio()
    CheckSNDIO()
  endif()

  if(SDL_VIDEO)
    # Need to check for Raspberry PI first and add platform specific compiler flags, otherwise the test for GLES fails!
    CheckRPI()
    # Need to check for ROCKCHIP platform and get rid of "Can't window GBM/EGL surfaces on window creation."
    CheckROCKCHIP()
    CheckX11()
    # Need to check for EGL first because KMSDRM and Wayland depend on it.
    CheckEGL()
    CheckKMSDRM()
    CheckGLX()
    CheckOpenGL()
    CheckOpenGLES()
    CheckWayland()
    CheckVivante()
    CheckVulkan()
    CheckQNXScreen()
  endif()

  if(UNIX)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/core/unix/*.c")

    if (HAVE_LINUX_INPUT_H)
      check_c_source_compiles("
          #include <linux/input.h>
          #ifndef EVIOCGNAME
          #error EVIOCGNAME() ioctl not available
          #endif
          int main(int argc, char** argv) { return 0; }" HAVE_INPUT_EVENTS)
    endif()

    if(LINUX)
      check_c_source_compiles("
          #include <linux/kd.h>
          #include <linux/keyboard.h>
          #include <sys/ioctl.h>
          int main(int argc, char **argv) {
              struct kbentry kbe;
              kbe.kb_table = KG_CTRL;
              ioctl(0, KDGKBENT, &kbe);
              return 0;
          }" HAVE_INPUT_KD)
    elseif(FREEBSD)
      check_c_source_compiles("
          #include <sys/kbio.h>
          #include <sys/ioctl.h>
          int main(int argc, char **argv) {
              accentmap_t accTable;
              ioctl(0, KDENABIO, 1);
              return 0;
          }" HAVE_INPUT_KBIO)
    elseif(OPENBSD OR NETBSD)
      check_c_source_compiles("
          #include <sys/time.h>
          #include <dev/wscons/wsconsio.h>
          #include <dev/wscons/wsksymdef.h>
          #include <dev/wscons/wsksymvar.h>
          #include <sys/ioctl.h>
          int main(int argc, char **argv) {
              struct wskbd_map_data data;
              ioctl(0, WSKBDIO_GETMAP, &data);
              return 0;
          }" HAVE_INPUT_WSCONS)
    endif()

    if(HAVE_INPUT_EVENTS)
      set(SDL_INPUT_LINUXEV 1)
    endif()

    if(SDL_HAPTIC AND HAVE_INPUT_EVENTS)
      set(SDL_HAPTIC_LINUX 1)
      sdl_glob_sources("${SDL3_SOURCE_DIR}/src/haptic/linux/*.c")
      set(HAVE_SDL_HAPTIC TRUE)
    endif()

    if(HAVE_INPUT_KD)
      set(SDL_INPUT_LINUXKD 1)
    endif()

    if(HAVE_INPUT_KBIO)
      set(SDL_INPUT_FBSDKBIO 1)
    endif()

    if(HAVE_INPUT_WSCONS)
      set(SDL_INPUT_WSCONS 1)
    endif()

    CheckLibUDev()
    check_include_file("sys/inotify.h" HAVE_SYS_INOTIFY_H)
    check_symbol_exists(inotify_init "sys/inotify.h" HAVE_INOTIFY_INIT)
    check_symbol_exists(inotify_init1 "sys/inotify.h" HAVE_INOTIFY_INIT1)

    if(HAVE_SYS_INOTIFY_H AND HAVE_INOTIFY_INIT)
      set(HAVE_INOTIFY 1)
    endif()

    if(PKG_CONFIG_FOUND)
      if(SDL_DBUS)
        pkg_search_module(DBUS dbus-1 dbus)
        if(DBUS_FOUND)
          set(HAVE_DBUS_DBUS_H TRUE)
          sdl_include_directories(PRIVATE SYSTEM ${DBUS_INCLUDE_DIRS})
          # Fcitx need only dbus.
          set(HAVE_FCITX TRUE)
          set(HAVE_DBUS TRUE)
        endif()
      endif()

      if(SDL_IBUS)
        pkg_search_module(IBUS ibus-1.0 ibus)
        find_path(HAVE_SYS_INOTIFY_H NAMES sys/inotify.h)
        if(IBUS_FOUND AND HAVE_SYS_INOTIFY_H)
          set(HAVE_IBUS_IBUS_H TRUE)
          sdl_include_directories(PRIVATE SYSTEM ${IBUS_INCLUDE_DIRS})
          set(HAVE_IBUS TRUE)
        endif()
      endif()

      if (HAVE_IBUS_IBUS_H OR HAVE_FCITX)
        set(SDL_USE_IME 1)
      endif()

      if(FREEBSD AND NOT HAVE_INOTIFY)
        find_package(LibInotify MODULE)
        if(LibInotify_FOUND)
          set(HAVE_INOTIFY 1)
          sdl_link_dependency(libinotify LIBS LibInotify::LibInotify CMAKE_MODULE LibInotify PKG_CONFIG_SPECS ${LibInotify_PKG_CONFIG_SPEC})
        endif()
      endif()

      if(HAVE_LIBUNWIND_H)
        # We've already found the header, so link the lib if present.
        # NB: This .pc file is not present on FreeBSD where the implicitly
        # linked base system libgcc_s includes all libunwind ABI.
        pkg_search_module(PKG_UNWIND libunwind)
        pkg_search_module(PKG_UNWIND_GENERIC libunwind-generic)
        list(APPEND EXTRA_TEST_LIBS ${PKG_UNWIND_LIBRARIES} ${PKG_UNWIND_GENERIC_LIBRARIES})
      endif()
    endif()

    if(HAVE_DBUS_DBUS_H)
      sdl_sources(
          "${SDL3_SOURCE_DIR}/src/core/linux/SDL_dbus.c"
          "${SDL3_SOURCE_DIR}/src/core/linux/SDL_system_theme.c"
      )
    endif()

    if(SDL_USE_IME)
      sdl_sources("${SDL3_SOURCE_DIR}/src/core/linux/SDL_ime.c")
    endif()

    if(HAVE_IBUS_IBUS_H)
      sdl_sources("${SDL3_SOURCE_DIR}/src/core/linux/SDL_ibus.c")
    endif()

    if(HAVE_FCITX)
      sdl_sources("${SDL3_SOURCE_DIR}/src/core/linux/SDL_fcitx.c")
    endif()

    if(HAVE_LIBUDEV_H)
      sdl_sources("${SDL3_SOURCE_DIR}/src/core/linux/SDL_udev.c")
    endif()

    if(HAVE_INPUT_EVENTS)
      sdl_sources(
          "${SDL3_SOURCE_DIR}/src/core/linux/SDL_evdev.c"
          "${SDL3_SOURCE_DIR}/src/core/linux/SDL_evdev_kbd.c"
      )
    endif()

    if(HAVE_INPUT_KBIO)
      sdl_sources("${SDL3_SOURCE_DIR}/src/core/freebsd/SDL_evdev_kbd_freebsd.c")
    endif()

    # Always compiled for Linux, unconditionally:
    sdl_sources(
        "${SDL3_SOURCE_DIR}/src/core/linux/SDL_evdev_capabilities.c"
        "${SDL3_SOURCE_DIR}/src/core/linux/SDL_threadprio.c"
        "${SDL3_SOURCE_DIR}/src/core/linux/SDL_sandbox.c"
    )

    # src/core/unix/*.c is included in a generic if(UNIX) section, elsewhere.
  endif()

  if(SDL_HIDAPI)
    CheckHIDAPI()
  endif()

  if(SDL_JOYSTICK)
    if(FREEBSD OR NETBSD OR OPENBSD OR BSDI)
      CheckUSBHID()
    endif()
    if(LINUX AND HAVE_LINUX_INPUT_H AND NOT ANDROID)
      set(SDL_JOYSTICK_LINUX 1)
      sdl_glob_sources(
          "${SDL3_SOURCE_DIR}/src/joystick/linux/*.c"
          "${SDL3_SOURCE_DIR}/src/joystick/steam/*.c"
      )
      set(HAVE_SDL_JOYSTICK TRUE)
    endif()
  endif()

  CheckPTHREAD()

  if(SDL_CLOCK_GETTIME)
    check_library_exists(c clock_gettime "" FOUND_CLOCK_GETTIME_LIBC)
    if(FOUND_CLOCK_GETTIME_LIBC)
      set(HAVE_CLOCK_GETTIME 1)
    else()
      check_library_exists(rt clock_gettime "" FOUND_CLOCK_GETTIME_LIBRT)
      if(FOUND_CLOCK_GETTIME_LIBRT)
        set(HAVE_CLOCK_GETTIME 1)
        sdl_link_dependency(clock LIBS rt)
      endif()
    endif()
  endif()

  if(SDL_MISC)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/misc/unix/*.c")
    set(HAVE_SDL_MISC TRUE)
  endif()

  if(SDL_POWER)
    if(LINUX)
      set(SDL_POWER_LINUX 1)
      sdl_glob_sources("${SDL3_SOURCE_DIR}/src/power/linux/*.c")
      set(HAVE_SDL_POWER TRUE)
    endif()
  endif()

  if(SDL_LOCALE)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/locale/unix/*.c")
    set(HAVE_SDL_LOCALE TRUE)
  endif()

  if(SDL_FILESYSTEM)
    set(SDL_FILESYSTEM_UNIX 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/filesystem/unix/*.c")
    set(HAVE_SDL_FILESYSTEM TRUE)
  endif()

  if(SDL_TIMERS)
    set(SDL_TIMER_UNIX 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/timer/unix/*.c")
    set(HAVE_SDL_TIMERS TRUE)
  endif()

  set(SDL_RLD_FLAGS "")
  if(SDL_RPATH AND SDL_SHARED)
    if(BSDI OR FREEBSD OR LINUX OR NETBSD)
      cmake_push_check_state()
      string(APPEND CMAKE_REQUIRED_FLAGS " -Wl,--enable-new-dtags")
      check_c_compiler_flag("" HAVE_ENABLE_NEW_DTAGS)
      cmake_pop_check_state()
      if(HAVE_ENABLE_NEW_DTAGS)
        set(SDL_RLD_FLAGS "-Wl,-rpath,\${libdir} -Wl,--enable-new-dtags")
      else()
        set(SDL_RLD_FLAGS "-Wl,-rpath,\${libdir}")
      endif()
    elseif(SOLARIS)
      set(SDL_RLD_FLAGS "-R\${libdir}")
    endif()
    set(HAVE_RPATH TRUE)
  endif()

  if(QNX)
    # QNX's *printf() family generates a SIGSEGV if NULL is passed for a string
    # specifier (on purpose), but SDL expects "(null)". Use the built-in
    # implementation.
    set (HAVE_VSNPRINTF 0)
    set (USE_POSIX_SPAWN 1)
  endif()
endmacro()
