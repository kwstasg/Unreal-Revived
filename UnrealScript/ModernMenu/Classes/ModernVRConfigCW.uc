// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived

class ModernVRConfigCW extends UWindowDialogClientWindow;

var UMenuLabelControl VRHeading;
var UWindowCheckbox EnableVRCheck;
var UWindowHSliderControl HUDDistanceSlider;
var UWindowHSliderControl HUDScaleSlider;
var ModernResetButton HUDDistanceResetButton;
var ModernResetButton HUDScaleResetButton;
var UWindowSmallButton RecenterButton;
var UMenuLabelControl StatusLabel;
var bool bInitialized;

var localized string VRHeadingText;
var localized string EnableVRText;
var localized string EnableVRHelp;
var localized string HUDDistanceText;
var localized string HUDDistanceHelp;
var localized string HUDScaleText;
var localized string HUDScaleHelp;
var localized string RecenterText;
var localized string RecenterHelp;
var localized string ActiveStatusText;
var localized string InactiveStatusText;
var localized string RestartStatusText;
var localized string D3D12RequiredText;
var localized string ResetVRSettingHelp;

function Created()
{
	Super.Created();

	VRHeading = UMenuLabelControl(CreateControl(class'UMenuLabelControl', 20, 15, 300, 1));
	VRHeading.SetText(VRHeadingText);
	VRHeading.SetFont(F_Bold);

	EnableVRCheck = UWindowCheckbox(CreateControl(class'UWindowCheckbox', 20, 45, 300, 1));
	EnableVRCheck.SetText(EnableVRText);
	EnableVRCheck.SetHelpText(EnableVRHelp);
	EnableVRCheck.SetFont(F_Normal);
	EnableVRCheck.Align = TA_Left;

	HUDDistanceSlider = UWindowHSliderControl(CreateControl(class'UWindowHSliderControl', 20, 75, 300, 1));
	HUDDistanceSlider.SetRange(50, 500, 5);
	HUDDistanceSlider.SetHelpText(HUDDistanceHelp);
	HUDDistanceSlider.SetFont(F_Normal);
	HUDDistanceSlider.SliderWidth = 110;
	HUDDistanceSlider.TrackWidth = 8;
	HUDDistanceSlider.bNoSlidingNotify = False;

	HUDScaleSlider = UWindowHSliderControl(CreateControl(class'UWindowHSliderControl', 20, 105, 300, 1));
	HUDScaleSlider.SetRange(50, 200, 5);
	HUDScaleSlider.SetHelpText(HUDScaleHelp);
	HUDScaleSlider.SetFont(F_Normal);
	HUDScaleSlider.SliderWidth = 110;
	HUDScaleSlider.TrackWidth = 8;
	HUDScaleSlider.bNoSlidingNotify = False;

	HUDDistanceResetButton = CreateSliderResetButton(HUDDistanceSlider);
	HUDScaleResetButton = CreateSliderResetButton(HUDScaleSlider);

	RecenterButton = UWindowSmallButton(CreateControl(class'UWindowSmallButton', 20, 140, 100, 16));
	RecenterButton.SetText(RecenterText);
	RecenterButton.SetHelpText(RecenterHelp);
	RecenterButton.SetFont(F_Normal);

	StatusLabel = UMenuLabelControl(CreateControl(class'UMenuLabelControl', 20, 175, 340, 1));
	StatusLabel.SetFont(F_Normal);

	RemoveFromTabOrder(VRHeading);
	RemoveFromTabOrder(StatusLabel);
	RemoveFromTabOrder(HUDDistanceResetButton);
	RemoveFromTabOrder(HUDScaleResetButton);
	LoadSettings();
	bInitialized = True;
	DesiredHeight = 210;
}

function ModernResetButton CreateSliderResetButton(UWindowHSliderControl Slider)
{
	local ModernResetButton Button;

	Button = ModernResetButton(CreateControl(class'ModernResetButton',
		Slider.WinLeft + Slider.WinWidth - 12, Slider.WinTop, 12, 10));
	Button.SetHelpText(ResetVRSettingHelp);
	Button.ToolTipString = ResetVRSettingHelp;
	return Button;
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

function string GetVideoDriverClassName()
{
	local string CurrentDriver, Prefix, Suffix;

	CurrentDriver = GetPlayerOwner().ConsoleCommand(
		"get ini:Engine.Engine.GameRenderDevice Class");
	if (Divide(CurrentDriver, "'", Prefix, CurrentDriver)
		&& Divide(CurrentDriver, "'", CurrentDriver, Suffix))
		return CurrentDriver;
	return "";
}

function bool IsD3D12Active()
{
	return GetVideoDriverClassName() ~= "D3D12Drv.D3D12RenderDevice";
}

function bool IsVRActive()
{
	return Left(GetPlayerOwner().ConsoleCommand("D3D12 OPENXRPOSE"), 1) == "1";
}

function string FormatDistance(float Value)
{
	local int DecimalPosition;
	local string ValueText;

	ValueText = string(Value);
	DecimalPosition = InStr(ValueText, ".");
	if (DecimalPosition < 0)
		return ValueText $ ".00";
	return Left(ValueText $ "00", DecimalPosition + 3);
}

function UpdateSliderText()
{
	HUDDistanceSlider.SetText(HUDDistanceText $ " ("
		$ FormatDistance(HUDDistanceSlider.Value / 100.0) $ " m)");
	HUDScaleSlider.SetText(HUDScaleText $ " (" $ int(HUDScaleSlider.Value) $ "%)");
}

function LoadSettings()
{
	local float Distance;
	local float Scale;

	EnableVRCheck.bChecked = bool(GetPlayerOwner().ConsoleCommand(
		"get ini:Engine.Engine.GameRenderDevice EnableVR"));
	Distance = float(GetPlayerOwner().ConsoleCommand(
		"get ini:Engine.Engine.GameRenderDevice VRHUDDistance"));
	Scale = float(GetPlayerOwner().ConsoleCommand(
		"get ini:Engine.Engine.GameRenderDevice VRHUDScale"));
	if (Distance <= 0)
		Distance = 1.75;
	if (Scale <= 0)
		Scale = 1.0;
	HUDDistanceSlider.SetValue(Clamp(Distance * 100.0, 50, 500), True);
	HUDScaleSlider.SetValue(Clamp(Scale * 100.0, 50, 200), True);
	UpdateSliderText();
}

function ApplyDistance()
{
	GetPlayerOwner().ConsoleCommand("D3D12 VRHUDDISTANCE"
		@ (HUDDistanceSlider.Value / 100.0));
}

function ApplyScale()
{
	GetPlayerOwner().ConsoleCommand("D3D12 VRHUDSCALE"
		@ (HUDScaleSlider.Value / 100.0));
}

function BeforePaint(Canvas C, float X, float Y)
{
	local bool bD3D12;
	local bool bVR;
	local float ControlWidth;

	Super.BeforePaint(C, X, Y);
	bD3D12 = IsD3D12Active();
	bVR = bD3D12 && IsVRActive();
	ControlWidth = FMax(220, WinWidth - 40);
	VRHeading.SetSize(ControlWidth, 1);
	EnableVRCheck.SetSize(ControlWidth, 1);
	HUDDistanceSlider.SetSize(ControlWidth - 16, 1);
	HUDScaleSlider.SetSize(ControlWidth - 16, 1);
	HUDDistanceResetButton.WinLeft = HUDDistanceSlider.WinLeft
		+ HUDDistanceSlider.WinWidth + 2;
	HUDScaleResetButton.WinLeft = HUDScaleSlider.WinLeft
		+ HUDScaleSlider.WinWidth + 2;
	RecenterButton.AutoWidth(C);
	StatusLabel.SetSize(ControlWidth, 1);

	EnableVRCheck.bDisabled = !bD3D12;
	HUDDistanceSlider.bDisabled = !bD3D12;
	HUDScaleSlider.bDisabled = !bD3D12;
	HUDDistanceResetButton.bDisabled = !bD3D12;
	HUDScaleResetButton.bDisabled = !bD3D12;
	RecenterButton.bDisabled = !bVR;
	if (!bD3D12)
		StatusLabel.SetText(D3D12RequiredText);
	else if (bVR)
		StatusLabel.SetText(ActiveStatusText);
	else if (EnableVRCheck.bChecked)
		StatusLabel.SetText(RestartStatusText);
	else
		StatusLabel.SetText(InactiveStatusText);
}

function WindowShown()
{
	Super.WindowShown();
	LoadSettings();
}

function bool ResetControllerSlider(UWindowHSliderControl Slider)
{
	if (Slider == HUDDistanceSlider)
		Notify(HUDDistanceResetButton, DE_Click);
	else if (Slider == HUDScaleSlider)
		Notify(HUDScaleResetButton, DE_Click);
	else
		return False;
	return True;
}

function Notify(UWindowDialogControl C, byte E)
{
	Super.Notify(C, E);
	if (!bInitialized)
		return;

	if (E == DE_Change && C == EnableVRCheck)
		GetPlayerOwner().ConsoleCommand("set ini:Engine.Engine.GameRenderDevice EnableVR"
			@ EnableVRCheck.bChecked);
	else if (E == DE_Change && C == HUDDistanceSlider)
	{
		ApplyDistance();
		UpdateSliderText();
	}
	else if (E == DE_Change && C == HUDScaleSlider)
	{
		ApplyScale();
		UpdateSliderText();
	}
	else if (E == DE_Click && C == HUDDistanceResetButton)
	{
		HUDDistanceSlider.SetValue(175, True);
		ApplyDistance();
		UpdateSliderText();
	}
	else if (E == DE_Click && C == HUDScaleResetButton)
	{
		HUDScaleSlider.SetValue(100, True);
		ApplyScale();
		UpdateSliderText();
	}
	else if (E == DE_Click && C == RecenterButton)
		GetPlayerOwner().ConsoleCommand("D3D12 RESETVRUIANCHOR");
}

defaultproperties
{
	VRHeadingText="Virtual Reality"
	EnableVRText="Enable VR on Next Launch"
	EnableVRHelp="Start OpenXR the next time Unreal Revived launches. Requires Direct3D 12 and a restart."
	HUDDistanceText="HUD Distance"
	HUDDistanceHelp="Set the distance of spatial HUD and menu panels from 0.50 to 5.00 meters."
	HUDScaleText="HUD Scale"
	HUDScaleHelp="Set the apparent size of spatial HUD and menu panels from 50% to 200%."
	RecenterText="Recenter HUD"
	RecenterHelp="Place the current spatial HUD or menu panel directly ahead."
	ActiveStatusText="OpenXR is active. Changes apply immediately."
	InactiveStatusText="VR is disabled. Enable it here and restart Unreal Revived."
	RestartStatusText="VR will be enabled after Unreal Revived restarts."
	D3D12RequiredText="VR requires the Direct3D 12 video driver."
	ResetVRSettingHelp="Reset this VR setting to the Unreal Revived default."
}
