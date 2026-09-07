// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived
// Inherited WinDrv source remains the property of Epic Games, Inc.

#include "WinDrv.h"

#include <SDL3/SDL_init.h>
#include <SDL3/SDL_version.h>

#include <cmath>

namespace
{
	constexpr DWORD XINPUT_LEFT_TRIGGER_BUTTON = 0x00010000;
	constexpr DWORD XINPUT_RIGHT_TRIGGER_BUTTON = 0x00020000;
	constexpr BYTE XINPUT_TRIGGER_RELEASE_THRESHOLD = 24;

	struct FXInputButtonMapping
	{
		DWORD Mask;
		EInputKey Key;
	};

	const FXInputButtonMapping ButtonMappings[] =
	{
		{ XINPUT_GAMEPAD_A, IK_Joy1 },
		{ XINPUT_GAMEPAD_B, IK_Joy2 },
		{ XINPUT_GAMEPAD_X, IK_Joy3 },
		{ XINPUT_GAMEPAD_Y, IK_Joy4 },
		{ XINPUT_GAMEPAD_LEFT_SHOULDER, IK_Joy5 },
		{ XINPUT_GAMEPAD_RIGHT_SHOULDER, IK_Joy6 },
		{ XINPUT_GAMEPAD_BACK, IK_Joy7 },
		{ XINPUT_GAMEPAD_START, IK_Joy8 },
		{ XINPUT_GAMEPAD_LEFT_THUMB, IK_Joy9 },
		{ XINPUT_GAMEPAD_RIGHT_THUMB, IK_Joy10 },
		{ XINPUT_RIGHT_TRIGGER_BUTTON, IK_Joy11 },
		{ XINPUT_LEFT_TRIGGER_BUTTON, IK_Joy12 },
		{ XINPUT_GAMEPAD_DPAD_UP, IK_JoyPovUp },
		{ XINPUT_GAMEPAD_DPAD_DOWN, IK_JoyPovDown },
		{ XINPUT_GAMEPAD_DPAD_LEFT, IK_JoyPovLeft },
		{ XINPUT_GAMEPAD_DPAD_RIGHT, IK_JoyPovRight },
	};

	BYTE SDLTriggerToByte(Sint16 Value)
	{
		return static_cast<BYTE>(Clamp<INT>(Value, 0, 32767) * 255 / 32767);
	}

	SHORT InvertSDLAxis(Sint16 Value)
	{
		return Value == -32768 ? 32767 : static_cast<SHORT>(-Value);
	}
}

FXInputController::FXInputController()
	: Module(NULL)
	, GetState(NULL)
	, Gamepad(NULL)
	, SDLInitialized(FALSE)
	, SDLControllerIndex(INDEX_NONE)
	, ActiveControllerIndex(INDEX_NONE)
	, SDLLastScanTime(GetTickCount() - 1000)
	, LastScanTime(GetTickCount() - 1000)
	, PreviousButtons(0)
	, LastPollTime()
{
}

FXInputController::~FXInputController()
{
	Shutdown();
}

UBOOL FXInputController::Initialize()
{
	if (SDLInitialized || Module)
		return TRUE;

	if (SDL_InitSubSystem(SDL_INIT_GAMEPAD))
	{
		SDLInitialized = TRUE;
		debugf(NAME_Init, TEXT("XInputWinDrv initialized SDL %hs gamepad backend"), SDL_GetRevision());
	}
	else
	{
		debugf(NAME_Init, TEXT("XInputWinDrv could not initialize SDL gamepad backend: %hs"), SDL_GetError());
	}

	const WCHAR* Libraries[] = { L"xinput1_4.dll", L"xinput9_1_0.dll" };
	for (INT Index = 0; Index < ARRAY_COUNT(Libraries); Index++)
	{
		Module = LoadLibraryExW(Libraries[Index], NULL, LOAD_LIBRARY_SEARCH_SYSTEM32);
		if (Module)
		{
			GetState = reinterpret_cast<XInputGetStateProc>(GetProcAddress(Module, "XInputGetState"));
			if (GetState)
			{
				debugf(NAME_Init, TEXT("XInputWinDrv loaded %ls fallback"), Libraries[Index]);
				return TRUE;
			}
			FreeLibrary(Module);
			Module = NULL;
		}
	}

	debugf(NAME_Init, TEXT("XInputWinDrv could not load a system XInput fallback"));
	return SDLInitialized;
}

void FXInputController::Shutdown()
{
	ResetState();
	CloseSDLGamepad();
	if (SDLInitialized)
	{
		SDL_QuitSubSystem(SDL_INIT_GAMEPAD);
		SDLInitialized = FALSE;
	}
	GetState = NULL;
	if (Module)
	{
		FreeLibrary(Module);
		Module = NULL;
	}
}

void FXInputController::ResetState()
{
	PreviousButtons = 0;
	LastPollTime = FTime();
}

void FXInputController::CloseSDLGamepad()
{
	if (Gamepad)
	{
		SDL_CloseGamepad(Gamepad);
		Gamepad = NULL;
	}
}

UBOOL FXInputController::ReadSDLState(INT ConfiguredIndex, FControllerState& State)
{
	if (!SDLInitialized)
		return FALSE;

	SDL_UpdateGamepads();
	if (Gamepad && !SDL_GamepadConnected(Gamepad))
	{
		debugf(NAME_Init, TEXT("XInputWinDrv disconnected SDL gamepad %i"), SDLControllerIndex);
		CloseSDLGamepad();
		SDLControllerIndex = INDEX_NONE;
		SDLLastScanTime = GetTickCount();
		LastPollTime = FTime();
	}

	if (!Gamepad)
	{
		const DWORD CurrentTime = GetTickCount();
		if (CurrentTime - SDLLastScanTime < 1000)
			return FALSE;
		SDLLastScanTime = CurrentTime;

		INT GamepadCount = 0;
		SDL_JoystickID* Gamepads = SDL_GetGamepads(&GamepadCount);
		const INT SelectedIndex = ConfiguredIndex >= 0 ? ConfiguredIndex : 0;
		if (Gamepads && SelectedIndex < GamepadCount)
		{
			Gamepad = SDL_OpenGamepad(Gamepads[SelectedIndex]);
			if (Gamepad)
			{
				SDLControllerIndex = SelectedIndex;
				debugf(NAME_Init, TEXT("XInputWinDrv connected SDL gamepad %i: %hs"),
					SelectedIndex, SDL_GetGamepadName(Gamepad));
			}
		}
		SDL_free(Gamepads);
		if (!Gamepad)
			return FALSE;
	}

	auto AddButton = [&](SDL_GamepadButton Button, DWORD Mask)
	{
		if (SDL_GetGamepadButton(Gamepad, Button))
			State.Buttons |= Mask;
	};
	AddButton(SDL_GAMEPAD_BUTTON_SOUTH, XINPUT_GAMEPAD_A);
	AddButton(SDL_GAMEPAD_BUTTON_EAST, XINPUT_GAMEPAD_B);
	AddButton(SDL_GAMEPAD_BUTTON_WEST, XINPUT_GAMEPAD_X);
	AddButton(SDL_GAMEPAD_BUTTON_NORTH, XINPUT_GAMEPAD_Y);
	AddButton(SDL_GAMEPAD_BUTTON_LEFT_SHOULDER, XINPUT_GAMEPAD_LEFT_SHOULDER);
	AddButton(SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER, XINPUT_GAMEPAD_RIGHT_SHOULDER);
	AddButton(SDL_GAMEPAD_BUTTON_BACK, XINPUT_GAMEPAD_BACK);
	AddButton(SDL_GAMEPAD_BUTTON_START, XINPUT_GAMEPAD_START);
	AddButton(SDL_GAMEPAD_BUTTON_LEFT_STICK, XINPUT_GAMEPAD_LEFT_THUMB);
	AddButton(SDL_GAMEPAD_BUTTON_RIGHT_STICK, XINPUT_GAMEPAD_RIGHT_THUMB);
	AddButton(SDL_GAMEPAD_BUTTON_DPAD_UP, XINPUT_GAMEPAD_DPAD_UP);
	AddButton(SDL_GAMEPAD_BUTTON_DPAD_DOWN, XINPUT_GAMEPAD_DPAD_DOWN);
	AddButton(SDL_GAMEPAD_BUTTON_DPAD_LEFT, XINPUT_GAMEPAD_DPAD_LEFT);
	AddButton(SDL_GAMEPAD_BUTTON_DPAD_RIGHT, XINPUT_GAMEPAD_DPAD_RIGHT);

	State.LeftTrigger = SDLTriggerToByte(SDL_GetGamepadAxis(Gamepad, SDL_GAMEPAD_AXIS_LEFT_TRIGGER));
	State.RightTrigger = SDLTriggerToByte(SDL_GetGamepadAxis(Gamepad, SDL_GAMEPAD_AXIS_RIGHT_TRIGGER));
	State.LeftX = SDL_GetGamepadAxis(Gamepad, SDL_GAMEPAD_AXIS_LEFTX);
	State.LeftY = InvertSDLAxis(SDL_GetGamepadAxis(Gamepad, SDL_GAMEPAD_AXIS_LEFTY));
	State.RightX = SDL_GetGamepadAxis(Gamepad, SDL_GAMEPAD_AXIS_RIGHTX);
	State.RightY = InvertSDLAxis(SDL_GetGamepadAxis(Gamepad, SDL_GAMEPAD_AXIS_RIGHTY));
	return TRUE;
}

UBOOL FXInputController::ReadXInputState(INT ConfiguredIndex, FControllerState& State)
{
	if (!GetState)
		return FALSE;

	XINPUT_STATE XInputState;
	appMemzero(&XInputState, sizeof(XInputState));

	if (ConfiguredIndex >= 0 && ConfiguredIndex < XUSER_MAX_COUNT)
	{
		if (GetState(ConfiguredIndex, &XInputState) == ERROR_SUCCESS)
		{
			if (ActiveControllerIndex != ConfiguredIndex)
				debugf(NAME_Init, TEXT("XInputWinDrv connected controller slot %i"), ConfiguredIndex);
			ActiveControllerIndex = ConfiguredIndex;
			goto CopyState;
		}
		if (ActiveControllerIndex != INDEX_NONE)
			debugf(NAME_Init, TEXT("XInputWinDrv disconnected controller slot %i"), ActiveControllerIndex);
		ActiveControllerIndex = INDEX_NONE;
		LastPollTime = FTime();
		return FALSE;
	}

	if (ActiveControllerIndex != INDEX_NONE)
	{
		if (GetState(ActiveControllerIndex, &XInputState) == ERROR_SUCCESS)
			goto CopyState;
		debugf(NAME_Init, TEXT("XInputWinDrv disconnected controller slot %i"), ActiveControllerIndex);
		ActiveControllerIndex = INDEX_NONE;
		LastScanTime = GetTickCount();
		LastPollTime = FTime();
	}

	const DWORD CurrentTime = GetTickCount();
	if (CurrentTime - LastScanTime < 1000)
		return FALSE;
	LastScanTime = CurrentTime;

	for (DWORD Index = 0; Index < XUSER_MAX_COUNT; Index++)
	{
		if (GetState(Index, &XInputState) == ERROR_SUCCESS)
		{
			ActiveControllerIndex = static_cast<INT>(Index);
			debugf(NAME_Init, TEXT("XInputWinDrv connected controller slot %i"), ActiveControllerIndex);
			goto CopyState;
		}
	}
	return FALSE;

CopyState:
	State.Buttons = XInputState.Gamepad.wButtons;
	State.LeftTrigger = XInputState.Gamepad.bLeftTrigger;
	State.RightTrigger = XInputState.Gamepad.bRightTrigger;
	State.LeftX = XInputState.Gamepad.sThumbLX;
	State.LeftY = XInputState.Gamepad.sThumbLY;
	State.RightX = XInputState.Gamepad.sThumbRX;
	State.RightY = XInputState.Gamepad.sThumbRY;
	return TRUE;
}

UBOOL FXInputController::ReadState(INT ConfiguredIndex, FControllerState& State)
{
	appMemzero(&State, sizeof(State));
	if (ReadSDLState(ConfiguredIndex, State))
		return TRUE;

	return ReadXInputState(ConfiguredIndex, State);
}

void FXInputController::EmitButtons(UWindowsViewport* Viewport, DWORD Buttons, BYTE* Processed)
{
	for (INT Index = 0; Index < ARRAY_COUNT(ButtonMappings); Index++)
	{
		const FXInputButtonMapping& Mapping = ButtonMappings[Index];
		const UBOOL WasPressed = (PreviousButtons & Mapping.Mask) != 0;
		const UBOOL IsPressed = (Buttons & Mapping.Mask) != 0;
		if (IsPressed != WasPressed)
			Viewport->CauseInputEvent(Mapping.Key, IsPressed ? IST_Press : IST_Release);
		Processed[Mapping.Key] = 1;
	}
	PreviousButtons = Buttons;
}

void FXInputController::NormalizeStick(SHORT X, SHORT Y, SHORT DeadZone, FLOAT& OutX, FLOAT& OutY)
{
	const FLOAT NormalizedX = X < 0 ? static_cast<FLOAT>(X) / 32768.0f : static_cast<FLOAT>(X) / 32767.0f;
	const FLOAT NormalizedY = Y < 0 ? static_cast<FLOAT>(Y) / 32768.0f : static_cast<FLOAT>(Y) / 32767.0f;
	FLOAT Magnitude = std::sqrt(NormalizedX * NormalizedX + NormalizedY * NormalizedY);
	if (Magnitude > 1.0f)
		Magnitude = 1.0f;

	const FLOAT NormalizedDeadZone = static_cast<FLOAT>(DeadZone) / 32767.0f;
	if (Magnitude <= NormalizedDeadZone || Magnitude == 0.0f)
	{
		OutX = 0.0f;
		OutY = 0.0f;
		return;
	}

	const FLOAT ScaledMagnitude = (Magnitude - NormalizedDeadZone) / (1.0f - NormalizedDeadZone);
	const FLOAT Scale = ScaledMagnitude / Magnitude;
	OutX = NormalizedX * Scale;
	OutY = NormalizedY * Scale;
}

UBOOL FXInputController::Poll(UWindowsViewport* Viewport, UWindowsClient* Client, BYTE* Processed)
{
	const FTime CurrentPollTime = appSeconds();
	const FLOAT StickFrameScale = LastPollTime != FTime()
		? Min((CurrentPollTime - LastPollTime) * 60.0f, 6.0f)
		: 1.0f;
	LastPollTime = CurrentPollTime;

	FControllerState State;
	if (!ReadState(Client->XInputControllerIndex, State))
	{
		EmitButtons(Viewport, 0, Processed);
		Viewport->CauseInputEvent(IK_JoyX, IST_Axis, 0.0f);
		Viewport->CauseInputEvent(IK_JoyY, IST_Axis, 0.0f);
		Viewport->CauseInputEvent(IK_JoyZ, IST_Axis, 0.0f);
		Viewport->CauseInputEvent(IK_JoyR, IST_Axis, 0.0f);
		Viewport->CauseInputEvent(IK_JoyU, IST_Axis, 0.0f);
		Viewport->CauseInputEvent(IK_JoyV, IST_Axis, 0.0f);
		return FALSE;
	}

	DWORD Buttons = State.Buttons;
	const UBOOL LeftTriggerPressed = (PreviousButtons & XINPUT_LEFT_TRIGGER_BUTTON)
		? State.LeftTrigger >= XINPUT_TRIGGER_RELEASE_THRESHOLD
		: State.LeftTrigger >= XINPUT_GAMEPAD_TRIGGER_THRESHOLD;
	const UBOOL RightTriggerPressed = (PreviousButtons & XINPUT_RIGHT_TRIGGER_BUTTON)
		? State.RightTrigger >= XINPUT_TRIGGER_RELEASE_THRESHOLD
		: State.RightTrigger >= XINPUT_GAMEPAD_TRIGGER_THRESHOLD;
	if (LeftTriggerPressed)
		Buttons |= XINPUT_LEFT_TRIGGER_BUTTON;
	if (RightTriggerPressed)
		Buttons |= XINPUT_RIGHT_TRIGGER_BUTTON;
	EmitButtons(Viewport, Buttons, Processed);

	FLOAT LeftX, LeftY, RightX, RightY;
	const SHORT LeftDeadZone = static_cast<SHORT>(Clamp(Client->LeftStickDeadZonePercent, 0.0f, 50.0f) * 32767.0f / 100.0f);
	const SHORT RightDeadZone = static_cast<SHORT>(Clamp(Client->RightStickDeadZonePercent, 0.0f, 50.0f) * 32767.0f / 100.0f);
	NormalizeStick(State.LeftX, State.LeftY,
		Client->DeadZoneXYZ ? LeftDeadZone : 0, LeftX, LeftY);
	NormalizeStick(State.RightX, State.RightY,
		Client->DeadZoneRUV ? RightDeadZone : 0, RightX, RightY);

	Viewport->CauseInputEvent(IK_JoyX, IST_Axis, Client->ScaleXYZ * LeftX * std::fabs(LeftX) * StickFrameScale);
	Viewport->CauseInputEvent(IK_JoyY, IST_Axis, Client->ScaleXYZ * LeftY * std::fabs(LeftY) * StickFrameScale);
	Viewport->CauseInputEvent(IK_JoyZ, IST_Axis, Client->ScaleXYZ * LeftX);
	Viewport->CauseInputEvent(IK_JoyR, IST_Axis, Client->ScaleXYZ * LeftY);
	Viewport->CauseInputEvent(IK_JoyU, IST_Axis, Client->ScaleRUV * RightX * std::fabs(RightX) * StickFrameScale);
	Viewport->CauseInputEvent(IK_JoyV, IST_Axis, Client->ScaleRUV * RightY * std::fabs(RightY) * StickFrameScale * (Client->InvertVertical ? -1.0f : 1.0f));
	return TRUE;
}
