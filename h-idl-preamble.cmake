if (WIN32)
#why this has to be here is SUPER annoying
cmake_policy(SET CMP0091 NEW) #required for MSVC runtime
endif()

cmake_policy(SET CMP0015 NEW)
cmake_policy(SET CMP0068 NEW)

if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
set(CMAKE_MACOSX_RPATH OFF)
set(CMAKE_INSTALL_RPATH "")
set(CMAKE_BUILD_RPATH "")
endif()