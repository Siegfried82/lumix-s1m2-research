cmake_minimum_required(VERSION 3.10)
project(s1m2_firmware_project C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)

# Core reverse-engineered protocol and stub routines
add_library(s1m2_core STATIC
    src/ipcu_protocol.c
)

# Header and architecture validator
add_executable(s1m2_verify
    src/main_verify.c
)
target_link_libraries(s1m2_verify PRIVATE s1m2_core)

# C header unit tests
add_executable(test_headers
    tests/test_headers.c
)

# Enable CTest integration
enable_testing()
add_test(NAME verify_headers COMMAND test_headers)
add_test(NAME verify_architecture COMMAND s1m2_verify)

find_package(Python3 COMPONENTS Interpreter QUIET)
if(Python3_FOUND)
    add_test(NAME test_dump_parser COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/tests/test_dump_parser.py)
    add_test(NAME test_toolchain COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/tests/test_toolchain.py)
endif()
