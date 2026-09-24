// Exercise the production input lifecycle with a deterministic OpenXR runtime.
#define XR_NO_PROTOTYPES
#include "../OpenXRControllers.h"
#include <cstdlib>
#include <iostream>
#include <map>
#include <string>
#include <set>

namespace {
int SyncCount = 0, AttachCount = 0, DestroyedSpaces = 0, DestroyedSets = 0;
int ActionCount = 0, FailAction = 0;
bool Active = true, PositionValid = true;
XrResult SyncResult = XR_SUCCESS;
uintptr_t NextHandle = 10;
std::map<XrPath,std::string> PathNames;
std::map<XrAction,std::string> ActionNames;
std::set<std::string> Suggested;
std::string RejectProfile;
bool RejectAll = false, WandMode = false, DigitalGrip = false, PadPressed = false;
XrVector2f PadPosition = {};

template<typename T> T Handle() { return (T)(++NextHandle); }
void Check(bool passed, const char* message) {
	if (!passed) { std::cerr << message << '\n'; std::exit(1); }
}
XrResult XRAPI_PTR StringToPath(XrInstance, const char* name, XrPath* path) { *path = ++NextHandle; PathNames[*path] = name; return XR_SUCCESS; }
XrResult XRAPI_PTR CreateActionSet(XrInstance, const XrActionSetCreateInfo*, XrActionSet* set) { *set = Handle<XrActionSet>(); return XR_SUCCESS; }
XrResult XRAPI_PTR DestroyActionSet(XrActionSet) { ++DestroyedSets; return XR_SUCCESS; }
XrResult XRAPI_PTR CreateAction(XrActionSet, const XrActionCreateInfo* info, XrAction* action) {
	if (++ActionCount == FailAction) return XR_ERROR_RUNTIME_FAILURE;
	*action = Handle<XrAction>(); ActionNames[*action] = info->actionName; return XR_SUCCESS;
}
XrResult XRAPI_PTR SuggestInteractionProfileBindings(XrInstance, const XrInteractionProfileSuggestedBinding* info) {
	const auto& profile = PathNames[info->interactionProfile];
	Suggested.insert(profile);
	if (profile == "/interaction_profiles/oculus/touch_controller")
		Check(info->countSuggestedBindings == 17, "original Touch bindings unchanged");
	for (uint32_t i=0; i<info->countSuggestedBindings; ++i) {
		const auto& binding = info->suggestedBindings[i];
		const auto& path = PathNames[binding.binding];
		Check(path.find("/system/") == std::string::npos, "never depend on system dashboard buttons");
		if (profile == "/interaction_profiles/valve/index_controller") {
			Check(path.find("/x/click") == std::string::npos && path.find("/y/click") == std::string::npos,
				"Index has A/B on both hands, not X/Y");
			if (ActionNames[binding.action] == "menu_pressure")
				Check(path == "/user/hand/left/input/trackpad/force", "Index menu has an application-accessible fallback");
		}
		if (profile == "/interaction_profiles/htc/vive_controller")
			Check(path.find("thumbstick") == std::string::npos && path.find("squeeze/value") == std::string::npos,
				"wands bind pad and digital squeeze paths");
	}
	return RejectAll || profile == RejectProfile ? XR_ERROR_PATH_UNSUPPORTED : XR_SUCCESS;
}
XrResult XRAPI_PTR AttachSessionActionSets(XrSession, const XrSessionActionSetsAttachInfo*) { ++AttachCount; return XR_SUCCESS; }
XrResult XRAPI_PTR CreateActionSpace(XrSession, const XrActionSpaceCreateInfo*, XrSpace* space) { *space = Handle<XrSpace>(); return XR_SUCCESS; }
XrResult XRAPI_PTR DestroySpace(XrSpace) { ++DestroyedSpaces; return XR_SUCCESS; }
XrResult XRAPI_PTR GetCurrentInteractionProfile(XrSession, XrPath, XrInteractionProfileState* state) {
	state->interactionProfile = XR_NULL_PATH; return XR_SUCCESS;
}
XrResult XRAPI_PTR PathToString(XrInstance, XrPath, uint32_t, uint32_t*, char*) { return XR_ERROR_PATH_INVALID; }
XrResult XRAPI_PTR SyncActions(XrSession, const XrActionsSyncInfo*) { ++SyncCount; return SyncResult; }
XrResult XRAPI_PTR GetActionStatePose(XrSession, const XrActionStateGetInfo*, XrActionStatePose* state) { state->isActive = Active; return XR_SUCCESS; }
XrResult XRAPI_PTR GetActionStateBoolean(XrSession, const XrActionStateGetInfo* info, XrActionStateBoolean* state) {
	state->isActive = Active;
	const auto& name = ActionNames[info->action];
	state->currentState = name == "squeeze_click" ? DigitalGrip : name == "pad_click" ? PadPressed :
		name == "pad_touch" ? true : name == "primary" ? !WandMode : false;
	return XR_SUCCESS;
}
XrResult XRAPI_PTR GetActionStateFloat(XrSession, const XrActionStateGetInfo* info, XrActionStateFloat* state) {
	state->isActive = Active; state->currentState = ActionNames[info->action] == "trigger" || (!WandMode && ActionNames[info->action] == "squeeze") ? 0.8f : 0.0f; return XR_SUCCESS;
}
XrResult XRAPI_PTR GetActionStateVector2f(XrSession, const XrActionStateGetInfo* info, XrActionStateVector2f* state) {
	state->isActive = Active && (ActionNames[info->action] == "pad" ? WandMode : !WandMode); state->currentState = WandMode ? PadPosition : XrVector2f{0.4f, -0.6f}; return XR_SUCCESS;
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
	FUNCTION(GetCurrentInteractionProfile) FUNCTION(PathToString)
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
	FailAction = 0; RejectProfile = "/interaction_profiles/oculus/touch_controller";
	Suggested.clear();
	Check(input.Initialize(instance,session,Resolve), "non-Touch runtime retains other profiles");
	Check(Suggested.size() == 5 && input.AcceptedProfiles.size() == 4, "only core profiles suggested without extensions");
	input.Release();
	RejectProfile.clear(); Suggested.clear();
	std::vector<const char*> extensions;
	for (const auto& profile : OpenXRControllers::Profiles()) if (profile.Extension) extensions.push_back(profile.Extension);
	Check(input.Initialize(instance,session,Resolve,extensions), "optional extension profiles initialize");
	Check(input.AcceptedProfiles.size() == OpenXRControllers::Profiles().size(), "all enabled profiles offered");
	WandMode = true; PadPosition = {0,0.8f}; DigitalGrip = false; PadPressed = false;
	input.Update(space,9,true);
	Check(input.Hands[0].Stick.y == 0.8f, "wand pad supplies movement");
	DigitalGrip = true; PadPressed = true;
	input.Update(space,10,true);
	Check(input.Hands[0].Primary && input.Hands[0].Squeeze == 0 && input.Hands[0].Stick.y == 0,
		"wand primary chord does not move or change weapon");
	PadPosition = {0,-0.8f}; input.Update(space,11,true);
	Check(input.Hands[1].Secondary && !input.Hands[1].Primary, "wand secondary chord supplies B/back");
	PadPosition = {0,0}; input.Update(space,12,true);
	Check(input.Hands[1].Click && !input.Hands[1].Secondary, "wand centre chord supplies recenter click");
	DigitalGrip = false; PadPressed = false; input.Update(space,13,true);
	Check(input.Hands[0].Squeeze == 0, "modifier release never changes weapon");
	DigitalGrip = true; input.Update(space,14,true);
	DigitalGrip = false; input.Update(space,15,true);
	Check(input.Hands[0].Squeeze == 1, "unchorded grip release supplies shoulder");
	input.Update(space,16,true); Check(input.Hands[0].Squeeze == 0, "shoulder pulse releases");
	DigitalGrip = true; input.Update(space,17,true); input.Update(space,18,false);
	DigitalGrip = false; input.Update(space,19,true);
	Check(input.Hands[0].Squeeze == 0, "focus loss clears pending wand chord");
	input.Release(); RejectAll = true;
	Check(!input.Initialize(instance,session,Resolve), "no usable binding profile is reported honestly");
	input.Release();
	std::cout << "OpenXR controller lifecycle tests passed\n";
}
