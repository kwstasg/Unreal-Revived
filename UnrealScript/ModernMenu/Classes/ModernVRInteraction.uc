// Unreal Revived
// Applies OpenXR orientation to UE1's authoritative calculated camera before
// the scene is culled. Gameplay aim and the underlying scripted camera remain
// unchanged.

class ModernVRInteraction extends PlayerInteraction;

function bool ReadHeadRotation(out rotator HeadRotation)
{
	local string Pose;
	local int Separator;

	Pose = PlayerOwner.ConsoleCommand("D3D12 OPENXRPOSE");
	if (Left(Pose, 1) != "1")
		return False;

	Pose = Mid(Pose, 2);
	Separator = InStr(Pose, " ");
	if (Separator < 0)
		return False;
	HeadRotation.Pitch = int(Left(Pose, Separator));

	Pose = Mid(Pose, Separator + 1);
	Separator = InStr(Pose, " ");
	if (Separator < 0)
		return False;
	HeadRotation.Yaw = int(Left(Pose, Separator));
	HeadRotation.Roll = int(Mid(Pose, Separator + 1));
	return True;
}

event bool PlayerCalcView(out actor ViewActor, out vector CameraLocation, out rotator CameraRotation)
{
	local rotator HeadRotation;
	local vector BaseX, BaseY, BaseZ;
	local vector HeadX, HeadY, HeadZ;
	local vector NewX, NewY, NewZ;

	if (PlayerOwner == None || !ReadHeadRotation(HeadRotation))
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
	return True;
}

defaultproperties
{
	Priority=255
	bPlayerCalcView=True
}
