cmake_minimum_required(VERSION 3.24)

project(UnrealRevived LANGUAGES CXX)

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
include(cmake/UnrealRevivedTargets.cmake)