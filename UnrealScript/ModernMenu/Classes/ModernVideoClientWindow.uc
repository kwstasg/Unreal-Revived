class ModernVideoClientWindow extends UMenuVideoClientWindow
	config;

var UWindowCheckbox ShowFPSCheck;
var localized string ShowFPSText;
var localized string ShowFPSHelp;
var config bool bShowFPS;
var UWindowHSliderControl BloomAmountSlider;
var localized string BloomAmountText;
var localized string BloomAmountHelp;

function Created()
{
	local UWindowWindow Child;
	local float ShowFPSTop;
	local float BloomAmountTop;

	Super.Created();

	ShowFPSTop = ShowWindowedCheck.WinTop + 25;
	BloomAmountTop = ShowFPSTop + 25;
	for (Child = FirstChildWindow; Child != None; Child = Child.NextSiblingWindow)
		if (Child.WinTop >= ShowFPSTop)
			Child.WinTop += 50;

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
	ControlOffset += 50;
	LoadBloomSetting();
}

function BeforePaint(Canvas C, float X, float Y)
{
	Super.BeforePaint(C, X, Y);
	ShowFPSCheck.WinLeft = ShowWindowedCheck.WinLeft;
	ShowFPSCheck.SetSize(ShowWindowedCheck.WinWidth, 1);
	BloomAmountSlider.WinLeft = BrightnessSlider.WinLeft;
	BloomAmountSlider.SetSize(BrightnessSlider.WinWidth, 1);
	BloomAmountSlider.SliderWidth = BrightnessSlider.SliderWidth;
}

function WindowShown()
{
	Super.WindowShown();
	ShowFPSCheck.bChecked = bShowFPS;
	LoadBloomSetting();
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
}

defaultproperties
{
	ShowFPSText="Show FPS Statistics"
	ShowFPSHelp="Display live frame-rate statistics while playing."
	BloomAmountText="Bloom Amount"
	BloomAmountHelp="Set bloom strength from 0 (off) to 255 (maximum)."
	bShowFPS=False
}