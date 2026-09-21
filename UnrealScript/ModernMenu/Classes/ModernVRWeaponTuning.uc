// Optional user adjustments. Neutral values retain the built-in calibration.
class ModernVRWeaponTuning extends Object config(ModernVRWeapons);

struct WeaponProfile
{
	var config string WeaponClass;
	var config float Scale;
	var config vector GazeOffsetCM, MotionOffsetCM;
};
var config array<WeaponProfile> Profiles;
var ModernVRWeaponTuning Settings;

struct ResolvedProfile
{
	var class<Weapon> WeaponType;
	var int ProfileIndex;
};
var transient array<ResolvedProfile> ResolvedProfiles;
var transient int CachedProfileCount;

static function bool Reload(PlayerPawn Player)
{
	local array<WeaponProfile> SavedProfiles;
	if (Player == None) return False;
	SavedProfiles = Default.Profiles;
	// Removed INI entries must revert to neutral, not retain old defaults.
	Array_Size(Default.Profiles, 0);
	if (Player.ConsoleCommand("D3D12 RELOADVRWEAPONS") != "1")
	{
		Default.Profiles = SavedProfiles;
		return False;
	}
	GetSettings().Profiles = Default.Profiles;
	Array_Size(Default.Settings.ResolvedProfiles, 0);
	Default.Settings.CachedProfileCount = Array_Size(Default.Profiles);
	return True;
}

static function ModernVRWeaponTuning GetSettings()
{
	if (Default.Settings == None)
		Default.Settings = new class'ModernVRWeaponTuning';
	return Default.Settings;
}

function int FindProfile(class<Weapon> WeaponType)
{
	local class<Object> Type;
	local int I;
	local string TypeName;
	// Exact class first, then nearest ancestor (including Old Weapons).
	for (Type = WeaponType; Type != None; Type = GetParentClass(Type))
	{
		TypeName = string(Type);
		for (I = 0; I < Array_Size(Profiles); I++)
			if (Profiles[I].WeaponClass ~= TypeName) return I;
	}
	return -1;
}

function int ResolveProfile(class<Weapon> WeaponType)
{
	local int I;
	if (CachedProfileCount != Array_Size(Profiles))
	{
		Array_Size(ResolvedProfiles, 0);
		CachedProfileCount = Array_Size(Profiles);
	}
	for (I = 0; I < Array_Size(ResolvedProfiles); I++)
		if (ResolvedProfiles[I].WeaponType == WeaponType)
			return ResolvedProfiles[I].ProfileIndex;
	I = Array_Size(ResolvedProfiles);
	Array_Size(ResolvedProfiles, I + 1);
	ResolvedProfiles[I].WeaponType = WeaponType;
	ResolvedProfiles[I].ProfileIndex = FindProfile(WeaponType);
	return ResolvedProfiles[I].ProfileIndex;
}

function GetAdjustment(class<Weapon> WeaponType, bool bMotion, out float Scale, out vector Offset)
{
	local int I;
	Scale = 1;
	Offset = vect(0,0,0);
	I = ResolveProfile(WeaponType);
	if (I < 0) return;
	Scale = Profiles[I].Scale;
	if (bMotion)
		Offset = Profiles[I].MotionOffsetCM;
	else
		Offset = Profiles[I].GazeOffsetCM;
	if (Scale <= 0) Scale = 1;
	Offset *= 0.5;
}

function ApplyMotion(class<Weapon> WeaponType, out float DrawScale, out vector Muzzle, out vector ModelOffset)
{
	local float Scale;
	local vector Offset;
	GetAdjustment(WeaponType, True, Scale, Offset);
	if (Scale == 1 && Offset == vect(0,0,0)) return;
	// Scale about the established hand anchor, with the same translation
	// for model, shot origin, flash and reticle. Preserve barrel clearance.
	DrawScale *= Scale;
	ModelOffset = ModelOffset * Scale + Offset;
	Muzzle = (Muzzle - vect(1,0,0)) * Scale + vect(1,0,0) + Offset;
}
