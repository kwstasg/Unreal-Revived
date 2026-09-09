// Unreal Revived
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

function bool ReadHeadPose(out rotator HeadRotation, out vector EyeOffset)
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
	EyeOffset.Z = float(Pose);
	return True;
}

event bool PlayerCalcView(out actor ViewActor, out vector CameraLocation, out rotator CameraRotation)
{
	local rotator HeadRotation;
	local vector BaseX, BaseY, BaseZ;
	local vector HeadX, HeadY, HeadZ;
	local vector NewX, NewY, NewZ;
	local vector EyeOffset;

	if (PlayerOwner == None || !ReadHeadPose(HeadRotation, EyeOffset))
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
	bPlayerCalcView=True
}
