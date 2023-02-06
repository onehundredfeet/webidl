
if(APPLE)
    enable_language(OBJC)
    enable_language(OBJCXX)
endif()

add_library(${PROJECT_LIB_NAME} SHARED
#Input C++ files go here
${PROJECT_ADDITIONAL_SOURCES}
src/idl_${TARGET_HOST}.cpp
)

set_target_properties(${PROJECT_LIB_NAME}
PROPERTIES
PREFIX ""
OUTPUT_NAME ${CMAKE_PROJECT_NAME}
SUFFIX ${PROJECT_LIB_SUFFIX}
)

cmake_policy(SET CMP0015 NEW)

target_include_directories(${PROJECT_LIB_NAME}
PRIVATE
${TARGET_INCLUDE_DIR}
${LOCAL_INC}
${PROJECT_ADDITIONAL_INCLUDES}
)
#target_include_directories(yojimbo.hdll BEFORE PRIVATE )

link_directories(${PROJECT_LIB_NAME}
${TARGET_LIB_DIR}
${LOCAL_LIB}
)

set(ALL_LIBS 
${TARGET_LIBS}
${PROJECT_ADDITIONAL_LIBS}
)

target_link_libraries(${PROJECT_LIB_NAME} ${ALL_LIBS})

set_property(TARGET ${PROJECT_LIB_NAME} PROPERTY CXX_STANDARD 17)

string(TOUPPER "IDL_${TARGET_HOST}" IDL_DEFINE)

SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D${IDL_DEFINE} ")
if (UNIX)
    # Some special flags are needed for GNU GCC compiler
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++17 -fPIC  -O3  -fpermissive")
    #not sure why the ${HL_LIB_DIR} is necessary given the above.
    SET(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} -shared  ")
endif (UNIX)

install(TARGETS ${PROJECT_LIB_NAME})