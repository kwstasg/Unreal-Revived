class ModernBindingsClientWindow extends UMenuCustomizeClientWindow;

function Created()
{
	local int GroupIndex;
	local int KeyIndex;

	Super.Created();
	bJoystick = False;
	JoystickHeading.HideWindow();
	JoyXCombo.HideWindow();
	JoyYCombo.HideWindow();
	DesiredHeight = NoJoyDesiredHeight;
	for (GroupIndex = 0; GroupIndex < NumGroups; GroupIndex++)
		for (KeyIndex = 0; KeyIndex < KeyGroups[GroupIndex].NumKeys; KeyIndex++)
			KeyGroups[GroupIndex].Keys[KeyIndex].KeyButton.bAcceptsFocus = True;
	ModernRootWindow(Root).ControllerBindings = Self;
	ApplyXboxKeyNames();
}

function WindowShown()
{
	Super.WindowShown();
	bJoystick = False;
	ApplyXboxKeyNames();
}

function ApplyXboxKeyNames()
{
	LocalizedKeyName[200] = "A";
	LocalizedKeyName[201] = "B";
	LocalizedKeyName[202] = "X";
	LocalizedKeyName[203] = "Y";
	LocalizedKeyName[204] = "LB";
	LocalizedKeyName[205] = "RB";
	LocalizedKeyName[206] = "View";
	LocalizedKeyName[207] = "Menu";
	LocalizedKeyName[208] = "LS";
	LocalizedKeyName[209] = "RS";
	LocalizedKeyName[210] = "RT";
	LocalizedKeyName[211] = "LT";
	LocalizedKeyName[240] = "D-pad Up";
	LocalizedKeyName[241] = "D-pad Down";
	LocalizedKeyName[242] = "D-pad Left";
	LocalizedKeyName[243] = "D-pad Right";
}

function Close(optional bool bByParent)
{
	if (ModernRootWindow(Root) != None && ModernRootWindow(Root).ControllerBindings == Self)
		ModernRootWindow(Root).ControllerBindings = None;
	Super.Close(bByParent);
}

defaultproperties
{
	CustomizeHelp="Select a binding, then press a keyboard, mouse, or controller button."
}