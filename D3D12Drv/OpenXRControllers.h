// Unreal Revived - optional OpenXR Touch input, independent of head tracking.
#pragma once

#include <openxr/openxr.h>
#include <cstring>
#include <vector>

class OpenXRControllers
{
public:
	struct HandState
	{
		XrPosef Aim = {};
		XrPosef Grip = {};
		bool Valid = false;
		bool Connected = false;
		XrVector2f Stick = {};
		float Trigger = 0;
		float Squeeze = 0;
		bool Primary = false, Secondary = false, Click = false, Menu = false;
	};
	HandState Hands[2]; // left, right
	bool Ready = false;

	bool Initialize(XrInstance instance, XrSession session, PFN_xrGetInstanceProcAddr resolve)
	{
		Instance = instance;
		Session = session;
#define XR_INPUT_FUNCTION(name) \
		if (XR_FAILED(resolve(instance, "xr" #name, reinterpret_cast<PFN_xrVoidFunction*>(&name))) || !name) return false
		XR_INPUT_FUNCTION(StringToPath);
		XR_INPUT_FUNCTION(CreateActionSet);
		XR_INPUT_FUNCTION(DestroyActionSet);
		XR_INPUT_FUNCTION(CreateAction);
		XR_INPUT_FUNCTION(SuggestInteractionProfileBindings);
		XR_INPUT_FUNCTION(AttachSessionActionSets);
		XR_INPUT_FUNCTION(CreateActionSpace);
		XR_INPUT_FUNCTION(DestroySpace);
		XR_INPUT_FUNCTION(SyncActions);
		XR_INPUT_FUNCTION(GetActionStatePose);
		XR_INPUT_FUNCTION(GetActionStateBoolean);
		XR_INPUT_FUNCTION(GetActionStateFloat);
		XR_INPUT_FUNCTION(GetActionStateVector2f);
		XR_INPUT_FUNCTION(LocateSpace);
#undef XR_INPUT_FUNCTION
		if (!Path("/user/hand/left", Paths[0]) || !Path("/user/hand/right", Paths[1])) return false;
		XrActionSetCreateInfo set = { XR_TYPE_ACTION_SET_CREATE_INFO };
		std::strcpy(set.actionSetName, "revived_motion");
		std::strcpy(set.localizedActionSetName, "Unreal Revived motion controls");
		if (XR_FAILED(CreateActionSet(instance, &set, &Set))) return false;
		if (!Action("aim", XR_ACTION_TYPE_POSE_INPUT, Aim) ||
			!Action("grip", XR_ACTION_TYPE_POSE_INPUT, Grip) ||
			!Action("stick", XR_ACTION_TYPE_VECTOR2F_INPUT, Stick) ||
			!Action("trigger", XR_ACTION_TYPE_FLOAT_INPUT, Trigger) ||
			!Action("squeeze", XR_ACTION_TYPE_FLOAT_INPUT, Squeeze) ||
			!Action("primary", XR_ACTION_TYPE_BOOLEAN_INPUT, Primary) ||
			!Action("secondary", XR_ACTION_TYPE_BOOLEAN_INPUT, Secondary) ||
			!Action("stick_click", XR_ACTION_TYPE_BOOLEAN_INPUT, Click) ||
			!Action("menu", XR_ACTION_TYPE_BOOLEAN_INPUT, Menu)) return false;
		std::vector<XrActionSuggestedBinding> bindings;
		auto Bind = [&](XrAction action, const char* path) -> bool {
			XrPath p;
			if (!Path(path, p)) return false;
			bindings.push_back({action, p});
			return true;
		};
#define BIND(action, path) if (!Bind(action, path)) return false
		BIND(Aim, "/user/hand/left/input/aim/pose");
		BIND(Aim, "/user/hand/right/input/aim/pose");
		BIND(Grip, "/user/hand/left/input/grip/pose");
		BIND(Grip, "/user/hand/right/input/grip/pose");
		BIND(Stick, "/user/hand/left/input/thumbstick");
		BIND(Stick, "/user/hand/right/input/thumbstick");
		BIND(Trigger, "/user/hand/left/input/trigger/value");
		BIND(Trigger, "/user/hand/right/input/trigger/value");
		BIND(Squeeze, "/user/hand/left/input/squeeze/value");
		BIND(Squeeze, "/user/hand/right/input/squeeze/value");
		BIND(Primary, "/user/hand/left/input/x/click");
		BIND(Primary, "/user/hand/right/input/a/click");
		BIND(Secondary, "/user/hand/left/input/y/click");
		BIND(Secondary, "/user/hand/right/input/b/click");
		BIND(Click, "/user/hand/left/input/thumbstick/click");
		BIND(Click, "/user/hand/right/input/thumbstick/click");
		BIND(Menu, "/user/hand/left/input/menu/click");
#undef BIND
		XrInteractionProfileSuggestedBinding profile = { XR_TYPE_INTERACTION_PROFILE_SUGGESTED_BINDING };
		if (!Path("/interaction_profiles/oculus/touch_controller", profile.interactionProfile)) return false;
		profile.countSuggestedBindings = static_cast<uint32_t>(bindings.size());
		profile.suggestedBindings = bindings.data();
		if (XR_FAILED(SuggestInteractionProfileBindings(instance, &profile))) return false;
		for (int i = 0; i < 2; ++i)
		{
			XrActionSpaceCreateInfo space = { XR_TYPE_ACTION_SPACE_CREATE_INFO };
			space.subactionPath = Paths[i];
			space.poseInActionSpace.orientation.w = 1;
			space.action = Aim;
			if (XR_FAILED(CreateActionSpace(session, &space, &AimSpaces[i]))) return false;
			space.action = Grip;
			if (XR_FAILED(CreateActionSpace(session, &space, &GripSpaces[i]))) return false;
		}
		XrSessionActionSetsAttachInfo attach = { XR_TYPE_SESSION_ACTION_SETS_ATTACH_INFO };
		attach.countActionSets = 1;
		attach.actionSets = &Set;
		Ready = XR_SUCCEEDED(AttachSessionActionSets(session, &attach));
		return Ready;
	}

	void Clear() { Hands[0] = {}; Hands[1] = {}; }

	void Update(XrSpace base, XrTime time, bool active)
	{
		Clear();
		if (!Ready || !active) return;
		XrActiveActionSet activeSet = {Set, XR_NULL_PATH};
		XrActionsSyncInfo sync = { XR_TYPE_ACTIONS_SYNC_INFO };
		sync.countActiveActionSets = 1;
		sync.activeActionSets = &activeSet;
		// XR_SESSION_NOT_FOCUSED is a positive result, but must not expose input.
		if (SyncActions(Session, &sync) != XR_SUCCESS) return;
		for (int i = 0; i < 2; ++i)
		{
			HandState& hand = Hands[i];
			auto poseInfo = Info(Aim, i);
			XrActionStatePose poseState = { XR_TYPE_ACTION_STATE_POSE };
			hand.Connected = XR_SUCCEEDED(GetActionStatePose(Session, &poseInfo, &poseState)) && poseState.isActive;
			hand.Valid = Pose(Aim, AimSpaces[i], i, base, time, hand.Aim) &&
				Pose(Grip, GripSpaces[i], i, base, time, hand.Grip);
			// Buttons/sticks remain usable as a gamepad in gaze mode even when
			// positional tracking is temporarily invalid.
			if (!hand.Connected) continue;
			hand.Trigger = Float(Trigger, i);
			hand.Squeeze = Float(Squeeze, i);
			hand.Primary = Boolean(Primary, i);
			hand.Secondary = Boolean(Secondary, i);
			hand.Click = Boolean(Click, i);
			hand.Menu = Boolean(Menu, i);
			XrActionStateGetInfo info = Info(Stick, i);
			XrActionStateVector2f value = { XR_TYPE_ACTION_STATE_VECTOR2F };
			if (XR_SUCCEEDED(GetActionStateVector2f(Session, &info, &value)) && value.isActive)
				hand.Stick = value.currentState;
		}
	}

	void Release()
	{
		Clear();
		Ready = false;
		for (int i = 0; i < 2; ++i)
		{
			if (AimSpaces[i] && DestroySpace) DestroySpace(AimSpaces[i]);
			if (GripSpaces[i] && DestroySpace) DestroySpace(GripSpaces[i]);
			AimSpaces[i] = GripSpaces[i] = XR_NULL_HANDLE;
		}
		if (Set && DestroyActionSet) DestroyActionSet(Set);
		Set = XR_NULL_HANDLE;
		Session = XR_NULL_HANDLE;
	}

private:
	XrInstance Instance = XR_NULL_HANDLE;
	XrSession Session = XR_NULL_HANDLE;
	XrActionSet Set = XR_NULL_HANDLE;
	XrPath Paths[2] = {};
	XrSpace AimSpaces[2] = {}, GripSpaces[2] = {};
	XrAction Aim = {}, Grip = {}, Stick = {}, Trigger = {}, Squeeze = {};
	XrAction Primary = {}, Secondary = {}, Click = {}, Menu = {};
#define XR_INPUT_MEMBER(name) PFN_xr##name name = nullptr
	XR_INPUT_MEMBER(StringToPath);
	XR_INPUT_MEMBER(CreateActionSet);
	XR_INPUT_MEMBER(DestroyActionSet);
	XR_INPUT_MEMBER(CreateAction);
	XR_INPUT_MEMBER(SuggestInteractionProfileBindings);
	XR_INPUT_MEMBER(AttachSessionActionSets);
	XR_INPUT_MEMBER(CreateActionSpace);
	XR_INPUT_MEMBER(DestroySpace);
	XR_INPUT_MEMBER(SyncActions);
	XR_INPUT_MEMBER(GetActionStatePose);
	XR_INPUT_MEMBER(GetActionStateBoolean);
	XR_INPUT_MEMBER(GetActionStateFloat);
	XR_INPUT_MEMBER(GetActionStateVector2f);
	XR_INPUT_MEMBER(LocateSpace);
#undef XR_INPUT_MEMBER
	bool Path(const char* name, XrPath& path) { return XR_SUCCEEDED(StringToPath(Instance, name, &path)); }
	bool Action(const char* name, XrActionType type, XrAction& action)
	{
		XrActionCreateInfo info = { XR_TYPE_ACTION_CREATE_INFO };
		std::strcpy(info.actionName, name);
		std::strcpy(info.localizedActionName, name);
		info.actionType = type;
		info.countSubactionPaths = 2;
		info.subactionPaths = Paths;
		return XR_SUCCEEDED(CreateAction(Set, &info, &action));
	}
	XrActionStateGetInfo Info(XrAction action, int hand)
	{
		XrActionStateGetInfo info = { XR_TYPE_ACTION_STATE_GET_INFO };
		info.action = action;
		info.subactionPath = Paths[hand];
		return info;
	}
	bool Boolean(XrAction action, int hand)
	{
		auto info = Info(action, hand);
		XrActionStateBoolean state = { XR_TYPE_ACTION_STATE_BOOLEAN };
		return XR_SUCCEEDED(GetActionStateBoolean(Session, &info, &state)) && state.isActive && state.currentState;
	}
	float Float(XrAction action, int hand)
	{
		auto info = Info(action, hand);
		XrActionStateFloat state = { XR_TYPE_ACTION_STATE_FLOAT };
		return XR_SUCCEEDED(GetActionStateFloat(Session, &info, &state)) && state.isActive ? state.currentState : 0;
	}
	bool Pose(XrAction action, XrSpace space, int hand, XrSpace base, XrTime time, XrPosef& pose)
	{
		auto info = Info(action, hand);
		XrActionStatePose state = { XR_TYPE_ACTION_STATE_POSE };
		if (XR_FAILED(GetActionStatePose(Session, &info, &state)) || !state.isActive) return false;
		XrSpaceLocation location = { XR_TYPE_SPACE_LOCATION };
		const XrSpaceLocationFlags required = XR_SPACE_LOCATION_POSITION_VALID_BIT | XR_SPACE_LOCATION_ORIENTATION_VALID_BIT;
		if (XR_FAILED(LocateSpace(space, base, time, &location)) || (location.locationFlags & required) != required) return false;
		pose = location.pose;
		return true;
	}
};
