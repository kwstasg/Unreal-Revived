// Exercises VR object lifetimes during actual map travel without an HMD.
class ModernVRTravelTestGame extends SinglePlayer;

var PlayerPawn TestPlayer;
var int TravelStage;
var bool bLoadedSave;
var Weapon GeometryWeapons[14];
var float ExpectedGazeScale[14];
var vector ExpectedGazeOffset[42];

// Exercise serialized weapons with a warm motion cache followed by gaze after
// actual save loading. Pose injection avoids requiring an HMD for this regression.
function CheckSavedGeometry(bool bPrepare)
{
	local class<Weapon> Types[14];
	local ModernVRInteraction Gaze;
	local Weapon W;
	local vector Muzzle, Offset, GazeOffset;
	local float Scale, SavedHand;
	local int I, Hand;
	Types[0] = class'DispersionPistol'; Types[1] = class'AutoMag';
	Types[2] = class'Stinger'; Types[3] = class'ASMD';
	Types[4] = class'Eightball'; Types[5] = class'FlakCannon';
	Types[6] = class'Rifle'; Types[7] = class'Minigun';
	Types[8] = class'RazorJack'; Types[9] = class'GESBioRifle';
	Types[10] = class'QuadShot'; Types[11] = class'CARifle';
	Types[12] = class'GrenadeLauncher'; Types[13] = class'RocketLauncher';
	Gaze = ModernVRInteraction(TestPlayer.AddInteraction(class'ModernVRWeaponTestInteraction', True));
	SavedHand = TestPlayer.Handedness;
	class'ModernVRMotionSupport'.default.Geometry = new class'ModernVRWeaponGeometry';
	for (I = 0; I < 14; I++)
	{
		if (bPrepare) GeometryWeapons[I] = Spawn(Types[I], TestPlayer);
		W = GeometryWeapons[I];
		if (W == None) { Log("VRTRAVEL FAIL: missing saved weapon " $ Types[I]); continue; }
		if (bPrepare)
		{
			W.AnimSequence = 'Select'; W.AnimFrame = 0.5;
			class'ModernVRMotionSupport'.static.GetWeaponGeometry(W, Scale, Muzzle, Offset);
			ExpectedGazeScale[I] = class'ModernVRMotionSupport'.static.GetGazeDrawScale(W);
		}
		else if (Abs(class'ModernVRMotionSupport'.static.GetGazeDrawScale(W) - ExpectedGazeScale[I]) > 0.0001)
			Log("VRTRAVEL FAIL: gaze scale after motion/save/load " $ Types[I]);
		for (Hand = -1; Hand <= 1; Hand++)
		{
			TestPlayer.Handedness = Hand;
			W.SetHand(Hand);
			GazeOffset = Gaze.GetGazeViewOffset(W, rot(0,1000,0), rot(2000,3000,0), vect(2,3,1), 0, 1);
			if (bPrepare) ExpectedGazeOffset[I * 3 + Hand + 1] = GazeOffset;
			else if (VSize(GazeOffset - ExpectedGazeOffset[I * 3 + Hand + 1]) > 0.01)
				Log("VRTRAVEL FAIL: gaze placement after motion/save/load " $ Types[I] $ " hand=" $ Hand);
		}
		// Serialize another pose than the one used to warm the motion cache.
		if (bPrepare) { W.AnimSequence = 'Still'; W.AnimFrame = 0; }
	}
	TestPlayer.Handedness = SavedHand;
	if (!bPrepare) Log("VRTRAVEL all 14 gaze weapon profiles stable after motion/save/load");
}

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
		CheckSavedGeometry(False);
		Log("VRTRAVEL save load and production hook rebinding completed");
		Log("VRTRAVEL repeated map changes and hook rebinding completed");
		TestPlayer.ConsoleCommand("quit");
		return;
	}
	if (TravelStage == 3)
	{
		TestPlayer.ConsoleCommand("D3D12 VRAIMMODE 1");
		CheckSavedGeometry(True);
		TravelStage = 4;
		TestPlayer.bDelayedCommand = True;
		TestPlayer.DelayedCommand = "SaveGame 0";
		SetTimer(2, False);
		return;
	}
	if (TravelStage == 4)
	{
		TestPlayer.ConsoleCommand("D3D12 VRAIMMODE 0");
		TestPlayer.ClientTravel("?load=0", TRAVEL_Absolute, False);
		return;
	}
	Log("VRTRAVEL populated VR references; starting new map");
	if (TravelStage == 1)
		TestPlayer.ConsoleCommand("open NyLeve?Game=ModernMenu.ModernVRTravelTestGame?VRTravelStage=2");
	else
		TestPlayer.ConsoleCommand("open Vortex2?Game=ModernMenu.ModernVRTravelTestGame?VRTravelStage=" $ (TravelStage + 1));
}
