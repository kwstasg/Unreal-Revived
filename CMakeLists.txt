cmake_minimum_required(VERSION 3.24)

project(UnrealGoldModernization LANGUAGES CXX)

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

foreach(required_path
        "${UE1_227K_SDK_ROOT}/Core/Inc/Core.h"
        "${UE1_227K_SDK_ROOT}/Engine/Inc/Engine.h"
        "${UE1_227K_SDK_ROOT}/Render/Inc/Render.h"
        "${UE1_227K_SDK_ROOT}/Core/Lib/x64/Core.lib"
        "${UE1_227K_SDK_ROOT}/Engine/Lib/x64/Engine.lib"
        "${UE1_227K_SDK_ROOT}/Render/Lib/x64/Render.lib")
    if(NOT EXISTS "${required_path}")
        message(FATAL_ERROR "Missing 227k_15 SDK file: ${required_path}")
    endif()
endforeach()

add_subdirectory(D3D12Drv)

if(EXISTS "${UE1_GAME_ROOT}/System64/Unreal.exe")
    add_custom_target(deploy-d3d12drv
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
            "$<TARGET_FILE:D3D12Drv>"
            "${UE1_GAME_ROOT}/System64/D3D12Drv.dll"
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
            "${CMAKE_CURRENT_SOURCE_DIR}/D3D12Drv/D3D12Drv.int"
            "${UE1_GAME_ROOT}/System64/D3D12Drv.int"
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
            "${UE1_GAME_ROOT}/SystemLocalized/int/UnrealShare.int"
            "${UE1_GAME_ROOT}/System/UnrealShare.int"
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
            "${UE1_GAME_ROOT}/SystemLocalized/int/UPak.int"
            "${UE1_GAME_ROOT}/System/UPak.int"
        DEPENDS D3D12Drv
        COMMENT "Deploying D3D12Drv to the disposable 227k_15 System64 runtime"
    )
else()
    message(STATUS "deploy-d3d12drv unavailable: ${UE1_GAME_ROOT}/System64/Unreal.exe not found")
endif()