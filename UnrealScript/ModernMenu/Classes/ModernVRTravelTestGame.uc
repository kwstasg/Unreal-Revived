// Exercises VR object lifetimes during actual map travel without an HMD.
class ModernVRTravelTestGame extends SinglePlayer;

var PlayerPawn TestPlayer;
var int TravelStage;

event InitGame(string Options, out string Error)
{
	Super.InitGame(Options, Error);
	TravelStage = int(ParseOption(Options, "VRTravelStage"));
}

event PostLogin(PlayerPawn NewPlayer)
{
	Super.PostLogin(NewPlayer);
	TestPlayer = NewPlayer;
	SetTimer(1, False);
}

event Timer()
{
	local ModernConsole C;
	local float Scale;
	local vector Muzzle, Offset;
	local ModernVRInteraction Interaction;
	if (TravelStage > 0)
	{
		Interaction = ModernVRInteraction(TestPlayer.AddInteraction(class'ModernVRInteraction', True));
		if (Interaction.bHasCrosshairRay)
			Log("VRTRAVEL FAIL: new player inherited previous camera ray");
		Log("VRTRAVEL map change completed stage=" $ TravelStage);
	}
	C = ModernConsole(TestPlayer.Player.Console);
	if (C.VRAimHook == None) C.VRAimHook = new class'ModernVRAimHook';
	C.VRAimHook.InstallHooks();
	if (C.VRMotionHook == None) C.VRMotionHook = new class'ModernVRMotionHook';
	C.VRMotionHook.EnsureHooks(TestPlayer);
	if (!C.VRAimHook.bHasHooks || !C.VRMotionHook.bHasHooks)
		Log("VRTRAVEL FAIL: VR hooks did not rebind");
	C.VRInteractionPlayer = TestPlayer;
	Interaction = ModernVRInteraction(TestPlayer.AddInteraction(class'ModernVRInteraction', True));
	class'ModernVRAimSupport'.static.SetCrosshairRay(TestPlayer, TestPlayer.Location, TestPlayer.ViewRotation);
	if (!Interaction.bHasCrosshairRay || Interaction.CrosshairStart != TestPlayer.Location)
		Log("VRTRAVEL FAIL: camera ray was not stored for current player");
	class'ModernVRWeaponTuning'.static.GetSettings();
	if (TestPlayer.Weapon != None)
		class'ModernVRMotionSupport'.static.GetWeaponGeometry(TestPlayer.Weapon, Scale, Muzzle, Offset);
	if (TravelStage >= 3)
	{
		Log("VRTRAVEL repeated map changes and hook rebinding completed");
		TestPlayer.ConsoleCommand("quit");
		return;
	}
	Log("VRTRAVEL populated VR references; starting new map");
	if (TravelStage == 1)
		TestPlayer.ConsoleCommand("open NyLeve?Game=ModernMenu.ModernVRTravelTestGame?VRTravelStage=2");
	else
		TestPlayer.ConsoleCommand("open Vortex2?Game=ModernMenu.ModernVRTravelTestGame?VRTravelStage=" $ (TravelStage + 1));
}
