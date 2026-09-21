// Offline verification of native hook signatures against the pinned engine.
class ModernVRMotionTestCommandlet extends Commandlet;

var int Failures;

function Check(bool Passed, string Description)
{
	if (!Passed)
	{
		Log("FAIL: " $ Description);
		Failures++;
	}
}

event int Main(string Params)
{
	local ModernVRMotionHook H;
	local Function F, Callback;
	local int Count;
	local rotator R;
	H = new class'ModernVRMotionHook';
	Log("Hook environment enabled=" $ H.HooksEnabled() $ " editor=" $ AppIsEditor());
	Check(H.SetHook(class'Weapon'.static.FindFunction('Fire'), H.HookFire), "fire hook signature");
	Check(H.SetHook(class'Weapon'.static.FindFunction('AltFire'), H.HookAltFire), "alt-fire hook signature");
	Check(H.SetHook(class'Weapon'.static.FindFunction('ProjectileFire'), H.HookProjectileFire), "projectile hook signature");
	Check(H.SetHook(class'Weapon'.static.FindFunction('TraceFire'), H.HookTraceFire), "trace hook signature");
	Check(H.SetHook(class'ASMD'.static.FindFunction('ProcessTraceHit'), H.HookASMDTraceHit), "ASMD trace-hit hook signature");
	foreach H.UsedHooks(F, Callback)
		Count++;
	Check(Count == 5, "all five firing hooks registered by the native engine");
	H.BindWeaponClass(class'Eightball');
	H.BindWeaponClass(class'RazorJack');
	H.BindWeaponClass(class'GrenadeLauncher');
	Count = Array_Size(H.BoundFunctions);
	Check(Count >= 4, "stock and UPak global firing hooks register without a viewport");
	H.BindWeaponClass(class'Eightball');
	H.BindWeaponClass(class'RazorJack');
	H.BindWeaponClass(class'GrenadeLauncher');
	Check(Count == Array_Size(H.BoundFunctions), "weapon switches do not accumulate duplicate hooks");
	Check(!class'ModernVRMotionSupport'.static.IsSelected(None), "non-player objects cannot activate motion mode");
	R = class'ModernVRAimSupport'.static.ComposeRotation(rot(0,16384,0), rot(0,16384,0));
	Check(VSize(vector(R) - vect(-1,0,0)) < 0.001, "body and tracked yaw compose once");
	Log("VR motion regression failures: " $ Failures);
	return Failures;
}

defaultproperties
{
	IsClient=False
	IsServer=False
	IsEditor=False
	LogToStdout=True
}
