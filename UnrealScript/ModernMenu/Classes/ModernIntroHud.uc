// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived

class ModernIntroHud extends IntroNullHud;

#exec TEXTURE IMPORT NAME=NvidiaIntroLogo FILE=Textures\NvidiaIntroLogoRuntime.png GROUP="Logo" MIPS=OFF FLAGS=2
#exec TEXTURE IMPORT NAME=UnrealRevivedIntroLogo FILE=Textures\UnrealRevivedLogo.png GROUP="Logo" MIPS=OFF FLAGS=2

var Font IntroFont;

simulated function PostRender(Canvas Canvas)
{
	local float StartX, IconScale;
	local float MessageWidth, MessageHeight;
	local float LogoHeight;
	local bool bVRUI;

	PlayerPawn(Owner).ConsoleCommand("D3D12 BEGINUIPASS");
	HUDSetup(Canvas);
	bVRUI = Left(PlayerPawn(Owner).ConsoleCommand("D3D12 OPENXRPOSE"), 1) == "1";
	if (bVRUI)
		PlayerPawn(Owner).ConsoleCommand("D3D12 BEGINVRUIPASS");

	if ((PlayerPawn(Owner) != None) && PlayerPawn(Owner).bShowMenu)
	{
		DisplayMenu(Canvas);
		if (bVRUI)
			PlayerPawn(Owner).ConsoleCommand("D3D12 ENDVRUIPASS");
		return;
	}
	else if (PlayerPawn(Owner).ProgressTimeOut > Level.TimeSeconds)
		DisplayProgressMessage(Canvas);

	if (IntroFont == None)
		IntroFont = Font(DynamicLoadObject("UWindowFonts.Tahoma10", class'Font'));
	if (IntroFont == None)
		IntroFont = Canvas.MedFont;
	Canvas.Font = IntroFont;
	Canvas.DrawColor = MakeColor(0, 255, 0);
	Canvas.TextSize(ESCMessage, MessageWidth, MessageHeight);
	Canvas.SetPos((Canvas.ClipX - MessageWidth) / 2.0, 4);
	Canvas.DrawText(ESCMessage, False);
	Canvas.DrawColor = MakeColor(255, 255, 255);

	StartX = 0.5 * Canvas.ClipX - 128;
	Canvas.Style = 2;
	// Keep the original width and bottom-center anchor. Use the source PNG's
	// aspect, independently of any power-of-two texture import conversion.
	LogoHeight = 256.0 * 725.0 / 2168.0;
	Canvas.SetPos(StartX, Canvas.ClipY - LogoHeight);
	Canvas.DrawTile(Texture'UnrealRevivedIntroLogo', 256, LogoHeight, 0, 0,
		Texture'UnrealRevivedIntroLogo'.USize, Texture'UnrealRevivedIntroLogo'.VSize);

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
	if (bVRUI)
		PlayerPawn(Owner).ConsoleCommand("D3D12 ENDVRUIPASS");
}
