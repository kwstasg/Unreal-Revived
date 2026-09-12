# Unreal Revived
# Author: Kwstasg - Kostas Giannakakis
# Project: https://github.com/kwstasg/Unreal-Revived

set(XINPUTWINDRV_STAGE_ROOT "${CMAKE_CURRENT_BINARY_DIR}/staged")
set(XINPUTWINDRV_PATCH "${CMAKE_CURRENT_SOURCE_DIR}/patches/227k_15-xinputwindrv.patch")

execute_process(
    COMMAND powershell -NoProfile -ExecutionPolicy Bypass
        -File "${CMAKE_CURRENT_SOURCE_DIR}/../scripts/stage-xinput-windrv.ps1"
        -SdkRoot "${UE1_227K_SDK_ROOT}"
        -StageRoot "${XINPUTWINDRV_STAGE_ROOT}"
        -PatchPath "${XINPUTWINDRV_PATCH}"
    RESULT_VARIABLE XINPUTWINDRV_STAGE_RESULT
)
if(NOT XINPUTWINDRV_STAGE_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to stage the pinned WinDrv source for XInputWinDrv.")
endif()

set(XINPUTWINDRV_SOURCES
    XInputController.cpp
    "${XINPUTWINDRV_STAGE_ROOT}/Src/WinClient.cpp"
    "${XINPUTWINDRV_STAGE_ROOT}/Src/WinDrv.cpp"
    "${XINPUTWINDRV_STAGE_ROOT}/Src/WinInput.cpp"
    "${XINPUTWINDRV_STAGE_ROOT}/Src/WinViewport.cpp"
    "${XINPUTWINDRV_STAGE_ROOT}/Src/Res/WinDrvRes.rc"
)

add_library(XInputWinDrv SHARED ${XINPUTWINDRV_SOURCES})
set_target_properties(XInputWinDrv PROPERTIES
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED YES
    DEBUG_POSTFIX ""
    PREFIX ""
)

target_compile_definitions(XInputWinDrv PRIVATE
    UNREAL_227=1
    UTGLR_UNREAL_227_BUILD
    UTGLR_USES_ALPHABLEND=1
    ENGINE_ARCHITECTURE="amd64"
    USES_SSE_INTRINSICS=1
    UNICODE=1
    _UNICODE=1
    WIN32=1
    WIN64=1
    _CRT_SECURE_NO_WARNINGS=1
    _CRT_NO_VA_START_VALIDATION
    WINDRV_API=DLL_EXPORT
)

target_compile_options(XInputWinDrv PRIVATE
    $<$<CXX_COMPILER_ID:MSVC>:/EHsc>
)

target_include_directories(XInputWinDrv PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${XINPUTWINDRV_STAGE_ROOT}/Inc"
    "${XINPUTWINDRV_STAGE_ROOT}/Src"
    "${XINPUTWINDRV_STAGE_ROOT}/Src/Res"
    "${UE1_227K_SDK_ROOT}/Core/Inc"
    "${UE1_227K_SDK_ROOT}/Engine/Inc"
    "${UE1_227K_SDK_ROOT}/Engine/Src"
    "${UE1_227K_SDK_ROOT}/Render/Inc"
    "${UE1_227K_SDK_ROOT}/Window/Inc"
)

target_link_libraries(XInputWinDrv PRIVATE
    SDL3::SDL3-static
    "${UE1_227K_SDK_ROOT}/Core/Lib/x64/Core.lib"
    "${UE1_227K_SDK_ROOT}/Engine/Lib/x64/Engine.lib"
    "${UE1_227K_SDK_ROOT}/Window/Lib/x64/Window.lib"
    comctl32
    dinput8
    dxguid
    imm32
    winmm
)
