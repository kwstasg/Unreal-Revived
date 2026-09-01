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
		DrawFocusIndicator(C);
	}
	else
		Super.WindowEvent(Msg, C, X, Y, Key);
}

function DrawFocusIndicator(Canvas C)
{
	local UWindowWindow FocusedControl;
	local UWindowWindow Parent;
	local UWindowHSliderControl Slider;
	local UWindowCheckbox Checkbox;
	local UWindowComboControl Combo;
	local UWindowEditControl EditControl;
	local float FocusLeft;
	local float FocusTop;
	local float FocusWidth;
	local float FocusHeight;
	local float ParentLeft;
	local float ParentTop;
	local float VisibleLeft;
	local float VisibleTop;
	local float VisibleRight;
	local float VisibleBottom;

	FocusedControl = Root.KeyFocusWindow;
	if (FocusedControl == None)
		return;
	for (Parent = FocusedControl; Parent != None && Parent != Self; Parent = Parent.ParentWindow)
		if (UWindowPulldownMenu(Parent) != None || UWindowComboList(Parent) != None)
			return;

	while (FocusedControl.ParentWindow != None && UWindowDialogControl(FocusedControl.ParentWindow) != None)
		FocusedControl = FocusedControl.ParentWindow;
	if (UWindowDialogControl(FocusedControl) == None || !FocusedControl.bWindowVisible)
		return;

	FocusLeft = FocusedControl.WinLeft;
	FocusTop = FocusedControl.WinTop;
	FocusWidth = FocusedControl.WinWidth;
	FocusHeight = FocusedControl.WinHeight;
	Slider = UWindowHSliderControl(FocusedControl);
	Checkbox = UWindowCheckbox(FocusedControl);
	Combo = UWindowComboControl(FocusedControl);
	EditControl = UWindowEditControl(FocusedControl);
	if (Slider != None)
	{
		FocusLeft += Slider.SliderDrawX;
		FocusTop += Slider.SliderDrawY - 4;
		FocusWidth = Slider.SliderWidth;
		FocusHeight = 10;
	}
	else if (Checkbox != None)
	{
		FocusLeft += Checkbox.ImageX;
		FocusTop += Checkbox.ImageY;
		FocusWidth = 16;
		FocusHeight = 16;
	}
	else if (Combo != None)
	{
		if (Combo.bListVisible)
			return;
		FocusLeft += Combo.EditAreaDrawX;
		FocusWidth = Combo.EditBoxWidth;
	}
	else if (EditControl != None)
	{
		FocusLeft += EditControl.EditAreaDrawX;
		FocusWidth = EditControl.EditBoxWidth;
	}
	for (Parent = FocusedControl.ParentWindow; Parent != None && Parent != Self; Parent = Parent.ParentWindow)
	{
		if (!Parent.bWindowVisible)
			return;
		FocusLeft += Parent.WinLeft;
		FocusTop += Parent.WinTop;
	}
	if (Parent != Self || FocusWidth <= 0 || FocusHeight <= 0)
		return;

	VisibleLeft = 0;
	VisibleTop = 0;
	VisibleRight = WinWidth;
	VisibleBottom = WinHeight;
	for (Parent = FocusedControl.ParentWindow; Parent != None && Parent != Self; Parent = Parent.ParentWindow)
	{
		Parent.WindowToGlobal(0, 0, ParentLeft, ParentTop);
		VisibleLeft = FMax(VisibleLeft, ParentLeft);
		VisibleTop = FMax(VisibleTop, ParentTop);
		VisibleRight = FMin(VisibleRight, ParentLeft + Parent.WinWidth);
		VisibleBottom = FMin(VisibleBottom, ParentTop + Parent.WinHeight);
	}
	FocusWidth = FMin(FocusLeft + FocusWidth, VisibleRight) - FMax(FocusLeft, VisibleLeft);
	FocusHeight = FMin(FocusTop + FocusHeight, VisibleBottom) - FMax(FocusTop, VisibleTop);
	FocusLeft = FMax(FocusLeft, VisibleLeft);
	FocusTop = FMax(FocusTop, VisibleTop);
	if (FocusWidth <= 0 || FocusHeight <= 0)
		return;

	C.Style = GetPlayerOwner().ERenderStyle.STY_Normal;
	C.DrawColor.R = 255;
	C.DrawColor.G = 196;
	C.DrawColor.B = 64;
	DrawStretchedTexture(C, FocusLeft - 2, FocusTop - 2, FocusWidth + 4, 2, Texture'WhiteTexture');
	DrawStretchedTexture(C, FocusLeft - 2, FocusTop + FocusHeight, FocusWidth + 4, 2, Texture'WhiteTexture');
	DrawStretchedTexture(C, FocusLeft - 2, FocusTop, 2, FocusHeight, Texture'WhiteTexture');
	DrawStretchedTexture(C, FocusLeft + FocusWidth, FocusTop, 2, FocusHeight, Texture'WhiteTexture');
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