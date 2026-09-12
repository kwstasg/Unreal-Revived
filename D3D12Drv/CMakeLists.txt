# Unreal Revived
# Author: Kwstasg - Kostas Giannakakis
# Project: https://github.com/kwstasg/Unreal-Revived

set(D3D12DRV_SOURCES
    D3D12Drv.cpp
    D3D12MemAlloc/D3D12MemAlloc.cpp
    FileResource.cpp
    mat.cpp
    Precomp.cpp
    TextureManager.cpp
    TextureUploader.cpp
    UploadManager.cpp
    UTF16.cpp
    UD3D12RenderDevice.cpp
)

add_library(D3D12Drv SHARED ${D3D12DRV_SOURCES})
set_target_properties(D3D12Drv PROPERTIES
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED YES
    DEBUG_POSTFIX ""
    PREFIX ""
)

target_compile_definitions(D3D12Drv PRIVATE
    UNREAL_227=1
    UTGLR_UNREAL_227_BUILD
    UTGLR_USES_ALPHABLEND=1
    ENGINE_ARCHITECTURE="amd64"
    USES_SSE_INTRINSICS=1
    UNICODE=1
    _UNICODE=1
    WIN32=1
    WIN64=1
    _CRT_NO_VA_START_VALIDATION
    XR_NO_PROTOTYPES
    XR_USE_PLATFORM_WIN32
    XR_USE_GRAPHICS_API_D3D12
)

target_compile_options(D3D12Drv PRIVATE
    $<$<CXX_COMPILER_ID:MSVC>:/EHsc>
)

target_include_directories(D3D12Drv PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${UE1_227K_SDK_ROOT}/Core/Inc"
    "${UE1_227K_SDK_ROOT}/Engine/Inc"
    "${UE1_227K_SDK_ROOT}/Engine/Src"
    "${UE1_227K_SDK_ROOT}/Render/Inc"
)

target_link_libraries(D3D12Drv PRIVATE
    OpenXR::headers
    "${UE1_227K_SDK_ROOT}/Core/Lib/x64/Core.lib"
    "${UE1_227K_SDK_ROOT}/Engine/Lib/x64/Engine.lib"
    "${UE1_227K_SDK_ROOT}/Render/Lib/x64/Render.lib"
    d3d12
    d3dcompiler
    dxgi
    dxguid
)
