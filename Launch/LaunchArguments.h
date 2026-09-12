// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived

// The executable itself hosts the pinned engine; no child game process is used.
#pragma once
#include <string>
#include <vector>
#ifndef STRICT
#define STRICT
#endif
#include <windows.h>
#include <shellapi.h>

inline std::wstring QuoteLaunchArgument(const std::wstring& value)
{
    std::wstring result = L"\"";
    size_t slashes = 0;
    for (wchar_t c : value)
    {
        if (c == L'\\') { ++slashes; continue; }
        result.append(c == L'"' ? slashes * 2 + 1 : slashes, L'\\');
        result += c;
        slashes = 0;
    }
    result.append(slashes * 2, L'\\');
    return result + L'"';
}

inline std::wstring BuildRevivedCommandLine(const std::vector<std::wstring>& args, bool vr)
{
    std::wstring map = L"Unreal.unr?Game=ModernMenu.ModernIntro";
    std::wstring options;
    bool haveMap = false, haveLog = false;
    for (size_t i = 1; i < args.size(); ++i)
    {
        const auto& arg = args[i];
        if (arg.empty()) continue;
        const wchar_t* option = arg.c_str();
        if (*option == L'-' || *option == L'/') ++option;
        // The executable owns mode and profile, including after Preferences Restart.
        if ((option != arg.c_str() && (!_wcsicmp(option, L"vr") || !_wcsicmp(option, L"novr"))) ||
            !_wcsnicmp(option, L"ini=", 4) || !_wcsnicmp(option, L"userini=", 8)) continue;
        const auto equals = arg.find(L'=');
        const auto query = arg.find(L'?');
        const bool isMap = arg[0] != L'-' && arg[0] != L'/' &&
            (equals == std::wstring::npos || query < equals);
        if (!haveMap && isMap)
        {
            map = arg;
            haveMap = true;
        }
        else
        {
            // UE1 Parse expects quotes after '=' for values containing spaces.
            if (equals != std::wstring::npos && query == std::wstring::npos)
                options += L" " + arg.substr(0, equals + 1) + QuoteLaunchArgument(arg.substr(equals + 1));
            else
                options += L" " + QuoteLaunchArgument(arg);
            haveLog |= !_wcsnicmp(arg.c_str(), L"log=", 4);
        }
    }
    // Core strips the executable name. The first engine argument MUST be a map.
    std::wstring result = QuoteLaunchArgument(args.at(0)) + L" " + QuoteLaunchArgument(map);
    result += vr ? L" ini=UnrealVR.ini userini=User.ini -vr" : L" ini=Unreal.ini userini=User.ini -novr";
    if (!haveLog) result += vr ? L" log=UnrealRevivedVR.log" : L" log=UnrealRevived.log";
    // Never forward a launch of one mode to an already running different mode.
    return result + L" -newwindow" + options;
}

inline const wchar_t* UnrealRevivedCommandLine()
{
    static const std::wstring command = [] {
        int count = 0;
        auto argv = CommandLineToArgvW(GetCommandLineW(), &count);
        if (!argv || !count) ExitProcess(ERROR_INVALID_PARAMETER);
        std::vector<std::wstring> args(argv, argv + count);
        LocalFree(argv);
        return BuildRevivedCommandLine(args, REVIVED_VR != 0);
    }();
    return command.c_str();
}
