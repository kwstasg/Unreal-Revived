// Exercise the production input lifecycle with a deterministic OpenXR runtime.
#define XR_NO_PROTOTYPES
#include "../OpenXRControllers.h"
#include <cstdlib>
#include <iostream>

namespace {
int SyncCount = 0, AttachCount = 0, DestroyedSpaces = 0, DestroyedSets = 0;
int ActionCount = 0, FailAction = 0;
bool Active = true, PositionValid = true;
XrResult SyncResult = XR_SUCCESS;
uintptr_t NextHandle = 10;
template<typename T> T Handle() { return (T)(++NextHandle); }
void Check(bool passed, const char* message) {
	if (!passed) { std::cerr << message << '\n'; std::exit(1); }
}
XrResult XRAPI_PTR StringToPath(XrInstance, const char*, XrPath* path) { *path = ++NextHandle; return XR_SUCCESS; }
XrResult XRAPI_PTR CreateActionSet(XrInstance, const XrActionSetCreateInfo*, XrActionSet* set) { *set = Handle<XrActionSet>(); return XR_SUCCESS; }
XrResult XRAPI_PTR DestroyActionSet(XrActionSet) { ++DestroyedSets; return XR_SUCCESS; }
XrResult XRAPI_PTR CreateAction(XrActionSet, const XrActionCreateInfo*, XrAction* action) {
	if (++ActionCount == FailAction) return XR_ERROR_RUNTIME_FAILURE;
	*action = Handle<XrAction>(); return XR_SUCCESS;
}
XrResult XRAPI_PTR SuggestInteractionProfileBindings(XrInstance, const XrInteractionProfileSuggestedBinding* info) {
	Check(info->countSuggestedBindings == 17, "complete Touch binding table"); return XR_SUCCESS;
}
XrResult XRAPI_PTR AttachSessionActionSets(XrSession, const XrSessionActionSetsAttachInfo*) { ++AttachCount; return XR_SUCCESS; }
XrResult XRAPI_PTR CreateActionSpace(XrSession, const XrActionSpaceCreateInfo*, XrSpace* space) { *space = Handle<XrSpace>(); return XR_SUCCESS; }
XrResult XRAPI_PTR DestroySpace(XrSpace) { ++DestroyedSpaces; return XR_SUCCESS; }
XrResult XRAPI_PTR SyncActions(XrSession, const XrActionsSyncInfo*) { ++SyncCount; return SyncResult; }
XrResult XRAPI_PTR GetActionStatePose(XrSession, const XrActionStateGetInfo*, XrActionStatePose* state) { state->isActive = Active; return XR_SUCCESS; }
XrResult XRAPI_PTR GetActionStateBoolean(XrSession, const XrActionStateGetInfo*, XrActionStateBoolean* state) {
	state->isActive = Active; state->currentState = true; return XR_SUCCESS;
}
XrResult XRAPI_PTR GetActionStateFloat(XrSession, const XrActionStateGetInfo*, XrActionStateFloat* state) {
	state->isActive = Active; state->currentState = 0.8f; return XR_SUCCESS;
}
XrResult XRAPI_PTR GetActionStateVector2f(XrSession, const XrActionStateGetInfo*, XrActionStateVector2f* state) {
	state->isActive = Active; state->currentState = {0.4f, -0.6f}; return XR_SUCCESS;
}
XrResult XRAPI_PTR LocateSpace(XrSpace, XrSpace, XrTime, XrSpaceLocation* location) {
	location->locationFlags = XR_SPACE_LOCATION_ORIENTATION_VALID_BIT |
		(PositionValid ? XR_SPACE_LOCATION_POSITION_VALID_BIT : 0);
	location->pose.orientation.w = 1;
	location->pose.position = {1,2,3}; return XR_SUCCESS;
}
XrResult XRAPI_PTR Resolve(XrInstance, const char* name, PFN_xrVoidFunction* output) {
#define FUNCTION(f) if (std::strcmp(name, "xr" #f) == 0) { *output = reinterpret_cast<PFN_xrVoidFunction>(f); return XR_SUCCESS; }
	FUNCTION(StringToPath) FUNCTION(CreateActionSet) FUNCTION(DestroyActionSet)
	FUNCTION(CreateAction) FUNCTION(SuggestInteractionProfileBindings) FUNCTION(AttachSessionActionSets)
	FUNCTION(CreateActionSpace) FUNCTION(DestroySpace) FUNCTION(SyncActions)
	FUNCTION(GetActionStatePose) FUNCTION(GetActionStateBoolean) FUNCTION(GetActionStateFloat)
	FUNCTION(GetActionStateVector2f) FUNCTION(LocateSpace)
#undef FUNCTION
	return XR_ERROR_FUNCTION_UNSUPPORTED;
}
}

int main() {
	OpenXRControllers input;
	const auto instance = Handle<XrInstance>();
	const auto session = Handle<XrSession>();
	const auto space = Handle<XrSpace>();
	input.Update(space, 1, true);
	Check(SyncCount == 0, "uninitialized input must not call the runtime");
	Check(input.Initialize(instance, session, Resolve), "Touch input initialization");
	Check(AttachCount == 1, "attach action sets once per session");
	input.Update(space, 1, false);
	Check(SyncCount == 0 && !input.Hands[0].Valid, "inactive VR must not synchronize controller actions");
	Active = false;
	input.Update(space, 2, true);
	Check(!input.Hands[0].Valid && input.Hands[0].Trigger == 0, "disconnected controllers stay neutral");
	Active = true;
	input.Update(space, 3, true);
	Check(input.Hands[0].Valid && input.Hands[1].Valid, "both tracked hands available");
	Check(input.Hands[0].Trigger == 0.8f && input.Hands[1].Stick.y == -0.6f, "input values read from actions");
	SyncResult = XR_SESSION_NOT_FOCUSED;
	input.Update(space, 4, true);
	Check(!input.Hands[0].Valid && input.Hands[1].Trigger == 0, "positive not-focused result releases input");
	SyncResult = XR_SUCCESS;
	input.Update(space, 5, true);
	PositionValid = false;
	input.Update(space, 6, true);
	Check(!input.Hands[0].Valid && input.Hands[0].Connected && input.Hands[0].Primary,
		"invalid positional tracking disables hand aim but preserves gaze-mode gamepad input");
	PositionValid = true;
	input.Update(space, 7, true);
	input.Update(space, 8, false);
	Check(!input.Hands[0].Valid && !input.Hands[0].Connected && input.Hands[0].Trigger == 0, "unfocused VR clears held inputs");
	input.Release();
	input.Release();
	Check(DestroyedSpaces == 4 && DestroyedSets == 1 && !input.Ready, "teardown is complete and idempotent");
	ActionCount = 0; FailAction = 3;
	Check(!input.Initialize(instance, session, Resolve), "partial initialization failure is reported");
	input.Release();
	Check(DestroyedSets == 2 && AttachCount == 1, "partial failure releases its action set without attaching");
	std::cout << "OpenXR controller lifecycle tests passed\n";
}
