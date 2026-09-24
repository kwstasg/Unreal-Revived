// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived

class ModernVRConfigCW extends UWindowDialogClientWindow;

var UMenuLabelControl VRHeading;
var UWindowComboControl AimMethodCombo;
var UWindowComboControl RenderQualityCombo;
var UWindowComboControl HUDQualityCombo;
var localized string RenderQualityText;
var localized string RenderQualityHelp;
var localized string CurrentProfileText;
var localized string PerformanceQualityText;
var localized string BalancedQualityText;
var localized string HighQualityText;
var localized string UltraQualityText;
var localized string QualityRestartText;
var localized string QualityFallbackText;
var UWindowHSliderControl HUDDistanceSlider;
var UWindowHSliderControl HUDScaleSlider;
var UWindowHSliderControl PlayerHeightSlider;
var UWindowHSliderControl WorldSizeSlider;
var ModernResetButton PlayerHeightResetButton;
var ModernResetButton WorldSizeResetButton;
var ModernResetButton HUDDistanceResetButton;
var ModernResetButton HUDScaleResetButton;
var UWindowSmallButton RecenterButton;
var UMenuLabelControl StatusLabel;
var UMenuLabelControl LeftEyeSizeLabel;
var UMenuLabelControl RightEyeSizeLabel;
var localized string LeftEyeSizeText;
var localized string RightEyeSizeText;
var localized string EyeSizeHelp;
var bool bInitialized;

var localized string VRHeadingText;
var localized string AimMethodText;
var localized string AimMethodHelp;
var localized string GazeAimText;
var localized string MotionAimText;
var localized string MotionReadyText;
var localized string MotionUnavailableText;
var localized string HUDDistanceText;
var localized string HUDDistanceHelp;
var localized string HUDScaleText;
var localized string HUDScaleHelp;
var localized string PlayerHeightText;
var localized string PlayerHeightHelp;
var localized string WorldSizeText;
var localized string WorldSizeHelp;
var localized string RecenterText;
var localized string RecenterHelp;
var localized string ActiveStatusText;
var localized string InactiveStatusText;
var localized string D3D12RequiredText;
var localized string ResetVRSettingHelp;

function Created()
{
	Super.Created();

	VRHeading = UMenuLabelControl(CreateControl(class'UMenuLabelControl', 20, 15, 300, 1));
	VRHeading.SetText(VRHeadingText);
	VRHeading.SetFont(F_Bold);

	AimMethodCombo = UWindowComboControl(CreateControl(class'UWindowComboControl', 20, 45, 300, 1));
	AimMethodCombo.SetText(AimMethodText);
	AimMethodCombo.SetHelpText(AimMethodHelp);
	AimMethodCombo.SetFont(F_Normal);
	AimMethodCombo.SetEditable(False);
	AimMethodCombo.AddItem(GazeAimText);
	AimMethodCombo.AddItem(MotionAimText);
	AimMethodCombo.EditBoxWidth = 150;

	RenderQualityCombo = UWindowComboControl(CreateControl(class'UWindowComboControl', 20, 75, 300, 1));
	RenderQualityCombo.SetText(RenderQualityText);
	RenderQualityCombo.SetHelpText(RenderQualityHelp);
	RenderQualityCombo.SetFont(F_Normal);
	RenderQualityCombo.SetEditable(False);
	RenderQualityCombo.AddItem(CurrentProfileText, "0");
	RenderQualityCombo.AddItem(PerformanceQualityText, "1");
	RenderQualityCombo.AddItem(BalancedQualityText, "2");
	RenderQualityCombo.AddItem(HighQualityText, "3");
	RenderQualityCombo.AddItem(UltraQualityText, "4");
	RenderQualityCombo.EditBoxWidth = 175;

	HUDQualityCombo = UWindowComboControl(CreateControl(class'UWindowComboControl', 20, 105, 300, 1));
	HUDQualityCombo.SetText("HUD/Menu Sharpness");
	HUDQualityCombo.SetHelpText("Changes the HUD/menu output texture immediately, keeping panel size and layout. Higher settings retain more detail from higher VR render quality; they cannot add detail absent from the source.");
	HUDQualityCombo.SetFont(F_Normal);
	HUDQualityCombo.SetEditable(False);
	HUDQualityCombo.AddItem("Default", "0");
	HUDQualityCombo.AddItem("High", "1");
	HUDQualityCombo.AddItem("Ultra", "2");
	HUDQualityCombo.EditBoxWidth = 175;

	HUDDistanceSlider = UWindowHSliderControl(CreateControl(class'UWindowHSliderControl', 20, 45, 300, 1));
	HUDDistanceSlider.SetRange(50, 500, 5);
	HUDDistanceSlider.SetHelpText(HUDDistanceHelp);
	HUDDistanceSlider.SetFont(F_Normal);
	HUDDistanceSlider.SliderWidth = 110;
	HUDDistanceSlider.TrackWidth = 8;
	HUDDistanceSlider.bNoSlidingNotify = False;

	HUDScaleSlider = UWindowHSliderControl(CreateControl(class'UWindowHSliderControl', 20, 75, 300, 1));
	HUDScaleSlider.SetRange(50, 200, 5);
	HUDScaleSlider.SetHelpText(HUDScaleHelp);
	HUDScaleSlider.SetFont(F_Normal);
	HUDScaleSlider.SliderWidth = 110;
	HUDScaleSlider.TrackWidth = 8;
	HUDScaleSlider.bNoSlidingNotify = False;

	PlayerHeightSlider = UWindowHSliderControl(CreateControl(class'ModernSignedSliderControl', 20, 105, 300, 1));
	PlayerHeightSlider.SetRange(-75, 150, 5);
	PlayerHeightSlider.SetHelpText(PlayerHeightHelp);
	PlayerHeightSlider.SetFont(F_Normal);
	PlayerHeightSlider.SliderWidth = 110;
	PlayerHeightSlider.TrackWidth = 8;
	PlayerHeightSlider.bNoSlidingNotify = False;

	WorldSizeSlider = UWindowHSliderControl(CreateControl(class'UWindowHSliderControl', 20, 135, 300, 1));
	WorldSizeSlider.SetRange(40, 250, 5);
	WorldSizeSlider.SetHelpText(WorldSizeHelp);
	WorldSizeSlider.SetFont(F_Normal);
	WorldSizeSlider.SliderWidth = 110;
	WorldSizeSlider.TrackWidth = 8;
	WorldSizeSlider.bNoSlidingNotify = False;

	HUDDistanceResetButton = CreateSliderResetButton(HUDDistanceSlider);
	HUDScaleResetButton = CreateSliderResetButton(HUDScaleSlider);
	PlayerHeightResetButton = CreateSliderResetButton(PlayerHeightSlider);
	WorldSizeResetButton = CreateSliderResetButton(WorldSizeSlider);

	RecenterButton = UWindowSmallButton(CreateControl(class'UWindowSmallButton', 20, 170, 100, 16));
	RecenterButton.SetText(RecenterText);
	RecenterButton.SetHelpText(RecenterHelp);
	RecenterButton.SetFont(F_Normal);

	StatusLabel = UMenuLabelControl(CreateControl(class'UMenuLabelControl', 20, 205, 340, 1));
	StatusLabel.SetFont(F_Normal);
	HUDDistanceSlider.WinTop += 90;
	HUDScaleSlider.WinTop += 90;
	PlayerHeightSlider.WinTop += 90;
	WorldSizeSlider.WinTop += 90;
	HUDDistanceResetButton.WinTop += 90;
	HUDScaleResetButton.WinTop += 90;
	PlayerHeightResetButton.WinTop += 90;
	WorldSizeResetButton.WinTop += 90;
	RecenterButton.WinTop += 90;
	StatusLabel.WinTop += 90;
	LeftEyeSizeLabel = UMenuLabelControl(CreateControl(class'UMenuLabelControl', 20, 320, 340, 1));
	LeftEyeSizeLabel.SetFont(F_Normal);
	LeftEyeSizeLabel.SetHelpText(EyeSizeHelp);
	RightEyeSizeLabel = UMenuLabelControl(CreateControl(class'UMenuLabelControl', 20, 340, 340, 1));
	RightEyeSizeLabel.SetFont(F_Normal);
	RightEyeSizeLabel.SetHelpText(EyeSizeHelp);

	RemoveFromTabOrder(VRHeading);
	RemoveFromTabOrder(StatusLabel);
	RemoveFromTabOrder(LeftEyeSizeLabel);
	RemoveFromTabOrder(RightEyeSizeLabel);
	RemoveFromTabOrder(HUDDistanceResetButton);
	RemoveFromTabOrder(HUDScaleResetButton);
	RemoveFromTabOrder(PlayerHeightResetButton);
	RemoveFromTabOrder(WorldSizeResetButton);
	LoadSettings();
	bInitialized = True;
	DesiredHeight = 370;
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
	PlayerHeightSlider.SetText(PlayerHeightText $ " ("
		$ FormatDistance(PlayerHeightSlider.Value / 100.0) $ " m)");
	WorldSizeSlider.SetText(WorldSizeText $ " (" $ int(WorldSizeSlider.Value) $ "%)");
}

function LoadSettings()
{
	local float Distance;
	local float Scale;
	local float HeightOffset;
	local float WorldScale;
	local int Quality;
	local bool bWasInitialized;

	bWasInitialized = bInitialized;
	bInitialized = False;
	AimMethodCombo.SetSelectedIndex(Clamp(int(GetPlayerOwner().ConsoleCommand(
		"get ini:Engine.Engine.GameRenderDevice VRAimMode")), 0, 1));
	Quality = int(GetPlayerOwner().ConsoleCommand("get ini:Engine.Engine.GameRenderDevice VRRenderQuality"));
	if (Quality == 5) Quality = 4;
	if (Quality < 0 || Quality > 4)
		Quality = 0;
	RenderQualityCombo.SetSelectedIndex(Quality);
	Quality = int(GetPlayerOwner().ConsoleCommand("get ini:Engine.Engine.GameRenderDevice VRHUDQuality"));
	if (Quality < 0 || Quality > 2) Quality = 0;
	HUDQualityCombo.SetSelectedIndex(Quality);

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
	HeightOffset = float(GetPlayerOwner().ConsoleCommand(
		"get ini:Engine.Engine.GameRenderDevice VRPlayerHeightOffset"));
	WorldScale = float(GetPlayerOwner().ConsoleCommand(
		"get ini:Engine.Engine.GameRenderDevice VRWorldScale"));
	if (WorldScale <= 0)
		WorldScale = 1.0;
	PlayerHeightSlider.SetValue(Clamp(HeightOffset * 100.0, -75, 150), True);
	WorldSizeSlider.SetValue(Clamp(WorldScale * 100.0, 40, 250), True);
	UpdateSliderText();
	bInitialized = bWasInitialized;
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

function ApplyPlayerHeight()
{
	GetPlayerOwner().ConsoleCommand("D3D12 VRPLAYERHEIGHT"
		@ (PlayerHeightSlider.Value / 100.0));
}

function ApplyWorldSize()
{
	GetPlayerOwner().ConsoleCommand("D3D12 VRWORLDSCALE"
		@ (WorldSizeSlider.Value / 100.0));
}

function BeforePaint(Canvas C, float X, float Y)
{
	local bool bD3D12;
	local bool bVR;
	local float ControlWidth;
	local string QualityStatus;

	Super.BeforePaint(C, X, Y);
	bD3D12 = IsD3D12Active();
	bVR = bD3D12 && IsVRActive();
	ControlWidth = FMax(220, WinWidth - 40);
	VRHeading.SetSize(ControlWidth, 1);
	AimMethodCombo.SetSize(ControlWidth, 1);
	RenderQualityCombo.SetSize(ControlWidth, 1);
	HUDQualityCombo.SetSize(ControlWidth, 1);
	HUDDistanceSlider.SetSize(ControlWidth - 16, 1);
	HUDScaleSlider.SetSize(ControlWidth - 16, 1);
	PlayerHeightSlider.SetSize(ControlWidth - 16, 1);
	WorldSizeSlider.SetSize(ControlWidth - 16, 1);
	PlayerHeightResetButton.WinLeft = PlayerHeightSlider.WinLeft
		+ PlayerHeightSlider.WinWidth + 2;
	WorldSizeResetButton.WinLeft = WorldSizeSlider.WinLeft
		+ WorldSizeSlider.WinWidth + 2;
	HUDDistanceResetButton.WinLeft = HUDDistanceSlider.WinLeft
		+ HUDDistanceSlider.WinWidth + 2;
	HUDScaleResetButton.WinLeft = HUDScaleSlider.WinLeft
		+ HUDScaleSlider.WinWidth + 2;
	RecenterButton.AutoWidth(C);
	StatusLabel.SetSize(ControlWidth, 1);
	LeftEyeSizeLabel.SetSize(ControlWidth, 1);
	RightEyeSizeLabel.SetSize(ControlWidth, 1);
	LeftEyeSizeLabel.SetText("");
	RightEyeSizeLabel.SetText("");

	HUDDistanceSlider.bDisabled = !bD3D12;
	AimMethodCombo.bDisabled = !bD3D12;
	RenderQualityCombo.SetDisabled(!bD3D12);
	HUDQualityCombo.SetDisabled(!bD3D12);
	HUDScaleSlider.bDisabled = !bD3D12;
	HUDDistanceResetButton.bDisabled = !bD3D12;
	HUDScaleResetButton.bDisabled = !bD3D12;
	PlayerHeightSlider.bDisabled = !bD3D12;
	WorldSizeSlider.bDisabled = !bD3D12;
	PlayerHeightResetButton.bDisabled = !bD3D12;
	WorldSizeResetButton.bDisabled = !bD3D12;
	RecenterButton.bDisabled = !bVR;
	if (!bD3D12)
		StatusLabel.SetText(D3D12RequiredText);
	else if (bVR && AimMethodCombo.GetSelectedIndex() == 1)
	{
		if (Left(GetPlayerOwner().ConsoleCommand("D3D12 OPENXRCONTROLLER"), 3) == "1 1")
			StatusLabel.SetText(MotionReadyText);
		else
			StatusLabel.SetText(MotionUnavailableText);
	}
	else if (bVR)
		StatusLabel.SetText(ActiveStatusText);
	else
		StatusLabel.SetText(InactiveStatusText);
	if (bD3D12)
	{
		QualityStatus = GetPlayerOwner().ConsoleCommand("D3D12 VRRENDERSIZE 0");
		if (QualityStatus != "")
			LeftEyeSizeLabel.SetText(LeftEyeSizeText $ QualityStatus);
		QualityStatus = GetPlayerOwner().ConsoleCommand("D3D12 VRRENDERSIZE 1");
		if (QualityStatus != "")
			RightEyeSizeLabel.SetText(RightEyeSizeText $ QualityStatus);
		QualityStatus = GetPlayerOwner().ConsoleCommand("D3D12 VRQUALITYSTATUS");
		if (QualityStatus == "fallback")
			StatusLabel.SetText(QualityFallbackText);
		else if (QualityStatus == "pending")
			StatusLabel.SetText(QualityRestartText);
		else if (QualityStatus == "failed")
			StatusLabel.SetText("Quality change failed. Previous quality retained.");
		if (GetPlayerOwner().ConsoleCommand("D3D12 VRHUDSTATUS") == "failed")
			StatusLabel.SetText("HUD quality unavailable. Previous sharpness retained.");
	}
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
	else if (Slider == PlayerHeightSlider)
		Notify(PlayerHeightResetButton, DE_Click);
	else if (Slider == WorldSizeSlider)
		Notify(WorldSizeResetButton, DE_Click);
	else
		return False;
	return True;
}

function Notify(UWindowDialogControl C, byte E)
{
	Super.Notify(C, E);
	if (!bInitialized)
		return;

	if (E == DE_Change && C == AimMethodCombo)
		GetPlayerOwner().ConsoleCommand("D3D12 VRAIMMODE" @ AimMethodCombo.GetSelectedIndex());
	else if (E == DE_Change && C == HUDQualityCombo)
		GetPlayerOwner().ConsoleCommand("D3D12 VRHUDQUALITY" @ HUDQualityCombo.GetValue2());
	else if (E == DE_Change && C == RenderQualityCombo)
		GetPlayerOwner().ConsoleCommand("D3D12 VRRENDERQUALITY" @ RenderQualityCombo.GetValue2());
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
	else if (E == DE_Change && C == PlayerHeightSlider)
	{
		ApplyPlayerHeight();
		UpdateSliderText();
	}
	else if (E == DE_Change && C == WorldSizeSlider)
	{
		ApplyWorldSize();
		UpdateSliderText();
	}
	else if (E == DE_Click && C == PlayerHeightResetButton)
	{
		PlayerHeightSlider.SetValue(0, True);
		ApplyPlayerHeight();
		UpdateSliderText();
	}
	else if (E == DE_Click && C == WorldSizeResetButton)
	{
		WorldSizeSlider.SetValue(100, True);
		ApplyWorldSize();
		UpdateSliderText();
	}
	else if (E == DE_Click && C == RecenterButton)
		GetPlayerOwner().ConsoleCommand("D3D12 RECENTERVR");
}

defaultproperties
{
	VRHeadingText="Virtual Reality"
	LeftEyeSizeText="Left eye: "
	RightEyeSizeText="Right eye: "
	EyeSizeHelp="Scene resolution -> image sent to the headset, in pixels. Before the first frame, this shows the configured eye size."
	RenderQualityText="VR Render Quality"
	RenderQualityHelp="Current profile keeps the original 1280 x 1024 scene resolution. Other modes scale the runtime-recommended eye resolution. Changes apply immediately with a brief pause. The VR layout stays fixed."
	CurrentProfileText="Current profile (Default)"
	PerformanceQualityText="Performance - 75%"
	BalancedQualityText="Balanced - 100%"
	HighQualityText="Quality - 125%"
	UltraQualityText="Ultra - 150%"
	QualityRestartText="Applying render quality..."
	QualityFallbackText="Using current profile: quality buffers unavailable."
	AimMethodText="Aiming Method"
	AimMethodHelp="Touch buttons and sticks work in both aiming modes. Motion aiming uses your weapon hand preference; Center and Hidden use the right hand. Release controls after switching."
	GazeAimText="Head gaze"
	MotionAimText="Motion controllers"
	MotionReadyText="Motion controller tracked. Xbox-style controls and menus."
	MotionUnavailableText="Aiming controller unavailable. Connect/wake controllers or choose Head gaze."
	HUDDistanceText="HUD Distance"
	HUDDistanceHelp="Set the distance of spatial HUD and menu panels from 0.50 to 5.00 meters."
	HUDScaleText="HUD Scale"
	HUDScaleHelp="Set the apparent size of spatial HUD and menu panels from 50% to 200%."
	PlayerHeightText="Height Offset"
	PlayerHeightHelp="Raise or lower your VR viewpoint from -0.75 to 1.50 meters. 0.00 keeps the original player height."
	WorldSizeText="World Size"
	WorldSizeHelp="100% is normal size. Above 100% makes you feel smaller in a larger world; below 100% makes you feel bigger in a smaller world. Scales viewpoint height, stereo depth and your displayed weapon together."
	RecenterText="Recenter VR View"
	RecenterHelp="Level software view tilt, make your current horizontal gaze forward, and recenter the shared HUD/menu panel."
	ActiveStatusText="OpenXR active. Render quality changes apply immediately."
	InactiveStatusText="Launch with the Unreal Revived VR shortcut to use VR."
	D3D12RequiredText="VR requires the Direct3D 12 video driver."
	ResetVRSettingHelp="Reset this VR setting to the Unreal Revived default."
}
