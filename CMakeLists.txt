# Unreal Revived
# Author: Kwstasg - Kostas Giannakakis
# Project: https://github.com/kwstasg/Unreal-Revived

cmake_minimum_required(VERSION 3.24)

project(UnrealRevived LANGUAGES C CXX)

include(FetchContent)

set(SDL_SHARED OFF CACHE BOOL "" FORCE)
set(SDL_STATIC ON CACHE BOOL "" FORCE)
set(SDL_TEST_LIBRARY OFF CACHE BOOL "" FORCE)
set(SDL_TESTS OFF CACHE BOOL "" FORCE)
set(SDL_EXAMPLES OFF CACHE BOOL "" FORCE)
set(SDL_INSTALL OFF CACHE BOOL "" FORCE)
FetchContent_Declare(SDL3
    URL "https://github.com/libsdl-org/SDL/releases/download/release-3.4.16/SDL3-3.4.16.tar.gz"
    URL_HASH SHA256=7322236cd12090c3eb40b9728be4d49c76f66ad17d04369584d4ecad5cf77c68
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
)
FetchContent_MakeAvailable(SDL3)

set(BUILD_TESTING OFF CACHE BOOL "" FORCE)
set(BUILD_LOADER ON CACHE BOOL "" FORCE)
set(DYNAMIC_LOADER ON CACHE BOOL "" FORCE)
set(BUILD_API_LAYERS OFF CACHE BOOL "" FORCE)
set(BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(BUILD_CONFORMANCE_TESTS OFF CACHE BOOL "" FORCE)
set(BUILD_SDK_TESTS OFF CACHE BOOL "" FORCE)
set(BUILD_ALL_EXTENSIONS OFF CACHE BOOL "" FORCE)
set(BUILD_WITH_SYSTEM_JSONCPP OFF CACHE BOOL "" FORCE)
FetchContent_Declare(OpenXR
    URL "https://github.com/KhronosGroup/OpenXR-SDK/archive/refs/tags/release-1.1.61.tar.gz"
    URL_HASH SHA256=d5e2773d282642e6e250bd10266f316fc3ff3b8602c83db009a1f434205998e6
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
)
FetchContent_MakeAvailable(OpenXR)

if(NOT WIN32 OR NOT CMAKE_SIZEOF_VOID_P EQUAL 8)
    message(FATAL_ERROR "The initial renderer target requires Windows x64.")
endif()

set(UE1_227K_SDK_ROOT "$ENV{UE1_227K_SDK_ROOT}" CACHE PATH "Path to the OldUnreal 227k_15 SDK")
if(NOT UE1_227K_SDK_ROOT)
    set(UE1_227K_SDK_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/local/sdk/227k_15")
endif()

set(UE1_GAME_ROOT "$ENV{UE1_GAME_ROOT}" CACHE PATH "Path to the disposable OldUnreal 227k_15 game")
if(NOT UE1_GAME_ROOT)
    set(UE1_GAME_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/local/game")
endif()

set(OLDUNREAL_227K15_PATCH_ARCHIVE "$ENV{OLDUNREAL_227K15_PATCH_ARCHIVE}" CACHE FILEPATH "Path to the pinned OldUnreal 227k_15 Windows patch archive")
if(NOT OLDUNREAL_227K15_PATCH_ARCHIVE)
    set(OLDUNREAL_227K15_PATCH_ARCHIVE "${CMAKE_CURRENT_SOURCE_DIR}/local/downloads/OldUnreal-UnrealPatch227k-Windows.zip")
endif()

foreach(required_path
        "${UE1_227K_SDK_ROOT}/Core/Inc/Core.h"
        "${UE1_227K_SDK_ROOT}/Engine/Inc/Engine.h"
        "${UE1_227K_SDK_ROOT}/Render/Inc/Render.h"
    "${UE1_227K_SDK_ROOT}/Window/Inc/Window.h"
    "${UE1_227K_SDK_ROOT}/WinDrv/Inc/WinDrv.h"
    "${UE1_227K_SDK_ROOT}/WinDrv/Src/WinClient.cpp"
    "${UE1_227K_SDK_ROOT}/WinDrv/Src/WinDrv.cpp"
    "${UE1_227K_SDK_ROOT}/WinDrv/Src/WinInput.cpp"
    "${UE1_227K_SDK_ROOT}/WinDrv/Src/WinViewport.cpp"
    "${UE1_227K_SDK_ROOT}/WinDrv/Src/Res/WinDrvRes.rc"
        "${UE1_227K_SDK_ROOT}/Core/Lib/x64/Core.lib"
        "${UE1_227K_SDK_ROOT}/Engine/Lib/x64/Engine.lib"
    "${UE1_227K_SDK_ROOT}/Render/Lib/x64/Render.lib"
    "${UE1_227K_SDK_ROOT}/Window/Lib/x64/Window.lib")
    if(NOT EXISTS "${required_path}")
        message(FATAL_ERROR "Missing 227k_15 SDK file: ${required_path}")
    endif()
endforeach()

add_subdirectory(D3D12Drv)
add_subdirectory(XInputWinDrv)
enable_testing()
add_subdirectory(Launch)
include(cmake/UnrealRevivedTargets.cmake)
