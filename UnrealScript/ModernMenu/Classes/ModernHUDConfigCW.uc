class ModernHUDConfigCW extends UMenuHUDConfigCW
	config;

var UWindowCheckbox ShowGameBehindMenusCheck;
var localized string ShowGameBehindMenusText;
var localized string ShowGameBehindMenusHelp;
var config bool bShowGameBehindMenus;
var UWindowHSliderControl CrosshairScaleSlider;
var UWindowHSliderControl HUDScaleSlider;
var ModernResetButton HUDConfigResetButton;
var ModernResetButton CrosshairResetButton;
var ModernResetButton CrosshairScaleResetButton;
var ModernResetButton HUDScaleResetButton;
var localized string ResetHUDSettingHelp;
var localized string ResetScaleHelp;

function Created()
{
	Super.Created();
	HUDConfigSlider.bNoSlidingNotify = False;
	CrosshairSlider.bNoSlidingNotify = False;
	HUDConfigSlider.TrackWidth = 8;
	CrosshairSlider.TrackWidth = 8;
	HUDConfigResetButton = ModernResetButton(CreateControl(class'ModernResetButton', HUDConfigSlider.WinLeft + HUDConfigSlider.WinWidth - 12, HUDConfigSlider.WinTop + 2, 12, 12));
	HUDConfigResetButton.SetHelpText(ResetHUDSettingHelp);
	HUDConfigResetButton.ToolTipString = ResetHUDSettingHelp;
	CrosshairResetButton = ModernResetButton(CreateControl(class'ModernResetButton', CrosshairSlider.WinLeft + CrosshairSlider.WinWidth - 12, CrosshairSlider.WinTop + 2, 12, 12));
	CrosshairResetButton.SetHelpText(ResetHUDSettingHelp);
	CrosshairResetButton.ToolTipString = ResetHUDSettingHelp;
	CrosshairScaleEditBox.HideWindow();
	HUDScaleEditBox.HideWindow();

	CrosshairScaleSlider = UWindowHSliderControl(CreateControl(class'UWindowHSliderControl', CrosshairScaleEditBox.WinLeft, CrosshairScaleEditBox.WinTop, CrosshairScaleEditBox.WinWidth, 1));
	CrosshairScaleSlider.bNoSlidingNotify = False;
	CrosshairScaleSlider.SetRange(1, 80, 1);
	CrosshairScaleSlider.SetHelpText(CrosshairScaleHelp);
	CrosshairScaleSlider.SetFont(F_Normal);
	CrosshairScaleSlider.TrackWidth = 8;

	HUDScaleSlider = UWindowHSliderControl(CreateControl(class'UWindowHSliderControl', HUDScaleEditBox.WinLeft, HUDScaleEditBox.WinTop, HUDScaleEditBox.WinWidth, 1));
	HUDScaleSlider.bNoSlidingNotify = False;
	HUDScaleSlider.SetRange(10, 160, 1);
	HUDScaleSlider.SetHelpText(class'UMenuVideoClientWindow'.Default.HUDScaleHelp);
	HUDScaleSlider.SetFont(F_Normal);
	HUDScaleSlider.TrackWidth = 8;

	CrosshairScaleResetButton = ModernResetButton(CreateControl(class'ModernResetButton', CrosshairScaleSlider.WinLeft + CrosshairScaleSlider.WinWidth + 2, CrosshairScaleSlider.WinTop, 12, 10));
	CrosshairScaleResetButton.SetHelpText(ResetScaleHelp);
	CrosshairScaleResetButton.ToolTipString = ResetScaleHelp;
	HUDScaleResetButton = ModernResetButton(CreateControl(class'ModernResetButton', HUDScaleSlider.WinLeft + HUDScaleSlider.WinWidth + 2, HUDScaleSlider.WinTop, 12, 10));
	HUDScaleResetButton.SetHelpText(ResetScaleHelp);
	HUDScaleResetButton.ToolTipString = ResetScaleHelp;
	LoadScaleSettings();

	ShowGameBehindMenusCheck = UWindowCheckbox(CreateControl(class'UWindowCheckbox', HUDScaleSlider.WinLeft, HUDScaleSlider.WinTop + 25, HUDScaleSlider.WinWidth, 1));
	ShowGameBehindMenusCheck.SetText(ShowGameBehindMenusText);
	ShowGameBehindMenusCheck.SetHelpText(ShowGameBehindMenusHelp);
	ShowGameBehindMenusCheck.SetFont(F_Normal);
	ShowGameBehindMenusCheck.Align = TA_Left;
	ShowGameBehindMenusCheck.bChecked = bShowGameBehindMenus;
	DesiredHeight += 25;
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
	RemoveFromTabOrder(HUDConfigResetButton);
	RemoveFromTabOrder(CrosshairResetButton);
	RemoveFromTabOrder(CrosshairScaleResetButton);
	RemoveFromTabOrder(HUDScaleResetButton);

	PlaceTabAfter(CrosshairScaleSlider, CrosshairSlider);
	PlaceTabAfter(HUDScaleSlider, CrosshairScaleSlider);
	PlaceTabAfter(ShowGameBehindMenusCheck, HUDScaleSlider);
}

function bool ResetControllerSlider(UWindowHSliderControl Slider)
{
	if (Slider == HUDConfigSlider)
		Notify(HUDConfigResetButton, DE_Click);
	else if (Slider == CrosshairSlider)
		Notify(CrosshairResetButton, DE_Click);
	else if (Slider == CrosshairScaleSlider)
		Notify(CrosshairScaleResetButton, DE_Click);
	else if (Slider == HUDScaleSlider)
		Notify(HUDScaleResetButton, DE_Click);
	else
		return False;
	return True;
}

function string FormatScaleValue(float Value)
{
	local int DecimalPosition;
	local string ValueText;

	ValueText = string(Value);
	DecimalPosition = InStr(ValueText, ".");
	if (DecimalPosition < 0)
		return ValueText $ ".0";
	return Left(ValueText, DecimalPosition + 2);
}

function UpdateScaleSettingText()
{
	CrosshairScaleSlider.SetText(CrosshairScaleText $ " (" $ FormatScaleValue(CrosshairScaleSlider.Value / 10) $ ")");
	HUDScaleSlider.SetText(class'UMenuVideoClientWindow'.Default.HUDScaleText $ " (" $ FormatScaleValue(HUDScaleSlider.Value / 10) $ ")");
	CrosshairScaleEditBox.SetText(CrosshairScaleSlider.Text);
	HUDScaleEditBox.SetText(HUDScaleSlider.Text);
}

function LoadScaleSettings()
{
	CrosshairScaleSlider.SetValue(class'HUD'.Default.CrosshairScale * 10, True);
	HUDScaleSlider.SetValue(class'HUD'.Default.HudScaler * 10, True);
	UpdateScaleSettingText();
}

function ApplyScaleSettings()
{
	class'HUD'.Default.CrosshairScale = CrosshairScaleSlider.Value / 10;
	class'HUD'.Default.HudScaler = HUDScaleSlider.Value / 10;
	if (GetPlayerOwner().MyHUD != None)
	{
		GetPlayerOwner().MyHUD.CrosshairScale = class'HUD'.Default.CrosshairScale;
		GetPlayerOwner().MyHUD.HudScaler = class'HUD'.Default.HudScaler;
	}
	class'HUD'.Static.StaticSaveConfig();
}

function BeforePaint(Canvas C, float X, float Y)
{
	Super.BeforePaint(C, X, Y);
	// Use the scale controls' standard label/edit geometry for every HUD slider.
	// The stock layout gives the first two sliders a different width and track
	// position, which becomes especially visible when Preferences is resized.
	HUDConfigSlider.WinLeft = CrosshairScaleEditBox.WinLeft;
	HUDConfigSlider.SetSize(CrosshairScaleEditBox.WinWidth - HUDConfigResetButton.WinWidth - 4, 1);
	HUDConfigSlider.SliderWidth = CrosshairScaleEditBox.EditBoxWidth - HUDConfigResetButton.WinWidth - 4;
	HUDConfigResetButton.WinLeft = HUDConfigSlider.WinLeft + HUDConfigSlider.WinWidth + 2;
	HUDConfigResetButton.WinTop = HUDConfigSlider.WinTop + HUDConfigSlider.SliderDrawY + 1 - HUDConfigResetButton.WinHeight / 2;
	CrosshairSlider.WinLeft = CrosshairScaleEditBox.WinLeft;
	CrosshairSlider.SetSize(CrosshairScaleEditBox.WinWidth - CrosshairResetButton.WinWidth - 4, 1);
	CrosshairSlider.SliderWidth = CrosshairScaleEditBox.EditBoxWidth - CrosshairResetButton.WinWidth - 4;
	CrosshairResetButton.WinLeft = CrosshairSlider.WinLeft + CrosshairSlider.WinWidth + 2;
	CrosshairResetButton.WinTop = CrosshairSlider.WinTop + CrosshairSlider.SliderDrawY + 1 - CrosshairResetButton.WinHeight / 2;
	CrosshairScaleSlider.WinLeft = CrosshairScaleEditBox.WinLeft;
	CrosshairScaleSlider.WinTop = CrosshairScaleEditBox.WinTop;
	CrosshairScaleSlider.SetSize(CrosshairScaleEditBox.WinWidth - CrosshairScaleResetButton.WinWidth - 4, 1);
	CrosshairScaleSlider.SliderWidth = CrosshairScaleEditBox.EditBoxWidth - CrosshairScaleResetButton.WinWidth - 4;
	HUDScaleSlider.WinLeft = HUDScaleEditBox.WinLeft;
	HUDScaleSlider.WinTop = HUDScaleEditBox.WinTop;
	HUDScaleSlider.SetSize(HUDScaleEditBox.WinWidth - HUDScaleResetButton.WinWidth - 4, 1);
	HUDScaleSlider.SliderWidth = HUDScaleEditBox.EditBoxWidth - HUDScaleResetButton.WinWidth - 4;
	CrosshairScaleResetButton.WinLeft = CrosshairScaleSlider.WinLeft + CrosshairScaleSlider.WinWidth + 2;
	CrosshairScaleResetButton.WinTop = CrosshairScaleSlider.WinTop + CrosshairScaleSlider.SliderDrawY + 1 - CrosshairScaleResetButton.WinHeight / 2;
	HUDScaleResetButton.WinLeft = HUDScaleSlider.WinLeft + HUDScaleSlider.WinWidth + 2;
	HUDScaleResetButton.WinTop = HUDScaleSlider.WinTop + HUDScaleSlider.SliderDrawY + 1 - HUDScaleResetButton.WinHeight / 2;
	ShowGameBehindMenusCheck.WinLeft = HUDScaleSlider.WinLeft;
	ShowGameBehindMenusCheck.WinTop = HUDScaleSlider.WinTop + 25;
	ShowGameBehindMenusCheck.SetSize(HUDScaleSlider.WinWidth - HUDScaleSlider.SliderWidth + 16, 1);
}

function WindowShown()
{
	Super.WindowShown();
	LoadScaleSettings();
}

function Notify(UWindowDialogControl C, byte E)
{
	Super.Notify(C, E);

	if (E == DE_Change && (C == CrosshairScaleSlider || C == HUDScaleSlider))
	{
		ApplyScaleSettings();
		UpdateScaleSettingText();
	}
	else if (E == DE_Click && C == HUDConfigResetButton)
	{
		HUDConfigSlider.SetValue(0, True);
		HUDConfigChanged();
	}
	else if (E == DE_Click && C == CrosshairResetButton)
	{
		CrosshairSlider.SetValue(0, True);
		CrosshairChanged();
	}
	else if (E == DE_Click && C == CrosshairScaleResetButton)
	{
		CrosshairScaleSlider.SetValue(15, True);
		ApplyScaleSettings();
		UpdateScaleSettingText();
	}
	else if (E == DE_Click && C == HUDScaleResetButton)
	{
		HUDScaleSlider.SetValue(15, True);
		ApplyScaleSettings();
		UpdateScaleSettingText();
	}
	else if (E == DE_Change && C == ShowGameBehindMenusCheck)
	{
		bShowGameBehindMenus = ShowGameBehindMenusCheck.bChecked;
		class'ModernHUDConfigCW'.Default.bShowGameBehindMenus = bShowGameBehindMenus;
		class'ModernHUDConfigCW'.Static.StaticSaveConfig();
	}
}

defaultproperties
{
	ShowGameBehindMenusText="Show Game Behind Menus"
	ShowGameBehindMenusHelp="Show the paused game world behind menus and Preferences for live visual adjustments."
	ResetHUDSettingHelp="Reset this HUD setting to the Unreal Revived default."
	ResetScaleHelp="Reset this scale to the Unreal Revived default of 1.5."
	bShowGameBehindMenus=True
}
