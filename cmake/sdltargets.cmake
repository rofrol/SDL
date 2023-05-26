function(sdl_glob_sources)
  file(GLOB new_sources ${ARGN})
  set(SOURCE_FILES ${SOURCE_FILES} ${new_sources} PARENT_SCOPE)
endfunction()

function(sdl_sources)
  set(SOURCE_FILES ${SOURCE_FILES} ${ARGN} PARENT_SCOPE)
endfunction()
