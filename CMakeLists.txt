cmake_minimum_required(VERSION 3.24)

project(TowerDefensePoc VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

set(CPM_FILE "${CMAKE_BINARY_DIR}/cmake/CPM.cmake")
if(NOT EXISTS "${CPM_FILE}")
    file(DOWNLOAD
        https://github.com/cpm-cmake/CPM.cmake/releases/download/v0.43.2/CPM.cmake
        "${CPM_FILE}"
    )
endif()
include("${CPM_FILE}")

option(TOWER_DEFENSE_EDITOR "Build the Ampersand editor (./build/ampersand_editor .)" OFF)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")

CPMAddPackage(
    NAME AmpersandEngine
    GITHUB_REPOSITORY Boz0o0/Ampersand-Engine
    GIT_TAG main
    OPTIONS
        "AMPERSAND_MODULE_NET OFF"
        "AMPERSAND_BUILD_EDITOR ${TOWER_DEFENSE_EDITOR}"
)

add_executable(tower_defense src/main.cpp src/GameBindings.cpp)

target_link_libraries(tower_defense PRIVATE
    ampersand_scene
    ampersand_scripting
    ampersand_render
    ampersand_audio
    ampersand_physics
    ampersand_input
)
