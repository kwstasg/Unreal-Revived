# Unreal Revived
# Author: Kwstasg - Kostas Giannakakis
# Project: https://github.com/kwstasg/Unreal-Revived

cmake_minimum_required(VERSION 3.20)
project(VRPanelTests LANGUAGES CXX)
enable_testing()
add_executable(vr-panel-geometry VRPanelGeometryTests.cpp)
target_compile_features(vr-panel-geometry PRIVATE cxx_std_17)
add_test(NAME vr-panel-geometry COMMAND vr-panel-geometry)

if(WIN32)
    add_executable(vr-ui-occlusion VRUIOcclusionTests.cpp ../FileResource.cpp)
    target_compile_features(vr-ui-occlusion PRIVATE cxx_std_17)
    target_link_libraries(vr-ui-occlusion PRIVATE d3d11 d3dcompiler)
    add_test(NAME vr-ui-occlusion COMMAND vr-ui-occlusion)
endif()

set(OPENXR_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../local/build/_deps/openxr-src/include" CACHE PATH "Pinned OpenXR headers")
if(EXISTS "${OPENXR_INCLUDE_DIR}/openxr/openxr.h")
    add_executable(vr-controller-lifecycle OpenXRControllersTests.cpp)
    target_compile_features(vr-controller-lifecycle PRIVATE cxx_std_17)
    target_include_directories(vr-controller-lifecycle PRIVATE "${OPENXR_INCLUDE_DIR}")
    add_test(NAME vr-controller-lifecycle COMMAND vr-controller-lifecycle)
endif()
