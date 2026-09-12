// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived

// Applies OpenXR orientation to UE1's authoritative calculated camera before
// the scene is culled. Gameplay aim and the underlying scripted camera remain
// unchanged.

class ModernVRInteraction extends PlayerInteraction;

function bool PopPoseValue(out string Pose, out string Value)
{
	local int Separator;

	Separator = InStr(Pose, " ");
	if (Separator < 0)
		return False;
	Value = Left(Pose, Separator);
	Pose = Mid(Pose, Separator + 1);
	return True;
}

function bool ReadHeadPose(out rotator HeadRotation, out vector EyeOffset, out vector HeadOffset)
{
	local string Pose;
	local string Value;

	Pose = PlayerOwner.ConsoleCommand("D3D12 OPENXRPOSE");
	if (Left(Pose, 1) != "1")
		return False;

	Pose = Mid(Pose, 2);
	if (!PopPoseValue(Pose, Value))
		return False;
	HeadRotation.Pitch = int(Value);
	if (!PopPoseValue(Pose, Value))
		return False;
	HeadRotation.Yaw = int(Value);
	if (!PopPoseValue(Pose, Value))
		return False;
	HeadRotation.Roll = int(Value);
	if (!PopPoseValue(Pose, Value))
		return False;
	EyeOffset.X = float(Value);
	if (!PopPoseValue(Pose, Value))
		return False;
	EyeOffset.Y = float(Value);
	if (!PopPoseValue(Pose, Value))
		return False;
	EyeOffset.Z = float(Value);
	if (!PopPoseValue(Pose, Value))
		return False;
	HeadOffset.X = float(Value);
	if (!PopPoseValue(Pose, Value))
		return False;
	HeadOffset.Y = float(Value);
	HeadOffset.Z = float(Pose);
	return True;
}

function rotator ComposeRotation(rotator BaseRotation, rotator HeadRotation)
{
	local vector BaseX, BaseY, BaseZ;
	local vector HeadX, HeadY, HeadZ;
	local vector NewX, NewY, NewZ;

	GetAxes(BaseRotation, BaseX, BaseY, BaseZ);
	GetAxes(HeadRotation, HeadX, HeadY, HeadZ);
	NewX = BaseX * HeadX.X + BaseY * HeadX.Y + BaseZ * HeadX.Z;
	NewY = BaseX * HeadY.X + BaseY * HeadY.Y + BaseZ * HeadY.Z;
	NewZ = BaseX * HeadZ.X + BaseY * HeadZ.Y + BaseZ * HeadZ.Z;
	return OrthoRotation(NewX, NewY, NewZ);
}

event bool RenderOverlays(Canvas Canvas)
{
	local rotator HeadRotation;
	local rotator AimRotation;
	local rotator SavedViewRotation;
	local vector BaseX, BaseY, BaseZ;
	local vector EyeOffset;
	local vector HeadOffset;
	local vector WorldHeadOffset;
	local vector LocalHeadOffset;
	local vector VRWeaponOffset;
	local vector SavedWeaponViewOffset;
	local float SavedWeaponDrawScale;
	local Weapon RenderWeapon;

	if (PlayerOwner == None || !ReadHeadPose(HeadRotation, EyeOffset, HeadOffset))
		return False;

	// Weapon.RenderOverlays derives its model rotation and draw offset from the
	// player's ViewRotation. Expose headset-composed aim only for this rendering
	// callback, then restore gameplay state before returning.
	SavedViewRotation = PlayerOwner.ViewRotation;
	AimRotation = ComposeRotation(SavedViewRotation, HeadRotation);
	PlayerOwner.ViewRotation = AimRotation;

	// CalcDrawOffset anchors the first-person weapon at Owner.Location. Add the
	// tracked head-center translation to its temporary view offset so the model
	// follows leaning without applying per-eye IPD to the weapon itself.
	RenderWeapon = PlayerOwner.Weapon;
	if (RenderWeapon != None)
	{
		GetAxes(SavedViewRotation, BaseX, BaseY, BaseZ);
		WorldHeadOffset = BaseX * HeadOffset.X + BaseY * HeadOffset.Y + BaseZ * HeadOffset.Z;
		LocalHeadOffset = WorldHeadOffset << AimRotation;
		// Preserve each weapon's authored offset, but place the complete model a
		// little farther forward, lower, and toward the selected hand in VR. This
		// keeps more of the view clear without changing gameplay or muzzle origin.
		VRWeaponOffset.X = 2.7;
		VRWeaponOffset.Y = -PlayerOwner.Handedness * 2.2;
		VRWeaponOffset.Z = -1.7;
		SavedWeaponViewOffset = RenderWeapon.PlayerViewOffset;
		SavedWeaponDrawScale = RenderWeapon.DrawScale;
		RenderWeapon.PlayerViewOffset += (LocalHeadOffset + VRWeaponOffset) * 100.0;
		// First-person models authored for a flat display feel undersized at
		// headset depth. Scale only the temporary VR overlay render.
		RenderWeapon.DrawScale *= 1.15;
	}
	bRenderOverlays = False;
	PlayerOwner.RenderOverlays(Canvas);
	bRenderOverlays = True;
	if (RenderWeapon != None)
	{
		RenderWeapon.PlayerViewOffset = SavedWeaponViewOffset;
		RenderWeapon.DrawScale = SavedWeaponDrawScale;
	}
	PlayerOwner.ViewRotation = SavedViewRotation;
	return True;
}

event bool PlayerCalcView(out actor ViewActor, out vector CameraLocation, out rotator CameraRotation)
{
	local rotator HeadRotation;
	local vector BaseX, BaseY, BaseZ;
	local vector HeadX, HeadY, HeadZ;
	local vector NewX, NewY, NewZ;
	local vector EyeOffset;
	local vector HeadOffset;

	if (PlayerOwner == None || !ReadHeadPose(HeadRotation, EyeOffset, HeadOffset))
		return False;

	// Re-enter the real player implementation with this highest-priority hook
	// disabled, preserving subclass/state flybys and view-target cameras.
	bPlayerCalcView = False;
	PlayerOwner.PlayerCalcView(ViewActor, CameraLocation, CameraRotation);
	bPlayerCalcView = True;

	GetAxes(CameraRotation, BaseX, BaseY, BaseZ);
	GetAxes(HeadRotation, HeadX, HeadY, HeadZ);
	NewX = BaseX * HeadX.X + BaseY * HeadX.Y + BaseZ * HeadX.Z;
	NewY = BaseX * HeadY.X + BaseY * HeadY.Y + BaseZ * HeadY.Z;
	NewZ = BaseX * HeadZ.X + BaseY * HeadZ.Y + BaseZ * HeadZ.Z;
	CameraRotation = OrthoRotation(NewX, NewY, NewZ);
	// The tracked eye position is expressed in the neutral camera's local axes.
	// This includes both IPD and seated head translation and matches the pose
	// supplied to the OpenXR compositor.
	CameraLocation += BaseX * EyeOffset.X + BaseY * EyeOffset.Y + BaseZ * EyeOffset.Z;
	return True;
}

defaultproperties
{
	Priority=255
	bRenderOverlays=True
	bPlayerCalcView=True
}
