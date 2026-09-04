class ModernInputOptionsClientWindow extends UMenuInputOptionsClientWindow;

var UMenuLabelControl MouseHeading;
var localized string MouseHeadingText;
var UMenuLabelControl ControllerHeading;
var localized string ControllerHeadingText;
var UWindowComboControl ControllerSlotCombo;
var localized string ControllerSlotText;
var localized string ControllerSlotHelp;
var localized string AutomaticSlotText;
var UWindowHSliderControl LeftDeadZoneSlider;
var localized string LeftDeadZoneText;
var localized string LeftDeadZoneHelp;
var UWindowHSliderControl RightDeadZoneSlider;
var localized string RightDeadZoneText;
var localized string RightDeadZoneHelp;
var UWindowHSliderControl MovementSensitivitySlider;
var localized string MovementSensitivityText;
var localized string MovementSensitivityHelp;
var UWindowHSliderControl LookSensitivitySlider;
var localized string LookSensitivityText;
var localized string LookSensitivityHelp;
var ModernResetButton MovementSensitivityResetButton;
var ModernResetButton LookSensitivityResetButton;
var ModernResetButton LeftDeadZoneResetButton;
var ModernResetButton RightDeadZoneResetButton;
var localized string ResetSensitivityHelp;
var UWindowCheckbox InvertControllerCheck;
var localized string InvertControllerText;
var localized string InvertControllerHelp;

function Created()
{
	Super.Created();
	HideLegacyControls();
	CreateModernControls();
	LeftDeadZoneResetButton = CreateSliderResetButton(LeftDeadZoneSlider);
	RightDeadZoneResetButton = CreateSliderResetButton(RightDeadZoneSlider);
	MovementSensitivityResetButton = CreateSliderResetButton(MovementSensitivitySlider);
	LookSensitivityResetButton = CreateSliderResetButton(LookSensitivitySlider);
	ConfigureTabOrder();
	LoadControllerSettings();
	DesiredHeight = 350;
}

function HideControl(UWindowDialogControl Control)
{
	if (Control == None)
		return;
	RemoveFromTabOrder(Control);
	Control.HideWindow();
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
	RemoveFromTabOrder(Control);
	Control.TabNext = PreviousControl.TabNext;
	Control.TabPrev = PreviousControl;
	PreviousControl.TabNext.TabPrev = Control;
	PreviousControl.TabNext = Control;
}

function HideLegacyControls()
{
	HideControl(AutoAimCheck);
	HideControl(LookSpringCheck);
	HideControl(MouseLookCheck);
	HideControl(AutoSlopeCheck);
	HideControl(MouseSmoothCheck);
	HideControl(DodgingCheck);
	HideControl(DodgeClickTimeEdit);
}

function CreateModernControls()
{
	local int Index;

	JoystickCheck.Align = TA_Left;
	RawHIDInputCheck.Align = TA_Left;
	bMouseSmoothCheck.Align = TA_Left;
	InvertMouseCheck.Align = TA_Left;

	MouseHeading = UMenuLabelControl(CreateControl(class'UMenuLabelControl', 20, 10, 200, 1));
	MouseHeading.SetText(MouseHeadingText);
	MouseHeading.SetFont(F_Bold);

	ControllerHeading = UMenuLabelControl(CreateControl(class'UMenuLabelControl', 20, 105, 200, 1));
	ControllerHeading.SetText(ControllerHeadingText);
	ControllerHeading.SetFont(F_Bold);

	ControllerSlotCombo = UWindowComboControl(CreateControl(class'UWindowComboControl', 20, 130, 300, 1));
	ControllerSlotCombo.SetText(ControllerSlotText);
	ControllerSlotCombo.SetHelpText(ControllerSlotHelp);
	ControllerSlotCombo.SetFont(F_Normal);
	ControllerSlotCombo.SetEditable(False);
	ControllerSlotCombo.AddItem(AutomaticSlotText, "-1");
	for (Index = 0; Index < 4; Index++)
		ControllerSlotCombo.AddItem("Controller" @ string(Index + 1), string(Index));
	ControllerSlotCombo.EditBoxWidth = 110;

	LeftDeadZoneSlider = UWindowHSliderControl(CreateControl(class'UWindowHSliderControl', 20, 155, 300, 1));
	LeftDeadZoneSlider.SetHelpText(LeftDeadZoneHelp);
	LeftDeadZoneSlider.SetFont(F_Normal);
	LeftDeadZoneSlider.SetRange(0, 50, 1);
	LeftDeadZoneSlider.SliderWidth = 110;
	LeftDeadZoneSlider.TrackWidth = 8;
	LeftDeadZoneSlider.bNoSlidingNotify = False;

	RightDeadZoneSlider = UWindowHSliderControl(CreateControl(class'UWindowHSliderControl', 20, 180, 300, 1));
	RightDeadZoneSlider.SetHelpText(RightDeadZoneHelp);
	RightDeadZoneSlider.SetFont(F_Normal);
	RightDeadZoneSlider.SetRange(0, 50, 1);
	RightDeadZoneSlider.SliderWidth = 110;
	RightDeadZoneSlider.TrackWidth = 8;
	RightDeadZoneSlider.bNoSlidingNotify = False;

	MovementSensitivitySlider = UWindowHSliderControl(CreateControl(class'UWindowHSliderControl', 20, 180, 300, 1));
	MovementSensitivitySlider.SetText(MovementSensitivityText);
	MovementSensitivitySlider.SetHelpText(MovementSensitivityHelp);
	MovementSensitivitySlider.SetFont(F_Normal);
	MovementSensitivitySlider.SetRange(20, 300, 5);
	MovementSensitivitySlider.SliderWidth = 110;
	MovementSensitivitySlider.TrackWidth = 8;
	MovementSensitivitySlider.bNoSlidingNotify = False;

	LookSensitivitySlider = UWindowHSliderControl(CreateControl(class'UWindowHSliderControl', 20, 205, 300, 1));
	LookSensitivitySlider.SetText(LookSensitivityText);
	LookSensitivitySlider.SetHelpText(LookSensitivityHelp);
	LookSensitivitySlider.SetFont(F_Normal);
	LookSensitivitySlider.SetRange(20, 300, 5);
	LookSensitivitySlider.SliderWidth = 110;
	LookSensitivitySlider.TrackWidth = 8;
	LookSensitivitySlider.bNoSlidingNotify = False;

	InvertControllerCheck = UWindowCheckbox(CreateControl(class'UWindowCheckbox', 20, 230, 220, 1));
	InvertControllerCheck.SetText(InvertControllerText);
	InvertControllerCheck.SetHelpText(InvertControllerHelp);
	InvertControllerCheck.SetFont(F_Normal);
	InvertControllerCheck.Align = TA_Left;
}

function ConfigureTabOrder()
{
	RemoveFromTabOrder(LeftDeadZoneResetButton);
	RemoveFromTabOrder(RightDeadZoneResetButton);
	RemoveFromTabOrder(MovementSensitivityResetButton);
	RemoveFromTabOrder(LookSensitivityResetButton);
	PlaceTabAfter(ControllerSlotCombo, JoystickCheck);
	PlaceTabAfter(LeftDeadZoneSlider, ControllerSlotCombo);
	PlaceTabAfter(RightDeadZoneSlider, LeftDeadZoneSlider);
	PlaceTabAfter(MovementSensitivitySlider, RightDeadZoneSlider);
	PlaceTabAfter(LookSensitivitySlider, MovementSensitivitySlider);
	PlaceTabAfter(InvertControllerCheck, LookSensitivitySlider);
	PlaceTabAfter(SensitivityEdit, InvertControllerCheck);
	PlaceTabAfter(RawHIDInputCheck, SensitivityEdit);
	PlaceTabAfter(bMouseSmoothCheck, RawHIDInputCheck);
	PlaceTabAfter(InvertMouseCheck, bMouseSmoothCheck);
	TabLast = InvertMouseCheck;
	ActiveWindow = JoystickCheck;
}

function ModernResetButton CreateSliderResetButton(UWindowHSliderControl Slider)
{
	local ModernResetButton Button;

	Button = ModernResetButton(CreateControl(class'ModernResetButton', Slider.WinLeft + Slider.WinWidth - 12, Slider.WinTop, 12, 10));
	Button.SetHelpText(ResetSensitivityHelp);
	Button.ToolTipString = ResetSensitivityHelp;
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

function UpdateSensitivityText()
{
	LeftDeadZoneSlider.SetText(LeftDeadZoneText $ " (" $ int(LeftDeadZoneSlider.Value) $ "%)");
	RightDeadZoneSlider.SetText(RightDeadZoneText $ " (" $ int(RightDeadZoneSlider.Value) $ "%)");
	MovementSensitivitySlider.SetText(MovementSensitivityText $ " (" $ int(MovementSensitivitySlider.Value) $ "%)");
	LookSensitivitySlider.SetText(LookSensitivityText $ " (" $ int(LookSensitivitySlider.Value) $ "%)");
}

function bool ResetControllerSlider(UWindowHSliderControl Slider)
{
	if (Slider == LeftDeadZoneSlider)
		Notify(LeftDeadZoneResetButton, DE_Click);
	else if (Slider == RightDeadZoneSlider)
		Notify(RightDeadZoneResetButton, DE_Click);
	else if (Slider == MovementSensitivitySlider)
		Notify(MovementSensitivityResetButton, DE_Click);
	else if (Slider == LookSensitivitySlider)
		Notify(LookSensitivityResetButton, DE_Click);
	else
		return False;
	return True;
}

function WindowShown()
{
	Super.WindowShown();
	LoadControllerSettings();
}

function LoadControllerSettings()
{
	local int SlotIndex;

	if (!bInitialized || ControllerSlotCombo == None)
		return;
	bInitialized = False;
	SlotIndex = int(GetPlayerOwner().ConsoleCommand("get ini:Engine.Engine.ViewportManager XInputControllerIndex"));
	ControllerSlotCombo.SetSelectedIndex(Clamp(SlotIndex + 1, 0, 4));
	if (bool(GetPlayerOwner().ConsoleCommand("get ini:Engine.Engine.ViewportManager DeadZoneXYZ")))
		LeftDeadZoneSlider.SetValue(float(GetPlayerOwner().ConsoleCommand("get ini:Engine.Engine.ViewportManager LeftStickDeadZonePercent")), True);
	else
		LeftDeadZoneSlider.SetValue(0, True);
	if (bool(GetPlayerOwner().ConsoleCommand("get ini:Engine.Engine.ViewportManager DeadZoneRUV")))
		RightDeadZoneSlider.SetValue(float(GetPlayerOwner().ConsoleCommand("get ini:Engine.Engine.ViewportManager RightStickDeadZonePercent")), True);
	else
		RightDeadZoneSlider.SetValue(0, True);
	MovementSensitivitySlider.SetValue(float(GetPlayerOwner().ConsoleCommand("get ini:Engine.Engine.ViewportManager ScaleXYZ")), True);
	LookSensitivitySlider.SetValue(float(GetPlayerOwner().ConsoleCommand("get ini:Engine.Engine.ViewportManager ScaleRUV")), True);
	InvertControllerCheck.bChecked = bool(GetPlayerOwner().ConsoleCommand("get ini:Engine.Engine.ViewportManager InvertVertical"));
	UpdateSensitivityText();
	bInitialized = True;
}

function BeforePaint(Canvas C, float X, float Y)
{
	local float CheckboxWidth, ControlWidth;

	Super.BeforePaint(C, X, Y);
	ControlWidth = FMin(360, WinWidth - 40);
	CheckboxWidth = ControlWidth - 110 + 16;
	ControllerHeading.WinLeft = 20;
	ControllerHeading.WinTop = 10;
	JoystickCheck.WinLeft = 20;
	JoystickCheck.WinTop = 35;
	JoystickCheck.SetSize(CheckboxWidth, 1);
	ControllerSlotCombo.WinLeft = 20;
	ControllerSlotCombo.WinTop = 60;
	ControllerSlotCombo.SetSize(ControlWidth, 1);
	LeftDeadZoneSlider.WinLeft = 20;
	LeftDeadZoneSlider.WinTop = 85;
	LeftDeadZoneSlider.SetSize(ControlWidth, 1);
	LeftDeadZoneSlider.SliderWidth = 110;
	RightDeadZoneSlider.WinLeft = 20;
	RightDeadZoneSlider.WinTop = 110;
	RightDeadZoneSlider.SetSize(ControlWidth, 1);
	RightDeadZoneSlider.SliderWidth = 110;
	MovementSensitivitySlider.WinLeft = 20;
	MovementSensitivitySlider.WinTop = 135;
	MovementSensitivitySlider.SetSize(ControlWidth, 1);
	MovementSensitivitySlider.SliderWidth = 110;
	LookSensitivitySlider.WinLeft = 20;
	LookSensitivitySlider.WinTop = 160;
	LookSensitivitySlider.SetSize(ControlWidth, 1);
	LookSensitivitySlider.SliderWidth = 110;
	LayoutSliderResetButton(LeftDeadZoneSlider, LeftDeadZoneResetButton);
	LayoutSliderResetButton(RightDeadZoneSlider, RightDeadZoneResetButton);
	LayoutSliderResetButton(MovementSensitivitySlider, MovementSensitivityResetButton);
	LayoutSliderResetButton(LookSensitivitySlider, LookSensitivityResetButton);
	InvertControllerCheck.WinLeft = 20;
	InvertControllerCheck.WinTop = 185;
	InvertControllerCheck.SetSize(CheckboxWidth, 1);
	MouseHeading.WinLeft = 20;
	MouseHeading.WinTop = 215;
	SensitivityEdit.WinLeft = 20;
	SensitivityEdit.WinTop = 240;
	SensitivityEdit.SetSize(ControlWidth, 1);
	SensitivityEdit.EditBoxWidth = 110;
	RawHIDInputCheck.WinLeft = 20;
	RawHIDInputCheck.WinTop = 265;
	RawHIDInputCheck.SetSize(CheckboxWidth, 1);
	bMouseSmoothCheck.WinLeft = 20;
	bMouseSmoothCheck.WinTop = 290;
	bMouseSmoothCheck.SetSize(CheckboxWidth, 1);
	InvertMouseCheck.WinLeft = 20;
	InvertMouseCheck.WinTop = 315;
	InvertMouseCheck.SetSize(CheckboxWidth, 1);
}

function Notify(UWindowDialogControl C, byte E)
{
	Super.Notify(C, E);
	if (E == DE_Click && C == LeftDeadZoneResetButton)
	{
		LeftDeadZoneSlider.SetValue(25, True);
		GetPlayerOwner().ConsoleCommand("set ini:Engine.Engine.ViewportManager DeadZoneXYZ True");
		GetPlayerOwner().ConsoleCommand("set ini:Engine.Engine.ViewportManager LeftStickDeadZonePercent 25");
		UpdateSensitivityText();
		return;
	}
	if (E == DE_Click && C == RightDeadZoneResetButton)
	{
		RightDeadZoneSlider.SetValue(25, True);
		GetPlayerOwner().ConsoleCommand("set ini:Engine.Engine.ViewportManager DeadZoneRUV True");
		GetPlayerOwner().ConsoleCommand("set ini:Engine.Engine.ViewportManager RightStickDeadZonePercent 25");
		UpdateSensitivityText();
		return;
	}
	if (E == DE_Click && C == MovementSensitivityResetButton)
	{
		MovementSensitivitySlider.SetValue(85, True);
		GetPlayerOwner().ConsoleCommand("set ini:Engine.Engine.ViewportManager ScaleXYZ 85");
		UpdateSensitivityText();
		return;
	}
	if (E == DE_Click && C == LookSensitivityResetButton)
	{
		LookSensitivitySlider.SetValue(85, True);
		GetPlayerOwner().ConsoleCommand("set ini:Engine.Engine.ViewportManager ScaleRUV 85");
		UpdateSensitivityText();
		return;
	}
	if (!bInitialized || E != DE_Change)
		return;

	if (C == ControllerSlotCombo)
		GetPlayerOwner().ConsoleCommand("set ini:Engine.Engine.ViewportManager XInputControllerIndex" @ ControllerSlotCombo.GetValue2());
	else if (C == LeftDeadZoneSlider)
	{
		GetPlayerOwner().ConsoleCommand("set ini:Engine.Engine.ViewportManager DeadZoneXYZ" @ (LeftDeadZoneSlider.Value > 0));
		GetPlayerOwner().ConsoleCommand("set ini:Engine.Engine.ViewportManager LeftStickDeadZonePercent" @ LeftDeadZoneSlider.GetValue());
		UpdateSensitivityText();
	}
	else if (C == RightDeadZoneSlider)
	{
		GetPlayerOwner().ConsoleCommand("set ini:Engine.Engine.ViewportManager DeadZoneRUV" @ (RightDeadZoneSlider.Value > 0));
		GetPlayerOwner().ConsoleCommand("set ini:Engine.Engine.ViewportManager RightStickDeadZonePercent" @ RightDeadZoneSlider.GetValue());
		UpdateSensitivityText();
	}
	else if (C == MovementSensitivitySlider)
	{
		GetPlayerOwner().ConsoleCommand("set ini:Engine.Engine.ViewportManager ScaleXYZ" @ MovementSensitivitySlider.GetValue());
		UpdateSensitivityText();
	}
	else if (C == LookSensitivitySlider)
	{
		GetPlayerOwner().ConsoleCommand("set ini:Engine.Engine.ViewportManager ScaleRUV" @ LookSensitivitySlider.GetValue());
		UpdateSensitivityText();
	}
	else if (C == InvertControllerCheck)
		GetPlayerOwner().ConsoleCommand("set ini:Engine.Engine.ViewportManager InvertVertical" @ InvertControllerCheck.bChecked);
}

defaultproperties
{
	JoystickText="Controller Enabled"
	JoystickHelp="Enable game controller input."
	RawHIDInputText="Raw Mouse Input"
	RawHIDInputHelp="Read mouse movement directly from Windows raw input."
	bMouseSmoothText="Mouse Smoothing"
	SensitivityText="Mouse Sensitivity"
	MouseHeadingText="Mouse"
	ControllerHeadingText="Controller"
	ControllerSlotText="Preferred Controller"
	ControllerSlotHelp="Select a fixed game controller or choose automatic detection."
	AutomaticSlotText="Automatic"
	LeftDeadZoneText="Movement Dead Zone"
	LeftDeadZoneHelp="Adjust the radial dead zone for the left stick."
	RightDeadZoneText="Look Dead Zone"
	RightDeadZoneHelp="Adjust the radial dead zone for the right stick."
	MovementSensitivityText="Movement Sensitivity"
	MovementSensitivityHelp="Adjust movement stick scaling."
	LookSensitivityText="Look Sensitivity"
	LookSensitivityHelp="Adjust look stick scaling."
	ResetSensitivityHelp="Reset this setting to its default value."
	InvertControllerText="Invert Vertical Look"
	InvertControllerHelp="Reverse vertical controller look input."
}