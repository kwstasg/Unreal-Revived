// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived

#include "LaunchArguments.h"
#include <iostream>
#include <stdexcept>

void Require(bool condition, const char* message)
{
    if (!condition) throw std::runtime_error(message);
}
std::vector<std::wstring> ParseWindows(const std::wstring& command)
{
    int count = 0;
    auto args = CommandLineToArgvW(command.c_str(), &count);
    Require(args != nullptr, "Cannot parse command line");
    std::vector<std::wstring> result(args, args + count);
    LocalFree(args);
    return result;
}
int main()
{
    try {
        for (bool vr : {false, true}) {
            const auto cmd = BuildRevivedCommandLine({L"C:\\Game With Spaces\\UnrealRevived.exe"}, vr);
            const auto args = ParseWindows(cmd);
            Require(args[1] == L"Unreal.unr?Game=ModernMenu.ModernIntro", "Startup map must come first");
            Require(args[2] == (vr ? L"ini=UnrealVR.ini" : L"ini=Unreal.ini"), "Wrong mode profile");
            Require(args[3] == L"userini=User.ini", "Controls must be shared");
            Require(args[4] == (vr ? L"-vr" : L"-novr"), "Wrong mode");
        }
        auto cmd = BuildRevivedCommandLine({L"game.exe", L"log=C:\\Logs With Spaces\\run.log", L"-novr", L"/novr", L"-vr", L"ini=bad.ini", L"userini=other.ini"}, true);
        Require(cmd.find(L"bad.ini") == std::wstring::npos && cmd.find(L"other.ini") == std::wstring::npos && cmd.find(L"novr") == std::wstring::npos, "Conflicting mode/profile survived");
        Require(cmd.find(L"log=\"C:\\Logs With Spaces\\run.log\"") != std::wstring::npos, "Engine value quoting is incorrect");
        auto args = ParseWindows(BuildRevivedCommandLine({L"game.exe", L"NyLeve.unr?Difficulty=2", L"-nosound"}, false));
        Require(args[1] == L"NyLeve.unr?Difficulty=2", "Explicit map lost");
        const std::wstring odd = L"trailing slash\\ and \"quote\"\\";
        Require(ParseWindows(L"game.exe " + QuoteLaunchArgument(odd))[1] == odd, "Windows quoting does not round trip");
        std::cout << "PASS: map ordering, mode/profile isolation, explicit maps, and argument quoting\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}
