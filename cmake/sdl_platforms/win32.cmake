macro(SDL_Platform_PreConfigureOptions)
  set(SDL_LIBC_DEFAULT OFF)
  set(SDL_HIDAPI_LIBUSB_AVAILABLE TRUE)
  set(SDL_SYSTEM_ICONV_DEFAULT OFF)
  if(WINDOWS_STORE)
    set(SDL_HIDAPI_LIBUSB_AVAILABLE FALSE)
  endif()
  set(SDL_SYSTEM_ICONV_DEFAULT OFF)
  set(SDL_SYSTEM_ICONV_DEFAULT OFF)
  set(SDL_OPENGL_AVAILABLE ON)
  set(SDL_OPENGLES_AVAILABLE ON)
  set(SDL_VULKAN_AVAILABLE ON)
endmacro()

macro(SDL_Platform_ExtraOptions)
endmacro()

macro(SDL_Platform_Features)
  if(TARGET SDL3-shared)
    set_property(TARGET SDL3-shared PROPERTY PREFIX "")
  endif()
  check_c_source_compiles("
    #include <windows.h>
    int main(int argc, char **argv) { return 0; }" HAVE_WIN32_CC)

  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/core/windows/*.c")

  if(WINDOWS_STORE)
    enable_language(CXX)
    sdl_glob_sources(
      "${SDL3_SOURCE_DIR}/src/core/winrt/*.c"
      "${SDL3_SOURCE_DIR}/src/core/winrt/*.cpp"
    )
  endif()

  if(TARGET SDL3-shared AND MSVC AND NOT SDL_LIBC)
    # Prevent codegen that would use the VC runtime libraries.
    target_compile_options(SDL3-shared PRIVATE $<$<COMPILE_LANGUAGE:C,CXX>:/GS-> $<$<COMPILE_LANGUAGE:C,CXX>:/Gs1048576>)
    if(SDL_CPU_X86)
      target_compile_options(SDL3-shared PRIVATE "/arch:SSE")
    endif()
  endif()

  if(WINDOWS_STORE)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/misc/winrt/*.cpp")
  else()
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/misc/windows/*.c")
  endif()
  set(HAVE_SDL_MISC TRUE)

  # Check for DirectX
  if(SDL_DIRECTX)
    cmake_push_check_state()
    if(DEFINED MSVC_VERSION AND NOT ${MSVC_VERSION} LESS 1700)
      set(USE_WINSDK_DIRECTX TRUE)
    endif()
    if(NOT MINGW AND NOT USE_WINSDK_DIRECTX)
      if("$ENV{DXSDK_DIR}" STREQUAL "")
        message(FATAL_ERROR "DIRECTX requires the \$DXSDK_DIR environment variable to be set")
      endif()
      string(APPEND CMAKE_REQUIRED_FLAGS " /I\"$ENV{DXSDK_DIR}\\Include\"")
    endif()

    check_include_file(d3d9.h HAVE_D3D_H)
    check_include_file(d3d11_1.h HAVE_D3D11_H)
    check_c_source_compiles("
      #include <winsdkver.h>
      #include <sdkddkver.h>
      #include <d3d12.h>
      ID3D12Device1 *device;
      #if WDK_NTDDI_VERSION > 0x0A000008
      int main(int argc, char **argv) { return 0; }
      #endif" HAVE_D3D12_H)
    check_include_file(ddraw.h HAVE_DDRAW_H)
    check_include_file(dsound.h HAVE_DSOUND_H)
    check_include_file(dinput.h HAVE_DINPUT_H)
    if(WINDOWS_STORE OR SDL_CPU_ARM32)
      set(HAVE_DINPUT_H 0)
    endif()
    check_include_file(dxgi.h HAVE_DXGI_H)
    cmake_pop_check_state()
    if(HAVE_D3D_H OR HAVE_D3D11_H OR HAVE_D3D12_H OR HAVE_DDRAW_H OR HAVE_DSOUND_H OR HAVE_DINPUT_H)
      set(HAVE_DIRECTX TRUE)
      if(NOT MINGW AND NOT USE_WINSDK_DIRECTX)
        if(CMAKE_SIZEOF_VOID_P EQUAL 8)
          set(PROCESSOR_ARCH "x64")
        else()
          set(PROCESSOR_ARCH "x86")
        endif()
        sdl_link_directories("$<BUILD_INTERFACE:$$ENV{DXSDK_DIR}\\lib\\${PROCESSOR_ARCH}>")
        sdl_include_directories(PRIVATE SYSTEM "$<BUILD_INTERFACE:$ENV{DXSDK_DIR}\\Include>")
      endif()
    endif()
  endif()

  if(SDL_XINPUT)
    # xinput.h may need windows.h, but does not include it itself.
    check_c_source_compiles("
      #include <windows.h>
      #include <xinput.h>
      int main(int argc, char **argv) { return 0; }" HAVE_XINPUT_H)
    check_c_source_compiles("
      #define COBJMACROS
      #include <windows.gaming.input.h>
      __x_ABI_CWindows_CGaming_CInput_CIGamepadStatics2 *s2;
      int main(int argc, char **argv) { return 0; }" HAVE_WINDOWS_GAMING_INPUT_H)
  endif()

  # headers needed elsewhere
  check_include_file(tpcshrd.h HAVE_TPCSHRD_H)
  check_include_file(roapi.h HAVE_ROAPI_H)
  check_include_file(mmdeviceapi.h HAVE_MMDEVICEAPI_H)
  check_include_file(audioclient.h HAVE_AUDIOCLIENT_H)
  check_include_file(sensorsapi.h HAVE_SENSORSAPI_H)
  check_include_file(shellscalingapi.h HAVE_SHELLSCALINGAPI_H)

  if(SDL_AUDIO)
    if(HAVE_DSOUND_H AND NOT WINDOWS_STORE)
      set(SDL_AUDIO_DRIVER_DSOUND 1)
      sdl_glob_sources("${SDL3_SOURCE_DIR}/src/audio/directsound/*.c")
      set(HAVE_SDL_AUDIO TRUE)
    endif()

    if(SDL_WASAPI AND HAVE_AUDIOCLIENT_H AND HAVE_MMDEVICEAPI_H)
      set(SDL_AUDIO_DRIVER_WASAPI 1)
      set(HAVE_WASAPI TRUE)
      sdl_glob_sources("${SDL3_SOURCE_DIR}/src/audio/wasapi/*.c")
      if(WINDOWS_STORE)
        sdl_sources("${SDL3_SOURCE_DIR}/src/audio/wasapi/SDL_wasapi_winrt.cpp")
      endif()
      set(HAVE_SDL_AUDIO TRUE)
    endif()
  endif()

  if(SDL_VIDEO)
    if(WINDOWS_STORE)
      set(SDL_VIDEO_DRIVER_WINRT 1)
      sdl_glob_sources(
        "${SDL3_SOURCE_DIR}/src/video/winrt/*.c"
        "${SDL3_SOURCE_DIR}/src/video/winrt/*.cpp"
        "${SDL3_SOURCE_DIR}/src/render/direct3d11/*.cpp"
      )
    else()
      set(SDL_VIDEO_DRIVER_WINDOWS 1)
      sdl_glob_sources("${SDL3_SOURCE_DIR}/src/video/windows/*.c")
    endif()

    if(SDL_RENDER_D3D AND HAVE_D3D_H AND NOT WINDOWS_STORE)
      set(SDL_VIDEO_RENDER_D3D 1)
      set(HAVE_RENDER_D3D TRUE)
    endif()
    if(SDL_RENDER_D3D AND HAVE_D3D11_H)
      set(SDL_VIDEO_RENDER_D3D11 1)
      set(HAVE_RENDER_D3D TRUE)
    endif()
    if(SDL_RENDER_D3D AND HAVE_D3D12_H AND NOT WINDOWS_STORE)
      set(SDL_VIDEO_RENDER_D3D12 1)
      set(HAVE_RENDER_D3D TRUE)
    endif()
    set(HAVE_SDL_VIDEO TRUE)
  endif()

  set(SDL_THREAD_GENERIC_COND_SUFFIX 1)
  set(SDL_THREAD_GENERIC_RWLOCK_SUFFIX 1)
  set(SDL_THREAD_WINDOWS 1)
  sdl_sources(
    "${SDL3_SOURCE_DIR}/src/thread/generic/SDL_syscond.c"
    "${SDL3_SOURCE_DIR}/src/thread/generic/SDL_sysrwlock.c"
    "${SDL3_SOURCE_DIR}/src/thread/windows/SDL_syscond_cv.c"
    "${SDL3_SOURCE_DIR}/src/thread/windows/SDL_sysmutex.c"
    "${SDL3_SOURCE_DIR}/src/thread/windows/SDL_sysrwlock_srw.c"
    "${SDL3_SOURCE_DIR}/src/thread/windows/SDL_syssem.c"
    "${SDL3_SOURCE_DIR}/src/thread/windows/SDL_systhread.c"
    "${SDL3_SOURCE_DIR}/src/thread/windows/SDL_systls.c"
  )
  set(HAVE_SDL_THREADS TRUE)

  if(SDL_SENSOR AND HAVE_SENSORSAPI_H AND NOT WINDOWS_STORE)
    set(SDL_SENSOR_WINDOWS 1)
    set(HAVE_SDL_SENSORS TRUE)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/sensor/windows/*.c")
  endif()

  if(SDL_POWER)
    if(WINDOWS_STORE)
      set(SDL_POWER_WINRT 1)
      sdl_sources("${SDL3_SOURCE_DIR}/src/power/winrt/SDL_syspower.cpp")
    else()
      set(SDL_POWER_WINDOWS 1)
      sdl_sources("${SDL3_SOURCE_DIR}/src/power/windows/SDL_syspower.c")
      set(HAVE_SDL_POWER TRUE)
    endif()
  endif()

  if(WINDOWS_STORE)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/locale/winrt/*.c")
  else()
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/locale/windows/*.c")
  endif()
  set(HAVE_SDL_LOCALE TRUE)

  set(SDL_FILESYSTEM_WINDOWS 1)
  if(WINDOWS_STORE)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/filesystem/winrt/*.cpp")
    sdl_sources("${SDL3_SOURCE_DIR}/src/filesystem/windows/SDL_sysfsops.c")
  else()
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/filesystem/windows/*.c")
  endif()
  set(HAVE_SDL_FILESYSTEM TRUE)

  set(SDL_FSOPS_WINDOWS 1)
  set(HAVE_SDL_FSOPS TRUE)

  set(SDL_STORAGE_GENERIC 1)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/storage/generic/*.c")
  if(NOT WINDOWS_STORE)
    set(SDL_STORAGE_STEAM 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/storage/steam/*.c")
  endif()
  set(HAVE_SDL_STORAGE 1)

  # Libraries for Win32 native and MinGW
  if(NOT WINDOWS_STORE)
    sdl_link_dependency(base LIBS kernel32 user32 gdi32 winmm imm32 ole32 oleaut32 version uuid advapi32 setupapi shell32)
  endif()

  if(WINDOWS_STORE)
    sdl_link_dependency(windows
      LIBS
        vccorlib$<$<CONFIG:Debug>:d>.lib
        msvcrt$<$<CONFIG:Debug>:d>.lib
      LINK_OPTIONS
        /nodefaultlib:vccorlib$<$<CONFIG:Debug>:d>
        /nodefaultlib:msvcrt$<$<CONFIG:Debug>:d>
    )
  endif()

  set(SDL_TIME_WINDOWS 1)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/time/windows/*.c")
  set(HAVE_SDL_TIME TRUE)

  set(SDL_TIMER_WINDOWS 1)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/timer/windows/*.c")
  set(HAVE_SDL_TIMERS TRUE)

  set(SDL_LOADSO_WINDOWS 1)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/loadso/windows/*.c")
  set(HAVE_SDL_LOADSO TRUE)

  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/core/windows/*.c")

  if(SDL_VIDEO)
    if(SDL_OPENGL AND NOT WINDOWS_STORE)
      set(SDL_VIDEO_OPENGL 1)
      set(SDL_VIDEO_OPENGL_WGL 1)
      set(SDL_VIDEO_RENDER_OGL 1)
      set(HAVE_OPENGL TRUE)
    endif()

    if(SDL_OPENGLES)
      set(SDL_VIDEO_OPENGL_EGL 1)
      set(SDL_VIDEO_OPENGL_ES2 1)
      set(SDL_VIDEO_RENDER_OGL_ES2 1)
      set(HAVE_OPENGLES TRUE)
    endif()

    if(SDL_VULKAN)
      set(SDL_VIDEO_VULKAN 1)
      set(HAVE_VULKAN TRUE)
      if(SDL_RENDER_VULKAN)
        set(SDL_VIDEO_RENDER_VULKAN 1)
        set(HAVE_RENDER_VULKAN TRUE)
      endif()
    endif()
  endif()

  if(SDL_HIDAPI)
    CheckHIDAPI()
  endif()

  if(SDL_JOYSTICK)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/joystick/windows/*.c")

    if(NOT WINDOWS_STORE)
      set(SDL_JOYSTICK_RAWINPUT 1)
    endif()
    if(HAVE_DINPUT_H)
      set(SDL_JOYSTICK_DINPUT 1)
      sdl_link_dependency(joystick LIBS dinput8)
    endif()
    if(HAVE_XINPUT_H)
      if(NOT WINDOWS_STORE)
        set(SDL_JOYSTICK_XINPUT 1)
        set(HAVE_XINPUT TRUE)
      endif()
      if(HAVE_WINDOWS_GAMING_INPUT_H)
        set(SDL_JOYSTICK_WGI 1)
      endif()
    endif()
    set(HAVE_SDL_JOYSTICK TRUE)

    if(SDL_HAPTIC)
      if(HAVE_DINPUT_H AND NOT WINDOWS_STORE)
        sdl_glob_sources("${SDL3_SOURCE_DIR}/src/haptic/windows/*.c")
        set(SDL_HAPTIC_DINPUT 1)
        set(HAVE_SDL_HAPTIC TRUE)
      endif()
    endif()
  endif()

  if(SDL_CAMERA)
    if(NOT WINDOWS_STORE)
      set(HAVE_CAMERA TRUE)
      set(SDL_CAMERA_DRIVER_MEDIAFOUNDATION 1)
      sdl_glob_sources("${SDL3_SOURCE_DIR}/src/camera/mediafoundation/*.c")
    endif()
  endif()

  sdl_glob_sources(SHARED "${SDL3_SOURCE_DIR}/src/core/windows/*.rc")
  if(MINGW OR CYGWIN)
    sdl_pc_link_options("-mwindows")
  endif()

  if(SDL_DIALOG)
    if(NOT WINDOWS_STORE)
      sdl_sources(
        "${SDL3_SOURCE_DIR}/src/dialog/SDL_dialog_utils.c"
        "${SDL3_SOURCE_DIR}/src/dialog/windows/SDL_windowsdialog.c"
      )
      set(HAVE_SDL_DIALOG TRUE)
    endif()
  endif()
endmacro()

macro(SDL_Platform_InstallExtras)
endmacro()
