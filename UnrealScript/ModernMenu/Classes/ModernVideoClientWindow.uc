// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived

class ModernVideoClientWindow extends UMenuVideoClientWindow
	config;

var UWindowCheckbox ShowFPSCheck;
var localized string ShowFPSText;
var localized string ShowFPSHelp;
var config bool bShowFPS;
var UWindowComboControl DisplayModeCombo;
var localized string DisplayModeText;
var localized string DisplayModeHelp;
var localized string FullscreenModeText;
var localized string BorderlessModeText;
var localized string WindowedModeText;
var UWindowHSliderControl ContrastSlider;
var localized string ContrastText;
var localized string ContrastHelp;
var config int SavedContrastPercent;
var UWindowHSliderControl SaturationSlider;
var localized string SaturationText;
var localized string SaturationHelp;
var UWindowHSliderControl BloomAmountSlider;
var localized string BloomAmountText;
var localized string BloomAmountHelp;
var UWindowHSliderControl ChromaticAberrationSlider;
var localized string ChromaticAberrationText;
var localized string ChromaticAberrationHelp;
var UWindowHSliderControl VignetteIntensitySlider;
var localized string VignetteIntensityText;
var localized string VignetteIntensityHelp;
var UWindowHSliderControl FilmGrainAmountSlider;
var localized string FilmGrainAmountText;
var localized string FilmGrainAmountHelp;
var UWindowHSliderControl ScanlineStrengthSlider;
var localized string ScanlineStrengthText;
var localized string ScanlineStrengthHelp;
var ModernResetButton BrightnessResetButton;
var ModernResetButton ContrastResetButton;
var ModernResetButton SaturationResetButton;
var ModernResetButton GUIScalingResetButton;
var ModernResetButton LightLODResetButton;
var ModernResetButton BloomAmountResetButton;
var ModernResetButton ChromaticAberrationResetButton;
var ModernResetButton VignetteIntensityResetButton;
var ModernResetButton FilmGrainAmountResetButton;
var ModernResetButton ScanlineStrengthResetButton;
var localized string ResetVideoSettingHelp;
var string SelectedVideoDriver;

function bool IsSupportedVideoDriver(string DriverClass)
{
	return DriverClass ~= "D3D12Drv.D3D12RenderDevice"
		|| DriverClass ~= "OpenGLDrv.OpenGLRenderDevice"
		|| DriverClass ~= "XOpenGLDrv.XOpenGLRenderDevice";
}

function ListAvailableVideoDrivers()
{
	local string NextDesc;
	local string NextDefault;
	local string ClassLeft;
	local string ClassRight;

	VideoCombo.Clear();
	foreach GetPlayerOwner().IntDescIterator(string(class'Engine.RenderDevice'), NextDefault, NextDesc, True)
	{
		if (!IsSupportedVideoDriver(NextDefault))
			continue;
		if (Len(NextDesc) == 0)
		{
			if (!Divide(NextDefault, ".", ClassLeft, ClassRight))
				continue;
			NextDesc = Localize(ClassRight, "ClassCaption", ClassLeft);
		}
		VideoCombo.AddItem(NextDesc, NextDefault);
	}
	VideoCombo.Sort();
}

function Created()
{
	local UWindowWindow Child;
	local float ContrastTop;
	local float SaturationTop;
	local float ShowFPSTop;
	local float BloomAmountTop;
	local float ChromaticAberrationTop;
	local float VignetteIntensityTop;
	local float FilmGrainAmountTop;
	local float ScanlineStrengthTop;

	Super.Created();
	// The stock skin list may omit our active skin. Saving its fallback entry
	// would reset the whole menu system when Preferences closes.
	if (GuiSkinCombo.FindItemIndex2(Root.LookAndFeelClass, True) < 0)
		GuiSkinCombo.AddItem("Unreal Revived", Root.LookAndFeelClass);
	GuiSkinCombo.SetSelectedIndex(GuiSkinCombo.FindItemIndex2(Root.LookAndFeelClass, True));
	CreateDisplayModeControl();
	RemoveObsoleteVideoControls();
	BrightnessSlider.bNoSlidingNotify = False;
	GUIScalingSlider.bNoSlidingNotify = False;
	LightLODSlider.bNoSlidingNotify = False;

	ContrastTop = BrightnessSlider.WinTop + 25;
	SaturationTop = ContrastTop + 25;
	BloomAmountTop = SaturationTop + 25;
	ChromaticAberrationTop = BloomAmountTop + 25;
	VignetteIntensityTop = ChromaticAberrationTop + 25;
	FilmGrainAmountTop = VignetteIntensityTop + 25;
	ScanlineStrengthTop = FilmGrainAmountTop + 25;
	for (Child = FirstChildWindow; Child != None; Child = Child.NextSiblingWindow)
		if (Child.WinTop >= ContrastTop)
			Child.WinTop += 175;

	ShowFPSTop = DisplayModeCombo.WinTop + 25;
	for (Child = FirstChildWindow; Child != None; Child = Child.NextSiblingWindow)
		if (Child.WinTop >= ShowFPSTop)
			Child.WinTop += 25;

	ContrastSlider = UWindowHSliderControl(CreateControl(class'UWindowHSliderControl', BrightnessSlider.WinLeft, ContrastTop, BrightnessSlider.WinWidth, 1));
	ContrastSlider.bNoSlidingNotify = False;
	ContrastSlider.SetRange(50, 200, 1);
	ContrastSlider.SetHelpText(ContrastHelp);
	ContrastSlider.SetFont(F_Normal);

	SaturationSlider = UWindowHSliderControl(CreateControl(class'UWindowHSliderControl', BrightnessSlider.WinLeft, SaturationTop, BrightnessSlider.WinWidth, 1));
	SaturationSlider.bNoSlidingNotify = False;
	SaturationSlider.SetRange(128, 383, 1);
	SaturationSlider.SetHelpText(SaturationHelp);
	SaturationSlider.SetFont(F_Normal);

	ShowFPSCheck = UWindowCheckbox(CreateControl(class'UWindowCheckbox', ShowWindowedCheck.WinLeft, ShowFPSTop, ShowWindowedCheck.WinWidth, 1));
	ShowFPSCheck.SetText(ShowFPSText);
	ShowFPSCheck.SetHelpText(ShowFPSHelp);
	ShowFPSCheck.SetFont(F_Normal);
	ShowFPSCheck.Align = TA_Left;
	ShowFPSCheck.bChecked = bShowFPS;

	BloomAmountSlider = UWindowHSliderControl(CreateControl(class'UWindowHSliderControl', ShowWindowedCheck.WinLeft, BloomAmountTop, ShowWindowedCheck.WinWidth, 1));
	BloomAmountSlider.bNoSlidingNotify = False;
	BloomAmountSlider.SetRange(0, 255, 1);
	BloomAmountSlider.SetHelpText(BloomAmountHelp);
	BloomAmountSlider.SetFont(F_Normal);

	ChromaticAberrationSlider = UWindowHSliderControl(CreateControl(class'UWindowHSliderControl', ShowWindowedCheck.WinLeft, ChromaticAberrationTop, ShowWindowedCheck.WinWidth, 1));
	ChromaticAberrationSlider.bNoSlidingNotify = False;
	ChromaticAberrationSlider.SetRange(0, 255, 1);
	ChromaticAberrationSlider.SetHelpText(ChromaticAberrationHelp);
	ChromaticAberrationSlider.SetFont(F_Normal);

	VignetteIntensitySlider = UWindowHSliderControl(CreateControl(class'UWindowHSliderControl', ShowWindowedCheck.WinLeft, VignetteIntensityTop, ShowWindowedCheck.WinWidth, 1));
	VignetteIntensitySlider.bNoSlidingNotify = False;
	VignetteIntensitySlider.SetRange(0, 255, 1);
	VignetteIntensitySlider.SetHelpText(VignetteIntensityHelp);
	VignetteIntensitySlider.SetFont(F_Normal);

	FilmGrainAmountSlider = UWindowHSliderControl(CreateControl(class'UWindowHSliderControl', ShowWindowedCheck.WinLeft, FilmGrainAmountTop, ShowWindowedCheck.WinWidth, 1));
	FilmGrainAmountSlider.bNoSlidingNotify = False;
	FilmGrainAmountSlider.SetRange(0, 255, 1);
	FilmGrainAmountSlider.SetHelpText(FilmGrainAmountHelp);
	FilmGrainAmountSlider.SetFont(F_Normal);

	ScanlineStrengthSlider = UWindowHSliderControl(CreateControl(class'UWindowHSliderControl', ShowWindowedCheck.WinLeft, ScanlineStrengthTop, ShowWindowedCheck.WinWidth, 1));
	ScanlineStrengthSlider.bNoSlidingNotify = False;
	ScanlineStrengthSlider.SetRange(0, 255, 1);
	ScanlineStrengthSlider.SetHelpText(ScanlineStrengthHelp);
	ScanlineStrengthSlider.SetFont(F_Normal);
	ControlOffset += 200;
	LoadColorSettings();
	LoadBloomSetting();
	LoadChromaticAberrationSetting();
	LoadRetroEffectSettings();
	WidenSliderHandles();
	BrightnessResetButton = CreateSliderResetButton(BrightnessSlider);
	ContrastResetButton = CreateSliderResetButton(ContrastSlider);
	SaturationResetButton = CreateSliderResetButton(SaturationSlider);
	GUIScalingResetButton = CreateSliderResetButton(GUIScalingSlider);
	LightLODResetButton = CreateSliderResetButton(LightLODSlider);
	BloomAmountResetButton = CreateSliderResetButton(BloomAmountSlider);
	ChromaticAberrationResetButton = CreateSliderResetButton(ChromaticAberrationSlider);
	VignetteIntensityResetButton = CreateSliderResetButton(VignetteIntensitySlider);
	FilmGrainAmountResetButton = CreateSliderResetButton(FilmGrainAmountSlider);
	ScanlineStrengthResetButton = CreateSliderResetButton(ScanlineStrengthSlider);
	ConfigureTabOrder();
}

function LoadPawnShadowSettings()
{
	local int UltraIndex;

	// Retire the expensive 1024 pawn-shadow preset, including saved selections.
	if (class'PawnShadow'.default.ShadowDetailRes > 512)
	{
		class'PawnShadow'.default.ShadowDetailRes = 512;
		class'PawnShadow'.static.StaticSaveConfig();
		class'ObjectShadow'.static.UpdateAllShadows(GetLevel(), True);
	}

	Super.LoadPawnShadowSettings();
	UltraIndex = PawnShadowCombo.FindItemIndex2("5");
	if (UltraIndex >= 0)
		PawnShadowCombo.RemoveItem(UltraIndex);
}

function RemoveFromTabOrder(UWindowDialogControl Control)
{
	if (Control == None || Control.TabNext == Control)
		return;

	Control.TabPrev.TabNext = Control.TabNext;
	Control.TabNext.TabPrev = Control.TabPrev;
	if (TabLast == Control)
		TabLast = Control.TabPrev;
	Control.TabNext = Control;
	Control.TabPrev = Control;
}

function PlaceTabAfter(UWindowDialogControl Control, UWindowDialogControl PreviousControl)
{
	if (Control == None || PreviousControl == None || Control == PreviousControl)
		return;

	RemoveFromTabOrder(Control);
	Control.TabNext = PreviousControl.TabNext;
	Control.TabPrev = PreviousControl;
	PreviousControl.TabNext.TabPrev = Control;
	PreviousControl.TabNext = Control;
}

function ConfigureTabOrder()
{
	RemoveFromTabOrder(BrightnessResetButton);
	RemoveFromTabOrder(ContrastResetButton);
	RemoveFromTabOrder(SaturationResetButton);
	RemoveFromTabOrder(GUIScalingResetButton);
	RemoveFromTabOrder(LightLODResetButton);
	RemoveFromTabOrder(BloomAmountResetButton);
	RemoveFromTabOrder(ChromaticAberrationResetButton);
	RemoveFromTabOrder(VignetteIntensityResetButton);
	RemoveFromTabOrder(FilmGrainAmountResetButton);
	RemoveFromTabOrder(ScanlineStrengthResetButton);

	PlaceTabAfter(DisplayModeCombo, VideoCombo);
	PlaceTabAfter(ShowFPSCheck, DisplayModeCombo);
	PlaceTabAfter(ContrastSlider, BrightnessSlider);
	PlaceTabAfter(SaturationSlider, ContrastSlider);
	PlaceTabAfter(BloomAmountSlider, SaturationSlider);
	PlaceTabAfter(ChromaticAberrationSlider, BloomAmountSlider);
	PlaceTabAfter(VignetteIntensitySlider, ChromaticAberrationSlider);
	PlaceTabAfter(FilmGrainAmountSlider, VignetteIntensitySlider);
	PlaceTabAfter(ScanlineStrengthSlider, FilmGrainAmountSlider);
}

function bool ResetControllerSlider(UWindowHSliderControl Slider)
{
	if (Slider == BrightnessSlider)
		Notify(BrightnessResetButton, DE_Click);
	else if (Slider == ContrastSlider)
		Notify(ContrastResetButton, DE_Click);
	else if (Slider == SaturationSlider)
		Notify(SaturationResetButton, DE_Click);
	else if (Slider == GUIScalingSlider)
		Notify(GUIScalingResetButton, DE_Click);
	else if (Slider == LightLODSlider)
		Notify(LightLODResetButton, DE_Click);
	else if (Slider == BloomAmountSlider)
		Notify(BloomAmountResetButton, DE_Click);
	else if (Slider == ChromaticAberrationSlider)
		Notify(ChromaticAberrationResetButton, DE_Click);
	else if (Slider == VignetteIntensitySlider)
		Notify(VignetteIntensityResetButton, DE_Click);
	else if (Slider == FilmGrainAmountSlider)
		Notify(FilmGrainAmountResetButton, DE_Click);
	else if (Slider == ScanlineStrengthSlider)
		Notify(ScanlineStrengthResetButton, DE_Click);
	else
		return False;
	return True;
}

function CreateDisplayModeControl()
{
	local UWindowWindow Child;
	local float BorderlessTop;
	local string CurrentMode;

	CurrentMode = GetPlayerOwner().ConsoleCommand("GetScreenMode");
	bSupportsBorderless = CurrentMode ~= "Fullscreen"
		|| CurrentMode ~= "Borderless"
		|| CurrentMode ~= "Windowed";

	DisplayModeCombo = UWindowComboControl(CreateControl(class'UWindowComboControl', ShowWindowedCheck.WinLeft, ShowWindowedCheck.WinTop, ShowWindowedCheck.WinWidth, 1));
	DisplayModeCombo.SetText(DisplayModeText);
	DisplayModeCombo.SetHelpText(DisplayModeHelp);
	DisplayModeCombo.SetFont(F_Normal);
	DisplayModeCombo.SetEditable(False);
	DisplayModeCombo.AddItem(FullscreenModeText, "Fullscreen");
	if (bSupportsBorderless)
		DisplayModeCombo.AddItem(BorderlessModeText, "Borderless");
	DisplayModeCombo.AddItem(WindowedModeText, "Windowed");

	ShowWindowedCheck.HideWindow();
	ShowWindowedCheck.SetText(DisplayModeText);
	if (BorderlessFSCheck != None)
	{
		BorderlessTop = BorderlessFSCheck.WinTop;
		BorderlessFSCheck.HideWindow();
		BorderlessFSCheck.SetText("");
		for (Child = FirstChildWindow; Child != None; Child = Child.NextSiblingWindow)
			if (Child != DisplayModeCombo && Child.WinTop > BorderlessTop)
				Child.WinTop -= 25;
	}
	SyncDisplayMode();
}

function SyncDisplayMode()
{
	local string CurrentMode;

	CurrentMode = GetPlayerOwner().ConsoleCommand("GetScreenMode");
	if (DisplayModeCombo.GetValue2() != CurrentMode)
		DisplayModeCombo.SetSelectedIndex(DisplayModeCombo.FindItemIndex2(CurrentMode));
	ResolutionCombo.SetDisabled(CurrentMode ~= "Borderless"
		|| GetPlayerOwner().ConsoleCommand("D3D12 VRLAUNCHMODE") == "-vr");
	if (GetPlayerOwner().ConsoleCommand("D3D12 VRLAUNCHMODE") == "-vr")
		ResolutionCombo.SetHelpText("VR layout is fixed at 1280 x 1024 (5:4). Use Preferences > VR > VR Render Quality to change eye resolution.");
}

function ApplyDisplayMode()
{
	GetPlayerOwner().ConsoleCommand("SetScreenMode" @ DisplayModeCombo.GetValue2());
	LoadAvailableSettings();
	SyncDisplayMode();
}

function RemoveObsoleteVideoControls()
{
	local UWindowWindow Child;
	local float ChildTop;
	local float ColorDepthTop;
	local float MouseTop;

	ColorDepthTop = ColorDepthCombo.WinTop;
	MouseTop = MouseSlider.WinTop;
	ColorDepthCombo.HideWindow();
	ColorDepthCombo.SetText("");
	MouseSlider.HideWindow();
	MouseSlider.SetText("");

	for (Child = FirstChildWindow; Child != None; Child = Child.NextSiblingWindow)
	{
		ChildTop = Child.WinTop;
		if (Child != ColorDepthCombo && Child != MouseSlider)
		{
			if (ChildTop > ColorDepthTop)
				Child.WinTop -= 25;
			if (ChildTop > MouseTop)
				Child.WinTop -= 25;
		}
	}
}

function ModernResetButton CreateSliderResetButton(UWindowHSliderControl Slider)
{
	local ModernResetButton Button;

	Button = ModernResetButton(CreateControl(class'ModernResetButton', Slider.WinLeft + Slider.WinWidth - 12, Slider.WinTop, 12, 10));
	Button.SetHelpText(ResetVideoSettingHelp);
	Button.ToolTipString = ResetVideoSettingHelp;
	return Button;
}

function LayoutSliderResetButton(UWindowHSliderControl Slider, ModernResetButton Button)
{
	Slider.SetSize(Slider.WinWidth - Button.WinWidth - 4, 1);
	Slider.SliderWidth -= Button.WinWidth + 4;
	Button.WinLeft = Slider.WinLeft + Slider.WinWidth + 2;
	Button.WinTop = Slider.WinTop + Slider.SliderDrawY + 1 - Button.WinHeight / 2;
	Button.bDisabled = Slider.bDisabled;
}

function WidenSliderHandles()
{
	local UWindowWindow Child;
	local UWindowHSliderControl Slider;

	for (Child = FirstChildWindow; Child != None; Child = Child.NextSiblingWindow)
	{
		Slider = UWindowHSliderControl(Child);
		if (Slider != None)
			Slider.TrackWidth = 8;
	}
}

function string FormatDecimalValue(float Value)
{
	local int DecimalPosition;
	local string ValueText;

	ValueText = string(Value);
	DecimalPosition = InStr(ValueText, ".");
	if (DecimalPosition < 0)
		return ValueText $ ".0";
	return Left(ValueText, DecimalPosition + 2);
}

function UpdateBrightnessText()
{
	BrightnessSlider.SetText(BrightnessText $ " (" $ int(BrightnessSlider.Value) $ "%)");
}

function LoadBrightnessSetting()
{
	local int BrightnessPercent;

	BrightnessPercent = Clamp(int(float(GetPlayerOwner().ConsoleCommand("get ini:Engine.Engine.ViewportManager Brightness")) * 200.0 + 0.5), 50, 200);
	BrightnessSlider.SetValue(BrightnessPercent, True);
	UpdateBrightnessText();
}

function LoadAvailableSettings()
{
	Super.LoadAvailableSettings();
	FormatResolutionOptions();
	// The parent loads brightness in legacy 1-10 units on creation and on
	// resolution/display changes. Restore percent units after every refresh,
	// without notifying the slider or writing the loaded value back.
	BrightnessSlider.SetRange(50, 200, 1);
	LoadBrightnessSetting();
}

static function string ResolutionLabel(string RawResolution)
{
	local string WidthText, HeightText;
	local int Width, Height, Hundredths;
	local float Ratio;
	local string Aspect;

	if (!Divide(Caps(RawResolution), "X", WidthText, HeightText))
		return RawResolution;
	Width = int(WidthText);
	Height = int(HeightText);
	if (Width <= 0 || Height <= 0)
		return RawResolution;
	Ratio = float(Width) / float(Height);
	// Allow rounding in modes such as 1366x768; retain custom/monitor modes.
	if (Abs(Ratio - 16.0/9.0) < 0.002) Aspect = "16:9";
	else if (Abs(Ratio - 16.0/10.0) < 0.002) Aspect = "16:10";
	else if (Abs(Ratio - 4.0/3.0) < 0.002) Aspect = "4:3";
	else if (Abs(Ratio - 5.0/4.0) < 0.002) Aspect = "5:4";
	else if (Abs(Ratio - 3.0/2.0) < 0.002) Aspect = "3:2";
	else if (Abs(Ratio - 32.0/9.0) < 0.002) Aspect = "32:9";
	else if (Abs(Ratio - 21.0/9.0) < 0.002) Aspect = "21:9";
	else if (Width == Height) Aspect = "1:1";
	else
	{
		Hundredths = int(Ratio * 100 + 0.5);
		Aspect = (Hundredths / 100) $ "." $ Right("0" $ int(Hundredths % 100), 2) $ ":1";
	}
	return Width $ " " $ Chr(215) $ " " $ Height $ " (" $ Aspect $ ")";
}

function FormatResolutionOptions()
{
	local UWindowComboListItem Item;
	local string Current;
	local bool WasInitialized;

	WasInitialized = bInitialized;
	bInitialized = False;
	Current = GetPlayerOwner().ConsoleCommand("GetCurrentRes");
	for (Item = UWindowComboListItem(ResolutionCombo.List.Items.Next); Item != None;
		Item = UWindowComboListItem(Item.Next))
	{
		if (Item.Value2 == "")
			Item.Value2 = Item.Value;
		Item.Value = ResolutionLabel(Item.Value2);
	}
	if (ResolutionCombo.FindItemIndex2(Current) < 0)
		ResolutionCombo.AddItem(ResolutionLabel(Current), Current);
	ResolutionCombo.SetSelectedIndex(ResolutionCombo.FindItemIndex2(Current));
	bInitialized = WasInitialized;
}

function SettingsChanged()
{
	local string NewSettings;

	if (!bInitialized || ResolutionCombo.GetValue2() == "")
		return;
	OldSettings = GetPlayerOwner().ConsoleCommand("GetCurrentRes") $ "x"
		$ GetPlayerOwner().ConsoleCommand("GetCurrentColorDepth");
	NewSettings = ResolutionCombo.GetValue2() $ "x" $ ColorDepthCombo.GetValue2();
	if (NewSettings != OldSettings)
	{
		GetPlayerOwner().ConsoleCommand("SetRes " $ NewSettings);
		LoadAvailableSettings();
		ConfirmSettings = MessageBox(ConfirmSettingsTitle, ConfirmSettingsText, MB_YesNo, MR_No, MR_None, 10);
	}
}

function ResolutionChanged(float W, float H)
{
	Super(UWindowDialogClientWindow).ResolutionChanged(W, H);
	// The inherited handler compares the display label to the engine value.
	// Our labels include an aspect ratio; refresh using the raw value instead.
	if (ResolutionCombo != None)
		LoadAvailableSettings();
}

function BrightnessChanged()
{
	if (bInitialized)
		GetPlayerOwner().ConsoleCommand("set ini:Engine.Engine.ViewportManager Brightness" @ (BrightnessSlider.Value / 200.0));
}

function bool HotKeyDown(int Key, float X, float Y)
{
	// Controller navigation uses the same key events. Keep mouse precision
	// and saved percentages intact while making arrow adjustments useful.
	if (bWindowVisible && BrightnessSlider != None && Root.CheckKeyFocusWindow() == BrightnessSlider
		&& !BrightnessSlider.bDisabled && !BrightnessSlider.bIndeterminate)
	{
		if (Key == GetPlayerOwner().EInputKey.IK_Left)
		{
			BrightnessSlider.SetValue(BrightnessSlider.Value - 5);
			return True;
		}
		if (Key == GetPlayerOwner().EInputKey.IK_Right)
		{
			BrightnessSlider.SetValue(BrightnessSlider.Value + 5);
			return True;
		}
	}
	return Super.HotKeyDown(Key, X, Y);
}

function BeforePaint(Canvas C, float X, float Y)
{
	bShowFPS = class'ModernVideoClientWindow'.Default.bShowFPS;
	ShowFPSCheck.bChecked = bShowFPS;
	Super.BeforePaint(C, X, Y);
	SyncDisplayMode();
	DisplayModeCombo.WinLeft = VideoCombo.WinLeft;
	DisplayModeCombo.WinTop = ShowWindowedCheck.WinTop;
	DisplayModeCombo.SetSize(VideoCombo.WinWidth, 1);
	DisplayModeCombo.EditBoxWidth = VideoCombo.EditBoxWidth;
	ShowFPSCheck.WinLeft = ShowWindowedCheck.WinLeft;
	ShowFPSCheck.SetSize(ShowWindowedCheck.WinWidth, 1);
	ContrastSlider.WinLeft = BrightnessSlider.WinLeft;
	ContrastSlider.WinTop = BrightnessSlider.WinTop + 25;
	ContrastSlider.SetSize(BrightnessSlider.WinWidth, 1);
	ContrastSlider.SliderWidth = BrightnessSlider.SliderWidth;
	SaturationSlider.WinLeft = BrightnessSlider.WinLeft;
	SaturationSlider.WinTop = BrightnessSlider.WinTop + 50;
	SaturationSlider.SetSize(BrightnessSlider.WinWidth, 1);
	SaturationSlider.SliderWidth = BrightnessSlider.SliderWidth;
	BloomAmountSlider.WinLeft = BrightnessSlider.WinLeft;
	BloomAmountSlider.WinTop = BrightnessSlider.WinTop + 75;
	BloomAmountSlider.SetSize(BrightnessSlider.WinWidth, 1);
	BloomAmountSlider.SliderWidth = BrightnessSlider.SliderWidth;
	ChromaticAberrationSlider.WinLeft = BrightnessSlider.WinLeft;
	ChromaticAberrationSlider.WinTop = BrightnessSlider.WinTop + 100;
	ChromaticAberrationSlider.SetSize(BrightnessSlider.WinWidth, 1);
	ChromaticAberrationSlider.SliderWidth = BrightnessSlider.SliderWidth;
	VignetteIntensitySlider.WinLeft = BrightnessSlider.WinLeft;
	VignetteIntensitySlider.WinTop = BrightnessSlider.WinTop + 125;
	VignetteIntensitySlider.SetSize(BrightnessSlider.WinWidth, 1);
	VignetteIntensitySlider.SliderWidth = BrightnessSlider.SliderWidth;
	FilmGrainAmountSlider.WinLeft = BrightnessSlider.WinLeft;
	FilmGrainAmountSlider.WinTop = BrightnessSlider.WinTop + 150;
	FilmGrainAmountSlider.SetSize(BrightnessSlider.WinWidth, 1);
	FilmGrainAmountSlider.SliderWidth = BrightnessSlider.SliderWidth;
	ScanlineStrengthSlider.WinLeft = BrightnessSlider.WinLeft;
	ScanlineStrengthSlider.WinTop = BrightnessSlider.WinTop + 175;
	ScanlineStrengthSlider.SetSize(BrightnessSlider.WinWidth, 1);
	ScanlineStrengthSlider.SliderWidth = BrightnessSlider.SliderWidth;
	LayoutSliderResetButton(BrightnessSlider, BrightnessResetButton);
	LayoutSliderResetButton(ContrastSlider, ContrastResetButton);
	LayoutSliderResetButton(SaturationSlider, SaturationResetButton);
	LayoutSliderResetButton(GUIScalingSlider, GUIScalingResetButton);
	LayoutSliderResetButton(LightLODSlider, LightLODResetButton);
	LayoutSliderResetButton(BloomAmountSlider, BloomAmountResetButton);
	LayoutSliderResetButton(ChromaticAberrationSlider, ChromaticAberrationResetButton);
	LayoutSliderResetButton(VignetteIntensitySlider, VignetteIntensityResetButton);
	LayoutSliderResetButton(FilmGrainAmountSlider, FilmGrainAmountResetButton);
	LayoutSliderResetButton(ScanlineStrengthSlider, ScanlineStrengthResetButton);
}

function WindowShown()
{
	Super.WindowShown();
	SyncDisplayMode();
	ShowFPSCheck.bChecked = bShowFPS;
	LoadColorSettings();
	LoadBloomSetting();
	LoadChromaticAberrationSetting();
	LoadRetroEffectSettings();
	SelectedVideoDriver = VideoCombo.GetValue2();
}

function LoadColorSettings()
{
	local bool bD3D12;
	local int Contrast;
	local int ContrastPercent;
	local int Saturation;

	if (ContrastSlider == None || SaturationSlider == None)
		return;

	bD3D12 = GetVideoDriverClassName() ~= "D3D12Drv.D3D12RenderDevice";
	ContrastSlider.bDisabled = !bD3D12;
	SaturationSlider.bDisabled = !bD3D12;
	if (!bD3D12)
	{
		ContrastSlider.SetValue(100, True);
		SaturationSlider.SetValue(255, True);
		UpdateColorSettingText();
		return;
	}

	Contrast = Clamp(int(GetPlayerOwner().ConsoleCommand("get ini:Engine.Engine.GameRenderDevice Contrast")), 0, 255);
	Saturation = Clamp(int(GetPlayerOwner().ConsoleCommand("get ini:Engine.Engine.GameRenderDevice Saturation")), 128, 383);
	ContrastPercent = ContrastValueToPercent(Contrast);
	if (SavedContrastPercent >= 50 && SavedContrastPercent <= 200
		&& ContrastPercentToValue(SavedContrastPercent) == Contrast)
		ContrastPercent = SavedContrastPercent;
	else
	{
		SavedContrastPercent = ContrastPercent;
		SaveConfig();
	}
	ContrastSlider.SetValue(ContrastPercent, True);
	SaturationSlider.SetValue(Saturation, True);
	UpdateColorSettingText();
}

function UpdateColorSettingText()
{
	local int SaturationPercent;

	SaturationPercent = int(200.0 * SaturationSlider.Value / 255.0 + 0.5) - 100;
	ContrastSlider.SetText(ContrastText $ " (" $ int(ContrastSlider.Value) $ "%)");
	SaturationSlider.SetText(SaturationText $ " (" $ SaturationPercent $ "%)");
}

function int ContrastValueToPercent(int ContrastValue)
{
	if (ContrastValue >= 128)
		return 100 + int((ContrastValue - 128) * 300.0 / 127.0 + 0.5);
	return Max(10, int(ContrastValue * 100.0 / 128.0 + 0.5));
}

function int ContrastPercentToValue(int ContrastPercent)
{
	if (ContrastPercent >= 100)
		return 128 + int((ContrastPercent - 100) * 127.0 / 300.0 + 0.5);
	return int(ContrastPercent * 128.0 / 100.0 + 0.5);
}

function ApplyContrastSetting()
{
	local string Value;

	SavedContrastPercent = int(ContrastSlider.Value);
	SaveConfig();
	Value = string(ContrastPercentToValue(SavedContrastPercent));
	GetPlayerOwner().ConsoleCommand("set ini:Engine.Engine.GameRenderDevice Contrast" @ Value);
	GetPlayerOwner().ConsoleCommand("D3D12 CONTRAST" @ Value);
}

function ApplySaturationSetting()
{
	local string Value;

	Value = string(int(SaturationSlider.Value));
	GetPlayerOwner().ConsoleCommand("set ini:Engine.Engine.GameRenderDevice Saturation" @ Value);
	GetPlayerOwner().ConsoleCommand("D3D12 SATURATION" @ Value);
}

function LoadBloomSetting()
{
	local int BloomAmount;

	if (BloomAmountSlider == None)
		return;

	if (!(GetVideoDriverClassName() ~= "D3D12Drv.D3D12RenderDevice"))
	{
		BloomAmountSlider.bDisabled = True;
		BloomAmountSlider.SetValue(0, True);
		UpdateBloomAmountText();
		return;
	}

	BloomAmountSlider.bDisabled = False;
	BloomAmount = Clamp(int(GetPlayerOwner().ConsoleCommand("get ini:Engine.Engine.GameRenderDevice BloomAmount")), 0, 255);
	if (!bool(GetPlayerOwner().ConsoleCommand("get ini:Engine.Engine.GameRenderDevice Bloom")))
		BloomAmount = 0;
	BloomAmountSlider.SetValue(BloomAmount, True);
	UpdateBloomAmountText();
}

function UpdateBloomAmountText()
{
	BloomAmountSlider.SetText(BloomAmountText $ " (" $ int(BloomAmountSlider.Value * 100.0 / 255.0 + 0.5) $ "%)");
}

function ApplyBloomSetting()
{
	local string Amount;
	local string Enabled;

	Amount = string(int(BloomAmountSlider.Value));
	Enabled = string(BloomAmountSlider.Value > 0);
	GetPlayerOwner().ConsoleCommand("set ini:Engine.Engine.GameRenderDevice BloomAmount" @ Amount);
	GetPlayerOwner().ConsoleCommand("set ini:Engine.Engine.GameRenderDevice Bloom" @ Enabled);
	GetPlayerOwner().ConsoleCommand("D3D12 BLOOM" @ Amount);
}

function LoadChromaticAberrationSetting()
{
	local int Amount;

	if (ChromaticAberrationSlider == None)
		return;
	if (!(GetVideoDriverClassName() ~= "D3D12Drv.D3D12RenderDevice"))
	{
		ChromaticAberrationSlider.bDisabled = True;
		ChromaticAberrationSlider.SetValue(0, True);
		UpdateChromaticAberrationText();
		return;
	}
	ChromaticAberrationSlider.bDisabled = False;
	Amount = Clamp(int(GetPlayerOwner().ConsoleCommand("get ini:Engine.Engine.GameRenderDevice ChromaticAberration")), 0, 255);
	ChromaticAberrationSlider.SetValue(Amount, True);
	UpdateChromaticAberrationText();
}

function UpdateChromaticAberrationText()
{
	ChromaticAberrationSlider.SetText(ChromaticAberrationText $ " (" $ int(ChromaticAberrationSlider.Value * 100.0 / 255.0 + 0.5) $ "%)");
}

function ApplyChromaticAberrationSetting()
{
	local string Amount;

	Amount = string(int(ChromaticAberrationSlider.Value));
	GetPlayerOwner().ConsoleCommand("set ini:Engine.Engine.GameRenderDevice ChromaticAberration" @ Amount);
	GetPlayerOwner().ConsoleCommand("D3D12 CHROMATICABERRATION" @ Amount);
}

function LoadRetroEffectSettings()
{
	local bool bD3D12;

	if (VignetteIntensitySlider == None || FilmGrainAmountSlider == None || ScanlineStrengthSlider == None)
		return;
	bD3D12 = GetVideoDriverClassName() ~= "D3D12Drv.D3D12RenderDevice";
	VignetteIntensitySlider.bDisabled = !bD3D12;
	FilmGrainAmountSlider.bDisabled = !bD3D12;
	ScanlineStrengthSlider.bDisabled = !bD3D12;
	if (bD3D12)
	{
		VignetteIntensitySlider.SetValue(Clamp(int(GetPlayerOwner().ConsoleCommand("get ini:Engine.Engine.GameRenderDevice VignetteIntensity")), 0, 255), True);
		FilmGrainAmountSlider.SetValue(Clamp(int(GetPlayerOwner().ConsoleCommand("get ini:Engine.Engine.GameRenderDevice FilmGrainAmount")), 0, 255), True);
		ScanlineStrengthSlider.SetValue(Clamp(int(GetPlayerOwner().ConsoleCommand("get ini:Engine.Engine.GameRenderDevice ScanlineStrength")), 0, 255), True);
	}
	else
	{
		VignetteIntensitySlider.SetValue(0, True);
		FilmGrainAmountSlider.SetValue(0, True);
		ScanlineStrengthSlider.SetValue(0, True);
	}
	UpdateRetroEffectText();
}

function UpdateRetroEffectText()
{
	VignetteIntensitySlider.SetText(VignetteIntensityText $ " (" $ int(VignetteIntensitySlider.Value * 100.0 / 255.0 + 0.5) $ "%)");
	FilmGrainAmountSlider.SetText(FilmGrainAmountText $ " (" $ int(FilmGrainAmountSlider.Value * 100.0 / 255.0 + 0.5) $ "%)");
	ScanlineStrengthSlider.SetText(ScanlineStrengthText $ " (" $ int(ScanlineStrengthSlider.Value * 100.0 / 255.0 + 0.5) $ "%)");
}

function ApplyRetroEffectSetting(UWindowHSliderControl Slider, string SettingName, string CommandName)
{
	local string Amount;

	Amount = string(int(Slider.Value));
	GetPlayerOwner().ConsoleCommand("set ini:Engine.Engine.GameRenderDevice" @ SettingName @ Amount);
	GetPlayerOwner().ConsoleCommand("D3D12" @ CommandName @ Amount);
}

function LoadConditionallySupportedSettings()
{
	local string CurrentMode;

	Super.LoadConditionallySupportedSettings();
	if (!(GetVideoDriverClassName() ~= "D3D12Drv.D3D12RenderDevice"))
	{
		LoadBloomSetting();
		LoadChromaticAberrationSetting();
		LoadRetroEffectSettings();
		return;
	}

	AntialiasingComboOptions = "AntialiasMode=Off AntialiasMode=MSAA_2x AntialiasMode=MSAA_4x AntialiasMode=MSAA_8x";
	AntialiasingCombo.Clear();
	AntialiasingCombo.AddItem(AntialiasingModes[0], "AntialiasMode=Off");
	AntialiasingCombo.AddItem(ReplaceStr(AntialiasingModes[2], "%N", "2"), "AntialiasMode=MSAA_2x");
	AntialiasingCombo.AddItem(ReplaceStr(AntialiasingModes[2], "%N", "4"), "AntialiasMode=MSAA_4x");
	AntialiasingCombo.AddItem(ReplaceStr(AntialiasingModes[2], "%N", "8"), "AntialiasMode=MSAA_8x");
	AntialiasingCombo.SetDisabled(False);

	CurrentMode = GetPlayerOwner().ConsoleCommand("get ini:Engine.Engine.GameRenderDevice AntialiasMode");
	if (CurrentMode ~= "MSAA_8x" || CurrentMode == "3")
		AntialiasingCombo.SetSelectedIndex(3);
	else if (CurrentMode ~= "MSAA_4x" || CurrentMode == "2")
		AntialiasingCombo.SetSelectedIndex(2);
	else if (CurrentMode ~= "MSAA_2x" || CurrentMode == "1")
		AntialiasingCombo.SetSelectedIndex(1);
	else
		AntialiasingCombo.SetSelectedIndex(0);

	LoadBloomSetting();
	LoadChromaticAberrationSetting();
	LoadRetroEffectSettings();
}

function Notify(UWindowDialogControl C, byte E)
{
	Super.Notify(C, E);

	if (E == DE_Change && C == VideoCombo)
	{
		if (bInitialized && VideoCombo.GetValue2() != SelectedVideoDriver)
		{
			SelectedVideoDriver = VideoCombo.GetValue2();
			ModernOptionsClientWindow(GetParent(class'ModernOptionsClientWindow')).RestartButtonChange();
		}
	}
	else if (E == DE_Change && C == DisplayModeCombo)
		ApplyDisplayMode();
	else if (E == DE_Change && C == ShowFPSCheck)
	{
		bShowFPS = ShowFPSCheck.bChecked;
		ModernRootWindow(Root).SetFPSStatistics(bShowFPS);
	}
	else if (E == DE_Change && C == BloomAmountSlider)
	{
		ApplyBloomSetting();
		UpdateBloomAmountText();
	}
	else if (E == DE_Change && C == ChromaticAberrationSlider)
	{
		ApplyChromaticAberrationSetting();
		UpdateChromaticAberrationText();
	}
	else if (E == DE_Change && C == VignetteIntensitySlider)
	{
		ApplyRetroEffectSetting(VignetteIntensitySlider, "VignetteIntensity", "VIGNETTE");
		UpdateRetroEffectText();
	}
	else if (E == DE_Change && C == FilmGrainAmountSlider)
	{
		ApplyRetroEffectSetting(FilmGrainAmountSlider, "FilmGrainAmount", "FILMGRAIN");
		UpdateRetroEffectText();
	}
	else if (E == DE_Change && C == ScanlineStrengthSlider)
	{
		ApplyRetroEffectSetting(ScanlineStrengthSlider, "ScanlineStrength", "SCANLINES");
		UpdateRetroEffectText();
	}
	else if (E == DE_Change && C == ContrastSlider)
	{
		ApplyContrastSetting();
		UpdateColorSettingText();
	}
	else if (E == DE_Change && C == SaturationSlider)
	{
		ApplySaturationSetting();
		UpdateColorSettingText();
	}
	else if (E == DE_Change && C == BrightnessSlider)
		UpdateBrightnessText();
	else if (E == DE_Click && C == BrightnessResetButton)
	{
		BrightnessSlider.SetValue(120, True);
		BrightnessChanged();
		UpdateBrightnessText();
	}
	else if (E == DE_Click && C == ContrastResetButton)
	{
		ContrastSlider.SetValue(100, True);
		ApplyContrastSetting();
		UpdateColorSettingText();
	}
	else if (E == DE_Click && C == SaturationResetButton)
	{
		SaturationSlider.SetValue(281, True);
		ApplySaturationSetting();
		UpdateColorSettingText();
	}
	else if (E == DE_Click && C == GUIScalingResetButton)
	{
		AutoGUIScalingCheck.bChecked = True;
		GUIScalingSlider.SetValue(150, True);
		ScaleChanged();
	}
	else if (E == DE_Click && C == LightLODResetButton)
	{
		LightLODSlider.SetValue(8, True);
		LightLODChange();
	}
	else if (E == DE_Click && C == BloomAmountResetButton)
	{
		BloomAmountSlider.SetValue(154, True);
		ApplyBloomSetting();
		UpdateBloomAmountText();
	}
	else if (E == DE_Click && C == ChromaticAberrationResetButton)
	{
		ChromaticAberrationSlider.SetValue(0, True);
		ApplyChromaticAberrationSetting();
		UpdateChromaticAberrationText();
	}
	else if (E == DE_Click && C == VignetteIntensityResetButton)
	{
		VignetteIntensitySlider.SetValue(0, True);
		ApplyRetroEffectSetting(VignetteIntensitySlider, "VignetteIntensity", "VIGNETTE");
		UpdateRetroEffectText();
	}
	else if (E == DE_Click && C == FilmGrainAmountResetButton)
	{
		FilmGrainAmountSlider.SetValue(0, True);
		ApplyRetroEffectSetting(FilmGrainAmountSlider, "FilmGrainAmount", "FILMGRAIN");
		UpdateRetroEffectText();
	}
	else if (E == DE_Click && C == ScanlineStrengthResetButton)
	{
		ScanlineStrengthSlider.SetValue(0, True);
		ApplyRetroEffectSetting(ScanlineStrengthSlider, "ScanlineStrength", "SCANLINES");
		UpdateRetroEffectText();
	}
}

defaultproperties
{
	bAcceptsHotKeys=True
	ShowFPSText="Show FPS Statistics"
	ShowFPSHelp="Display live frame-rate statistics while playing."
	DisplayModeText="Display Mode"
	DisplayModeHelp="Choose fullscreen, borderless, or windowed display mode."
	FullscreenModeText="Fullscreen"
	BorderlessModeText="Borderless"
	WindowedModeText="Windowed"
	ContrastText="Contrast"
	ContrastHelp="Adjust contrast from 50% through 100% neutral to 200% maximum."
	SaturationText="Saturation"
	SaturationHelp="Adjust saturation from 0% grayscale through 100% normal color up to 200% boosted color."
	BloomAmountText="Bloom Amount"
	BloomAmountHelp="Set bloom strength from 0% off to 100% maximum."
	ChromaticAberrationText="Chromatic Aberration"
	ChromaticAberrationHelp="Separate colors toward the screen edges, from 0% off to 100% maximum."
	VignetteIntensityText="Vignette"
	VignetteIntensityHelp="Increase edge darkness and coverage together. 0% is off; 100% gives the narrowest view. Optional for VR comfort."
	FilmGrainAmountText="Film Grain"
	FilmGrainAmountHelp="Add animated monochrome film grain, from 0% off to 100% maximum."
	ScanlineStrengthText="CRT Scanlines"
	ScanlineStrengthHelp="Darken alternating output-pixel rows, from 0% off to 100% maximum."
	ResetVideoSettingHelp="Reset this setting to its Unreal Revived default."
	bShowFPS=True
	SavedContrastPercent=-1
}
