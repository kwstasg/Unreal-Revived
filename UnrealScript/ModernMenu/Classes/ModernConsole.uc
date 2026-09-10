// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived

class ModernConsole extends UnrealConsole;

const SmoothTextPolyFlags = 0x00000102;

var bool bShowFPSStatistics;
var int StatisticsFrameCount;
var int StatisticsTotalFrames;
var float StatisticsIntervalTime;
var float StatisticsTotalTime;
var float StatisticsFPS;
var float StatisticsLowFPS;
var float StatisticsHighFPS;
var string StatisticsVSync;
var float ControllerMenuX;
var float ControllerMenuY;
var float ControllerMenuScale;
var float ControllerMenuNextRepeat;
var int ControllerMenuDirection;
var float ControllerGameplayX;
var float ControllerGameplayY;
var float SavedDodgeClickTime;
var bool bControllerDodgeSuppressed;
var int BindingActivationKey;
var bool bLocalizedHudFontInitialized;
var Font OriginalHudMedFont;
var Font LocalizedHudMedFont;
var Font LocalizedActionFont;
var UnrealHUD LocalizedMOTDHud;
var float LocalizedMOTDFadeOutTime;
var Translator SuppressedTranslator;
var bool bSuppressedTranslatorActive;
var PlayerPawn SeamAssistPlayer;
var vector SeamAssistLastLocation;
var float SeamAssistOriginalRadius;
var float SeamAssistBlockedTime;
var bool bSeamAssistRadiusReduced;
var PlayerPawn VRInteractionPlayer;
var ModernVRAimHook VRAimHook;

const PlayerMaxStepHeight = 32.0;
const SeamAssistRadiusReduction = 8.0;
const SeamAssistDelay = 0.08;
const SeamAssistPawnClearance = 2.0;
const SeamAssistTraceDistance = 10.0;

// Keep dynamically spawned Brute projectile effects in the startup asset graph.
// Otherwise their first encounter can synchronously load and precache the effect
// classes and textures in the middle of a rendered frame.
var private class<Actor> PreloadedBruteProjectileClass;
var private class<Actor> PreloadedBruteSmokeClass;
var private class<Actor> PreloadedBruteExplosionClass;
var private class<Actor> PreloadedBruteExplosionChildClass;
var private class<Actor> PreloadedBruteBlackSmokeClass;
var private class<Actor> PreloadedBruteDecalClass;

const ControllerMenuThreshold = 0.55;
const ControllerMenuInitialRepeat = 0.45;
const ControllerMenuRepeatInterval = 0.20;
const ControllerSliderInitialRepeat = 0.20;
const ControllerSliderRepeatInterval = 0.04;
const FPSStatisticsStartY = 80.0;

simulated function ShowLoadGameMenu()
{
	Root.CreateWindow(class'ModernLoadGameWindow', 100, 100, 200, 200, None, True);
}

// The stock HUD font only contains Latin glyphs.  Replace the Canvas medium
// font before the HUD renders when Greek is active.  This lets the original
// HUD and Translator draw themselves once, with their original geometry and
// colors, instead of attempting to duplicate either renderer here.
event PreRender(Canvas C)
{
	InitializeLocalizedHudFont();
	PrepareLocalizedHudRendering();

	if (LocalizedHudMedFont != None)
	{
		class'Canvas'.Default.MedFont = LocalizedHudMedFont;
		C.MedFont = LocalizedHudMedFont;
	}
	else if (OriginalHudMedFont != None)
		C.MedFont = OriginalHudMedFont;

	Super.PreRender(C);
}

function InitializeLocalizedHudFont()
{
	if (bLocalizedHudFontInitialized)
		return;

	bLocalizedHudFontInitialized = True;
	OriginalHudMedFont = class'Canvas'.Default.MedFont;
	if (class'Locale'.Static.GetLanguage() ~= "elt")
	{
		LocalizedHudMedFont = Font(DynamicLoadObject("UWindowFonts.Tahoma12", class'Font'));
		LocalizedActionFont = Font(DynamicLoadObject("UWindowFonts.TahomaB15", class'Font'));
		if (LocalizedHudMedFont != None)
			class'Canvas'.Default.MedFont = LocalizedHudMedFont;
	}
}

function PrepareLocalizedHudRendering()
{
	local Inventory Inv;
	local bool bLocalizedHud;
	local bool bVRUI;

	SuppressedTranslator = None;
	bSuppressedTranslatorActive = False;
	if (Viewport.Actor == None)
		return;
	bLocalizedHud = class'Locale'.Static.GetLanguage() ~= "elt";
	bVRUI = Left(Viewport.Actor.ConsoleCommand("D3D12 OPENXRPOSE"), 1) == "1";
	if (!bLocalizedHud && !bVRUI)
		return;

	if (bLocalizedHud)
		CaptureLocalizedMOTD();
	foreach Viewport.Actor.AllInventory(class'Inventory', Inv)
	{
		if (Translator(Inv) != None)
		{
			SuppressedTranslator = Translator(Inv);
			break;
		}
	}
	if (SuppressedTranslator != None && SuppressedTranslator.bCurrentlyActivated)
	{
		bSuppressedTranslatorActive = True;
		SuppressedTranslator.bCurrentlyActivated = False;
	}
}

function CaptureLocalizedMOTD()
{
	local UnrealHUD CurrentHud;

	if (Viewport.Actor == None)
		return;
	CurrentHud = UnrealHUD(Viewport.Actor.MyHUD);
	if (CurrentHud == None)
		return;
	LocalizedMOTDHud = CurrentHud;
	if (CurrentHud.MOTDFadeOutTime > 0)
	{
		LocalizedMOTDFadeOutTime = CurrentHud.MOTDFadeOutTime;
		CurrentHud.MOTDFadeOutTime = 0;
	}
}

function DrawLevelAction(Canvas C)
{
	local Font SavedFont, SavedMedFont, SavedLargeFont;
	local float SavedFontScale;

	if (!(class'Locale'.Static.GetLanguage() ~= "elt") || LocalizedHudMedFont == None)
	{
		Super.DrawLevelAction(C);
		return;
	}

	SavedFont = C.Font;
	SavedMedFont = C.MedFont;
	SavedLargeFont = C.LargeFont;
	SavedFontScale = C.FontScale;
	C.MedFont = LocalizedHudMedFont;
	C.FontScale = SavedFontScale * class'HUD'.Default.HudScaler;
	if (LocalizedActionFont != None)
		C.LargeFont = LocalizedActionFont;
	else
		C.LargeFont = LocalizedHudMedFont;

	Super.DrawLevelAction(C);

	C.Font = SavedFont;
	C.MedFont = SavedMedFont;
	C.LargeFont = SavedLargeFont;
	C.FontScale = SavedFontScale;
}

function SetFPSStatistics(bool bEnabled)
{
	bShowFPSStatistics = bEnabled;
	StatisticsFrameCount = 0;
	StatisticsTotalFrames = 0;
	StatisticsIntervalTime = 0;
	StatisticsTotalTime = 0;
	StatisticsFPS = 0;
	StatisticsLowFPS = 0;
	StatisticsHighFPS = 0;
	UpdateVSyncStatistics();
}

function SetFPSStatisticsPreference(bool bEnabled)
{
	class'ModernVideoClientWindow'.Default.bShowFPS = bEnabled;
	class'ModernVideoClientWindow'.Static.StaticSaveConfig();
	SetFPSStatistics(bEnabled);
}

exec function ToggleFPSStatistics()
{
	SetFPSStatisticsPreference(!bShowFPSStatistics);
}

event Tick(float Delta)
{
	InitializeLocalizedHudFont();
	EnsureModernGameHud();
	EnsureVRInteraction();
	EnsureVRAimHook();
	if (class'Locale'.Static.GetLanguage() ~= "elt")
	{
		CaptureLocalizedMOTD();
		if (LocalizedMOTDFadeOutTime > 0)
			LocalizedMOTDFadeOutTime = FMax(0, LocalizedMOTDFadeOutTime - Delta * 45);
	}
	Super.Tick(Delta);
	UpdateBSPSeamAssist(Delta);
	if (!bShowFPSStatistics)
		return;

	StatisticsFrameCount++;
	StatisticsTotalFrames++;
	StatisticsIntervalTime += Delta;
	StatisticsTotalTime += Delta;
	if (StatisticsIntervalTime >= 1.0)
	{
		StatisticsFPS = StatisticsFrameCount / StatisticsIntervalTime;
		if (StatisticsLowFPS == 0 || StatisticsFPS < StatisticsLowFPS)
			StatisticsLowFPS = StatisticsFPS;
		if (StatisticsFPS > StatisticsHighFPS)
			StatisticsHighFPS = StatisticsFPS;
		UpdateVSyncStatistics();
		StatisticsFrameCount = 0;
		StatisticsIntervalTime = 0;
	}
}

// Hook the original PlayerPawn implementation, including pawns restored from
// old saves. Hooks are detached by 227 on every map change and rebound here.
function EnsureVRAimHook()
{
	local PlayerPawn Player;
	local string Pose;

	Player = Viewport.Actor;
	if (Player == None)
		return;
	Pose = Player.ConsoleCommand("D3D12 OPENXRPOSE");
	if (Left(Pose, 1) != "1")
		return;
	if (VRAimHook == None)
		VRAimHook = new(Self) class'ModernVRAimHook';
	if (!VRAimHook.bHasHooks)
		VRAimHook.InstallHooks();
}

// Install the camera hook only after the active renderer reports a valid
// OpenXR pose. AddInteraction's unique mode also covers player replacement on
// map travel without accumulating callbacks.
function EnsureVRInteraction()
{
	local PlayerPawn Player;
	local string Pose;

	Player = Viewport.Actor;
	if (Player == None || Player == VRInteractionPlayer)
		return;

	Pose = Player.ConsoleCommand("D3D12 OPENXRPOSE");
	if (Left(Pose, 1) == "1")
	{
		Player.AddInteraction(class'ModernVRInteraction', True);
		VRInteractionPlayer = Player;
	}
}

// Normal campaign travel and old save games can restore the stock UnrealHUD
// without passing through the New Game dialog. Replace only that exact HUD;
// custom game-mode HUD subclasses keep their own rendering and behavior.
function EnsureModernGameHud()
{
	local PlayerPawn Player;

	Player = Viewport.Actor;
	if (Player == None)
		return;

	if (Player.HUDType == class'UnrealHUD')
		Player.HUDType = class'ModernGameHud';
	else if (Player.HUDType == class'IntroNullHud')
		Player.HUDType = class'ModernIntroHud';

	if (Player.MyHUD != None && Player.MyHUD.Class == class'UnrealHUD')
	{
		Player.MyHUD.Destroy();
		Player.MyHUD = None;
		Player.HUDType = class'ModernGameHud';
	}
	else if (Player.MyHUD != None && Player.MyHUD.Class == class'IntroNullHud')
	{
		Player.MyHUD.Destroy();
		Player.MyHUD = None;
		Player.HUDType = class'ModernIntroHud';
	}
}

function UpdateVSyncStatistics()
{
	if (bool(Viewport.Actor.ConsoleCommand("get ini:Engine.Engine.GameRenderDevice UseVSync")))
		StatisticsVSync = "On";
	else
		StatisticsVSync = "Off";
}

event PostRender(Canvas C)
{
	local float HudScale;
	local bool bVRUI;

	if (LocalizedHudMedFont != None)
		C.MedFont = LocalizedHudMedFont;

	HudScale = class'HUD'.Default.HudScaler;
	bVRUI = Viewport.Actor != None
		&& Left(Viewport.Actor.ConsoleCommand("D3D12 OPENXRPOSE"), 1) == "1";
	if ((LocalizedMOTDHud != None && LocalizedMOTDFadeOutTime > 0)
		|| (SuppressedTranslator != None && bSuppressedTranslatorActive))
	{
		if (bVRUI)
			Viewport.Actor.ConsoleCommand("D3D12 BEGINVRUIPASS");
		C.SetOrigin(0, 0);
		if (!bVRUI && HudScale != 1.0)
			C.PushCanvasScale(HudScale, True);
		if (LocalizedMOTDHud != None && LocalizedMOTDFadeOutTime > 0)
		{
			class'ModernGameHud'.Static.DrawLocalizedMOTD(C, LocalizedMOTDHud,
				LocalizedMOTDFadeOutTime);
		}
		if (SuppressedTranslator != None && bSuppressedTranslatorActive)
			class'ModernGameHud'.Static.DrawLocalizedTranslator(C, SuppressedTranslator);
		if (!bVRUI && HudScale != 1.0)
			C.PopCanvasScale();
		if (bVRUI)
			Viewport.Actor.ConsoleCommand("D3D12 ENDVRUIPASS");
	}
	if (SuppressedTranslator != None)
		SuppressedTranslator.bCurrentlyActivated = bSuppressedTranslatorActive;

	Super.PostRender(C);
	if (bShowFPSStatistics)
		DrawFPSStatistics(C);
}

// Keep one canonical player step height across travel and save loads. If native
// walking sticks on a BSP seam, briefly narrow the collision cylinder and let
// the engine perform the movement normally; never reposition the player.
function UpdateBSPSeamAssist(float Delta)
{
	local PlayerPawn Player;
	local vector HorizontalAcceleration;
	local vector HorizontalMovement;

	Player = Viewport.Actor;
	if (Player == None)
		return;
	Player.MaxStepHeight = PlayerMaxStepHeight;

	if (Player != SeamAssistPlayer)
	{
		RestoreSeamAssistRadius();
		SeamAssistPlayer = Player;
		SeamAssistOriginalRadius = Player.CollisionRadius;
		SeamAssistLastLocation = Player.Location;
		SeamAssistBlockedTime = 0;
		return;
	}

	HorizontalAcceleration = Player.Acceleration;
	HorizontalAcceleration.Z = 0;
	HorizontalMovement = Player.Location - SeamAssistLastLocation;
	HorizontalMovement.Z = 0;
	SeamAssistLastLocation = Player.Location;
	if (Player.Level.NetMode != NM_Standalone
		|| Player.Physics != PHYS_Walking || Player.bIsCrouching
		|| VSize(HorizontalAcceleration) < 10)
	{
		SeamAssistBlockedTime = 0;
		RestoreSeamAssistRadius();
		return;
	}

	if (VSize(HorizontalMovement) >= 0.25)
	{
		SeamAssistBlockedTime = 0;
		RestoreSeamAssistRadius();
		return;
	}

	SeamAssistBlockedTime += Delta;
	if (!bSeamAssistRadiusReduced && SeamAssistBlockedTime >= SeamAssistDelay
		&& IsSeamAssistPawnClear(Player, SeamAssistOriginalRadius)
		&& IsWorldGeometryObstruction(Player, HorizontalAcceleration)
		&& Player.SetCollisionSize(FMax(8.0,
			SeamAssistOriginalRadius - SeamAssistRadiusReduction),
			Player.CollisionHeight, true))
		bSeamAssistRadiusReduced = true;
}

// PlayerPawn permits encroachment on other pawns, whose EncroachedBy event
// gibs them. Never use collision resizing while either cylinder is close
// enough for restoring the player's full radius to overlap another pawn.
function bool IsSeamAssistPawnClear(PlayerPawn Player, float TestRadius)
{
	local Pawn Other;
	local vector Separation;
	local float CombinedRadius;

	for (Other = Player.Level.PawnList; Other != None; Other = Other.NextPawn)
	{
		if (Other == Player || Other.bDeleteMe || !Other.bCollideActors)
			continue;
		Separation = Other.Location - Player.Location;
		if (Abs(Separation.Z) >= Player.CollisionHeight + Other.CollisionHeight)
			continue;
		CombinedRadius = TestRadius + Other.CollisionRadius
			+ SeamAssistPawnClearance;
		Separation.Z = 0;
		if (Separation Dot Separation < CombinedRadius * CombinedRadius)
			return false;
	}
	return true;
}

function bool IsWorldGeometryObstruction(PlayerPawn Player,
	vector HorizontalAcceleration)
{
	local Actor HitActor;
	local vector HitLocation;
	local vector HitNormal;
	local vector TraceExtent;
	local vector TraceEnd;

	HorizontalAcceleration.Z = 0;
	TraceExtent.X = SeamAssistOriginalRadius;
	TraceExtent.Y = SeamAssistOriginalRadius;
	TraceExtent.Z = FMax(1.0, Player.CollisionHeight - 2.0);
	TraceEnd = Player.Location + Normal(HorizontalAcceleration)
		* SeamAssistTraceDistance;
	HitActor = Player.Trace(HitLocation, HitNormal, TraceEnd, Player.Location,
		true, TraceExtent);
	return HitActor != None && HitActor.bWorldGeometry;
}

function RestoreSeamAssistRadius()
{
	if (!bSeamAssistRadiusReduced || SeamAssistPlayer == None)
		return;
	if (!IsSeamAssistPawnClear(SeamAssistPlayer, SeamAssistOriginalRadius))
		return;
	if (SeamAssistPlayer.SetCollisionSize(SeamAssistOriginalRadius,
		SeamAssistPlayer.CollisionHeight, true))
		bSeamAssistRadiusReduced = false;
}

simulated function DrawSingleView(Canvas C)
{
	local float HudScale;
	local UnrealHUD CurrentHud;

	if (!(class'Locale'.Static.GetLanguage() ~= "elt")
		|| Viewport.Actor == None || UnrealHUD(Viewport.Actor.MyHUD) == None)
	{
		Super.DrawSingleView(C);
		return;
	}

	CurrentHud = UnrealHUD(Viewport.Actor.MyHUD);
	C.SetOrigin(0, 0);
	HudScale = class'HUD'.Default.HudScaler;
	if (HudScale != 1.0)
		C.PushCanvasScale(HudScale, True);
	class'ModernGameHud'.Static.DisplayLocalizedMessages(C, CurrentHud);
	if (HudScale != 1.0)
		C.PopCanvasScale();
}

function string FormatFPS(float Value)
{
	local int DecimalPosition;
	local string ValueText;

	ValueText = string(float(int(Value * 10.0 + 0.5)) / 10.0);
	DecimalPosition = InStr(ValueText, ".");
	if (DecimalPosition < 0)
		return ValueText $ ".0";
	return Left(ValueText, DecimalPosition + 2);
}

function DrawFPSStatistics(Canvas C)
{
	local float AverageFPS;
	local float LabelWidth;
	local float LineHeight;
	local float UnusedHeight;
	local Font SavedFont;
	local float SavedFontScale;
	local byte SavedStyle;
	local color SavedDrawColor;
	local bool bSavedNoSmooth;
	local float SavedZ;

	if (StatisticsTotalTime > 0)
		AverageFPS = StatisticsTotalFrames / StatisticsTotalTime;

	SavedFont = C.Font;
	SavedFontScale = C.FontScale;
	SavedStyle = C.Style;
	SavedDrawColor = C.DrawColor;
	bSavedNoSmooth = C.bNoSmooth;
	SavedZ = C.Z;
	C.Reset();
	C.bNoSmooth = False;
	C.DrawColor = MakeColor(255, 255, 255);
	C.Font = C.LargeFont;
	C.FontScale = 0.5 * class'HUD'.Default.HudScaler;
	C.StrLen("VSync:", LabelWidth, UnusedHeight);
	C.StrLen("T", UnusedHeight, LineHeight);
	LineHeight += FMax(1, LineHeight / 3);
	// Keep the global statistics overlay below the four-line gameplay message
	// area.  This console is shared by every map and language, and scaling the
	// offset with HudScaler keeps the separation consistent with the messages.
	C.SetPos(16, FPSStatisticsStartY * class'HUD'.Default.HudScaler);
	DrawFPSLine(C, "FPS:", StatisticsFPS, LabelWidth, LineHeight);
	DrawFPSLine(C, "AVG:", AverageFPS, LabelWidth, LineHeight);
	DrawFPSLine(C, "Low:", StatisticsLowFPS, LabelWidth, LineHeight);
	DrawFPSLine(C, "High:", StatisticsHighFPS, LabelWidth, LineHeight);
	DrawTextLine(C, "Res:", string(C.SizeX) @ "x" @ string(C.SizeY), LabelWidth, LineHeight);
	DrawTextLine(C, "VSync:", StatisticsVSync, LabelWidth, LineHeight);
	C.Font = SavedFont;
	C.FontScale = SavedFontScale;
	C.Style = SavedStyle;
	C.DrawColor = SavedDrawColor;
	C.bNoSmooth = bSavedNoSmooth;
	C.Z = SavedZ;
}

function DrawFPSLine(Canvas C, string Label, float Value, float LabelWidth, float LineHeight)
{
	local float X;
	local float Y;

	X = C.CurX;
	Y = C.CurY;
	C.DrawText(Label, False, SmoothTextPolyFlags);
	C.SetPos(X + LabelWidth + 8, Y);
	C.DrawText(FormatFPS(Value), False, SmoothTextPolyFlags);
	C.SetPos(X, Y + LineHeight);
}

function DrawTextLine(Canvas C, string Label, string Value, float LabelWidth, float LineHeight)
{
	local float X;
	local float Y;

	X = C.CurX;
	Y = C.CurY;
	C.DrawText(Label, False, SmoothTextPolyFlags);
	C.SetPos(X + LabelWidth + 8, Y);
	C.DrawText(Value, False, SmoothTextPolyFlags);
	C.SetPos(X, Y + LineHeight);
}

function bool KeyEvent(EInputKey Key, EInputAction Action, float Delta)
{
	if (Action == IST_Axis && (Key == IK_JoyX || Key == IK_JoyY))
		UpdateControllerDodgeSuppression(Key, Delta);
	if (Key == IK_Joy8 && Action == IST_Press)
	{
		LaunchUWindow();
		return True;
	}
	return Super.KeyEvent(Key, Action, Delta);
}

function UpdateControllerDodgeSuppression(EInputKey Key, float Delta)
{
	local PlayerPawn Player;

	Player = Viewport.Actor;
	if (Player == None)
		return;
	if (Key == IK_JoyX)
		ControllerGameplayX = Delta;
	else
		ControllerGameplayY = Delta;
	if (ControllerGameplayX != 0 || ControllerGameplayY != 0)
	{
		if (!bControllerDodgeSuppressed)
		{
			SavedDodgeClickTime = Player.DodgeClickTime;
			bControllerDodgeSuppressed = True;
		}
		Player.DodgeClickTime = 0;
	}
	else if (bControllerDodgeSuppressed)
	{
		Player.DodgeClickTime = SavedDodgeClickTime;
		bControllerDodgeSuppressed = False;
	}
}

function LaunchUWindow()
{
	if (Viewport.Actor != None
		&& Left(Viewport.Actor.ConsoleCommand("D3D12 OPENXRPOSE"), 1) == "1")
		Viewport.Actor.ConsoleCommand("D3D12 RESETVRUIANCHOR");
	if (bControllerDodgeSuppressed && Viewport.Actor != None)
	{
		Viewport.Actor.DodgeClickTime = SavedDodgeClickTime;
		bControllerDodgeSuppressed = False;
	}
	ControllerMenuScale = float(Viewport.Actor.ConsoleCommand("get ini:Engine.Engine.ViewportManager ScaleXYZ"));
	if (ControllerMenuScale == 0)
		ControllerMenuScale = 1;
	ControllerMenuX = 0;
	ControllerMenuY = 0;
	ControllerMenuDirection = -1;
	ControllerMenuNextRepeat = 0;
	Super.LaunchUWindow();
	if (ModernRootWindow(Root) != None && ModernRootWindow(Root).MenuBar != None)
		ModernRootWindow(Root).MenuBar.CloseUp();
}

state Menuing
{
	event Tick(float Delta)
	{
		Viewport.Actor.bShowMenu = False;
		LaunchUWindow();
	}
}

state UWindow
{
	event PostRender(Canvas C)
	{
		local bool bVRUI;

		if (LocalizedHudMedFont != None)
			C.MedFont = LocalizedHudMedFont;
		bVRUI = Viewport.Actor != None
			&& Left(Viewport.Actor.ConsoleCommand("D3D12 OPENXRPOSE"), 1) == "1";
		if (bVRUI)
			Viewport.Actor.ConsoleCommand("D3D12 BEGINVRUIPASS");
		Super.PostRender(C);
		if (bVRUI)
			Viewport.Actor.ConsoleCommand("D3D12 ENDVRUIPASS");
	}

	function bool KeyEvent(EInputKey Key, EInputAction Action, float Delta)
	{
		local ModernRootWindow ModernRoot;
		local ModernBindingsClientWindow Bindings;
		local bool bWasPolling;
		local bool bHandled;

		ModernRoot = ModernRootWindow(Root);
		if (ModernRoot != None && Action == IST_Press
			&& Key != IK_MouseWheelUp && Key != IK_MouseWheelDown)
			ModernRoot.bSuppressFocusIndicator = False;
		if (ModernRoot != None)
			Bindings = ModernRoot.ControllerBindings;
		if (Bindings != None && !Bindings.IsVisibleForInput())
			Bindings = None;

		if (Bindings != None && Bindings.bPolling && Action == IST_Release
			&& BindingActivationKey == int(Key))
		{
			BindingActivationKey = -1;
			return True;
		}
		if (Action == IST_Press && Bindings != None && Bindings.bPolling)
		{
			if (Key == IK_Joy2)
				Bindings.CancelKeySelection(True);
			else if (Key == IK_Joy8)
			{
				ModernRoot.PrepareControllerMenuClose();
				CloseUWindow();
			}
			else if (CaptureControllerBinding(Bindings, Key))
				return True;
			else if (Bindings.CaptureKeyboardBinding(int(Key)))
				return True;
			return Super.KeyEvent(Key, Action, Delta);
		}
		if (Action == IST_Press && ModernRoot != None
			&& (Key == IK_MouseWheelUp || Key == IK_MouseWheelDown))
		{
			if (Key == IK_MouseWheelUp && ModernRoot.ScrollVisibleOptions(-1))
				return True;
			if (Key == IK_MouseWheelDown && ModernRoot.ScrollVisibleOptions(1))
				return True;
		}
		if (Action == IST_Press && Bindings != None && Key == IK_Tab)
		{
			Bindings.FocusNextBindingControl();
			return True;
		}
		if (Action == IST_Press && ModernRoot != None && Key == IK_Tab)
		{
			ModernRoot.FocusAdjacentControl(True);
			return True;
		}
		if (Action == IST_Press && Bindings != None
			&& (Key == IK_Delete || Key == IK_Joy4)
			&& Bindings.ClearFocusedBinding())
			return True;
		if (Action == IST_Press && Bindings != None
			&& (Key == IK_Enter || Key == IK_Space)
			&& Bindings.BeginFocusedBindingCapture(Key == IK_Space))
		{
			BindingActivationKey = int(Key);
			return True;
		}
		if (Action == IST_Press && Bindings != None
			&& (Key == IK_Joy1 || Key == IK_Joy3)
			&& Bindings.BeginFocusedBindingCapture(Key == IK_Joy3))
		{
			BindingActivationKey = int(Key);
			return True;
		}
		if (Action == IST_Press && ModernRoot != None
			&& (Key == IK_Enter || Key == IK_Space)
			&& ModernRoot.CanKeyboardConfirmFocusedControl())
		{
			ModernRoot.ControllerConfirm();
			return True;
		}
		if (Action == IST_Press && ModernRoot != None)
		{
			switch (Key)
			{
			case IK_Up:
				ModernRoot.ControllerNavigate(0);
				return True;
			case IK_Down:
				ModernRoot.ControllerNavigate(1);
				return True;
			case IK_Left:
				ModernRoot.ControllerNavigate(2);
				return True;
			case IK_Right:
				ModernRoot.ControllerNavigate(3);
				return True;
			}
		}
		if (Action == IST_Axis && (Key == IK_JoyZ || Key == IK_JoyR))
		{
			if (Key == IK_JoyZ)
				ControllerMenuX = Delta / ControllerMenuScale;
			else
				ControllerMenuY = Delta / ControllerMenuScale;
			UpdateControllerMenuDirection(ModernRoot);
			return True;
		}
		if (IsControllerMenuKey(Key))
		{
			if (Action == IST_Press && ModernRoot != None)
			{
				switch (Key)
				{
				case IK_Joy1:
					ModernRoot.ControllerConfirm();
					break;
				case IK_Joy2:
					ModernRoot.ControllerBack();
					break;
				case IK_Joy5:
					ModernRoot.SwitchOptionsTab(False);
					break;
				case IK_Joy6:
					ModernRoot.SwitchOptionsTab(True);
					break;
				case IK_Joy8:
					ModernRoot.PrepareControllerMenuClose();
					CloseUWindow();
					break;
				case EInputKey(240):
					ModernRoot.ControllerNavigate(0);
					break;
				case EInputKey(241):
					ModernRoot.ControllerNavigate(1);
					break;
				case EInputKey(242):
					ModernRoot.ControllerNavigate(2);
					break;
				case EInputKey(243):
					ModernRoot.ControllerNavigate(3);
					break;
				}
			}
			return True;
		}
		bWasPolling = Bindings != None && Bindings.bPolling;
		bHandled = Super.KeyEvent(Key, Action, Delta);
		if (Action == IST_Press && Bindings != None && !bWasPolling && Bindings.bPolling)
			BindingActivationKey = int(Key);
		return bHandled;
	}

	function bool CaptureControllerBinding(ModernBindingsClientWindow Bindings, EInputKey Key)
	{
		switch (Key)
		{
		case IK_Joy1:
			Bindings.ProcessMenuKey(200, "Joy1");
			break;
		case IK_Joy3:
			Bindings.ProcessMenuKey(202, "Joy3");
			break;
		case IK_Joy4:
			Bindings.ProcessMenuKey(203, "Joy4");
			break;
		case IK_Joy5:
			Bindings.ProcessMenuKey(204, "Joy5");
			break;
		case IK_Joy6:
			Bindings.ProcessMenuKey(205, "Joy6");
			break;
		case IK_Joy7:
			Bindings.ProcessMenuKey(206, "Joy7");
			break;
		case IK_Joy9:
			Bindings.ProcessMenuKey(208, "Joy9");
			break;
		case IK_Joy10:
			Bindings.ProcessMenuKey(209, "Joy10");
			break;
		case IK_Joy11:
			Bindings.ProcessMenuKey(210, "Joy11");
			break;
		case IK_Joy12:
			Bindings.ProcessMenuKey(211, "Joy12");
			break;
		case EInputKey(240):
			Bindings.ProcessMenuKey(240, "JoyPovUp");
			break;
		case EInputKey(241):
			Bindings.ProcessMenuKey(241, "JoyPovDown");
			break;
		case EInputKey(242):
			Bindings.ProcessMenuKey(242, "JoyPovLeft");
			break;
		case EInputKey(243):
			Bindings.ProcessMenuKey(243, "JoyPovRight");
			break;
		default:
			return False;
		}
		return True;
	}

	function UpdateControllerMenuDirection(ModernRootWindow ModernRoot)
	{
		local int NewDirection;
		local float AbsX;
		local float AbsY;
		local float Now;

		AbsX = ControllerMenuX;
		if (AbsX < 0)
			AbsX = -AbsX;
		AbsY = ControllerMenuY;
		if (AbsY < 0)
			AbsY = -AbsY;
		NewDirection = -1;
		if (AbsX >= ControllerMenuThreshold || AbsY >= ControllerMenuThreshold)
		{
			if (AbsX > AbsY)
			{
				if (ControllerMenuX > 0)
					NewDirection = 3;
				else
					NewDirection = 2;
			}
			else if (ControllerMenuY < 0)
				NewDirection = 1;
			else
				NewDirection = 0;
		}

		if (NewDirection < 0)
		{
			ControllerMenuDirection = -1;
			return;
		}
		if (ModernRoot == None)
			return;

		Now = Viewport.Actor.Level.TimeSeconds;
		if (NewDirection != ControllerMenuDirection)
		{
			ControllerMenuDirection = NewDirection;
			if (ModernRoot.HasFocusedControllerSlider())
				ControllerMenuNextRepeat = Now + ControllerSliderInitialRepeat;
			else
				ControllerMenuNextRepeat = Now + ControllerMenuInitialRepeat;
			ModernRoot.ControllerNavigate(NewDirection);
		}
		else if (Now >= ControllerMenuNextRepeat)
		{
			if (ModernRoot.HasFocusedControllerSlider())
				ControllerMenuNextRepeat = Now + ControllerSliderRepeatInterval;
			else
				ControllerMenuNextRepeat = Now + ControllerMenuRepeatInterval;
			ModernRoot.ControllerNavigate(NewDirection);
		}
	}

	function bool IsControllerMenuKey(EInputKey Key)
	{
		switch (Key)
		{
		case IK_Joy1:
		case IK_Joy2:
		case IK_Joy5:
		case IK_Joy6:
		case IK_Joy8:
		case IK_JoyX:
		case IK_JoyY:
		case EInputKey(240):
		case EInputKey(241):
		case EInputKey(242):
		case EInputKey(243):
			return True;
		}
		return False;
	}
}

defaultproperties
{
	RootWindow="ModernMenu.ModernRootWindow"
	PreloadedBruteProjectileClass=Class'UnrealShare.BruteProjectile'
	PreloadedBruteSmokeClass=Class'UnrealShare.SpriteSmokePuff'
	PreloadedBruteExplosionClass=Class'UnrealShare.SpriteBallExplosion'
	PreloadedBruteExplosionChildClass=Class'UnrealShare.SpriteBallChild'
	PreloadedBruteBlackSmokeClass=Class'UnrealShare.BlackSmoke'
	PreloadedBruteDecalClass=Class'UnrealShare.RipperMark'
}
