define_property(DIRECTORY
  PROPERTY SDL_PKGCONFIG_PRIVATE_REQUIRES
  BRIEF_DOCS "pkg-config requirement when using a static SDL library"
  FULL_DOCS "pkg-config requirement when using a static SDL library"
)

define_property(DIRECTORY
    PROPERTY SDL_PKGCONFIG_INTERFACE_COMPILE_OPTIONS
    BRIEF_DOCS "pkg-config compile options when using a (shared) SDL library"
    FULL_DOCS "pkg-config compile options when using a (shared) SDL library"
)

define_property(DIRECTORY
  PROPERTY SDL_PKGCONFIG_PRIVATE_LIBRARIES
  BRIEF_DOCS "pkg-config libraries when using a static SDL library"
  FULL_DOCS "pkg-config libraries when using a static SDL library"
)

define_property(DIRECTORY
  PROPERTY SDL_PKGCONFIG_PRIVATE_LINK_OPTIONS
  BRIEF_DOCS "pkg-config link options when using a static SDL library"
  FULL_DOCS "pkg-config link options when using a static SDL library"
)

function(sdl_private_sources )
  if(TARGET SDL3-shared)
    target_sources(SDL3-shared PRIVATE ${ARGN})
  endif()
  if(TARGET SDL3-static)
    target_sources(SDL3-static PRIVATE ${ARGN})
  endif()
endfunction()

function(sdl_glob_private_sources )
  file(GLOB files ${ARGN})
  sdl_private_sources(PRIVATE ${files})
endfunction()

function(sdl_compile_options )
  if(TARGET SDL3-shared)
    target_compile_options(SDL3-shared ${ARGN})
  endif()
  if(TARGET SDL3-static)
    target_compile_options(SDL3-static ${ARGN})
  endif()
endfunction()

function(sdl_compile_definitions)
  cmake_parse_arguments(ST "CMAKE;CMAKE_PC;PC" "" "PRIVATE;PUBLIC;INTERFACE" ${ARGN})
  if(ST_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unparsed arguments: ${ST_UNPARSED_ARGUMENTS}")
  endif()
  if(NOT (ST_PRIVATE OR ST_PUBLIC OR ST_INTERFACE))
    message(FATAL_ERROR "Need one of PRIVATE;PUBLIC;INTERFACE")
  endif()
  if(NOT (ST_CMAKE_PC OR ST_CMAKE OR ST_PC))
    if(ST_PRIVATE AND NOT (ST_PUBLIC OR ST_INTERFACE))
      set(ST_CMAKE TRUE)
    else()
      message(FATAL_ERROR "Need one of CMAKE_PC;CMAKE;PC")
    endif()
  endif()
  if(TARGET SDL3-shared AND (ST_CMAKE_PC OR ST_CMAKE))
    target_compile_definitions(SDL3-shared PUBLIC ${ST_PUBLIC} PRIVATE ${ST_PRIVATE} INTERFACE ${ST_INTERFACE})
  endif()
  if(TARGET SDL3-static AND (ST_CMAKE_PC OR ST_CMAKE))
    target_compile_definitions(SDL3-static PUBLIC ${ST_PUBLIC} PRIVATE ${ST_PRIVATE} INTERFACE ${ST_INTERFACE})
  endif()
  if(ST_CMAKE_PC OR ST_PC)
    foreach(var IN LISTS ST_PUBLIC ST_INTERFACE)
      set_property(DIRECTORY "${SDL3_SOURCE_DIR}" APPEND PROPERTY SDL_PKGCONFIG_INTERFACE_COMPILE_OPTIONS "-D${var}")
    endforeach()
  endif()
endfunction()

function(sdl_include_directories )
  if(TARGET SDL3-shared)
    target_include_directories(SDL3-shared ${ARGN})
  endif()
  if(TARGET SDL3-static)
    target_include_directories(SDL3-static ${ARGN})
  endif()
endfunction()

function(sdl_link_directories )
  if(TARGET SDL3-shared)
    target_link_directories(SDL3-shared ${ARGN})
  endif()
  if(TARGET SDL3-static)
    target_link_directories(SDL3-static ${ARGN})
  endif()
endfunction()

function(sdl_private_link_options )
  cmake_parse_arguments(ST "" "" "CMAKE;CMAKE_PC;PC" ${ARGN})
  if(ST_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unparsed arguments: ${ST_UNPARSED_ARGUMENTS}")
  endif()
  if(TARGET SDL3-shared)
    target_link_options(SDL3-shared PRIVATE ${ST_CMAKE_PC} ${ST_CMAKE})
  endif()
  if(TARGET SDL3-static)
    target_link_options(SDL3-static INTERFACE ${ST_CMAKE_PC} ${ST_CMAKE})
  endif()
  set_property(DIRECTORY "${SDL3_SOURCE_DIR}" APPEND PROPERTY SDL_PKGCONFIG_PRIVATE_LINK_OPTIONS ${ST_CMAKE_PC} ${ST_PC})
endfunction()

function(sdl_private_link_libraries )
  cmake_parse_arguments(ST "" "" "CMAKE;CMAKE_PC;PC;PC_REQUIRES" ${ARGN})
  if(ST_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unparsed arguments: ${ST_UNPARSED_ARGUMENTS}")
  endif()
  if(TARGET SDL3-shared)
    target_link_libraries(SDL3-shared PRIVATE ${ST_CMAKE_PC} ${ST_CMAKE})
  endif()
  if(TARGET SDL3-static)
    target_link_libraries(SDL3-static PRIVATE ${ST_CMAKE_PC} ${ST_CMAKE})
  endif()

  set_property(DIRECTORY "${SDL3_SOURCE_DIR}" APPEND PROPERTY SDL_PKGCONFIG_PRIVATE_LIBRARIES ${ST_CMAKE_PC} ${ST_PC})
  set_property(DIRECTORY "${SDL3_SOURCE_DIR}" APPEND PROPERTY SDL_PKGCONFIG_PRIVATE_REQUIRES ${ST_PC_REQUIRES})
endfunction()
