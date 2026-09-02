#include "WinDrv.h"

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
}

FXInputController::FXInputController()
	: Module(NULL)
	, GetState(NULL)
	, ActiveControllerIndex(INDEX_NONE)
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
	if (Module)
		return TRUE;

	const WCHAR* Libraries[] = { L"xinput1_4.dll", L"xinput9_1_0.dll" };
	for (INT Index = 0; Index < ARRAY_COUNT(Libraries); Index++)
	{
		Module = LoadLibraryExW(Libraries[Index], NULL, LOAD_LIBRARY_SEARCH_SYSTEM32);
		if (Module)
		{
			GetState = reinterpret_cast<XInputGetStateProc>(GetProcAddress(Module, "XInputGetState"));
			if (GetState)
			{
				debugf(NAME_Init, TEXT("XInputWinDrv loaded %ls"), Libraries[Index]);
				return TRUE;
			}
			FreeLibrary(Module);
			Module = NULL;
		}
	}

	debugf(NAME_Init, TEXT("XInputWinDrv could not load a system XInput library"));
	return FALSE;
}

void FXInputController::Shutdown()
{
	ResetState();
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

UBOOL FXInputController::ReadState(INT ConfiguredIndex, XINPUT_STATE& State)
{
	if (!GetState)
		return FALSE;

	if (ConfiguredIndex >= 0 && ConfiguredIndex < XUSER_MAX_COUNT)
	{
		if (GetState(ConfiguredIndex, &State) == ERROR_SUCCESS)
		{
			if (ActiveControllerIndex != ConfiguredIndex)
				debugf(NAME_Init, TEXT("XInputWinDrv connected controller slot %i"), ConfiguredIndex);
			ActiveControllerIndex = ConfiguredIndex;
			return TRUE;
		}
		if (ActiveControllerIndex != INDEX_NONE)
			debugf(NAME_Init, TEXT("XInputWinDrv disconnected controller slot %i"), ActiveControllerIndex);
		ActiveControllerIndex = INDEX_NONE;
		ResetState();
		return FALSE;
	}

	if (ActiveControllerIndex != INDEX_NONE)
	{
		if (GetState(ActiveControllerIndex, &State) == ERROR_SUCCESS)
			return TRUE;
		debugf(NAME_Init, TEXT("XInputWinDrv disconnected controller slot %i"), ActiveControllerIndex);
		ActiveControllerIndex = INDEX_NONE;
		LastScanTime = GetTickCount();
		ResetState();
	}

	const DWORD CurrentTime = GetTickCount();
	if (CurrentTime - LastScanTime < 1000)
		return FALSE;
	LastScanTime = CurrentTime;

	for (DWORD Index = 0; Index < XUSER_MAX_COUNT; Index++)
	{
		if (GetState(Index, &State) == ERROR_SUCCESS)
		{
			ActiveControllerIndex = static_cast<INT>(Index);
			debugf(NAME_Init, TEXT("XInputWinDrv connected controller slot %i"), ActiveControllerIndex);
			return TRUE;
		}
	}
	return FALSE;
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

	XINPUT_STATE State;
	appMemzero(&State, sizeof(State));
	if (!ReadState(Client->XInputControllerIndex, State))
		return FALSE;

	DWORD Buttons = State.Gamepad.wButtons;
	const UBOOL LeftTriggerPressed = (PreviousButtons & XINPUT_LEFT_TRIGGER_BUTTON)
		? State.Gamepad.bLeftTrigger >= XINPUT_TRIGGER_RELEASE_THRESHOLD
		: State.Gamepad.bLeftTrigger >= XINPUT_GAMEPAD_TRIGGER_THRESHOLD;
	const UBOOL RightTriggerPressed = (PreviousButtons & XINPUT_RIGHT_TRIGGER_BUTTON)
		? State.Gamepad.bRightTrigger >= XINPUT_TRIGGER_RELEASE_THRESHOLD
		: State.Gamepad.bRightTrigger >= XINPUT_GAMEPAD_TRIGGER_THRESHOLD;
	if (LeftTriggerPressed)
		Buttons |= XINPUT_LEFT_TRIGGER_BUTTON;
	if (RightTriggerPressed)
		Buttons |= XINPUT_RIGHT_TRIGGER_BUTTON;
	EmitButtons(Viewport, Buttons, Processed);

	FLOAT LeftX, LeftY, RightX, RightY;
	NormalizeStick(State.Gamepad.sThumbLX, State.Gamepad.sThumbLY,
		Client->DeadZoneXYZ ? XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE : 0, LeftX, LeftY);
	NormalizeStick(State.Gamepad.sThumbRX, State.Gamepad.sThumbRY,
		Client->DeadZoneRUV ? XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE : 0, RightX, RightY);

	Viewport->CauseInputEvent(IK_JoyX, IST_Axis, Client->ScaleXYZ * LeftX);
	Viewport->CauseInputEvent(IK_JoyY, IST_Axis, Client->ScaleXYZ * LeftY);
	Viewport->CauseInputEvent(IK_JoyZ, IST_Axis, Client->ScaleXYZ * LeftX * StickFrameScale);
	Viewport->CauseInputEvent(IK_JoyR, IST_Axis, Client->ScaleXYZ * LeftY * StickFrameScale);
	Viewport->CauseInputEvent(IK_JoyU, IST_Axis, Client->ScaleRUV * RightX * StickFrameScale);
	Viewport->CauseInputEvent(IK_JoyV, IST_Axis, Client->ScaleRUV * RightY * StickFrameScale * (Client->InvertVertical ? -1.0f : 1.0f));
	return TRUE;
}