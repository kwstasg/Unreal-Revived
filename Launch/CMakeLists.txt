# Unreal Revived
# Author: Kwstasg - Kostas Giannakakis
# Project: https://github.com/kwstasg/Unreal-Revived

cmake_minimum_required(VERSION 3.24)
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    project(UnrealRevivedLaunch LANGUAGES CXX RC)
else()
    enable_language(RC)
endif()

if(NOT WIN32 OR NOT CMAKE_SIZEOF_VOID_P EQUAL 8)
    message(FATAL_ERROR "The branded launch executables require Windows x64.")
endif()
set(UE1_227K_SDK_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../local/sdk/227k_15" CACHE PATH "Pinned 227k_15 SDK")
set(launch_source "${UE1_227K_SDK_ROOT}/Launch/Src/Launch.cpp")
file(SHA256 "${launch_source}" launch_hash)
if(NOT launch_hash STREQUAL "1554e139f468912c078ef6fc8f6e1c57f2a9d0832a7137b79582e892519e8f5e")
    message(FATAL_ERROR "Launch.cpp does not match the pinned 227k_15 SDK.")
endif()

# Preserve the SDK startup, main loop, and shutdown. Change only argument
# construction and the localization package identity of these renamed hosts.
file(READ "${launch_source}" launch_text)
string(REPLACE "#include \"LaunchPrivate.h\"" "#include \"LaunchArguments.h\"\n#include \"LaunchPrivate.h\"" launch_text "${launch_text}")
string(REPLACE "const TCHAR* CmdLine = GetCommandLine();" "const TCHAR* CmdLine = UnrealRevivedCommandLine();" launch_text "${launch_text}")
string(REPLACE "appStrncpy(const_cast<TCHAR*>(GPackage), appPackage(), 64);" "appStrncpy(const_cast<TCHAR*>(GPackage), TEXT(\"Unreal\"), 64);" launch_text "${launch_text}")
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/Launch.cpp" "// Unreal Revived\n// Author: Kwstasg - Kostas Giannakakis\n// Project: https://github.com/kwstasg/Unreal-Revived\n\n${launch_text}")

foreach(mode IN ITEMS Desktop VR)
    if(mode STREQUAL "VR")
        set(executable UnrealRevivedVR)
        set(description "Unreal Revived VR")
        set(vr 1)
    else()
        set(executable UnrealRevived)
        set(description "Unreal Revived")
        set(vr 0)
    endif()
    configure_file(Launch.rc.in "${CMAKE_CURRENT_BINARY_DIR}/${executable}.rc" @ONLY)
    add_executable(${executable} WIN32 "${CMAKE_CURRENT_BINARY_DIR}/Launch.cpp" "${CMAKE_CURRENT_BINARY_DIR}/${executable}.rc")
    target_compile_features(${executable} PRIVATE cxx_std_17)
    target_compile_definitions(${executable} PRIVATE
        REVIVED_VR=${vr} UNREAL_227=1 ENGINE_ARCHITECTURE="amd64"
        USES_SSE_INTRINSICS=1 UNICODE=1 _UNICODE=1 WIN32=1 WIN64=1
        _CRT_SECURE_NO_WARNINGS=1 _CRT_NO_VA_START_VALIDATION)
    target_compile_options(${executable} PRIVATE /EHsc)
    target_include_directories(${executable} PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}"
        "${UE1_227K_SDK_ROOT}/Launch/Src"
        "${UE1_227K_SDK_ROOT}/Core/Inc"
        "${UE1_227K_SDK_ROOT}/Engine/Inc"
        "${UE1_227K_SDK_ROOT}/Engine/Src"
        "${UE1_227K_SDK_ROOT}/Render/Inc"
        "${UE1_227K_SDK_ROOT}/Window/Inc")
    target_link_libraries(${executable} PRIVATE
        "${UE1_227K_SDK_ROOT}/Core/Lib/x64/Core.lib"
        "${UE1_227K_SDK_ROOT}/Engine/Lib/x64/Engine.lib"
        "${UE1_227K_SDK_ROOT}/Window/Lib/x64/Window.lib"
        comctl32 shell32 winmm)
endforeach()

enable_testing()
add_executable(LaunchArgumentsTests tests/LaunchArgumentsTests.cpp)
target_compile_features(LaunchArgumentsTests PRIVATE cxx_std_17)
target_compile_definitions(LaunchArgumentsTests PRIVATE REVIVED_VR=0)
target_include_directories(LaunchArgumentsTests PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
target_link_libraries(LaunchArgumentsTests PRIVATE shell32)
add_test(NAME LaunchArguments COMMAND LaunchArgumentsTests)
