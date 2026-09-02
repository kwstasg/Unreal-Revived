class ModernInputOptionsClientWindow extends UMenuInputOptionsClientWindow;

var UMenuLabelControl MouseHeading;
var localized string MouseHeadingText;
var UMenuLabelControl ControllerHeading;
var localized string ControllerHeadingText;
var UWindowComboControl ControllerSlotCombo;
var localized string ControllerSlotText;
var localized string ControllerSlotHelp;
var localized string AutomaticSlotText;
var UWindowCheckbox LeftDeadZoneCheck;
var localized string LeftDeadZoneText;
var localized string LeftDeadZoneHelp;
var UWindowCheckbox RightDeadZoneCheck;
var localized string RightDeadZoneText;
var localized string RightDeadZoneHelp;
var UWindowHSliderControl MovementSensitivitySlider;
var localized string MovementSensitivityText;
var localized string MovementSensitivityHelp;
var UWindowHSliderControl LookSensitivitySlider;
var localized string LookSensitivityText;
var localized string LookSensitivityHelp;
var UWindowCheckbox InvertControllerCheck;
var localized string InvertControllerText;
var localized string InvertControllerHelp;

function Created()
{
	Super.Created();
	HideLegacyControls();
	CreateModernControls();
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

	LeftDeadZoneCheck = UWindowCheckbox(CreateControl(class'UWindowCheckbox', 20, 155, 220, 1));
	LeftDeadZoneCheck.SetText(LeftDeadZoneText);
	LeftDeadZoneCheck.SetHelpText(LeftDeadZoneHelp);
	LeftDeadZoneCheck.SetFont(F_Normal);
	LeftDeadZoneCheck.Align = TA_Left;

	RightDeadZoneCheck = UWindowCheckbox(CreateControl(class'UWindowCheckbox', 250, 155, 220, 1));
	RightDeadZoneCheck.SetText(RightDeadZoneText);
	RightDeadZoneCheck.SetHelpText(RightDeadZoneHelp);
	RightDeadZoneCheck.SetFont(F_Normal);
	RightDeadZoneCheck.Align = TA_Left;

	MovementSensitivitySlider = UWindowHSliderControl(CreateControl(class'UWindowHSliderControl', 20, 180, 300, 1));
	MovementSensitivitySlider.SetText(MovementSensitivityText);
	MovementSensitivitySlider.SetHelpText(MovementSensitivityHelp);
	MovementSensitivitySlider.SetFont(F_Normal);
	MovementSensitivitySlider.SetRange(20, 300, 5);
	MovementSensitivitySlider.SliderWidth = 110;

	LookSensitivitySlider = UWindowHSliderControl(CreateControl(class'UWindowHSliderControl', 20, 205, 300, 1));
	LookSensitivitySlider.SetText(LookSensitivityText);
	LookSensitivitySlider.SetHelpText(LookSensitivityHelp);
	LookSensitivitySlider.SetFont(F_Normal);
	LookSensitivitySlider.SetRange(20, 300, 5);
	LookSensitivitySlider.SliderWidth = 110;

	InvertControllerCheck = UWindowCheckbox(CreateControl(class'UWindowCheckbox', 20, 230, 220, 1));
	InvertControllerCheck.SetText(InvertControllerText);
	InvertControllerCheck.SetHelpText(InvertControllerHelp);
	InvertControllerCheck.SetFont(F_Normal);
	InvertControllerCheck.Align = TA_Left;
}

function ConfigureTabOrder()
{
	PlaceTabAfter(ControllerSlotCombo, JoystickCheck);
	PlaceTabAfter(LeftDeadZoneCheck, ControllerSlotCombo);
	PlaceTabAfter(RightDeadZoneCheck, LeftDeadZoneCheck);
	PlaceTabAfter(MovementSensitivitySlider, RightDeadZoneCheck);
	PlaceTabAfter(LookSensitivitySlider, MovementSensitivitySlider);
	PlaceTabAfter(InvertControllerCheck, LookSensitivitySlider);
	PlaceTabAfter(SensitivityEdit, InvertControllerCheck);
	PlaceTabAfter(RawHIDInputCheck, SensitivityEdit);
	PlaceTabAfter(bMouseSmoothCheck, RawHIDInputCheck);
	PlaceTabAfter(InvertMouseCheck, bMouseSmoothCheck);
	TabLast = InvertMouseCheck;
	ActiveWindow = JoystickCheck;
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
	LeftDeadZoneCheck.bChecked = bool(GetPlayerOwner().ConsoleCommand("get ini:Engine.Engine.ViewportManager DeadZoneXYZ"));
	RightDeadZoneCheck.bChecked = bool(GetPlayerOwner().ConsoleCommand("get ini:Engine.Engine.ViewportManager DeadZoneRUV"));
	MovementSensitivitySlider.SetValue(float(GetPlayerOwner().ConsoleCommand("get ini:Engine.Engine.ViewportManager ScaleXYZ")), True);
	LookSensitivitySlider.SetValue(float(GetPlayerOwner().ConsoleCommand("get ini:Engine.Engine.ViewportManager ScaleRUV")), True);
	InvertControllerCheck.bChecked = bool(GetPlayerOwner().ConsoleCommand("get ini:Engine.Engine.ViewportManager InvertVertical"));
	bInitialized = True;
}

function BeforePaint(Canvas C, float X, float Y)
{
	local float ControlWidth;

	Super.BeforePaint(C, X, Y);
	ControlWidth = FMin(360, WinWidth - 40);
	ControllerHeading.WinLeft = 20;
	ControllerHeading.WinTop = 10;
	JoystickCheck.WinLeft = 20;
	JoystickCheck.WinTop = 35;
	JoystickCheck.SetSize(ControlWidth, 1);
	ControllerSlotCombo.WinLeft = 20;
	ControllerSlotCombo.WinTop = 60;
	ControllerSlotCombo.SetSize(ControlWidth, 1);
	LeftDeadZoneCheck.WinLeft = 20;
	LeftDeadZoneCheck.WinTop = 85;
	LeftDeadZoneCheck.SetSize(ControlWidth, 1);
	RightDeadZoneCheck.WinLeft = 20;
	RightDeadZoneCheck.WinTop = 110;
	RightDeadZoneCheck.SetSize(ControlWidth, 1);
	MovementSensitivitySlider.WinLeft = 20;
	MovementSensitivitySlider.WinTop = 135;
	MovementSensitivitySlider.SetSize(ControlWidth, 1);
	LookSensitivitySlider.WinLeft = 20;
	LookSensitivitySlider.WinTop = 160;
	LookSensitivitySlider.SetSize(ControlWidth, 1);
	InvertControllerCheck.WinLeft = 20;
	InvertControllerCheck.WinTop = 185;
	InvertControllerCheck.SetSize(ControlWidth, 1);
	MouseHeading.WinLeft = 20;
	MouseHeading.WinTop = 215;
	SensitivityEdit.WinLeft = 20;
	SensitivityEdit.WinTop = 240;
	SensitivityEdit.SetSize(ControlWidth, 1);
	SensitivityEdit.EditBoxWidth = 110;
	RawHIDInputCheck.WinLeft = 20;
	RawHIDInputCheck.WinTop = 265;
	RawHIDInputCheck.SetSize(ControlWidth, 1);
	bMouseSmoothCheck.WinLeft = 20;
	bMouseSmoothCheck.WinTop = 290;
	bMouseSmoothCheck.SetSize(ControlWidth, 1);
	InvertMouseCheck.WinLeft = 20;
	InvertMouseCheck.WinTop = 315;
	InvertMouseCheck.SetSize(ControlWidth, 1);
}

function Notify(UWindowDialogControl C, byte E)
{
	Super.Notify(C, E);
	if (!bInitialized || E != DE_Change)
		return;

	if (C == ControllerSlotCombo)
		GetPlayerOwner().ConsoleCommand("set ini:Engine.Engine.ViewportManager XInputControllerIndex" @ ControllerSlotCombo.GetValue2());
	else if (C == LeftDeadZoneCheck)
		GetPlayerOwner().ConsoleCommand("set ini:Engine.Engine.ViewportManager DeadZoneXYZ" @ LeftDeadZoneCheck.bChecked);
	else if (C == RightDeadZoneCheck)
		GetPlayerOwner().ConsoleCommand("set ini:Engine.Engine.ViewportManager DeadZoneRUV" @ RightDeadZoneCheck.bChecked);
	else if (C == MovementSensitivitySlider)
		GetPlayerOwner().ConsoleCommand("set ini:Engine.Engine.ViewportManager ScaleXYZ" @ MovementSensitivitySlider.GetValue());
	else if (C == LookSensitivitySlider)
		GetPlayerOwner().ConsoleCommand("set ini:Engine.Engine.ViewportManager ScaleRUV" @ LookSensitivitySlider.GetValue());
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
	ControllerSlotHelp="Select a fixed XInput controller slot or choose automatic detection."
	AutomaticSlotText="Automatic"
	LeftDeadZoneText="Movement Dead Zone"
	LeftDeadZoneHelp="Apply the standard Xbox dead zone to the left stick."
	RightDeadZoneText="Look Dead Zone"
	RightDeadZoneHelp="Apply the standard Xbox dead zone to the right stick."
	MovementSensitivityText="Movement Sensitivity"
	MovementSensitivityHelp="Adjust movement stick scaling."
	LookSensitivityText="Look Sensitivity"
	LookSensitivityHelp="Adjust look stick scaling."
	InvertControllerText="Invert Vertical Look"
	InvertControllerHelp="Reverse vertical controller look input."
}