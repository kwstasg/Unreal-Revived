class ModernIntroHud extends IntroNullHud;

#exec TEXTURE IMPORT NAME=NvidiaIntroLogo FILE=Textures\NvidiaIntroLogoRuntime.png GROUP="Logo" MIPS=OFF FLAGS=2

simulated function PostRender(Canvas Canvas)
{
	local float StartX, IconScale;

	HUDSetup(Canvas);

	if ((PlayerPawn(Owner) != None) && PlayerPawn(Owner).bShowMenu)
	{
		DisplayMenu(Canvas);
		return;
	}
	else if (PlayerPawn(Owner).ProgressTimeOut > Level.TimeSeconds)
		DisplayProgressMessage(Canvas);

	Canvas.Font = Canvas.MedFont;
	Canvas.SetPos(Canvas.ClipX / 2.0 - 66, 4);
	Canvas.DrawText(ESCMessage, False);

	StartX = 0.5 * Canvas.ClipX - 128;
	Canvas.SetPos(StartX, Canvas.ClipY - 58);
	Canvas.Style = ERenderStyle.STY_Translucent;
	Canvas.DrawTile(Texture'MenuBarrier', 256, 64, 0, 0, 256, 64);
	Canvas.Style = 2;
	Canvas.SetPos(StartX, Canvas.ClipY - 52);
	Canvas.DrawIcon(Texture'Logo2', 1.0);

	if (Canvas.ClipX > 790)
	{
		Canvas.SetPos(0, Canvas.ClipY - 128);
		Canvas.DrawIcon(Texture'DE', 1.0);
		Canvas.SetPos(0, Canvas.ClipY - 256);
		Canvas.DrawIcon(Texture'GT', 1.0);
		Canvas.SetPos(0, Canvas.ClipY - 384);
		Canvas.DrawIcon(Texture'Epic', 1.0);
		IconScale = 128.0;
	}
	else if (Canvas.ClipX > 390)
	{
		Canvas.SetPos(0, Canvas.ClipY - 64);
		Canvas.DrawIcon(Texture'DE2', 1.0);
		Canvas.SetPos(0, Canvas.ClipY - 128);
		Canvas.DrawIcon(Texture'GT', 0.5);
		Canvas.SetPos(0, Canvas.ClipY - 192);
		Canvas.DrawIcon(Texture'Epic2', 1.0);
		IconScale = 64.0;
	}
	else
		IconScale = 32.0;

	Canvas.SetPos(Canvas.ClipX - IconScale - 1, Canvas.ClipY - IconScale - 1);
	Canvas.DrawRect(Texture'NvidiaIntroLogo', IconScale, IconScale);

	Canvas.Style = 1;
}