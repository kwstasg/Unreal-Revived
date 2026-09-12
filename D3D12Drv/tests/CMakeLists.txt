# Unreal Revived
# Author: Kwstasg - Kostas Giannakakis
# Project: https://github.com/kwstasg/Unreal-Revived

cmake_minimum_required(VERSION 3.20)
project(VRPanelTests LANGUAGES CXX)
enable_testing()
add_executable(vr-panel-geometry VRPanelGeometryTests.cpp)
target_compile_features(vr-panel-geometry PRIVATE cxx_std_17)
add_test(NAME vr-panel-geometry COMMAND vr-panel-geometry)
