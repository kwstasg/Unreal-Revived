// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived

// Adapted from the 227k_15 UPakHUD.PostRender layout. Inherit expansion
// hints, crosshair rules, menu behavior and cinematic flags from UPakHUD.
class ModernUPakHud extends UPakHUD;

function CopyExpansionState(UPakHUD Previous)
{
	// Saves and campaign scripts can set these on the live stock HUD before
	// the console installs the adapter. Preserve the active cinematic/hint.
	bNoMenu = Previous.bNoMenu;
	bCheck = Previous.bCheck;
	bLetterBox = Previous.bLetterBox;
	bNoHUD = Previous.bNoHUD;
	bNoCrosshair = Previous.bNoCrosshair;
	bHintDisplayed = Previous.bHintDisplayed;
	bDisplayHint = Previous.bDisplayHint;
	HintFadeOutTime = Previous.HintFadeOutTime;
	MultWeapSlotMsg = Previous.MultWeapSlotMsg;
	HudMode = Previous.HudMode;
	Crosshair = Previous.Crosshair;
	MOTDFadeOutTime = Previous.MOTDFadeOutTime;
}

simulated function PostRender( canvas Canvas )
{
	local float XL, YL;
	local PlayerPawn Player;

	Player = PlayerPawn(Owner);
	if (Player == None)
		return;
	Player.ConsoleCommand("D3D12 BEGINUIPASS");
	if (Left(Player.ConsoleCommand("D3D12 OPENXRPOSE"), 1) != "1")
	{
		Super.PostRender(Canvas);
		return;
	}


	HUDSetup(canvas);

	if ( PlayerPawn(Owner) != None )
	{
		if ( PlayerPawn(Owner).bShowMenu  )
		{
			if( bCheck )
			{
				Player.ConsoleCommand("D3D12 BEGINVRUIPASS");
				DisplayMenu(Canvas);
				Player.ConsoleCommand("D3D12 ENDVRUIPASS");
				return;
			}
			else
			{
				if (UPakConsole(Player.Player.Console) != None)
					UPakConsole(Player.Player.Console).bTransition = false;
				PlayerPawn( Owner ).bShowMenu = false;
				PlayerPawn( Owner ).SetPause( false );
				bCheck = true;
			}
		}

		if ( PlayerPawn(Owner).bShowScores )
		{
			if ( ( PlayerPawn(Owner).Weapon != None ) && ( !PlayerPawn(Owner).Weapon.bOwnsCrossHair ) )
				DrawCrossHair(Canvas, 0.5 * Canvas.ClipX - 8, 0.5 * Canvas.ClipY - 8);
			if ( (PlayerPawn(Owner).Scoring == None) && (PlayerPawn(Owner).ScoringType != None) )
				PlayerPawn(Owner).Scoring = Spawn(PlayerPawn(Owner).ScoringType, PlayerPawn(Owner));
			if ( PlayerPawn(Owner).Scoring != None )
			{
				Player.ConsoleCommand("D3D12 BEGINVRUIPASS");
				PlayerPawn(Owner).Scoring.ShowScores(Canvas);
				Player.ConsoleCommand("D3D12 ENDVRUIPASS");
				return;
			}
		}
		else if ( (PlayerPawn(Owner).Weapon != None) && (Level.LevelAction == LEVACT_None) )
		{
			PlayerPawn(Owner).Weapon.PostRender(Canvas);
			if ( !PlayerPawn(Owner).Weapon.bOwnsCrossHair )
				DrawCrossHair(Canvas, 0.5 * Canvas.ClipX - 8, 0.5 * Canvas.ClipY - 8);
		}

	}

	// Keep weapon overlays and the gaze crosshair in the eye projection.
	// All expansion status graphics use the same panel as the Unreal HUD.
	Player.ConsoleCommand("D3D12 BEGINVRUIPASS");
	if( bDisplayHint )
	{
		if( HintFadeOutTime != 0 )
		{
			Canvas.Style = 3;
			Canvas.bCenter = true;
			Canvas.SetPos( 0.0, 95 );
			Canvas.Font = Canvas.MedFont;
			Canvas.DrawColor.R = 0;
			Canvas.DrawColor.G = HintFadeOutTime / 2;
			Canvas.DrawColor.B = HintFadeOutTime;
			Canvas.SetPos(0.0, 32);
			Canvas.StrLen("TEST", XL, YL);
			Canvas.DrawColor.R = HintFadeOutTime;
			Canvas.DrawColor.G = HintFadeOutTime;
			Canvas.DrawColor.B = HintFadeOutTime;

			Canvas.SetPos(0.0, 32 + YL);
			Canvas.DrawText( MultWeapSlotMsg, true );
		}
		else bDisplayHint = false;
	}

	HUDSetup(Canvas);
	if( bLetterBox && !bNoHUD )
		DrawLetterBox(Canvas);
	if (Player.ProgressTimeOut > Level.TimeSeconds)
		DisplayProgressMessage(Canvas);

	if (HudMode==5)
	{
		DrawInventory(Canvas, Canvas.ClipX-96, 0,False);
		Player.ConsoleCommand("D3D12 ENDVRUIPASS");
		Return;
	}
	if (Canvas.ClipX<320) HudMode = 4;

	// Draw Armor
	if (HudMode<2) DrawArmor(Canvas, 0, 0,False);
	else if (HudMode==3 || HudMode==2) DrawArmor(Canvas, 0, Canvas.ClipY-32,False);
	else if (HudMode==4) DrawArmor(Canvas, Canvas.ClipX-64, Canvas.ClipY-64,True);

	// Draw Ammo
	if (HudMode!=4) DrawAmmo(Canvas, Canvas.ClipX-48-64, Canvas.ClipY-32);
	else DrawAmmo(Canvas, Canvas.ClipX-48, Canvas.ClipY-32);

	// Draw Health
	if (HudMode<2) DrawHealth(Canvas, 0, Canvas.ClipY-32);
	else if (HudMode==3||HudMode==2) DrawHealth(Canvas, Canvas.ClipX-128, Canvas.ClipY-32);
	else if (HudMode==4) DrawHealth(Canvas, Canvas.ClipX-64, Canvas.ClipY-32);

	// Display Inventory
	if (HudMode<2) DrawInventory(Canvas, Canvas.ClipX-96, 0,False);
	else if (HudMode==3) DrawInventory(Canvas, Canvas.ClipX-96, Canvas.ClipY-64,False);
	else if (HudMode==4) DrawInventory(Canvas, Canvas.ClipX-64, Canvas.ClipY-64,True);
	else if (HudMode==2) DrawInventory(Canvas, Canvas.ClipX/2-64, Canvas.ClipY-32,False);

	// Display Frag count
	if ( (Level.Game == None) || Level.Game.IsA('DeathMatchGame') )
	{
		if (HudMode<3) DrawFragCount(Canvas, Canvas.ClipX-32,Canvas.ClipY-64);
		else if (HudMode==3) DrawFragCount(Canvas, 0,Canvas.ClipY-64);
		else if (HudMode==4) DrawFragCount(Canvas, 0,Canvas.ClipY-32);
	}

	// Display Identification Info
	if (!bNoHUD)
		DrawIdentifyInfo(Canvas, 0, Canvas.ClipY - 64.0);

	// Message of the Day / Map Info Header
	if (MOTDFadeOutTime != 0.0)
		DrawMOTD(Canvas);

	// Team Game Synopsis
	if (Player.GameReplicationInfo != None && Player.GameReplicationInfo.bTeamGame)
		DrawTeamGameSynopsis(Canvas);

	if( bLetterBox && bNoHUD )
		DrawLetterBox(Canvas);
	Player.ConsoleCommand("D3D12 ENDVRUIPASS");
}

