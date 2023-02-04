


##### Apple Configuration
if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
#OSX Configuration details
if (TARGET_ARCH STREQUAL "x86" OR TARGET_ARCH STREQUAL "x64" OR NOT TARGET_ARCH)
    set(TARGET_ARCH "x86_64")
endif()

if (TARGET_ARCH STREQUAL "arm")
    set(TARGET_ARCH "arm64")
endif()

if (TARGET_ARCH STREQUAL "x86_64")
    set(BREW_ROOT "/usr/local")
endif()

if (TARGET_ARCH STREQUAL "arm64")
    set(LOCAL_LIB "/opt/homebrew/lib")
    set(LOCAL_INC "/opt/homebrew/include")
endif()

set(CELLAR_ROOT "${BREW_ROOT}/Cellar")
set(LOCAL_LIB "${BREW_ROOT}/lib")
set(LOCAL_INC "${BREW_ROOT}/include")

set(CMAKE_OSX_ARCHITECTURES ${TARGET_ARCH})

endif()


if (NOT TARGET_HOST)
    set(TARGET_HOST "hl")
endif()


############## TARGET CONFIGURATION

## Where to find the target support libraries
if (TARGET_HOST STREQUAL "hl")
if (NOT TARGET_INCLUDE_DIR) 
    set(TARGET_INCLUDE_DIR ${LOCAL_INC})
endif()

if (NOT TARGET_LIB_DIR) 
    set(TARGET_LIB_DIR ${LOCAL_LIB})
endif()

# Target specific output
set(PROJECT_LIB_NAME "${CMAKE_PROJECT_NAME}.hdll")
set(PROJECT_LIB_SUFFIX ".hdll")
find_library(LIBHL NAMES hl  HINTS ${TARGET_LIB_DIR} )
set(TARGET_LIBS ${LIBHL})

elseif(TARGET_HOST STREQUAL "jvm")



find_package(JNI)

if (JNI_FOUND)
    message (STATUS "JNI_INCLUDE_DIRS=${JNI_INCLUDE_DIRS}")
    message (STATUS "JNI_LIBRARIES=${JNI_LIBRARIES}")
else()
    execute_process(COMMAND "/usr/libexec/java_home" OUTPUT_VARIABLE JAVA_HOME OUTPUT_STRIP_TRAILING_WHITESPACE)
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
set(PROJECT_LIB_NAME "${CMAKE_PROJECT_NAME}.dylib")
set(TARGET_LIBS )
endif() #hl



