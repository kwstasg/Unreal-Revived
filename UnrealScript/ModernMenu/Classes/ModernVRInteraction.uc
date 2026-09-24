// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived

// Applies OpenXR orientation to UE1's authoritative calculated camera before
// the scene is culled. Gameplay aim and the underlying scripted camera remain
// unchanged.

class ModernVRInteraction extends PlayerInteraction;

// Updated by each eye's calculated view and shared with its weapon overlay.
var float BodyHeightOffset;
var transient bool bBasePitchInitialized;

// Calculated before eye separation. Owned by this player's interaction, never
// by a class default that could retain a destroyed pawn across map travel.
var bool bHasCrosshairRay;
var vector CrosshairStart;
var rotator CrosshairAim;

event NotifyLevelChange()
{
	bBasePitchInitialized = False;
	bHasCrosshairRay = False;
}

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

function bool ReadHeadPose(out rotator HeadRotation, out vector EyeOffset, out vector HeadOffset, out float HeightOffset, out float BodyScale, optional bool bHeadCenter)
{
	local string Pose;
	local string Value;

	if (bHeadCenter)
		Pose = PlayerOwner.ConsoleCommand("D3D12 OPENXRPOSE CENTER");
	else
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

function vector GetGazeViewOffset(Weapon W, rotator BaseRotation, rotator AimRotation,
	vector HeadOffset, float HeightOffset, float BodyScale)
{
	local vector WorldHeadOffset, WeaponOffset, UserOffset, ViewOffset, Muzzle, ModelOffset, RightMuzzle;
	local float UserScale, BaseScale;
	local rotator ModelRotation;
	WorldHeadOffset = HeadOffset >> BaseRotation;
	WorldHeadOffset.Z += HeightOffset + BodyHeightOffset;
	WeaponOffset.X = 2.7;
	WeaponOffset.Y = -PlayerOwner.Handedness * 2.2;
	WeaponOffset.Z = -1.7;
	class'ModernVRWeaponTuning'.static.GetSettings().GetAdjustment(W.Class, False, UserScale, UserOffset);
	if (PlayerOwner.Handedness == 0)
		UserOffset.Y = 0;
	else if (PlayerOwner.Handedness == 1)
		UserOffset.Y = -UserOffset.Y;
	ViewOffset = W.PlayerViewOffset;
	if (((RocketLauncher(W) != None && W.PlayerViewMesh == class'RocketLauncher'.default.PlayerViewMesh)
		|| (Eightball(W) != None && W.PlayerViewMesh == class'Eightball'.default.PlayerViewMesh))
		&& (PlayerOwner.Handedness == 0 || PlayerOwner.Handedness == 1))
	{
		if (class'ModernVRMotionSupport'.default.Geometry == None)
			class'ModernVRMotionSupport'.default.Geometry = new class'ModernVRWeaponGeometry';
		class'ModernVRMotionSupport'.default.Geometry.GetGeometry(W, BaseScale, Muzzle, ModelOffset);
		Muzzle = (Muzzle - ModelOffset - vect(1,0,0)) * UserScale;
		ModelRotation.Roll = -W.Default.Rotation.Roll;
		RightMuzzle = Muzzle >> ModelRotation;
		if (PlayerOwner.Handedness == 0) ModelRotation.Roll = -2 * W.Default.Rotation.Roll;
		else ModelRotation.Roll = W.Default.Rotation.Roll;
		Muzzle = Muzzle >> ModelRotation;
		ViewOffset.Y = -PlayerOwner.Handedness * (-W.Default.PlayerViewOffset.Y * 100 + RightMuzzle.Y * 100)
			- Muzzle.Y * 100;
	}
	return ViewOffset * BodyScale
		+ ((WorldHeadOffset << AimRotation) + (WeaponOffset + UserOffset) * BodyScale) * 100.0;
}

function bool GetGazeMuzzle(out vector Start, out rotator Aim, out int Blocked)
{
	local Weapon W;
	local rotator HeadRotation, SavedRotation, ModelRotation;
	local vector EyeOffset, HeadOffset, SavedOffset, ModelOrigin;
	local vector Muzzle, ModelOffset, HitLocation, HitNormal, Anchor, Target;
	local float HeightOffset, BodyScale, BaseScale, GazeScale;
	if (PlayerOwner == None || PlayerOwner.Weapon == None || PlayerOwner.bBehindView || PlayerOwner.ViewTarget != None)
		return False;
	if (!ReadHeadPose(HeadRotation, EyeOffset, HeadOffset, HeightOffset, BodyScale, True)) return False;
	W = PlayerOwner.Weapon;
	SavedRotation = PlayerOwner.ViewRotation;
	Aim = ComposeRotation(SavedRotation, HeadRotation);
	SavedOffset = W.PlayerViewOffset;
	W.PlayerViewOffset = GetGazeViewOffset(W, SavedRotation, Aim, HeadOffset, HeightOffset, BodyScale);
	PlayerOwner.ViewRotation = Aim;
	ModelOrigin = PlayerOwner.Location + W.CalcDrawOffset();
	W.PlayerViewOffset = SavedOffset;
	PlayerOwner.ViewRotation = SavedRotation;
	if (class'ModernVRMotionSupport'.default.Geometry == None)
		class'ModernVRMotionSupport'.default.Geometry = new class'ModernVRWeaponGeometry';
	class'ModernVRMotionSupport'.default.Geometry.GetGeometry(W, BaseScale, Muzzle, ModelOffset);
	GazeScale = class'ModernVRMotionSupport'.static.GetGazeDrawScale(W);
	ModelRotation = Aim;
	if (PlayerOwner.Handedness == 0)
		ModelRotation.Roll = -2 * W.Default.Rotation.Roll;
	else
		ModelRotation.Roll = W.Default.Rotation.Roll * PlayerOwner.Handedness;
	Muzzle = (Muzzle - ModelOffset - vect(1,0,0)) * (GazeScale / FMax(BaseScale, 0.001)) + vect(1,0,0);
	Start = ModelOrigin + ((Muzzle * BodyScale) >> ModelRotation);
	Anchor = PlayerOwner.Location;
	Anchor.Z += PlayerOwner.EyeHeight;
	Blocked = int(PlayerOwner.Trace(HitLocation, HitNormal, Start, Anchor,
		True, vect(0,0,0), True, 0, 86) != None);
	if (Blocked != 0) return True;
	Anchor += HeadOffset >> SavedRotation;
	Anchor.Z += HeightOffset + BodyHeightOffset;
	Target = Anchor + vector(Aim) * 10000;
	if (PlayerOwner.Trace(HitLocation, HitNormal, Target, Anchor, True) != None)
		Target = HitLocation;
	Aim = rotator(Target - Start);
	return True;
}

event bool RenderOverlays(Canvas Canvas)
{
	local rotator HeadRotation;
	local rotator AimRotation;
	local rotator SavedViewRotation;
	local vector EyeOffset;
	local vector HeadOffset;
	local vector SavedWeaponViewOffset;
	local float SavedWeaponDrawScale;
	local float HeightOffset;
	local float BodyScale;
	local Weapon RenderWeapon;

	if (PlayerOwner == None || !ReadHeadPose(HeadRotation, EyeOffset, HeadOffset, HeightOffset, BodyScale))
		return False;
	if (class'ModernVRMotionSupport'.static.IsSelected(PlayerOwner))
	{
		PlayerOwner.ConsoleCommand("D3D12 BEGINVRWEAPONPASS");
		RenderControllerWeapon(Canvas);
		PlayerOwner.ConsoleCommand("D3D12 ENDVRWEAPONPASS");
		if (PlayerOwner.myHUD != None)
			PlayerOwner.myHUD.RenderOverlays(Canvas);
		return True;
	}

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
		SavedWeaponViewOffset = RenderWeapon.PlayerViewOffset;
		SavedWeaponDrawScale = RenderWeapon.DrawScale;
		RenderWeapon.PlayerViewOffset = GetGazeViewOffset(RenderWeapon, SavedViewRotation, AimRotation,
			HeadOffset, HeightOffset, BodyScale);
		// First-person models authored for a flat display feel undersized at
		// headset depth. Scale only the temporary VR overlay render.
		RenderWeapon.DrawScale = class'ModernVRMotionSupport'.static.GetGazeDrawScale(RenderWeapon) * BodyScale;
	}
	bRenderOverlays = False;
	PlayerOwner.ConsoleCommand("D3D12 BEGINVRWEAPONPASS");
	PlayerOwner.RenderOverlays(Canvas);
	PlayerOwner.ConsoleCommand("D3D12 ENDVRWEAPONPASS");
	bRenderOverlays = True;
	if (RenderWeapon != None)
	{
		RenderWeapon.PlayerViewOffset = SavedWeaponViewOffset;
		RenderWeapon.DrawScale = SavedWeaponDrawScale;
	}
	PlayerOwner.ViewRotation = SavedViewRotation;
	return True;
}

function bool RenderControllerWeapon(Canvas C)
{
	local Weapon W;
	local rotator Aim, SavedRotation;
	local vector Hand, SavedLocation, Muzzle, Screen;
	local float Scale, SavedScale, FlashScale, MeshScale;
	local vector LocalMuzzle, ModelOffset;
	W = PlayerOwner.Weapon;
	if (W == None || PlayerOwner.Handedness == 2 || W.bHideWeapon)
		return True;
	if (!class'ModernVRMotionSupport'.static.ReadFrame(PlayerOwner, Aim, Hand, Scale))
		return True;
	SavedScale = W.DrawScale;
	SavedLocation = W.Location;
	SavedRotation = W.Rotation;
	class'ModernVRMotionSupport'.static.GetWeaponGeometry(W, MeshScale, LocalMuzzle, ModelOffset);
	W.DrawScale = MeshScale * Scale;
	W.SetLocation(Hand + ((ModelOffset * Scale) >> Aim), Aim);
	C.DrawActor(W, False);
	W.SetLocation(SavedLocation, SavedRotation);
	W.DrawScale = SavedScale;
	// Stock screen-space flashes must follow the tracked barrel, not eye center.
	if (W.bMuzzleFlash > 0 && W.bDrawMuzzleFlash && W.MFTexture != None)
	{
		if (!W.bSetFlashTime)
		{
			W.bSetFlashTime = True;
			W.FlashTime = PlayerOwner.Level.TimeSeconds + W.FlashLength;
		}
		if (W.FlashTime < PlayerOwner.Level.TimeSeconds)
			W.bMuzzleFlash = 0;
		else
		{
			Muzzle = Hand + ((LocalMuzzle * Scale) >> Aim);
			Screen = C.WorldToScreen(Muzzle);
			if (Screen.Z > 0)
			{
				FlashScale = W.Default.MuzzleScale * C.ClipX / 640.0;
				C.SetPos(Screen.X - FlashScale * W.FlashS, Screen.Y - FlashScale * W.FlashS);
				C.Style = 3;
				C.DrawIcon(W.MFTexture, FlashScale);
				C.Style = 1;
			}
		}
	}
	else W.bSetFlashTime = False;
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
	local rotator CenterRotation;

	BodyHeightOffset = 0;
	if (PlayerOwner == None || !ReadHeadPose(HeadRotation, EyeOffset, HeadOffset, HeightOffset, BodyScale))
		return False;
	if (!bBasePitchInitialized && !PlayerOwner.bBehindView && PlayerOwner.ViewTarget == None
		&& PlayerOwner.ConsoleCommand("D3D12 VRSTATSACTIVE") == "1")
	{
		class'ModernVRAimSupport'.static.LevelBasePitch(PlayerOwner);
		bBasePitchInitialized = True;
	}

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
		// The camera and tracked hands must share a bob-free anchor. Retain
		// EyeHeight for crouching/stair smoothing and preserve gaze mode's view.
		if (class'ModernVRMotionSupport'.static.IsSelected(PlayerOwner))
			CameraLocation -= PlayerOwner.WalkBob;
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
	// Both eyes project a head-center ray, so the reticle converges on the hit.
	if (class'ModernVRAimSupport'.static.ReadHeadRotation(PlayerOwner, CenterRotation, True))
		class'ModernVRAimSupport'.static.SetCrosshairRay(PlayerOwner, HeadCenter,
			ComposeRotation(CameraRotation, CenterRotation));
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
