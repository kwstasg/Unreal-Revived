// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived
// Inherited WinDrv source remains the property of Epic Games, Inc.

#include "WinDrv.h"

#include <SDL3/SDL_init.h>
#include <SDL3/SDL_version.h>

#include <cmath>
#include "VRGamepadAxes.h"
#include "VRControllerInput.h"

namespace
{
	// Only transform plain movement-axis bindings. Preserve custom aliases and
	// compound commands instead of silently changing their semantics.
	bool ReadAxisSpeed(const TCHAR* Binding, const TCHAR* Axis, FLOAT& Speed)
	{
		if (appStrchr(Binding, '|') || !ParseCommand(&Binding, TEXT("Axis")) || !ParseCommand(&Binding, Axis))
			return false;
		Speed = 1.0f;
		Parse(Binding, TEXT("Speed="), Speed);
		return std::isfinite(Speed) && std::fabs(Speed) > 0.0001f;
	}

	bool ReadMovementYaw(UWindowsViewport* Viewport, FLOAT& YawRadians, bool& RotateGroundMovement)
	{
		APlayerPawn* Player = Viewport->Actor;
		if (!Player || !Viewport->RenDev || !Viewport->Input || Player->Health <= 0 ||
			Player->bBehindView || Player->ViewTarget || Player->bShowMenu || Player->bFreeLook)
			return false;
		RotateGroundMovement = Player->Physics == PHYS_Walking || Player->Physics == PHYS_Falling;
		const bool CheatFlying = Player->GetStateFrame() && Player->GetStateFrame()->StateNode &&
			Player->GetStateFrame()->StateNode->GetFName() == FName(TEXT("CheatFlying"));
		if (!RotateGroundMovement && Player->Physics != PHYS_Swimming && Player->Physics != PHYS_Flying && !CheatFlying)
			return false;
		// Query cached renderer state only; this does not initialize OpenXR or
		// load its DLL. Flat/recovery renderers return no active pose.
		FStringOutputDevice Pose;
		if (!Viewport->RenDev->Exec(TEXT("D3D12 OPENXRPOSE"), Pose))
			return false;
		const TCHAR* Cursor = *Pose;
		FString Token;
		if (!ParseToken(Cursor, Token, 0) || Token != TEXT("1") ||
			!ParseToken(Cursor, Token, 0) || !ParseToken(Cursor, Token, 0))
			return false;
		// Walking constructs acceleration from body Rotation, while the camera
		// composes headset orientation onto ViewRotation. Account for both bases.
		const DWORD Yaw = static_cast<DWORD>(appAtoi(*Token)) +
			static_cast<DWORD>(Player->ViewRotation.Yaw) - static_cast<DWORD>(Player->Rotation.Yaw);
		YawRadians = static_cast<FLOAT>(Yaw & 65535) * (6.28318530718f / 65536.0f);
		return true;
	}

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

bool SuppressVRMousePitch(UWindowsViewport* Viewport)
{
	if (!Viewport || !Viewport->RenDev || !Viewport->Input || !Viewport->Actor ||
		GIsEditor || Viewport->Actor->bShowMenu || Viewport->Actor->bBehindView || Viewport->Actor->ViewTarget)
		return false;
	FLOAT Speed;
	const TCHAR* Binding = *Viewport->Input->Bindings[IK_MouseY];
	if (!ReadAxisSpeed(Binding, TEXT("aMouseY"), Speed) && !ReadAxisSpeed(Binding, TEXT("aLookUp"), Speed))
		return false;
	FStringOutputDevice Active;
	return Viewport->RenDev->Exec(TEXT("D3D12 VRSTATSACTIVE"), Active) && Active == TEXT("1");
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
	MotionActive = MotionNeutral = MotionFireReady = FALSE;
	MotionAimMode = -1;
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

UBOOL FXInputController::ReadMotionState(UWindowsViewport* Viewport, FControllerState& State, UBOOL& CanAim, INT& AimMode)
{
	if (!Viewport->RenDev) return FALSE;
	FStringOutputDevice Output;
	if (!Viewport->RenDev->Exec(TEXT("D3D12 OPENXRINPUT"), Output)) return FALSE;
	const TCHAR* Cursor = *Output;
	FString Token;
	if (!ParseToken(Cursor, Token, 0) || Token != TEXT("1")) return FALSE;
	INT Values[9] = {};
	for (INT i = 0; i < 9; ++i)
		if (ParseToken(Cursor, Token, 0)) Values[i] = appAtoi(*Token);
		else { State = {}; CanAim = FALSE; return TRUE; }
	CanAim = Values[0] != 0;
	State.Buttons = Values[1];
	State.LeftX = static_cast<SHORT>(Values[2]);
	State.LeftY = static_cast<SHORT>(Values[3]);
	State.RightX = static_cast<SHORT>(Values[4]);
	State.RightY = static_cast<SHORT>(Values[5]);
	State.LeftTrigger = static_cast<BYTE>(Values[6]);
	State.RightTrigger = static_cast<BYTE>(Values[7]);
	AimMode = Values[8];
	return TRUE;
}

UBOOL FXInputController::Poll(UWindowsViewport* Viewport, UWindowsClient* Client, BYTE* Processed)
{
	const FTime CurrentPollTime = appSeconds();
	const FLOAT StickFrameScale = LastPollTime != FTime()
		? Min((CurrentPollTime - LastPollTime) * 60.0f, 6.0f)
		: 1.0f;
	LastPollTime = CurrentPollTime;

	FControllerState State = {};
	UBOOL CanAim = FALSE;
	INT AimMode = -1;
	const UBOOL UseMotion = ReadMotionState(Viewport, State, CanAim, AimMode);
	if (UseMotion != MotionActive || AimMode != MotionAimMode)
	{
		MotionActive = UseMotion;
		MotionAimMode = AimMode;
		MotionNeutral = MotionFireReady = FALSE;
	}
	if (UseMotion)
	{
		// Never carry a held trigger into controller mode or across tracking loss.
		if (!CanAim) MotionFireReady = FALSE;
		if (CanAim && State.LeftTrigger < XINPUT_TRIGGER_RELEASE_THRESHOLD &&
			State.RightTrigger < XINPUT_TRIGGER_RELEASE_THRESHOLD) MotionFireReady = TRUE;
		if (!MotionNeutral && !State.Buttons && State.LeftTrigger < XINPUT_TRIGGER_RELEASE_THRESHOLD &&
			State.RightTrigger < XINPUT_TRIGGER_RELEASE_THRESHOLD &&
			abs(State.LeftX) < 6500 && abs(State.LeftY) < 6500 && abs(State.RightX) < 6500 && abs(State.RightY) < 6500)
			MotionNeutral = TRUE;
		if (!MotionNeutral) State = {};
		if (!MotionFireReady) State.LeftTrigger = State.RightTrigger = 0;
	}
	FControllerState Gamepad = {};
	const UBOOL HasGamepad = ReadState(Client->XInputControllerIndex, Gamepad);
	if (UseMotion) LastPollTime = CurrentPollTime;
	if (HasGamepad) VRControllerInput::Merge(State, Gamepad);
	if (!UseMotion && !HasGamepad)
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

	FLOAT MoveX = Client->ScaleXYZ * LeftX * std::fabs(LeftX) * StickFrameScale;
	FLOAT MoveY = Client->ScaleXYZ * LeftY * std::fabs(LeftY) * StickFrameScale;
	FLOAT YawRadians, StrafeSpeed, ForwardSpeed, LookSpeed;
	bool RotateGroundMovement = false;
	if (ReadMovementYaw(Viewport, YawRadians, RotateGroundMovement))
	{
		// Swimming/flying already compose the full gaze in PlayerMove. Only
		// walking/falling need this horizontal input rotation; never apply both.
		if (RotateGroundMovement && ReadAxisSpeed(*Viewport->Input->Bindings[IK_JoyX], TEXT("aStrafe"), StrafeSpeed) &&
			ReadAxisSpeed(*Viewport->Input->Bindings[IK_JoyY], TEXT("aBaseY"), ForwardSpeed))
		{
			MoveX *= StrafeSpeed;
			MoveY *= ForwardSpeed;
			VRGamepadAxes::Rotate(MoveX, MoveY, YawRadians);
			MoveX /= StrafeSpeed;
			MoveY /= ForwardSpeed;
		}
		// Head pitch supplies vertical view; the right stick turns the body.
		if (ReadAxisSpeed(*Viewport->Input->Bindings[IK_JoyV], TEXT("aLookUp"), LookSpeed))
			RightY = 0.0f;
	}
	Viewport->CauseInputEvent(IK_JoyX, IST_Axis, MoveX);
	Viewport->CauseInputEvent(IK_JoyY, IST_Axis, MoveY);
	Viewport->CauseInputEvent(IK_JoyZ, IST_Axis, Client->ScaleXYZ * LeftX);
	Viewport->CauseInputEvent(IK_JoyR, IST_Axis, Client->ScaleXYZ * LeftY);
	Viewport->CauseInputEvent(IK_JoyU, IST_Axis, Client->ScaleRUV * RightX * std::fabs(RightX) * StickFrameScale);
	Viewport->CauseInputEvent(IK_JoyV, IST_Axis, Client->ScaleRUV * RightY * std::fabs(RightY) * StickFrameScale * (Client->InvertVertical ? -1.0f : 1.0f));
	return TRUE;
}
