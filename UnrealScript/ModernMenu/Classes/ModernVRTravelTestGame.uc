// Exercises VR object lifetimes during actual map travel without an HMD.
class ModernVRTravelTestGame extends SinglePlayer;

var PlayerPawn TestPlayer;
var int TravelStage;
var bool bLoadedSave;

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

event PostLoadGame()
{
	Super.PostLoadGame();
	bLoadedSave = True;
	SetTimer(1, False);
}

event Timer()
{
	local ModernConsole C;
	local float Scale;
	local vector Muzzle, Offset;
	local ModernVRInteraction Interaction;
	if (TravelStage > 0 && TravelStage < 4)
	{
		Interaction = ModernVRInteraction(TestPlayer.AddInteraction(class'ModernVRInteraction', True));
		if (Interaction.bHasCrosshairRay)
			Log("VRTRAVEL FAIL: new player inherited previous camera ray");
		Log("VRTRAVEL map change completed stage=" $ TravelStage);
	}
	C = ModernConsole(TestPlayer.Player.Console);
	C.BindVRWeaponHooks(TestPlayer);
	if (C.VRAimHook.Outer == C || C.VRMotionHook.Outer == C)
		Log("VRTRAVEL FAIL: hooks must not use the console as their outer");
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
	if (bLoadedSave)
	{
		Log("VRTRAVEL save load and production hook rebinding completed");
		Log("VRTRAVEL repeated map changes and hook rebinding completed");
		TestPlayer.ConsoleCommand("quit");
		return;
	}
	if (TravelStage == 3)
	{
		TravelStage = 4;
		TestPlayer.bDelayedCommand = True;
		TestPlayer.DelayedCommand = "SaveGame 0";
		SetTimer(2, False);
		return;
	}
	if (TravelStage == 4)
	{
		TestPlayer.ClientTravel("?load=0", TRAVEL_Absolute, False);
		return;
	}
	Log("VRTRAVEL populated VR references; starting new map");
	if (TravelStage == 1)
		TestPlayer.ConsoleCommand("open NyLeve?Game=ModernMenu.ModernVRTravelTestGame?VRTravelStage=2");
	else
		TestPlayer.ConsoleCommand("open Vortex2?Game=ModernMenu.ModernVRTravelTestGame?VRTravelStage=" $ (TravelStage + 1));
}
