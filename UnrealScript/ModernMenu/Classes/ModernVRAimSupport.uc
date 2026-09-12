// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived

// Shared, temporary gaze composition for stock player-pawn aim overrides.

class ModernVRAimSupport extends Object abstract;

static function bool PopPoseValue(out string Pose, out string Value)
{
	local int Separator;

	Separator = InStr(Pose, " ");
	if (Separator < 0)
		return False;
	Value = Left(Pose, Separator);
	Pose = Mid(Pose, Separator + 1);
	return True;
}

static function bool ReadHeadRotation(PlayerPawn Player, out rotator HeadRotation)
{
	local string Pose;
	local string Value;

	Pose = Player.ConsoleCommand("D3D12 OPENXRPOSE");
	if (!PopPoseValue(Pose, Value) || Value != "1")
		return False;
	if (!PopPoseValue(Pose, Value))
		return False;
	HeadRotation.Pitch = int(Value);
	if (!PopPoseValue(Pose, Value))
		return False;
	HeadRotation.Yaw = int(Value);
	if (!PopPoseValue(Pose, Value))
		return False;
	HeadRotation.Roll = int(Value);
	return True;
}

static function rotator ComposeRotation(rotator BaseRotation, rotator HeadRotation)
{
	local vector BaseX, BaseY, BaseZ;
	local vector HeadX, HeadY, HeadZ;

	GetAxes(BaseRotation, BaseX, BaseY, BaseZ);
	GetAxes(HeadRotation, HeadX, HeadY, HeadZ);
	return OrthoRotation(
		BaseX * HeadX.X + BaseY * HeadX.Y + BaseZ * HeadX.Z,
		BaseX * HeadY.X + BaseY * HeadY.Y + BaseZ * HeadY.Z,
		BaseX * HeadZ.X + BaseY * HeadZ.Y + BaseZ * HeadZ.Z);
}

static function bool BeginAim(PlayerPawn Player, out rotator SavedViewRotation)
{
	local rotator HeadRotation;

	if (!ReadHeadRotation(Player, HeadRotation))
		return False;
	SavedViewRotation = Player.ViewRotation;
	Player.ViewRotation = ComposeRotation(SavedViewRotation, HeadRotation);
	return True;
}

static function EndAim(PlayerPawn Player, rotator SavedViewRotation)
{
	Player.ViewRotation = SavedViewRotation;
}
