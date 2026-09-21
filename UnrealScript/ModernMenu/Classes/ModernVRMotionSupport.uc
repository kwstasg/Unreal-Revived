// Unreal Revived - controller transforms and shared VR weapon sizing.
class ModernVRMotionSupport extends Object abstract;

// Only set around synchronous weapon callbacks; never persists into a tick/view.
var PlayerPawn FiringPlayer;
var rotator BodyRotation;
var ModernVRWeaponGeometry Geometry;

static function GetWeaponGeometry(Weapon W, out float DrawScale, out vector Muzzle, optional out vector ModelOffset)
{
	if (Default.Geometry == None)
		Default.Geometry = new class'ModernVRWeaponGeometry';
	Default.Geometry.GetGeometry(W, DrawScale, Muzzle, ModelOffset);
	class'ModernVRWeaponTuning'.static.GetSettings().ApplyMotion(W.Class, DrawScale, Muzzle, ModelOffset);
}

static function float GetGazeDrawScale(Weapon W)
{
	local float Scale, BaseScale;
	local vector Offset, Muzzle, ModelOffset;
	if (Default.Geometry == None)
		Default.Geometry = new class'ModernVRWeaponGeometry';
	Default.Geometry.GetGeometry(W, BaseScale, Muzzle, ModelOffset);
	class'ModernVRWeaponTuning'.static.GetSettings().GetAdjustment(W.Class, False, Scale, Offset);
	return BaseScale * Scale;
}

static function bool IsLocalPlayer(PlayerPawn Player)
{
	return Player != None && Player.Player != None && Player.Player.Console != None
		&& Player.Player.Actor == Player;
}

static function bool IsSelected(PlayerPawn Player)
{
	return IsLocalPlayer(Player) && Player.ConsoleCommand("D3D12 OPENXRMOTIONACTIVE") == "1";
}

static function bool ReadFrame(PlayerPawn Player, out rotator Aim, out vector Hand, out float Scale)
{
	local string Pose, Value;
	local rotator Relative, Base;
	local vector Offset;
	local float Height;

	if (!IsLocalPlayer(Player) || Player.bBehindView || Player.ViewTarget != None)
		return False;
	Pose = Player.ConsoleCommand("D3D12 OPENXRCONTROLLER");
	if (!class'ModernVRAimSupport'.static.PopPoseValue(Pose, Value) || Value != "1")
		return False;
	if (!class'ModernVRAimSupport'.static.PopPoseValue(Pose, Value) || Value != "1")
		return False;
	if (!class'ModernVRAimSupport'.static.PopPoseValue(Pose, Value)) return False;
	Relative.Pitch = int(Value);
	if (!class'ModernVRAimSupport'.static.PopPoseValue(Pose, Value)) return False;
	Relative.Yaw = int(Value);
	if (!class'ModernVRAimSupport'.static.PopPoseValue(Pose, Value)) return False;
	Relative.Roll = int(Value);
	if (!class'ModernVRAimSupport'.static.PopPoseValue(Pose, Value)) return False;
	Offset.X = float(Value);
	if (!class'ModernVRAimSupport'.static.PopPoseValue(Pose, Value)) return False;
	Offset.Y = float(Value);
	if (!class'ModernVRAimSupport'.static.PopPoseValue(Pose, Value)) return False;
	Offset.Z = float(Value);
	if (!class'ModernVRAimSupport'.static.PopPoseValue(Pose, Value)) return False;
	Height = float(Value);
	if (!class'ModernVRAimSupport'.static.PopPoseValue(Pose, Value)) return False;
	Scale = FClamp(float(Value), 0.4, 2.5);
	Base = Player.ViewRotation;
	if (Default.FiringPlayer == Player)
		Base = Default.BodyRotation;
	Aim = class'ModernVRAimSupport'.static.ComposeRotation(Base, Relative);
	Hand = Player.Location + (Offset >> Base);
	Hand.Z += (Player.CollisionHeight + Player.EyeHeight) * Scale - Player.CollisionHeight + Height;
	return True;
}

static function vector MuzzleOffset(PlayerPawn Player, Weapon W, float Scale)
{
	local vector Offset;
	local float MeshScale;
	GetWeaponGeometry(W, MeshScale, Offset);
	return Offset * Scale;
}

static function bool GetMuzzle(PlayerPawn Player, out vector Start, out rotator Aim, out int Blocked)
{
	local vector Hand, Anchor, HitLocation, HitNormal;
	local float Scale;
	if (Player == None || Player.Weapon == None || !ReadFrame(Player, Aim, Hand, Scale))
		return False;
	Start = Hand + (MuzzleOffset(Player, Player.Weapon, Scale) >> Aim);
	Anchor = Player.Location;
	Anchor.Z += Player.EyeHeight;
	// Same blocking-world filter as head collision; includes movers/decorations.
	Blocked = int(Player.Trace(HitLocation, HitNormal, Hand, Anchor,
		True, vect(0,0,0), True, 0, 86) != None);
	if (Blocked == 0)
		Blocked = int(Player.Trace(HitLocation, HitNormal, Start, Hand,
			True, vect(0,0,0), True, 0, 86) != None);
	if (Blocked != 0)
		Start = HitLocation + HitNormal * 2;
	return True;
}

static function bool CrosshairPosition(PlayerPawn Player, Canvas C, out float X, out float Y)
{
	local vector Start, End, HitLocation, HitNormal, Screen;
	local rotator Aim;
	local int Blocked;
	if (!GetMuzzle(Player, Start, Aim, Blocked) || Blocked != 0)
		return False;
	End = Start + vector(Aim) * 10000;
	if (Player.Trace(HitLocation, HitNormal, End, Start, True) != None)
		End = HitLocation;
	Screen = C.WorldToScreen(End);
	if (Screen.Z <= 0 || Screen.X < 0 || Screen.Y < 0 || Screen.X > C.ClipX || Screen.Y > C.ClipY)
		return False;
	X = Screen.X - 8;
	Y = Screen.Y - 8;
	return True;
}
