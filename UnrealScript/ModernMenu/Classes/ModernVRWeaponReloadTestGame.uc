// Driven by test-vr-weapon-reload.ps1 while it edits/restores the tuning INI.
class ModernVRWeaponReloadTestGame extends ModernVRMotionTestGame;

var int Stage, Attempts;
var ModernVRWeaponTuning InitialSettings;

event Timer()
{
	local float Scale;
	local vector Offset;
	Attempts++;
	if (Attempts > 20)
	{
		Check(False, "live INI reload timed out");
		TestPlayer.ConsoleCommand("quit");
		return;
	}
	if (Stage == 0)
	{
		// Populate the engine's config cache before the external file edit.
		InitialSettings = class'ModernVRWeaponTuning'.static.GetSettings();
		class'ModernVRWeaponTuning'.static.GetSettings().GetAdjustment(class'ModernVRMotionTestWeapon', True, Scale, Offset);
		Log("VRRELOAD sample stage=" $ Stage $ " scale=" $ Scale $ " profiles=" $ Array_Size(class'ModernVRWeaponTuning'.default.Profiles));
		Check(Scale == 1, "reload fixture begins neutral");
		Log("VRRELOAD ready for edit");
		Stage = 1;
	}
	else
	{
		// Exercise the user-facing console command as well as native reload.
		Check(TestPlayer.Player.Console.ConsoleCommand("ReloadVRWeapons"), "console accepts reload command");
		Check(class'ModernVRWeaponTuning'.static.GetSettings() == InitialSettings, "reload reuses the tuning instance");
		class'ModernVRWeaponTuning'.static.GetSettings().GetAdjustment(class'ModernVRMotionTestWeapon', True, Scale, Offset);
		Log("VRRELOAD current stage=" $ Stage $ " scale=" $ Scale $ " offset=" $ Offset
			$ " defaults=" $ Array_Size(class'ModernVRWeaponTuning'.default.Profiles)
			$ " instance=" $ Array_Size(class'ModernVRWeaponTuning'.static.GetSettings().Profiles));
		if (Stage == 1 && Abs(Scale - 1.37) < 0.001 && Offset == vect(1,-2,3))
		{
			Log("VRRELOAD edited values applied");
			Stage = 2;
		}
		else if (Stage == 2 && Scale == 1 && Offset == vect(0,0,0))
		{
			Log("VRRELOAD removed profile reverted to neutral");
			Log("VRMOTION regression failures: " $ Failures);
			TestPlayer.ConsoleCommand("quit");
			return;
		}
	}
	SetTimer(1, False);
}
