class ModernVideoClientWindow extends UMenuVideoClientWindow
	config;

var UWindowCheckbox ShowFPSCheck;
var localized string ShowFPSText;
var localized string ShowFPSHelp;
var config bool bShowFPS;
var UWindowHSliderControl ContrastSlider;
var localized string ContrastText;
var localized string ContrastHelp;
var UWindowHSliderControl SaturationSlider;
var localized string SaturationText;
var localized string SaturationHelp;
var UWindowHSliderControl BloomAmountSlider;
var localized string BloomAmountText;
var localized string BloomAmountHelp;

function Created()
{
	local UWindowWindow Child;
	local float ContrastTop;
	local float SaturationTop;
	local float ShowFPSTop;
	local float BloomAmountTop;

	Super.Created();

	ContrastTop = BrightnessSlider.WinTop + 25;
	SaturationTop = ContrastTop + 25;
	for (Child = FirstChildWindow; Child != None; Child = Child.NextSiblingWindow)
		if (Child.WinTop >= ContrastTop)
			Child.WinTop += 50;

	ShowFPSTop = ShowWindowedCheck.WinTop + 25;
	BloomAmountTop = ShowFPSTop + 25;
	for (Child = FirstChildWindow; Child != None; Child = Child.NextSiblingWindow)
		if (Child.WinTop >= ShowFPSTop)
			Child.WinTop += 50;

	ContrastSlider = UWindowHSliderControl(CreateControl(class'UWindowHSliderControl', BrightnessSlider.WinLeft, ContrastTop, BrightnessSlider.WinWidth, 1));
	ContrastSlider.bNoSlidingNotify = True;
	ContrastSlider.SetRange(0, 255, 1);
	ContrastSlider.SetHelpText(ContrastHelp);
	ContrastSlider.SetFont(F_Normal);

	SaturationSlider = UWindowHSliderControl(CreateControl(class'UWindowHSliderControl', BrightnessSlider.WinLeft, SaturationTop, BrightnessSlider.WinWidth, 1));
	SaturationSlider.bNoSlidingNotify = True;
	SaturationSlider.SetRange(0, 255, 1);
	SaturationSlider.SetHelpText(SaturationHelp);
	SaturationSlider.SetFont(F_Normal);

	ShowFPSCheck = UWindowCheckbox(CreateControl(class'UWindowCheckbox', ShowWindowedCheck.WinLeft, ShowFPSTop, ShowWindowedCheck.WinWidth, 1));
	ShowFPSCheck.SetText(ShowFPSText);
	ShowFPSCheck.SetHelpText(ShowFPSHelp);
	ShowFPSCheck.SetFont(F_Normal);
	ShowFPSCheck.Align = TA_Left;
	ShowFPSCheck.bChecked = bShowFPS;

	BloomAmountSlider = UWindowHSliderControl(CreateControl(class'UWindowHSliderControl', ShowWindowedCheck.WinLeft, BloomAmountTop, ShowWindowedCheck.WinWidth, 1));
	BloomAmountSlider.bNoSlidingNotify = True;
	BloomAmountSlider.SetRange(0, 255, 1);
	BloomAmountSlider.SetHelpText(BloomAmountHelp);
	BloomAmountSlider.SetFont(F_Normal);
	ControlOffset += 100;
	LoadColorSettings();
	LoadBloomSetting();
}

function BeforePaint(Canvas C, float X, float Y)
{
	Super.BeforePaint(C, X, Y);
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
	BloomAmountSlider.SetSize(BrightnessSlider.WinWidth, 1);
	BloomAmountSlider.SliderWidth = BrightnessSlider.SliderWidth;
}

function WindowShown()
{
	Super.WindowShown();
	ShowFPSCheck.bChecked = bShowFPS;
	LoadColorSettings();
	LoadBloomSetting();
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
		ContrastSlider.SetValue(128, True);
		SaturationSlider.SetValue(255, True);
		UpdateColorSettingText();
		return;
	}

	Contrast = Clamp(int(GetPlayerOwner().ConsoleCommand("get ini:Engine.Engine.GameRenderDevice Contrast")), 0, 255);
	Saturation = Clamp(int(GetPlayerOwner().ConsoleCommand("get ini:Engine.Engine.GameRenderDevice Saturation")), 0, 255);
	ContrastSlider.SetValue(Contrast, True);
	SaturationSlider.SetValue(Saturation, True);
	UpdateColorSettingText();
}

function UpdateColorSettingText()
{
	ContrastSlider.SetText(ContrastText $ " (" $ int(ContrastSlider.Value) $ ")");
	SaturationSlider.SetText(SaturationText $ " (" $ int(SaturationSlider.Value) $ ")");
}

function ApplyContrastSetting()
{
	local string Value;

	Value = string(int(ContrastSlider.Value));
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
	BloomAmountSlider.SetText(BloomAmountText $ " (" $ int(BloomAmountSlider.Value) $ ")");
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

	if (E == DE_Change && C == ShowFPSCheck)
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
}

defaultproperties
{
	ShowFPSText="Show FPS Statistics"
	ShowFPSHelp="Display live frame-rate statistics while playing."
	ContrastText="Contrast"
	ContrastHelp="Adjust contrast from low at 0 through neutral at 128 to maximum at 255."
	SaturationText="Saturation"
	SaturationHelp="Adjust saturation from inverse color at 0 through grayscale at 128 to normal color at 255."
	BloomAmountText="Bloom Amount"
	BloomAmountHelp="Set bloom strength from 0 (off) to 255 (maximum)."
	bShowFPS=False
}