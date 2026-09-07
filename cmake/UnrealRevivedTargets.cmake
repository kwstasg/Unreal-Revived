# Unreal Revived
# Author: Kwstasg - Kostas Giannakakis
# Project: https://github.com/kwstasg/Unreal-Revived

if(EXISTS "${UE1_GAME_ROOT}/System64/Unreal.exe")
    add_custom_target(deploy-d3d12drv
        COMMAND powershell -NoProfile -ExecutionPolicy Bypass
            -File "${CMAKE_CURRENT_SOURCE_DIR}/scripts/assert-development-runtime.ps1"
            -GameRoot "${UE1_GAME_ROOT}"
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
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
            "${UE1_GAME_ROOT}/SystemLocalized/int/Startup.int"
            "${UE1_GAME_ROOT}/System/Startup.int"
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
            "${UE1_GAME_ROOT}/SystemLocalized/int/Startup.int"
            "${UE1_GAME_ROOT}/System64/Startup.int"
        DEPENDS D3D12Drv
        COMMENT "Deploying D3D12Drv to the disposable 227k_15 System64 runtime"
    )
    add_custom_target(deploy-xinputwindrv
        COMMAND powershell -NoProfile -ExecutionPolicy Bypass
            -File "${CMAKE_CURRENT_SOURCE_DIR}/scripts/assert-development-runtime.ps1"
            -GameRoot "${UE1_GAME_ROOT}"
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
            "$<TARGET_FILE:XInputWinDrv>"
            "${UE1_GAME_ROOT}/System64/XInputWinDrv.dll"
        DEPENDS XInputWinDrv
        COMMENT "Deploying XInputWinDrv to the disposable 227k_15 System64 runtime"
    )
    add_custom_target(deploy-modern-menu
        COMMAND powershell -NoProfile -ExecutionPolicy Bypass
            -File "${CMAKE_CURRENT_SOURCE_DIR}/scripts/build-modern-menu.ps1"
            -GameRoot "${UE1_GAME_ROOT}"
        COMMENT "Building and deploying the ModernMenu UnrealScript package"
    )
    add_custom_target(stage-offline-package
        COMMAND powershell -NoProfile -ExecutionPolicy Bypass
            -File "${CMAKE_CURRENT_SOURCE_DIR}/scripts/package-offline-installer.ps1"
            -RendererDll "$<TARGET_FILE:D3D12Drv>"
            -InputDll "$<TARGET_FILE:XInputWinDrv>"
            -GameRoot "${UE1_GAME_ROOT}"
            -PatchArchive "${OLDUNREAL_227K15_PATCH_ARCHIVE}"
        DEPENDS deploy-d3d12drv deploy-xinputwindrv deploy-modern-menu
        COMMENT "Staging the hash-verified offline installer payload"
    )
    add_custom_target(package-offline-installer
        COMMAND powershell -NoProfile -ExecutionPolicy Bypass
            -File "${CMAKE_CURRENT_SOURCE_DIR}/scripts/package-offline-installer.ps1"
            -RendererDll "$<TARGET_FILE:D3D12Drv>"
            -InputDll "$<TARGET_FILE:XInputWinDrv>"
            -GameRoot "${UE1_GAME_ROOT}"
            -PatchArchive "${OLDUNREAL_227K15_PATCH_ARCHIVE}"
            -BuildInstaller
        DEPENDS deploy-d3d12drv deploy-xinputwindrv deploy-modern-menu
        COMMENT "Building the fully offline Unreal Revived installer"
    )
else()
    message(STATUS "deploy-d3d12drv unavailable: ${UE1_GAME_ROOT}/System64/Unreal.exe not found")
    message(STATUS "deploy-xinputwindrv unavailable: ${UE1_GAME_ROOT}/System64/Unreal.exe not found")
endif()
