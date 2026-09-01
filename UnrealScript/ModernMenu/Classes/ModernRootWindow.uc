class ModernRootWindow extends UMenuRootWindow;

#exec TEXTURE IMPORT NAME=ModernBg11 FILE=Textures\ModernBg11.bmp GROUP="Icons" MIPS=OFF VClampMode=VClamp UClampMode=UClamp
#exec TEXTURE IMPORT NAME=ModernBg21 FILE=Textures\ModernBg21.bmp GROUP="Icons" MIPS=OFF VClampMode=VClamp UClampMode=UClamp
#exec TEXTURE IMPORT NAME=ModernBg31 FILE=Textures\ModernBg31.bmp GROUP="Icons" MIPS=OFF VClampMode=VClamp UClampMode=UClamp
#exec TEXTURE IMPORT NAME=ModernBg41 FILE=Textures\ModernBg41.bmp GROUP="Icons" MIPS=OFF VClampMode=VClamp UClampMode=UClamp
#exec TEXTURE IMPORT NAME=ModernBg12 FILE=Textures\ModernBg12.bmp GROUP="Icons" MIPS=OFF VClampMode=VClamp UClampMode=UClamp
#exec TEXTURE IMPORT NAME=ModernBg22 FILE=Textures\ModernBg22.bmp GROUP="Icons" MIPS=OFF VClampMode=VClamp UClampMode=UClamp
#exec TEXTURE IMPORT NAME=ModernBg32 FILE=Textures\ModernBg32.bmp GROUP="Icons" MIPS=OFF VClampMode=VClamp UClampMode=UClamp
#exec TEXTURE IMPORT NAME=ModernBg42 FILE=Textures\ModernBg42.bmp GROUP="Icons" MIPS=OFF VClampMode=VClamp UClampMode=UClamp
#exec TEXTURE IMPORT NAME=ModernBg13 FILE=Textures\ModernBg13.bmp GROUP="Icons" MIPS=OFF VClampMode=VClamp UClampMode=UClamp
#exec TEXTURE IMPORT NAME=ModernBg23 FILE=Textures\ModernBg23.bmp GROUP="Icons" MIPS=OFF VClampMode=VClamp UClampMode=UClamp
#exec TEXTURE IMPORT NAME=ModernBg33 FILE=Textures\ModernBg33.bmp GROUP="Icons" MIPS=OFF VClampMode=VClamp UClampMode=UClamp
#exec TEXTURE IMPORT NAME=ModernBg43 FILE=Textures\ModernBg43.bmp GROUP="Icons" MIPS=OFF VClampMode=VClamp UClampMode=UClamp

function Created()
{
	local class<GameInfo> GameClass;
	local PlayerPawn PlayerOwner;

	if (class'UMenuHelpMenu'.Default.SupportURLName == "-")
		class'UMenuHelpMenu'.Default.SupportURLName = "Technical Support";

	PlayerOwner = GetPlayerOwner();
	if (PlayerOwner.MyHUD != None && PlayerOwner.MyHUD.Class == class'UnrealI.IntroNullHud')
	{
		PlayerOwner.MyHUD.Destroy();
		PlayerOwner.HUDType = class'ModernIntroHud';
		PlayerOwner.MyHUD = GetLevel().Spawn(class'ModernIntroHud', PlayerOwner);
	}

	if (GetLevel().Game != None)
	{
		GameClass = GetLevel().Game.Class;
		GameClass.Default.GameOptionsMenuType = "ModernMenu.ModernOptionsMenu";
	}

	Super.Created();

	if (class'ModernVideoClientWindow'.Default.bShowFPS)
		GetPlayerOwner().ConsoleCommand("TIMEDEMO 1");
}

function WindowEvent(WinMessage Msg, Canvas C, float X, float Y, int Key)
{
	if (Msg == WM_Paint)
	{
		if (GetPlayerOwner().MyHUD == None)
			Console.bNoDrawWorld = False;
		else
			Console.bNoDrawWorld = !class'ModernHUDConfigCW'.Default.bShowGameBehindMenus;
		PaintModernBackground(C);
		PaintClients(C, X, Y);
	}
	else
		Super.WindowEvent(Msg, C, X, Y, Key);
}

function PaintModernBackground(Canvas C)
{
	local float XOffset, YOffset, W, H;

	if (Console.bNoDrawWorld)
	{
		DrawStretchedTexture(C, 0, 0, WinWidth, WinHeight, Texture'UMenu.Icons.MenuBlack');

		if (Console.bBlackOut)
			return;

		H = ((WinWidth + 3) * 3) / 16;

		if ((WinHeight + 2) / 3 > H)
			H = (WinHeight + 2) / 3;

		W = (H * 4) / 3;

		XOffset = (WinWidth - ((4 * W) - 3)) / 2;
		YOffset = (WinHeight - ((3 * H) - 2)) / 2;

		C.bNoSmooth = False;

		DrawStretchedTexture(C, XOffset + (3 * (W - 1)), YOffset + (2 * (H - 1)), W, H, Texture'ModernBg43');
		DrawStretchedTexture(C, XOffset + (2 * (W - 1)), YOffset + (2 * (H - 1)), W, H, Texture'ModernBg33');
		DrawStretchedTexture(C, XOffset + (W - 1), YOffset + (2 * (H - 1)), W, H, Texture'ModernBg23');
		DrawStretchedTexture(C, XOffset, YOffset + (2 * (H - 1)), W, H, Texture'ModernBg13');

		DrawStretchedTexture(C, XOffset + (3 * (W - 1)), YOffset + (H - 1), W, H, Texture'ModernBg42');
		DrawStretchedTexture(C, XOffset + (2 * (W - 1)), YOffset + (H - 1), W, H, Texture'ModernBg32');
		DrawStretchedTexture(C, XOffset + (W - 1), YOffset + (H - 1), W, H, Texture'ModernBg22');
		DrawStretchedTexture(C, XOffset, YOffset + (H - 1), W, H, Texture'ModernBg12');

		DrawStretchedTexture(C, XOffset + (3 * (W - 1)), YOffset, W, H, Texture'ModernBg41');
		DrawStretchedTexture(C, XOffset + (2 * (W - 1)), YOffset, W, H, Texture'ModernBg31');
		DrawStretchedTexture(C, XOffset + (W - 1), YOffset, W, H, Texture'ModernBg21');
		DrawStretchedTexture(C, XOffset, YOffset, W, H, Texture'ModernBg11');

		C.bNoSmooth = True;
	}
}