#ifndef _INC_XINPUTCONTROLLER
#define _INC_XINPUTCONTROLLER

#include <xinput.h>

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

	HMODULE Module;
	XInputGetStateProc GetState;
	INT ActiveControllerIndex;
	DWORD LastScanTime;
	DWORD PreviousButtons;
	FTime LastPollTime;

	UBOOL ReadState(INT ConfiguredIndex, XINPUT_STATE& State);
	void EmitButtons(UWindowsViewport* Viewport, DWORD Buttons, BYTE* Processed);
	static void NormalizeStick(SHORT X, SHORT Y, SHORT DeadZone, FLOAT& OutX, FLOAT& OutY);
};

#endif