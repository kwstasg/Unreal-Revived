# Unreal Revived
# Author: Kwstasg - Kostas Giannakakis
# Project: https://github.com/kwstasg/Unreal-Revived

cmake_minimum_required(VERSION 3.20)
project(VRGamepadAxesTests LANGUAGES CXX)
enable_testing()
add_executable(vr-gamepad-axes VRGamepadAxesTests.cpp)
target_compile_features(vr-gamepad-axes PRIVATE cxx_std_17)
add_test(NAME vr-gamepad-axes COMMAND vr-gamepad-axes)
add_executable(vr-controller-input VRControllerInputTests.cpp)
target_compile_features(vr-controller-input PRIVATE cxx_std_17)
add_test(NAME vr-controller-input COMMAND vr-controller-input)
