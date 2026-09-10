// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived

class ModernGameHud extends UnrealHUD;

simulated function PostRender(Canvas Canvas)
{
	local PlayerPawn Player;

	// The world is complete when HUD.PostRender begins. Start the shared UI
	// pass before UnrealHUD draws status icons, messages, or weapon overlays.
	PlayerPawn(Owner).ConsoleCommand("D3D12 BEGINUIPASS");
	Player = PlayerPawn(Owner);
	if (Player == None
		|| Left(Player.ConsoleCommand("D3D12 OPENXRPOSE"), 1) != "1")
	{
		Super.PostRender(Canvas);
		return;
	}

	// Keep the weapon and gaze crosshair on the full eye canvas. The remaining
	// status HUD uses the desktop canvas layout on the VR panel, without an
	// additional inset or an override of the user's HUD scaling.
	HUDSetup(Canvas);
	if (Player.PlayerReplicationInfo == None)
		return;
	if (Level.bIsDemoPlayback || Level.bIsDemoRecording)
		DrawDemoInfo(Canvas);
	if (Player.bShowMenu)
	{
		Player.ConsoleCommand("D3D12 BEGINVRUIPASS");
		DisplayMenu(Canvas);
		Player.ConsoleCommand("D3D12 ENDVRUIPASS");
		return;
	}
	if (Player.bShowScores)
	{
		if (Player.Weapon != None && !Player.Weapon.bOwnsCrossHair)
			DrawCrossHair(Canvas, 0.5 * Canvas.ClipX - 8,
				0.5 * Canvas.ClipY - 8);
		if (Player.Scoring == None && Player.ScoringType != None)
			Player.Scoring = Spawn(Player.ScoringType, Player);
		if (Player.Scoring != None)
		{
			Player.ConsoleCommand("D3D12 BEGINVRUIPASS");
			Player.Scoring.ShowScores(Canvas);
			Player.ConsoleCommand("D3D12 ENDVRUIPASS");
			return;
		}
	}
	else if (Player.Weapon != None && Level.LevelAction == LEVACT_None)
	{
		Canvas.Font = Font'WhiteFont';
		Player.Weapon.PostRender(Canvas);
		if (!Player.Weapon.bOwnsCrossHair)
			DrawCrossHair(Canvas, 0.5 * Canvas.ClipX - 8,
				0.5 * Canvas.ClipY - 8);
	}

	Player.ConsoleCommand("D3D12 BEGINVRUIPASS");

	if (Player.ProgressTimeOut > Level.TimeSeconds)
		DisplayProgressMessage(Canvas);
	if (HudMode == 5)
		DrawInventory(Canvas, Canvas.ClipX - 96, 0, False);
	else
	{
		if (HudMode < 2)
			DrawArmor(Canvas, 0, 0, False);
		else if (HudMode == 2 || HudMode == 3)
			DrawArmor(Canvas, 0, Canvas.ClipY - 32, False);
		else if (HudMode == 4)
			DrawArmor(Canvas, Canvas.ClipX - 64, Canvas.ClipY - 64, True);

		if (HudMode != 4)
			DrawAmmo(Canvas, Canvas.ClipX - 48 - 64, Canvas.ClipY - 32);
		else
			DrawAmmo(Canvas, Canvas.ClipX - 48, Canvas.ClipY - 32);

		if (HudMode < 2)
			DrawHealth(Canvas, 0, Canvas.ClipY - 32);
		else if (HudMode == 2 || HudMode == 3)
			DrawHealth(Canvas, Canvas.ClipX - 128, Canvas.ClipY - 32);
		else if (HudMode == 4)
			DrawHealth(Canvas, Canvas.ClipX - 64, Canvas.ClipY - 32);

		if (HudMode < 2)
			DrawInventory(Canvas, Canvas.ClipX - 96, 0, False);
		else if (HudMode == 3)
			DrawInventory(Canvas, Canvas.ClipX - 96, Canvas.ClipY - 64, False);
		else if (HudMode == 4)
			DrawInventory(Canvas, Canvas.ClipX - 64, Canvas.ClipY - 64, True);
		else if (HudMode == 2)
			DrawInventory(Canvas, Canvas.ClipX / 2 - 64,
				Canvas.ClipY - 32, False);

		if (Level.Game == None || Level.Game.bDeathMatch)
		{
			if (HudMode < 3)
				DrawFragCount(Canvas, Canvas.ClipX - 32, Canvas.ClipY - 64);
			else if (HudMode == 3)
				DrawFragCount(Canvas, 0, Canvas.ClipY - 64);
			else if (HudMode == 4)
				DrawFragCount(Canvas, 0, Canvas.ClipY - 32);
		}

		DrawIdentifyInfo(Canvas, 0, Canvas.ClipY - 64.0);
		if (MOTDFadeOutTime != 0.0)
			DrawMOTD(Canvas);
		if (Player.GameReplicationInfo != None
			&& Player.GameReplicationInfo.bTeamGame)
			DrawTeamGameSynopsis(Canvas);
	}

	Player.ConsoleCommand("D3D12 ENDVRUIPASS");
}

static simulated function Font GetLocalizedMessageFont(Canvas Canvas)
{
	local Font MessageFont;

	MessageFont = Font(DynamicLoadObject("UWindowFonts.Tahoma12", class'Font'));
	if (MessageFont == None)
		return Canvas.MedFont;
	return MessageFont;
}

static simulated function Font GetLocalizedMOTDFont(Canvas Canvas)
{
	return GetLocalizedMessageFont(Canvas);
}

static simulated function bool DisplayLocalizedMessages(Canvas Canvas, UnrealHUD SourceHUD)
{
	local float XL, YL;
	local int I, J, YPos;
	local float PickupColor;
	local Console Console;
	local MessageStruct ShortMessages[4];
	local string MessageString[4];
	local name MsgType;

	Console = Canvas.Viewport.Console;
	Canvas.Font = GetLocalizedMessageFont(Canvas);

	if (!Console.Viewport.Actor.bShowMenu)
		SourceHUD.DrawTypingPrompt(Canvas, Console);

	if ((Console.TextLines > 0) && (!Console.Viewport.Actor.bShowMenu || Console.Viewport.Actor.bShowScores))
	{
		MsgType = Console.GetMsgType(Console.TopLine);
		if (MsgType == 'Pickup')
		{
			Canvas.bCenter = True;
			if (SourceHUD.Level.bHighDetailMode)
				Canvas.Style = ERenderStyle.STY_Translucent;
			else
				Canvas.Style = ERenderStyle.STY_Normal;
			PickupColor = 42.0 * FMin(6, Console.GetMsgTick(Console.TopLine));
			Canvas.DrawColor.r = PickupColor;
			Canvas.DrawColor.g = PickupColor;
			Canvas.DrawColor.b = PickupColor;
			Canvas.SetPos(4, Console.FrameY - 44);
			Canvas.DrawText(Console.GetMsgText(Console.TopLine), True);
			Canvas.bCenter = False;
			Canvas.Style = 1;
			J = Console.TopLine - 1;
		}
		else if ((MsgType == 'CriticalEvent') || (MsgType == 'LowCriticalEvent')
			|| (MsgType == 'RedCriticalEvent'))
		{
			Canvas.bCenter = True;
			Canvas.Style = 1;
			Canvas.DrawColor.r = 0;
			Canvas.DrawColor.g = 128;
			Canvas.DrawColor.b = 255;
			if (MsgType == 'CriticalEvent')
				Canvas.SetPos(0, Console.FrameY / 2 - 32);
			else if (MsgType == 'LowCriticalEvent')
				Canvas.SetPos(0, Console.FrameY / 2 + 32);
			else
			{
				PickupColor = 42.0 * FMin(6, Console.GetMsgTick(Console.TopLine));
				Canvas.DrawColor.r = PickupColor;
				Canvas.DrawColor.g = 0;
				Canvas.DrawColor.b = 0;
				Canvas.SetPos(4, Console.FrameY - 44);
			}
			Canvas.DrawText(Console.GetMsgText(Console.TopLine), True);
			Canvas.bCenter = False;
			J = Console.TopLine - 1;
		}
		else
			J = Console.TopLine;

		I = 0;
		while ((I < 4) && (J >= 0))
		{
			MsgType = Console.GetMsgType(J);
			if ((MsgType != '') && (MsgType != 'Log'))
			{
				MessageString[I] = Console.GetMsgText(J);
				if ((MessageString[I] != "") && (Console.GetMsgTick(J) > 0.0))
				{
					if ((MsgType == 'Event') || (MsgType == 'DeathMessage'))
					{
						ShortMessages[I].PRI = None;
						ShortMessages[I].Type = MsgType;
						I++;
					}
					else if ((MsgType == 'Say') || (MsgType == 'TeamSay'))
					{
						ShortMessages[I].PRI = Console.GetMsgPlayer(J);
						ShortMessages[I].Type = MsgType;
						I++;
					}
				}
			}
			J--;
		}

		J = 0;
		Canvas.Font = GetLocalizedMessageFont(Canvas);
		for (I = 0; I < 4; I++)
		{
			if (Len(MessageString[3 - I]) != 0)
			{
				YPos = 2 + J;
				if (!SourceHUD.DrawMessageHeader(Canvas, ShortMessages[3 - I], YPos))
				{
					if (ShortMessages[3 - I].Type == 'DeathMessage')
						Canvas.DrawColor = SourceHUD.RedColor;
					else
						Canvas.DrawColor = MakeColor(200, 200, 200);
					Canvas.SetPos(SourceHUD.ArmorOffset + 4, YPos);
				}
				if (!SourceHUD.SpecialType(ShortMessages[3 - I].Type))
				{
					Canvas.StrLen(MessageString[3 - I], XL, YL);
					Canvas.DrawText(MessageString[3 - I], False);
					J += YL;
				}
			}
		}
	}
	return True;
}

static simulated function DrawLocalizedMOTD(Canvas Canvas, UnrealHUD SourceHUD,
	float FadeOutTime)
{
	local float XL, YL;
	local PlayerPawn PP;

	if (SourceHUD == None || SourceHUD.Owner == None)
		return;

	Canvas.Font = GetLocalizedMOTDFont(Canvas);
	Canvas.Style = 3;
	Canvas.DrawColor.R = FadeOutTime;
	Canvas.DrawColor.G = FadeOutTime;
	Canvas.DrawColor.B = FadeOutTime;
	Canvas.bCenter = True;

	PP = Canvas.Viewport.Actor;
	if (PP.GameReplicationInfo == None)
	{
		foreach SourceHUD.AllActors(class'GameReplicationInfo', PP.GameReplicationInfo)
			break;
	}

	if (PP.GameReplicationInfo != None && PP.GameReplicationInfo.GameName != "Game")
	{
		Canvas.DrawColor.R = 0;
		Canvas.DrawColor.G = FadeOutTime / 2;
		Canvas.DrawColor.B = FadeOutTime;
		Canvas.SetPos(0, 32);
		Canvas.StrLen("TEST", XL, YL);
		if (SourceHUD.Level.NetMode != NM_Standalone)
			Canvas.DrawText(PP.GameReplicationInfo.ServerName);

		Canvas.DrawColor.R = FadeOutTime;
		Canvas.DrawColor.G = FadeOutTime;
		Canvas.DrawColor.B = FadeOutTime;
		Canvas.SetPos(0, 32 + YL);
		Canvas.DrawText(class'UnrealScoreBoard'.Default.GameType $ PP.GameReplicationInfo.GameName, True);
		Canvas.SetPos(0, 32 + 2 * YL);
		Canvas.DrawText(class'UnrealScoreBoard'.Default.MapTitle $ SourceHUD.Level.Title, True);
		Canvas.SetPos(0, 32 + 3 * YL);
		Canvas.DrawText(class'UnrealScoreBoard'.Default.Author $ SourceHUD.Level.Author, True);
		Canvas.SetPos(0, 32 + 4 * YL);
		if (SourceHUD.Level.IdealPlayerCount != "")
			Canvas.DrawText(class'UnrealScoreBoard'.Default.IdealPlayerCount $ SourceHUD.Level.IdealPlayerCount, True);

		Canvas.DrawColor.R = 0;
		Canvas.DrawColor.G = FadeOutTime / 2;
		Canvas.DrawColor.B = FadeOutTime;
		Canvas.SetPos(0, 32 + 6 * YL);
		Canvas.DrawText(SourceHUD.Level.LevelEnterText, True);
		Canvas.SetPos(0, 32 + 8 * YL);
		Canvas.DrawText(PP.GameReplicationInfo.MOTDLine1, True);
		Canvas.SetPos(0, 32 + 9 * YL);
		Canvas.DrawText(PP.GameReplicationInfo.MOTDLine2, True);
		Canvas.SetPos(0, 32 + 10 * YL);
		Canvas.DrawText(PP.GameReplicationInfo.MOTDLine3, True);
		Canvas.SetPos(0, 32 + 11 * YL);
		Canvas.DrawText(PP.GameReplicationInfo.MOTDLine4, True);
	}

	Canvas.bCenter = False;
	Canvas.Style = 1;
	Canvas.DrawColor = MakeColor(255, 255, 255);
}

static simulated function DrawLocalizedTranslator(Canvas Canvas, Translator T)
{
	local float SavedOrgX, SavedOrgY, SavedClipX, SavedClipY;
	local float SavedCurX, SavedCurY, SavedFontScale;
	local Font SavedFont, TranslatorFont;
	local byte SavedStyle;
	local color SavedColor;
	local bool bSavedCenter;
	local string CurrentMessage;

	SavedOrgX = Canvas.OrgX;
	SavedOrgY = Canvas.OrgY;
	SavedClipX = Canvas.ClipX;
	SavedClipY = Canvas.ClipY;
	SavedCurX = Canvas.CurX;
	SavedCurY = Canvas.CurY;
	SavedFont = Canvas.Font;
	SavedFontScale = Canvas.FontScale;
	SavedStyle = Canvas.Style;
	SavedColor = Canvas.DrawColor;
	bSavedCenter = Canvas.bCenter;

	if (T.bShowHint && Len(T.Hint) != 0)
		CurrentMessage = T.HintString @ T.Hint;
	else
		CurrentMessage = T.NewMessage;

	Canvas.bCenter = False;
	Canvas.FontScale = 1.0;
	Canvas.DrawColor = MakeColor(255, 255, 255);
	Canvas.Style = ERenderStyle.STY_Masked;
	if (T.TranslatorScale <= 1.0)
	{
		Canvas.SetPos(Canvas.ClipX / 2 - 128, Canvas.ClipY / 2 - 68);
		Canvas.DrawIcon(T.LowResHUD, 1.0);
		Canvas.SetOrigin(Canvas.ClipX / 2 - 110, Canvas.ClipY / 2 - 52);
		Canvas.SetClip(225, 110);
		TranslatorFont = Font(DynamicLoadObject("UWindowFonts.Tahoma10", class'Font'));
	}
	else
	{
		Canvas.SetPos(Canvas.ClipX / 2 - 128 * T.TranslatorScale,
			Canvas.ClipY / 2 - 68 * T.TranslatorScale);
		Canvas.DrawTile(T.HiResHUD, T.TranslatorScale * 256, T.TranslatorScale * 256,
			0, 0, T.HiResHUD.USize, T.HiResHUD.VSize);
		Canvas.SetOrigin(Canvas.ClipX / 2 - 100 * T.TranslatorScale,
			Canvas.ClipY / 2 - 52 * T.TranslatorScale);
		Canvas.SetClip(205 * T.TranslatorScale, 110 * T.TranslatorScale);
		if (T.TranslatorScale <= 1.7)
			TranslatorFont = Font(DynamicLoadObject("UWindowFonts.Tahoma14", class'Font'));
		else if (T.TranslatorScale <= 2.35)
			TranslatorFont = Font(DynamicLoadObject("UWindowFonts.Tahoma16", class'Font'));
		else if (T.TranslatorScale <= 4.25)
			TranslatorFont = Font(DynamicLoadObject("UWindowFonts.Tahoma20", class'Font'));
		else
			TranslatorFont = Font(DynamicLoadObject("UWindowFonts.Tahoma30", class'Font'));
	}

	if (TranslatorFont == None)
		TranslatorFont = Canvas.MedFont;
	Canvas.SetPos(0, 0);
	Canvas.Font = TranslatorFont;
	Canvas.DrawColor = MakeColor(0, 255, 0);
	Canvas.Style = ERenderStyle.STY_Normal;
	Canvas.DrawText(CurrentMessage, False);

	Canvas.OrgX = SavedOrgX;
	Canvas.OrgY = SavedOrgY;
	Canvas.ClipX = SavedClipX;
	Canvas.ClipY = SavedClipY;
	Canvas.CurX = SavedCurX;
	Canvas.CurY = SavedCurY;
	Canvas.Font = SavedFont;
	Canvas.FontScale = SavedFontScale;
	Canvas.Style = SavedStyle;
	Canvas.DrawColor = SavedColor;
	Canvas.bCenter = bSavedCenter;
}
