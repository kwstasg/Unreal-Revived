// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived

// Applies OpenXR orientation to UE1's authoritative calculated camera before
// the scene is culled. Gameplay aim and the underlying scripted camera remain
// unchanged.

class ModernVRInteraction extends PlayerInteraction;

// Updated by each eye's calculated view and shared with its weapon overlay.
var float BodyHeightOffset;

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

function bool ReadHeadPose(out rotator HeadRotation, out vector EyeOffset, out vector HeadOffset, out float HeightOffset, out float BodyScale)
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
	// Accept the original pose format when paired with an older renderer.
	HeightOffset = 0;
	BodyScale = 1;
	if (PopPoseValue(Pose, Value))
	{
		HeadOffset.Z = float(Value);
		if (PopPoseValue(Pose, Value))
		{
			HeightOffset = float(Value);
			BodyScale = FClamp(float(Pose), 0.4, 2.5);
		}
		else
			HeightOffset = float(Pose);
	}
	else
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
	local float HeightOffset;
	local float BodyScale;
	local Weapon RenderWeapon;

	if (PlayerOwner == None || !ReadHeadPose(HeadRotation, EyeOffset, HeadOffset, HeightOffset, BodyScale))
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
		WorldHeadOffset.Z += HeightOffset + BodyHeightOffset;
		LocalHeadOffset = WorldHeadOffset << AimRotation;
		// Preserve each weapon's authored offset, but place the complete model a
		// little farther forward, lower, and toward the selected hand in VR. This
		// keeps more of the view clear without changing gameplay or muzzle origin.
		VRWeaponOffset.X = 2.7;
		VRWeaponOffset.Y = -PlayerOwner.Handedness * 2.2;
		VRWeaponOffset.Z = -1.7;
		SavedWeaponViewOffset = RenderWeapon.PlayerViewOffset;
		SavedWeaponDrawScale = RenderWeapon.DrawScale;
		RenderWeapon.PlayerViewOffset = RenderWeapon.PlayerViewOffset * BodyScale
			+ (LocalHeadOffset + VRWeaponOffset * BodyScale) * 100.0;
		// First-person models authored for a flat display feel undersized at
		// headset depth. Scale only the temporary VR overlay render.
		RenderWeapon.DrawScale *= 1.15 * BodyScale;
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

function UpdateHeadCollision(vector Anchor, vector HeadCenter, float BodyScale)
{
	local vector HitLocation, HitNormal, Extent;
	local actor HitActor;
	local float Radius, Fade;

	// Trace only blocking world, movers and decorations (0x56). Do not include
	// pawns, triggers or water volumes. Sweep from the untracked camera/body
	// so leaning completely through a thin wall stays black on the other side.
	HitActor = PlayerOwner.Trace(HitLocation, HitNormal, HeadCenter, Anchor,
		True, vect(0,0,0), True, 0, 86);
	if (HitActor != None)
		Fade = 1;
	else
	{
		// A 12 cm comfort volume covers both eyes and scales with the player.
		// Fade progressively over its radius before the head center hits a wall.
		Radius = 6.0 * BodyScale;
		Extent = vect(1,1,1) * Radius;
		HitActor = PlayerOwner.Trace(HitLocation, HitNormal, HeadCenter, Anchor,
			True, Extent, True, 0, 86);
		if (HitActor != None)
			Fade = FClamp(VSize(HeadCenter - HitLocation) / Radius, 0, 1);
	}
	PlayerOwner.ConsoleCommand("D3D12 VRHEADCOLLISION" @ Fade);
}

event bool PlayerCalcView(out actor ViewActor, out vector CameraLocation, out rotator CameraRotation)
{
	local float HeightOffset;
	local float BodyScale;
	local float FeetZ;
	local rotator HeadRotation;
	local vector BaseX, BaseY, BaseZ;
	local vector HeadX, HeadY, HeadZ;
	local vector NewX, NewY, NewZ;
	local vector EyeOffset;
	local vector HeadOffset;
	local vector CollisionAnchor, HeadCenter;

	BodyHeightOffset = 0;
	if (PlayerOwner == None || !ReadHeadPose(HeadRotation, EyeOffset, HeadOffset, HeightOffset, BodyScale))
		return False;

	// Re-enter the real player implementation with this highest-priority hook
	// disabled, preserving subclass/state flybys and view-target cameras.
	bPlayerCalcView = False;
	PlayerOwner.PlayerCalcView(ViewActor, CameraLocation, CameraRotation);
	bPlayerCalcView = True;
	CollisionAnchor = CameraLocation;

	// Scale the first-person eye height around the pawn's feet so stereo size
	// and the view of the floor agree. Preserve crouch/bob and custom cameras.
	if (ViewActor == PlayerOwner && !PlayerOwner.bBehindView
		&& PlayerOwner.ViewTarget == None)
	{
		CollisionAnchor = PlayerOwner.Location;
		FeetZ = PlayerOwner.Location.Z - PlayerOwner.CollisionHeight;
		BodyHeightOffset = (CameraLocation.Z - FeetZ) * (BodyScale - 1.0);
		CameraLocation.Z += BodyHeightOffset;
	}

	GetAxes(CameraRotation, BaseX, BaseY, BaseZ);
	// Use the shared head center, not either eye, for identical stereo fading.
	HeadCenter = CameraLocation + BaseX * HeadOffset.X
		+ BaseY * HeadOffset.Y + BaseZ * HeadOffset.Z;
	HeadCenter.Z += HeightOffset;
	UpdateHeadCollision(CollisionAnchor, HeadCenter, BodyScale);
	GetAxes(HeadRotation, HeadX, HeadY, HeadZ);
	NewX = BaseX * HeadX.X + BaseY * HeadX.Y + BaseZ * HeadX.Z;
	NewY = BaseX * HeadY.X + BaseY * HeadY.Y + BaseZ * HeadY.Z;
	NewZ = BaseX * HeadZ.X + BaseY * HeadZ.Y + BaseZ * HeadZ.Z;
	CameraRotation = OrthoRotation(NewX, NewY, NewZ);
	// The tracked eye position is expressed in the neutral camera's local axes.
	// This includes both IPD and seated head translation and matches the pose
	// supplied to the OpenXR compositor.
	CameraLocation += BaseX * EyeOffset.X + BaseY * EyeOffset.Y + BaseZ * EyeOffset.Z;
	// Height stays vertical even when the player's base view is tilted.
	CameraLocation.Z += HeightOffset;
	return True;
}

defaultproperties
{
	Priority=255
	bRenderOverlays=True
	bPlayerCalcView=True
}
