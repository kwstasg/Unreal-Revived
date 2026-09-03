#ifndef _INC_XINPUTCONTROLLER
#define _INC_XINPUTCONTROLLER

#include <xinput.h>
#include <SDL3/SDL_gamepad.h>

class UWindowsClient;
class UWindowsViewport;

class FXInputController
{
public:
	FXInputController();
	~FXInputController();

	UBOOL Initialize();
	void Shutdown();
	void ResetState();
	UBOOL Poll(UWindowsViewport* Viewport, UWindowsClient* Client, BYTE* Processed);

private:
	typedef DWORD(WINAPI* XInputGetStateProc)(DWORD UserIndex, XINPUT_STATE* State);

	struct FControllerState
	{
		DWORD Buttons;
		BYTE LeftTrigger;
		BYTE RightTrigger;
		SHORT LeftX;
		SHORT LeftY;
		SHORT RightX;
		SHORT RightY;
	};

	HMODULE Module;
	XInputGetStateProc GetState;
	SDL_Gamepad* Gamepad;
	UBOOL SDLInitialized;
	INT SDLControllerIndex;
	INT ActiveControllerIndex;
	DWORD SDLLastScanTime;
	DWORD LastScanTime;
	DWORD PreviousButtons;
	FTime LastPollTime;

	UBOOL ReadState(INT ConfiguredIndex, FControllerState& State);
	UBOOL ReadSDLState(INT ConfiguredIndex, FControllerState& State);
	UBOOL ReadXInputState(INT ConfiguredIndex, FControllerState& State);
	void CloseSDLGamepad();
	void EmitButtons(UWindowsViewport* Viewport, DWORD Buttons, BYTE* Processed);
	static void NormalizeStick(SHORT X, SHORT Y, SHORT DeadZone, FLOAT& OutX, FLOAT& OutY);
};

#endif