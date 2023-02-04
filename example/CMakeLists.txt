cmake_minimum_required(VERSION 3.10)
#you need to modify this yourself
project(sample C CXX)

set(PATH_TO_IDL "..")
# a bunch of pre-configured options that may or may not be useful
# it attempts to cover most of what is used for basic libraries
# you can reference the paths defined here to help make your cmake code more portable
include(${PATH_TO_IDL}/h-idl-defines.cmake)

set( PROJECT_ADDITIONAL_SOURCES 
src/sample_custom.cpp
)

set (PROJECT_ADDITIONAL_INCLUDES
# otherlib/include
)

set (PROJECT_ADDITIONAL_LIB_DIRS
# otherlib/lib
)

# Just an example, LOCAL_LIB is defined in the include above, and points to /usr/local typically on unix
#find_library(LIBSODIUM NAMES sodium  HINTS ${LOCAL_LIB})
             
set(PROJECT_ADDITIONAL_LIBS
#LIBSODIUM
)           

include(${PATH_TO_IDL}/h-idl-configure.cmake)


