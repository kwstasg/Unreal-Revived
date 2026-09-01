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
var UWindowHSliderControl SaturationSlider;
var localized string SaturationText;
var localized string SaturationHelp;
var UWindowHSliderControl BloomAmountSlider;
var localized string BloomAmountText;
var localized string BloomAmountHelp;
var ModernResetButton BrightnessResetButton;
var ModernResetButton ContrastResetButton;
var ModernResetButton SaturationResetButton;
var ModernResetButton GUIScalingResetButton;
var ModernResetButton LightLODResetButton;
var ModernResetButton BloomAmountResetButton;
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

	Super.Created();
	CreateDisplayModeControl();
	RemoveObsoleteVideoControls();
	BrightnessSlider.bNoSlidingNotify = False;
	GUIScalingSlider.bNoSlidingNotify = False;
	LightLODSlider.bNoSlidingNotify = False;
	BrightnessSlider.SetRange(50, 200, 1);
	LoadBrightnessSetting();

	ContrastTop = BrightnessSlider.WinTop + 25;
	SaturationTop = ContrastTop + 25;
	BloomAmountTop = SaturationTop + 25;
	for (Child = FirstChildWindow; Child != None; Child = Child.NextSiblingWindow)
		if (Child.WinTop >= ContrastTop)
			Child.WinTop += 75;

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
	ControlOffset += 100;
	LoadColorSettings();
	LoadBloomSetting();
	WidenSliderHandles();
	BrightnessResetButton = CreateSliderResetButton(BrightnessSlider);
	ContrastResetButton = CreateSliderResetButton(ContrastSlider);
	SaturationResetButton = CreateSliderResetButton(SaturationSlider);
	GUIScalingResetButton = CreateSliderResetButton(GUIScalingSlider);
	LightLODResetButton = CreateSliderResetButton(LightLODSlider);
	BloomAmountResetButton = CreateSliderResetButton(BloomAmountSlider);
	ConfigureTabOrder();
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

	PlaceTabAfter(DisplayModeCombo, VideoCombo);
	PlaceTabAfter(ShowFPSCheck, DisplayModeCombo);
	PlaceTabAfter(ContrastSlider, BrightnessSlider);
	PlaceTabAfter(SaturationSlider, ContrastSlider);
	PlaceTabAfter(BloomAmountSlider, SaturationSlider);
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
	ResolutionCombo.SetDisabled(CurrentMode ~= "Borderless");
}

function ApplyDisplayMode()
{
	GetPlayerOwner().ConsoleCommand("SetScreenMode" @ DisplayModeCombo.GetValue2());
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

function BrightnessChanged()
{
	if (bInitialized)
		GetPlayerOwner().ConsoleCommand("set ini:Engine.Engine.ViewportManager Brightness" @ (BrightnessSlider.Value / 200.0));
}

function BeforePaint(Canvas C, float X, float Y)
{
	UpdateBrightnessText();
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
	LayoutSliderResetButton(BrightnessSlider, BrightnessResetButton);
	LayoutSliderResetButton(ContrastSlider, ContrastResetButton);
	LayoutSliderResetButton(SaturationSlider, SaturationResetButton);
	LayoutSliderResetButton(GUIScalingSlider, GUIScalingResetButton);
	LayoutSliderResetButton(LightLODSlider, LightLODResetButton);
	LayoutSliderResetButton(BloomAmountSlider, BloomAmountResetButton);
}

function WindowShown()
{
	Super.WindowShown();
	SyncDisplayMode();
	ShowFPSCheck.bChecked = bShowFPS;
	LoadBrightnessSetting();
	LoadColorSettings();
	LoadBloomSetting();
	SelectedVideoDriver = VideoCombo.GetValue2();
}

function LoadColorSettings()
{
	local bool bD3D12;
	local int Contrast;
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
	ContrastSlider.SetValue(ContrastValueToPercent(Contrast), True);
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

	Value = string(ContrastPercentToValue(int(ContrastSlider.Value)));
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

function LoadConditionallySupportedSettings()
{
	local string CurrentMode;

	Super.LoadConditionallySupportedSettings();
	if (!(GetVideoDriverClassName() ~= "D3D12Drv.D3D12RenderDevice"))
	{
		LoadBloomSetting();
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
		SaveConfig();
		if (bShowFPS)
			GetPlayerOwner().ConsoleCommand("TIMEDEMO 1");
		else
			GetPlayerOwner().ConsoleCommand("TIMEDEMO 0");
	}
	else if (E == DE_Change && C == BloomAmountSlider)
	{
		ApplyBloomSetting();
		UpdateBloomAmountText();
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
		BrightnessSlider.SetValue(100, True);
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
		SaturationSlider.SetValue(255, True);
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
		BloomAmountSlider.SetValue(128, True);
		ApplyBloomSetting();
		UpdateBloomAmountText();
	}
}

defaultproperties
{
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
	ResetVideoSettingHelp="Reset this setting to its Unreal Revived default."
	bShowFPS=False
}