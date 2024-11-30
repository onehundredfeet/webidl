cmake_policy(SET CMP0015 NEW)
cmake_policy(SET CMP0091 NEW) #needs to be in the actual CMakeFiles.txt, why, no idea.

##### Common
#if (NOT CMAKE_BUILD_TYPE)
#set(CMAKE_BUILD_TYPE DEBUG)
#endif()

## Bring in Environment variables
if (DEFINED ENV{HL_LIB_DIR})
    message("Enviornment variable : HL_LIB_DIR is $ENV{HL_LIB_DIR}")
    set( HL_LIB_DIR $ENV{HL_LIB_DIR})
endif()

if (DEFINED ENV{HL_INC_DIR})
    message("Enviornment variable : HL_INC_DIR is $ENV{HL_INC_DIR}")
    set( HL_INC_DIR $ENV{HL_INC_DIR})
endif()

if (NOT H_GLUE_ROOT)
    set(H_GLUE_ROOT "src")
endif()


##### Apple Configuration
if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
if (NOT CMAKE_OSX_ARCHITECTURES)
#OSX Configuration details
if (TARGET_ARCH STREQUAL "x86" OR TARGET_ARCH STREQUAL "x64" OR NOT TARGET_ARCH)
    set(TARGET_ARCH "x86_64")
elseif(TARGET_ARCH STREQUAL "arm")
    set(TARGET_ARCH "arm64")
elseif(TARGET_ARCH STREQUAL "all")
    set(TARGET_ARCH "x86_64;arm64")
endif()

message("Target Arch: ${TARGET_ARCH}")
if (TARGET_ARCH STREQUAL "x86_64")
    set(BREW_ROOT "/usr/local")
endif()

if (TARGET_ARCH STREQUAL "arm64")
    set(BREW_ROOT "/opt/homebrew")
endif()

if (NOT DEPENDENCY_ROOT) 
set(DEPENDENCY_ROOT ${BREW_ROOT})
endif()

set(CELLAR_ROOT "${BREW_ROOT}/Cellar")

set(CMAKE_OSX_ARCHITECTURES ${TARGET_ARCH})


else()
set( HL_LIB_DIR "/usr/local/lib")
set( HL_INC_DIR "/usr/local/include")
endif() # NOT CMAKE_OSX_ARCHITECTURES

set(HL_LIB_SHORT_NAME "hl")

############## WINDOWS CONFIGURATION
elseif( WIN32 )
IF(CMAKE_BUILD_TYPE MATCHES Debug)
    message("BUILDING DEBUG...")
    set( CONFIG_POSTFIX "_d")
else()
    set (CONFIG_POSTFIX "")
endif()

if (NOT DEPENDENCY_ROOT)
set (DEPENDENCY_ROOT "ext")
endif()

set(HL_LIB_SHORT_NAME "hl")

endif()

############## COMMON DOWNSTREAM CONFIGURATION
if (NOT LOCAL_INC)
set(LOCAL_INC "${DEPENDENCY_ROOT}/include")
endif()

if (NOT LOCAL_LIB)
set(LOCAL_LIB "${DEPENDENCY_ROOT}/lib")
endif()

if (NOT HL_LIB_DIR)
    set( HL_LIB_DIR ${LOCAL_LIB})
endif()

if (NOT HL_INC_DIR)
    set( HL_INC_DIR ${LOCAL_INC})
endif()

############## TARGET HOST DETERMINATION
if (NOT TARGET_HOST)
    set(TARGET_HOST "hl")
endif()


############## TARGET HOST CONFIGURATION

## Where to find the target support libraries
if (TARGET_HOST STREQUAL "hl")
if (NOT TARGET_INCLUDE_DIR) 
    set(TARGET_INCLUDE_DIR ${HL_INC_DIR})
endif()

if (NOT TARGET_LIB_DIR) 
    set(TARGET_LIB_DIR ${HL_LIB_DIR})
endif()

# Target specific output
set(PROJECT_LIB_SUFFIX ".hdll")


message( "Looking for ${HL_LIB_SHORT_NAME} lib in  ${TARGET_LIB_DIR} with suffix ${CMAKE_FIND_LIBRARY_SUFFIXES} ")

if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
set(HL_LIB_PREFIX "")
elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
set(HL_LIB_PREFIX "lib")
else()
set(HL_LIB_PREFIX "")
endif()

message(${TARGET_LIB_DIR})

set (HL_LIB_NAME ${HL_LIB_PREFIX}hl${CONFIG_POSTFIX})

message( ${HL_LIB_NAME})

set(CMAKE_IGNORE_PATH)
find_library(LIBHL NAMES ${HL_LIB_NAME} PATHS ${TARGET_LIB_DIR} NO_DEFAULT_PATH)
set(TARGET_LIBS ${LIBHL})

message("Target Libs: ${TARGET_LIBS} $PATHS ${TARGET_LIB_DIR} ${HL_LIB_NAME}")
message("${CMAKE_PREFIX_PATH}")
elseif(TARGET_HOST STREQUAL "jvm")



find_package(JNI)

if (JNI_FOUND)
    message (STATUS "JNI_INCLUDE_DIRS=${JNI_INCLUDE_DIRS}")
    message (STATUS "JNI_LIBRARIES=${JNI_LIBRARIES}")
else()
    #currently only works on unix, maybe only mac
    execute_process(COMMAND "/usr/libexec/java_home" OUTPUT_VARIABLE JAVA_HOME OUTPUT_STRIP_TRAILING_WHITESPACE)
    message("Looking for java at ${JAVA_HOME}. If not set, please set JAVA_HOME environment variable")
    set(JNI_INCLUDE_DIRS "${JAVA_HOME}/include" "${JAVA_HOME}/include/darwin")
    set(JNI_LIBRARIES "${JAVA_HOME}/lib")
endif()

if (NOT TARGET_INCLUDE_DIR) 
    set(TARGET_INCLUDE_DIR ${JNI_INCLUDE_DIRS})
endif()

if (NOT TARGET_LIB_DIR) 
    set(TARGET_LIB_DIR ${JNI_LIBRARIES})
endif()


set(PROJECT_LIB_SUFFIX ".dylib")
#set(PROJECT_LIB_NAME "${CMAKE_PROJECT_NAME}.dylib")
set(TARGET_LIBS )
endif() #hl


set(PROJECT_LIB_NAME "${CMAKE_PROJECT_NAME}${CONFIG_POSTFIX}")
message( "Project lib name ${PROJECT_LIB_NAME}")