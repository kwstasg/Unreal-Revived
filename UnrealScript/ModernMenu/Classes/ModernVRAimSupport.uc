// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived

// Shared, temporary gaze composition for stock player-pawn aim overrides.

class ModernVRAimSupport extends Object abstract;

// Clear only software tilt, never the facing direction or tracked head pose.
static function LevelBasePitch(PlayerPawn Player)
{
	Player.ViewRotation.Pitch = 0;
	Player.ViewRotation.Roll = 0;
	Player.aLookUp = 0;
	Player.aMouseY = 0;
}

static function SetCrosshairRay(PlayerPawn Player, vector Start, rotator Aim)
{
	local ModernVRInteraction Interaction;
	if (Player == None) return;
	Interaction = ModernVRInteraction(Player.FindInteraction(class'ModernVRInteraction'));
	if (Interaction == None) return;
	Interaction.CrosshairStart = Start;
	Interaction.CrosshairAim = Aim;
	Interaction.bHasCrosshairRay = True;
}

static function bool CrosshairPosition(PlayerPawn Player, Canvas C, out float X, out float Y)
{
	local vector End, HitLocation, HitNormal, Screen;
	local ModernVRInteraction Interaction;
	if (Player == None || Player.bBehindView || Player.ViewTarget != None)
		return False;
	Interaction = ModernVRInteraction(Player.FindInteraction(class'ModernVRInteraction'));
	if (Interaction == None || !Interaction.bHasCrosshairRay) return False;
	End = Interaction.CrosshairStart + vector(Interaction.CrosshairAim) * 10000;
	if (Player.Trace(HitLocation, HitNormal, End, Interaction.CrosshairStart, True) != None)
		End = HitLocation;
	Screen = C.WorldToScreen(End);
	if (Screen.Z <= 0 || Screen.X < 0 || Screen.Y < 0 || Screen.X > C.ClipX || Screen.Y > C.ClipY)
		return False;
	X = Screen.X - 8;
	Y = Screen.Y - 8;
	return True;
}

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

static function bool ReadHeadRotation(PlayerPawn Player, out rotator HeadRotation, optional bool bHeadCenter)
{
	local string Pose;
	local string Value;

	if (bHeadCenter)
		Pose = Player.ConsoleCommand("D3D12 OPENXRPOSE CENTER");
	else
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
