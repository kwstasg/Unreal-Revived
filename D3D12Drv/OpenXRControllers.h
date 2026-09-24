// Unreal Revived - optional OpenXR controller input, independent of head tracking.
#pragma once

#include <openxr/openxr.h>
#include <cstring>
#include <vector>
#include <string>
#include <algorithm>
#include <cmath>

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
		bool Primary = false, Secondary = false, Click = false, Menu = false, View = false;
	};
	HandState Hands[2]; // left, right
	bool Ready = false;

	enum class Layout { Touch, Index, Wand, Simple, Mixed, DigitalTouch, BothMenuTouch };
	struct Profile { const char* Path; const char* Extension; Layout Controls; };
	static const std::vector<Profile>& Profiles()
	{
		static const std::vector<Profile> Entries = {
			{"/interaction_profiles/oculus/touch_controller", nullptr, Layout::Touch},
			{"/interaction_profiles/valve/index_controller", nullptr, Layout::Index},
			{"/interaction_profiles/htc/vive_controller", nullptr, Layout::Wand},
			{"/interaction_profiles/microsoft/motion_controller", nullptr, Layout::Mixed},
			{"/interaction_profiles/khr/simple_controller", nullptr, Layout::Simple},
			{"/interaction_profiles/htc/vive_cosmos_controller", "XR_HTC_vive_cosmos_controller_interaction", Layout::DigitalTouch},
			{"/interaction_profiles/htc/vive_focus3_controller", "XR_HTC_vive_focus3_controller_interaction", Layout::Touch},
			{"/interaction_profiles/hp/mixed_reality_controller", "XR_EXT_hp_mixed_reality_controller", Layout::BothMenuTouch},
			{"/interaction_profiles/facebook/touch_controller_pro", "XR_FB_touch_controller_pro", Layout::Touch},
			{"/interaction_profiles/meta/touch_controller_plus", "XR_META_touch_controller_plus", Layout::Touch}
		};
		return Entries;
	}
	std::vector<std::string> AcceptedProfiles;

	bool Initialize(XrInstance instance, XrSession session, PFN_xrGetInstanceProcAddr resolve,
		const std::vector<const char*>& enabledExtensions = {})
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
		XR_INPUT_FUNCTION(GetCurrentInteractionProfile);
		XR_INPUT_FUNCTION(PathToString);
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
			!Action("menu", XR_ACTION_TYPE_BOOLEAN_INPUT, Menu) ||
			!Action("view", XR_ACTION_TYPE_BOOLEAN_INPUT, View) ||
			!Action("squeeze_click", XR_ACTION_TYPE_BOOLEAN_INPUT, SqueezeClick) ||
			!Action("pad", XR_ACTION_TYPE_VECTOR2F_INPUT, Pad) ||
			!Action("pad_click", XR_ACTION_TYPE_BOOLEAN_INPUT, PadClick) ||
			!Action("pad_touch", XR_ACTION_TYPE_BOOLEAN_INPUT, PadTouch) ||
			!Action("menu_pressure", XR_ACTION_TYPE_FLOAT_INPUT, MenuPressure) ||
			!Action("view_pressure", XR_ACTION_TYPE_FLOAT_INPUT, ViewPressure)) return false;
		AcceptedProfiles.clear();
		for (const auto& profile : Profiles())
		{
			if (profile.Extension && std::none_of(enabledExtensions.begin(), enabledExtensions.end(),
				[&](const char* value) { return std::strcmp(value, profile.Extension) == 0; })) continue;
			if (Suggest(profile)) AcceptedProfiles.push_back(profile.Path);
		}
		// An unsupported optional profile must never disable other controllers.
		if (AcceptedProfiles.empty()) return false;
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

	void Clear() { Hands[0] = {}; Hands[1] = {}; WandGrip[0] = WandGrip[1] = false; WandUsed[0] = WandUsed[1] = false; }

	void Update(XrSpace base, XrTime time, bool active)
	{
		Hands[0] = {}; Hands[1] = {};
		if (!Ready || !active) { Clear(); return; }
		XrActiveActionSet activeSet = {Set, XR_NULL_PATH};
		XrActionsSyncInfo sync = { XR_TYPE_ACTIONS_SYNC_INFO };
		sync.countActiveActionSets = 1;
		sync.activeActionSets = &activeSet;
		// XR_SESSION_NOT_FOCUSED is a positive result, but must not expose input.
		if (SyncActions(Session, &sync) != XR_SUCCESS) { Clear(); return; }
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
			if (!hand.Connected) { WandGrip[i] = WandUsed[i] = false; continue; }
			hand.Trigger = Float(Trigger, i);
			hand.Squeeze = std::max(Float(Squeeze, i), Boolean(SqueezeClick, i) ? 1.0f : 0.0f);
			hand.Primary = Boolean(Primary, i);
			hand.Secondary = Boolean(Secondary, i);
			hand.Click = Boolean(Click, i);
			hand.Menu = Boolean(Menu, i) || Float(MenuPressure, i) > 0.5f;
			hand.View = Boolean(View, i) || Float(ViewPressure, i) > 0.5f;
			XrActionStateGetInfo info = Info(Stick, i);
			XrActionStateVector2f value = { XR_TYPE_ACTION_STATE_VECTOR2F };
			if (XR_SUCCEEDED(GetActionStateVector2f(Session, &info, &value)) && value.isActive)
			{
				hand.Stick = value.currentState;
				WandGrip[i] = WandUsed[i] = false;
			}
			else
			{
				info = Info(Pad, i);
				value = { XR_TYPE_ACTION_STATE_VECTOR2F };
				if (XR_SUCCEEDED(GetActionStateVector2f(Session, &info, &value)) && value.isActive)
				{
					if (Boolean(PadTouch, i)) hand.Stick = value.currentState;
					const bool held = hand.Squeeze > 0.5f;
					if (held)
					{
						WandUsed[i] |= hand.Menu || hand.Secondary;
						hand.Stick = {};
						if (Boolean(PadClick, i))
						{
							WandUsed[i] = true;
							hand.Primary = value.currentState.y > 0.35f;
							hand.Secondary |= value.currentState.y < -0.35f;
							hand.Click = std::abs(value.currentState.y) <= 0.35f && std::abs(value.currentState.x) <= 0.35f;
						}
						// Shoulder fires on release only if this was not a modifier chord.
						hand.Squeeze = 0;
					}
					else
					{
						hand.Squeeze = WandGrip[i] && !WandUsed[i] ? 1.0f : 0.0f;
						WandUsed[i] = false;
					}
					WandGrip[i] = held;
				}
			}
		}
	}

	std::string ProfileName(int hand)
	{
		if (!Ready || hand < 0 || hand > 1) return "unavailable";
		XrInteractionProfileState state = { XR_TYPE_INTERACTION_PROFILE_STATE };
		if (XR_FAILED(GetCurrentInteractionProfile(Session, Paths[hand], &state)) || !state.interactionProfile)
			return "unbound";
		char name[XR_MAX_PATH_LENGTH] = {};
		uint32_t count = 0;
		if (XR_FAILED(PathToString(Instance,state.interactionProfile,sizeof(name),&count,name))) return "unavailable";
		return name;
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
	XrAction Primary = {}, Secondary = {}, Click = {}, Menu = {}, View = {};
	XrAction SqueezeClick = {}, Pad = {}, PadClick = {}, PadTouch = {}, MenuPressure = {}, ViewPressure = {};
	bool WandGrip[2] = {}, WandUsed[2] = {};
	bool Suggest(const Profile& profile)
	{
		std::vector<XrActionSuggestedBinding> bindings;
		auto bind = [&](XrAction action, int hand, const char* suffix) {
			XrPath path = XR_NULL_PATH;
			const std::string name = std::string(hand ? "/user/hand/right/input/" : "/user/hand/left/input/") + suffix;
			if (!Path(name.c_str(), path)) return false;
			bindings.push_back({action, path});
			return true;
		};
		const auto layout = profile.Controls;
		for (int hand = 0; hand < 2; ++hand)
		{
			if (!bind(Aim,hand,"aim/pose") || !bind(Grip,hand,"grip/pose")) return false;
			if (layout == Layout::Simple)
			{
				if (!bind(Primary,hand,"select/click") || !bind(Menu,hand,"menu/click")) return false;
				continue;
			}
			if (!bind(Trigger,hand,"trigger/value")) return false;
			const bool digital = layout == Layout::Wand || layout == Layout::Mixed || layout == Layout::DigitalTouch;
			if (!bind(digital ? SqueezeClick : Squeeze, hand, digital ? "squeeze/click" : "squeeze/value")) return false;
			if (layout == Layout::Wand)
			{
				if (!bind(Pad,hand,"trackpad") || !bind(PadClick,hand,"trackpad/click") ||
					!bind(PadTouch,hand,"trackpad/touch") || !bind(hand ? Secondary : Menu,hand,"menu/click")) return false;
				continue;
			}
			if (!bind(Stick,hand,"thumbstick") || !bind(Click,hand,"thumbstick/click")) return false;
			if (layout == Layout::Mixed)
			{
				if (!bind(Primary,hand,"trackpad/click") || !bind(hand ? Secondary : Menu,hand,"menu/click")) return false;
				continue;
			}
			if (!bind(Primary,hand,hand || layout == Layout::Index ? "a/click" : "x/click") ||
				!bind(Secondary,hand,hand || layout == Layout::Index ? "b/click" : "y/click")) return false;
			if (layout == Layout::Index)
			{
				if (!bind(hand ? ViewPressure : MenuPressure,hand,"trackpad/force")) return false;
			}
			else if (!hand || layout == Layout::BothMenuTouch)
			{
				if (!bind(hand ? View : Menu,hand,"menu/click")) return false;
			}
		}
		XrInteractionProfileSuggestedBinding info = { XR_TYPE_INTERACTION_PROFILE_SUGGESTED_BINDING };
		if (!Path(profile.Path,info.interactionProfile)) return false;
		info.countSuggestedBindings = static_cast<uint32_t>(bindings.size());
		info.suggestedBindings = bindings.data();
		return XR_SUCCEEDED(SuggestInteractionProfileBindings(Instance,&info));
	}
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
	XR_INPUT_MEMBER(GetCurrentInteractionProfile);
	XR_INPUT_MEMBER(PathToString);
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
