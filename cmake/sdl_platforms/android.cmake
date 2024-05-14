macro(SDL_Platform_PreConfigureOptions)
  set(SDL_PTHREADS_DEFAULT ON)
  set(SDL_CLOCK_GETTIME_DEFAULT ON)
  set(SDL_OPENGL_AVAILABLE ON)
  set(SDL_OPENGLES_AVAILABLE ON)
  set(SDL_VULKAN_AVAILABLE ON)
endmacro()

macro(SDL_Platform_ExtraOptions)
  cmake_dependent_option(SDL_DISABLE_ANDROID_JAR  "Disable creation of SDL3.jar" ${SDL3_SUBPROJECT} "ANDROID" ON)
endmacro()

macro(SDL_Platform_Features)
  list(APPEND CMAKE_MODULE_PATH "${SDL3_SOURCE_DIR}/cmake/android")

  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/core/android/*.c")
  sdl_sources("${ANDROID_NDK}/sources/android/cpufeatures/cpu-features.c")
  set_property(SOURCE "${ANDROID_NDK}/sources/android/cpufeatures/cpu-features.c" APPEND_STRING PROPERTY COMPILE_FLAGS " -Wno-declaration-after-statement")

  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/misc/android/*.c")
  set(HAVE_SDL_MISC TRUE)

  # SDL_spinlock.c Needs to be compiled in ARM mode.
  # There seems to be no better way currently to set the ARM mode.
  # see: https://issuetracker.google.com/issues/62264618
  # Another option would be to set ARM mode to all compiled files
  cmake_push_check_state()
  string(APPEND CMAKE_REQUIRED_FLAGS " -Werror=unused-command-line-argument")
  check_c_compiler_flag(-marm HAVE_ARM_MODE)
  cmake_pop_check_state()
  if(HAVE_ARM_MODE)
    set_property(SOURCE "${SDL3_SOURCE_DIR}/src/atomic/SDL_spinlock.c" APPEND_STRING PROPERTY COMPILE_FLAGS " -marm")
    set_source_files_properties(src/atomic/SDL_spinlock.c PROPERTIES SKIP_PRECOMPILE_HEADERS 1)
  endif()

  if(SDL_AUDIO)
    set(SDL_AUDIO_DRIVER_ANDROID 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/audio/android/*.c")

    set(SDL_AUDIO_DRIVER_OPENSLES 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/audio/openslES/*.c")

    sdl_link_dependency(opensles LIBS ${ANDROID_DL_LIBRARY} OpenSLES)

    set(SDL_AUDIO_DRIVER_AAUDIO 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/audio/aaudio/*.c")

    set(HAVE_SDL_AUDIO TRUE)
  endif()

  set(SDL_FILESYSTEM_ANDROID 1)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/filesystem/android/*.c")
  set(HAVE_SDL_FILESYSTEM TRUE)

  set(SDL_FSOPS_POSIX 1)  # !!! FIXME: this might need something else for .apk data?
  sdl_sources("${SDL3_SOURCE_DIR}/src/filesystem/posix/SDL_sysfsops.c")
  set(HAVE_SDL_FSOPS TRUE)

  if(SDL_HAPTIC)
    set(SDL_HAPTIC_ANDROID 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/haptic/android/*.c")
    set(HAVE_SDL_HAPTIC TRUE)
  endif()

  if(SDL_HIDAPI)
    CheckHIDAPI()
  endif()

  if(SDL_JOYSTICK)
    set(SDL_JOYSTICK_ANDROID 1)
    sdl_glob_sources(
      "${SDL3_SOURCE_DIR}/src/joystick/android/*.c"
      "${SDL3_SOURCE_DIR}/src/joystick/steam/*.c"
    )
    set(HAVE_SDL_JOYSTICK TRUE)
  endif()

  set(SDL_LOADSO_DLOPEN 1)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/loadso/dlopen/*.c")
  set(HAVE_SDL_LOADSO TRUE)

  if(SDL_POWER)
    set(SDL_POWER_ANDROID 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/power/android/*.c")
    set(HAVE_SDL_POWER TRUE)
  endif()

  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/locale/android/*.c")
  set(HAVE_SDL_LOCALE TRUE)

  set(SDL_TIME_UNIX 1)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/time/unix/*.c")
  set(HAVE_SDL_TIME TRUE)

  set(SDL_TIMER_UNIX 1)
  sdl_glob_sources("${SDL3_SOURCE_DIR}/src/timer/unix/*.c")
  set(HAVE_SDL_TIMERS TRUE)

  if(SDL_SENSOR)
    set(SDL_SENSOR_ANDROID 1)
    set(HAVE_SDL_SENSORS TRUE)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/sensor/android/*.c")
  endif()

  if(SDL_CAMERA)
    set(SDL_CAMERA_DRIVER_ANDROID 1)
    set(HAVE_CAMERA TRUE)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/camera/android/*.c")
  endif()

  if(SDL_VIDEO)
    set(SDL_VIDEO_DRIVER_ANDROID 1)
    sdl_glob_sources("${SDL3_SOURCE_DIR}/src/video/android/*.c")
    set(HAVE_SDL_VIDEO TRUE)

    # Core stuff
    # find_library(ANDROID_DL_LIBRARY dl)
    # FIXME failing dlopen https://github.com/android-ndk/ndk/issues/929
    sdl_link_dependency(android_video LIBS dl log android)
    sdl_compile_definitions(PRIVATE "GL_GLEXT_PROTOTYPES")

    #enable gles
    if(SDL_OPENGLES)
      set(SDL_VIDEO_OPENGL_EGL 1)
      set(HAVE_OPENGLES TRUE)
      set(SDL_VIDEO_OPENGL_ES 1)
      set(SDL_VIDEO_OPENGL_ES2 1)
      set(SDL_VIDEO_RENDER_OGL_ES2 1)

      sdl_link_dependency(opengles LIBS GLESv1_CM GLESv2)
    endif()

    if(SDL_VULKAN)
      check_c_source_compiles("
      #if defined(__ARM_ARCH) && __ARM_ARCH < 7
      #error Vulkan doesn't work on this configuration
      #endif
      int main(int argc, char **argv) { return 0; }
      " VULKAN_PASSED_ANDROID_CHECKS)
      if(VULKAN_PASSED_ANDROID_CHECKS)
        set(SDL_VIDEO_VULKAN 1)
        set(HAVE_VULKAN TRUE)
      endif()
    endif()
  endif()

  CheckPTHREAD()
  if(SDL_CLOCK_GETTIME)
    set(HAVE_CLOCK_GETTIME 1)
  endif()

  if(NOT SDL_DISABLE_ANDROID_JAR)
    find_package(Java)
    find_package(SdlAndroidPlatform MODULE)

    if(Java_FOUND AND SdlAndroidPlatform_FOUND)
      include(UseJava)
      set(path_android_jar "${SDL_ANDROID_PLATFORM_ROOT}/android.jar")
      set(android_java_sources_root "${SDL3_SOURCE_DIR}/android-project/app/src/main/java")
      file(GLOB SDL_JAVA_SOURCES "${android_java_sources_root}/org/libsdl/app/*.java")
      set(CMAKE_JAVA_COMPILE_FLAGS "-encoding;utf-8")
      add_jar(SDL3-jar
        SOURCES ${SDL_JAVA_SOURCES}
        INCLUDE_JARS "${path_android_jar}"
        OUTPUT_NAME "SDL3"
        VERSION "${SDL3_VERSION}"
      )
      set_property(TARGET SDL3-jar PROPERTY OUTPUT "${SDL3_BINARY_DIR}/SDL3-${SDL3_VERSION}.jar")
      add_library(SDL3__Jar INTERFACE)
      add_library(SDL3::Jar ALIAS SDL3__Jar)
      get_property(sdl3_jar_location TARGET SDL3-jar PROPERTY JAR_FILE)
      set_property(TARGET SDL3__Jar PROPERTY JAR_FILE "${sdl3_jar_location}")
      set(javasourcesjar "${SDL3_BINARY_DIR}/SDL3-${SDL3_VERSION}-sources.jar")
      string(REGEX REPLACE "${android_java_sources_root}/" "" sdl_relative_java_sources "${SDL_JAVA_SOURCES}")
      add_custom_command(
        OUTPUT "${javasourcesjar}"
        COMMAND ${Java_JAR_EXECUTABLE} cf "${javasourcesjar}" ${sdl_relative_java_sources}
        WORKING_DIRECTORY "${android_java_sources_root}"
        DEPENDS ${SDL_JAVA_SOURCES}
      )
      add_custom_target(SDL3-javasources ALL DEPENDS "${javasourcesjar}")
      if(NOT SDL_DISABLE_INSTALL_DOCS)
        set(javadocdir "${SDL3_BINARY_DIR}/docs/javadoc")
        set(javadocjar "${SDL3_BINARY_DIR}/SDL3-${SDL3_VERSION}-javadoc.jar")
        set(javadoc_index_html "${javadocdir}/index.html")
        add_custom_command(
          OUTPUT "${javadoc_index_html}"
          COMMAND ${CMAKE_COMMAND} -E rm -rf "${javadocdir}"
          COMMAND ${Java_JAVADOC_EXECUTABLE} -encoding utf8 -d "${javadocdir}"
            -classpath "${path_android_jar}"
            -author -use -version ${SDL_JAVA_SOURCES}
          DEPENDS ${SDL_JAVA_SOURCES} "${path_android_jar}"
        )
        add_custom_target(SDL3-javadoc ALL DEPENDS "${javadoc_index_html}")
        set_property(TARGET SDL3-javadoc PROPERTY OUTPUT_DIR "${javadocdir}")
      endif()
    endif()
  endif()

  if(SDL_DIALOG)
    sdl_sources(
      "${SDL3_SOURCE_DIR}/src/dialog/SDL_dialog_utils.c"
      "${SDL3_SOURCE_DIR}/src/dialog/android/SDL_androiddialog.c"
    )
    set(HAVE_SDL_DIALOG TRUE)
  endif()

  sdl_include_directories(PRIVATE SYSTEM "${ANDROID_NDK}/sources/android/cpufeatures")
endmacro()

macro(SDL_Platform_InstallExtras)
  if(TARGET SDL3-jar)
    set(SDL_INSTALL_JAVADIR "${CMAKE_INSTALL_DATAROOTDIR}/java" CACHE PATH "Path where to install java clases + java sources")
    install(FILES $<TARGET_PROPERTY:SDL3-jar,INSTALL_FILES>
      DESTINATION "${SDL_INSTALL_JAVADIR}/SDL3")
    configure_package_config_file(cmake/SDL3jarTargets.cmake.in SDL3jarTargets.cmake
      INSTALL_DESTINATION "${SDL_SDL_INSTALL_CMAKEDIR}"
      PATH_VARS SDL_INSTALL_JAVADIR
      NO_CHECK_REQUIRED_COMPONENTS_MACRO
      INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}"
    )
    install(FILES "${CMAKE_CURRENT_BINARY_DIR}/SDL3jarTargets.cmake"
      DESTINATION "${SDL_SDL_INSTALL_CMAKEDIR}"
    )
  endif()
  if(TARGET SDL3-javasources)
    install(FILES  "${SDL3_BINARY_DIR}/SDL3-${SDL3_VERSION}-sources.jar"
      DESTINATION "${SDL_INSTALL_JAVADIR}/SDL3")
  endif()
  if(TARGET SDL3-javadoc)
    set(SDL_INSTALL_JAVADOCDIR "${CMAKE_INSTALL_DATAROOTDIR}/javadoc" CACHE PATH "Path where to install SDL3 javadoc")
    install(DIRECTORY "${SDL3_BINARY_DIR}/docs/javadoc/"
      DESTINATION "${SDL_INSTALL_JAVADOCDIR}/SDL3")
  endif()
endmacro()
