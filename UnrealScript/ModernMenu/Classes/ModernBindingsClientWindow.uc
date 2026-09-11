// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived

class ModernBindingsClientWindow extends UMenuCustomizeClientWindow;

var array<int> ThirdBoundKeys;
var string BaseLocalizedKeyName[255];
var bool bBindingLayoutValid;
var bool bBindingVisibilityValid;
var float BindingLayoutWidth;
var float LastBindingScrollTop;
var localized string VRRecenterText;

function Created()
{
	local int GroupIndex;
	local int KeyIndex;

	Super.Created();
	AddVRRecenterBinding();
	bJoystick = False;
	JoystickHeading.HideWindow();
	JoyXCombo.HideWindow();
	JoyYCombo.HideWindow();
	DesiredHeight = NoJoyDesiredHeight;
	for (GroupIndex = 0; GroupIndex < NumGroups; GroupIndex++)
		for (KeyIndex = 0; KeyIndex < KeyGroups[GroupIndex].NumKeys; KeyIndex++)
			KeyGroups[GroupIndex].Keys[KeyIndex].KeyButton.SetAcceptsFocus();
	ConfigureBindingTabOrder();
	ModernRootWindow(Root).ControllerBindings = Self;
	ApplyXboxKeyNames();
	CacheLocalizedKeyNames();
}

function AddVRRecenterBinding()
{
	local int G, ButtonTop;
	if (KeyIsThere("RecenterVR"))
		return;
	G = NumGroups++;
	KeyGroups[G].GroupName = "VR";
	KeyGroups[G].LabelText = UMenuLabelControl(CreateControl(class'UMenuLabelControl', 0, 0, 100, 1));
	KeyGroups[G].LabelText.SetText("VR");
	KeyGroups[G].LabelText.SetFont(F_Bold);
	KeyGroups[G].NumKeys = 1;
	KeyGroups[G].Keys[0].AliasString = "RecenterVR";
	KeyGroups[G].Keys[0].KeyName = UMenuLabelControl(CreateControl(class'UMenuLabelControl', 0, 0, 100, 1));
	KeyGroups[G].Keys[0].KeyName.SetText(VRRecenterText);
	KeyGroups[G].Keys[0].KeyName.SetFont(F_Normal);
	KeyGroups[G].Keys[0].KeyName.SetHelpText(CustomizeHelp);
	KeyGroups[G].Keys[0].KeyName.bNotifyMouseClicks = True;
	KeyGroups[G].Keys[0].KeyButton = UMenuRaisedButton(CreateControl(class'UMenuRaisedButton', 0, 0, EditAreaWidth, 1));
	KeyGroups[G].Keys[0].KeyButton.SetHelpText(CustomizeHelp);
	KeyGroups[G].Keys[0].KeyButton.bIgnoreLDoubleClick = True;
	KeyGroups[G].Keys[0].KeyButton.bIgnoreMDoubleClick = True;
	KeyGroups[G].Keys[0].KeyButton.bIgnoreRDoubleClick = True;
	ButtonTop = 25;
	SetButtonsHeight(ButtonTop);
	NoJoyDesiredHeight = ButtonTop + 10;
}

function ConfigureBindingTabOrder()
{
	local int GroupIndex;
	local int KeyIndex;
	local UWindowDialogControl FirstControl;
	local UWindowDialogControl PreviousControl;
	local UWindowDialogControl CurrentControl;

	for (GroupIndex = 0; GroupIndex < NumGroups; GroupIndex++)
	{
		for (KeyIndex = 0; KeyIndex < KeyGroups[GroupIndex].NumKeys; KeyIndex++)
		{
			CurrentControl = KeyGroups[GroupIndex].Keys[KeyIndex].KeyButton;
			if (FirstControl == None)
				FirstControl = CurrentControl;
			if (PreviousControl != None)
			{
				PreviousControl.TabNext = CurrentControl;
				CurrentControl.TabPrev = PreviousControl;
			}
			PreviousControl = CurrentControl;
		}
	}
	PreviousControl.TabNext = FirstControl;
	FirstControl.TabPrev = PreviousControl;
	DefaultsButton.TabNext = FirstControl;
	DefaultsButton.TabPrev = PreviousControl;
	TabLast = PreviousControl;
	ActiveWindow = FirstControl;
}

function bool IsVisibleForInput()
{
	local UWindowWindow Window;

	for (Window = Self; Window != None && Window != Root; Window = Window.ParentWindow)
		if (!Window.bWindowVisible)
			return False;
	return Window == Root;
}

function FocusNextBindingControl()
{
	local UWindowDialogControl Control;
	local UWindowDialogControl Candidate;
	local int GroupIndex;
	local int KeyIndex;

	Control = UWindowDialogControl(Root.KeyFocusWindow);
	if (Control == DefaultsButton)
		Candidate = DefaultsButton.TabNext;
	else
	{
		for (GroupIndex = 0; GroupIndex < NumGroups; GroupIndex++)
			for (KeyIndex = 0; KeyIndex < KeyGroups[GroupIndex].NumKeys; KeyIndex++)
				if (Control == KeyGroups[GroupIndex].Keys[KeyIndex].KeyButton)
					Candidate = Control.TabNext;
	}
	if (Candidate == None)
		Candidate = DefaultsButton.TabNext;
	Candidate.ActivateWindow(0, False);
	ModernRootWindow(Root).RevealControllerControl(Candidate);
}

function FocusFirstBindingControl()
{
	if (DefaultsButton.TabNext != None)
	{
		DefaultsButton.TabNext.ActivateWindow(0, False);
		ModernRootWindow(Root).RevealControllerControl(DefaultsButton.TabNext);
	}
}

function bool BeginFocusedBindingCapture(bool bFromScratch)
{
	local int GroupIndex;
	local int KeyIndex;
	local UWindowDialogControl Control;

	Control = UWindowDialogControl(Root.KeyFocusWindow);
	for (GroupIndex = 0; GroupIndex < NumGroups; GroupIndex++)
	{
		for (KeyIndex = 0; KeyIndex < KeyGroups[GroupIndex].NumKeys; KeyIndex++)
		{
			if (Control == KeyGroups[GroupIndex].Keys[KeyIndex].KeyButton)
			{
				if (bFromScratch)
					Notify(Control, DE_RClick);
				else
					Notify(Control, DE_Click);
				return True;
			}
		}
	}
	return False;
}

function bool ClearFocusedBinding()
{
	if (!BeginFocusedBindingCapture(True))
		return False;
	CancelKeySelection();
	RefreshThirdBindings();
	return True;
}

function WindowShown()
{
	Super.WindowShown();
	bJoystick = False;
	bBindingLayoutValid = False;
	bBindingVisibilityValid = False;
	ModernRootWindow(Root).ControllerBindings = Self;
	ApplyXboxKeyNames();
	RefreshThirdBindings();
	FocusFirstBindingControl();
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

function CacheLocalizedKeyNames()
{
	local int KeyNo;

	for (KeyNo = 0; KeyNo < 255; KeyNo++)
		BaseLocalizedKeyName[KeyNo] = LocalizedKeyName[KeyNo];
}

function string NormalizeBindingAlias(string Alias)
{
	local int Pos;

	Pos = InStr(Alias, " ");
	if (Pos >= 0
		&& !(Left(Alias, Pos) ~= "taunt")
		&& !(Left(Alias, Pos) ~= "getweapon")
		&& !(Left(Alias, Pos) ~= "viewplayernum")
		&& !(Left(Alias, Pos) ~= "button")
		&& !(Left(Alias, Pos) ~= "mutate"))
		return Left(Alias, Pos);
	return Alias;
}

function RestoreDefaultControllerBindings()
{
	GetPlayerOwner().ConsoleCommand("SET Input MiddleMouse");
	GetPlayerOwner().ConsoleCommand("SET Input NumPadPeriod");
	GetPlayerOwner().ConsoleCommand("SET Input GreyPlus");
	GetPlayerOwner().ConsoleCommand("SET Input Shift");
	GetPlayerOwner().ConsoleCommand("SET Input Ctrl Duck");
	GetPlayerOwner().ConsoleCommand("SET Input C Duck");
	GetPlayerOwner().ConsoleCommand("SET Input Joy1 Jump");
	GetPlayerOwner().ConsoleCommand("SET Input Joy2");
	GetPlayerOwner().ConsoleCommand("SET Input Joy3 InventoryActivate");
	GetPlayerOwner().ConsoleCommand("SET Input Joy4 InventoryNext");
	GetPlayerOwner().ConsoleCommand("SET Input Joy5 PrevWeapon");
	GetPlayerOwner().ConsoleCommand("SET Input Joy6 NextWeapon");
	GetPlayerOwner().ConsoleCommand("SET Input Joy7 InventoryPrevious");
	GetPlayerOwner().ConsoleCommand("SET Input Joy8");
	GetPlayerOwner().ConsoleCommand("SET Input Joy9 Duck");
	GetPlayerOwner().ConsoleCommand("SET Input Joy10 RecenterVR");
	GetPlayerOwner().ConsoleCommand("SET Input F10 RecenterVR");
	GetPlayerOwner().ConsoleCommand("SET Input Joy11 Fire");
	GetPlayerOwner().ConsoleCommand("SET Input Joy12 AltFire");
	GetPlayerOwner().ConsoleCommand("SET Input Joy13 InventoryNext");
	GetPlayerOwner().ConsoleCommand("SET Input Joy14");
	GetPlayerOwner().ConsoleCommand("SET Input Joy15");
	GetPlayerOwner().ConsoleCommand("SET Input Joy16");
	GetPlayerOwner().ConsoleCommand("SET Input JoyPovRight SwitchWeapon 6");
	GetPlayerOwner().ConsoleCommand("SET Input JoyPovLeft SwitchWeapon 7");
	GetPlayerOwner().ConsoleCommand("SET Input JoyPovUp SwitchWeapon 8");
	GetPlayerOwner().ConsoleCommand("SET Input JoyPovDown SwitchWeapon 5");
}

function int CountSelectedBindings()
{
	local int BindingCount;
	local int KeyNo;
	local string Alias;
	local string KeyName;

	for (KeyNo = 1; KeyNo < 255; KeyNo++)
	{
		KeyName = GetPlayerOwner().ConsoleCommand("KEYNAME" @ KeyNo);
		if (KeyName == "")
			continue;
		Alias = NormalizeBindingAlias(GetPlayerOwner().ConsoleCommand("KEYBINDING" @ KeyName));
		if (KeyGroups[Selection[0]].Keys[Selection[1]].AliasString ~= Alias)
			BindingCount++;
	}
	return BindingCount;
}

function int GetFlatBindingIndex(int GroupIndex, int KeyIndex)
{
	local int Index;
	local int CurrentGroup;

	for (CurrentGroup = 0; CurrentGroup < GroupIndex; CurrentGroup++)
		Index += KeyGroups[CurrentGroup].NumKeys;
	return Index + KeyIndex;
}

function RefreshThirdBindings()
{
	local string DisplayName;
	local int FlatIndex;
	local int GroupIndex;
	local int KeyIndex;
	local int KeyNo;
	local string Alias;
	local string KeyName;

	ThirdBoundKeys.SetSize(0);
	for (KeyNo = 0; KeyNo < 255; KeyNo++)
		LocalizedKeyName[KeyNo] = BaseLocalizedKeyName[KeyNo];
	for (GroupIndex = 0; GroupIndex < NumGroups; GroupIndex++)
		for (KeyIndex = 0; KeyIndex < KeyGroups[GroupIndex].NumKeys; KeyIndex++)
			ThirdBoundKeys[GetFlatBindingIndex(GroupIndex, KeyIndex)] = 0;

	for (KeyNo = 1; KeyNo < 255; KeyNo++)
	{
		KeyName = GetPlayerOwner().ConsoleCommand("KEYNAME" @ KeyNo);
		if (KeyName == "")
			continue;
		Alias = NormalizeBindingAlias(GetPlayerOwner().ConsoleCommand("KEYBINDING" @ KeyName));
		if (Alias == "")
			continue;
		for (GroupIndex = 0; GroupIndex < NumGroups; GroupIndex++)
		{
			for (KeyIndex = 0; KeyIndex < KeyGroups[GroupIndex].NumKeys; KeyIndex++)
			{
				if (!(KeyGroups[GroupIndex].Keys[KeyIndex].AliasString ~= Alias)
					|| KeyGroups[GroupIndex].Keys[KeyIndex].BoundKey1 == KeyNo
					|| KeyGroups[GroupIndex].Keys[KeyIndex].BoundKey2 == KeyNo)
					continue;
				FlatIndex = GetFlatBindingIndex(GroupIndex, KeyIndex);
				if (ThirdBoundKeys[FlatIndex] == 0)
					ThirdBoundKeys[FlatIndex] = KeyNo;
			}
		}
	}
	for (GroupIndex = 0; GroupIndex < NumGroups; GroupIndex++)
	{
		for (KeyIndex = 0; KeyIndex < KeyGroups[GroupIndex].NumKeys; KeyIndex++)
		{
			KeyNo = ThirdBoundKeys[GetFlatBindingIndex(GroupIndex, KeyIndex)];
			if (KeyNo == 0 || KeyGroups[GroupIndex].Keys[KeyIndex].BoundKey2 <= 0)
				continue;
			DisplayName = BaseLocalizedKeyName[KeyNo];
			if (DisplayName == "")
				DisplayName = RealKeyName[KeyNo];
			KeyNo = KeyGroups[GroupIndex].Keys[KeyIndex].BoundKey2;
			LocalizedKeyName[KeyNo] = BaseLocalizedKeyName[KeyNo] $ OrString $ DisplayName;
		}
	}
	RefreshBindingButtonTexts();
}

function string GetBindingButtonText(int GroupIndex, int KeyIndex)
{
	local string KeyText;
	local int KeyNo;

	if (bPolling && bErasing && Selection[0] == GroupIndex && Selection[1] == KeyIndex)
		return "";
	KeyNo = KeyGroups[GroupIndex].Keys[KeyIndex].BoundKey1;
	if (KeyNo > 0)
		KeyText = LocalizedKeyName[KeyNo];
	else if (KeyNo < 0)
		KeyText = Chr(-KeyNo) @ "(" $ -KeyNo $ ")";
	if (KeyNo != 0 && KeyGroups[GroupIndex].Keys[KeyIndex].BoundKey2 != 0)
		KeyText $= OrString;
	KeyNo = KeyGroups[GroupIndex].Keys[KeyIndex].BoundKey2;
	if (KeyNo > 0)
		KeyText $= LocalizedKeyName[KeyNo];
	else if (KeyNo < 0)
		KeyText $= Chr(-KeyNo) @ "(" $ -KeyNo $ ")";
	return KeyText;
}

function RefreshBindingButtonTexts()
{
	local int GroupIndex;
	local int KeyIndex;

	for (GroupIndex = 0; GroupIndex < NumGroups; GroupIndex++)
		for (KeyIndex = 0; KeyIndex < KeyGroups[GroupIndex].NumKeys; KeyIndex++)
			KeyGroups[GroupIndex].Keys[KeyIndex].KeyButton.SetText(GetBindingButtonText(GroupIndex, KeyIndex));
}

function LayoutBindingControls(Canvas C)
{
	local int ButtonWidth;
	local int ButtonLeft;
	local int GroupIndex;
	local int KeyIndex;
	local int LabelWidth;
	local int LabelHSpacing;
	local int RightSpacing;
	local float LabelTextAreaWidth;

	CalcLabelTextAreaWidth(C, LabelTextAreaWidth);
	LabelHSpacing = (WinWidth - LabelTextAreaWidth - EditAreaWidth) / 3;
	RightSpacing = VScrollbarWidth() + 3;
	if (LabelHSpacing < RightSpacing)
		LabelHSpacing = (WinWidth - LabelTextAreaWidth - EditAreaWidth - RightSpacing) / 2;
	LabelWidth = LabelTextAreaWidth + LabelHSpacing;
	ButtonWidth = EditAreaWidth;
	ButtonLeft = LabelHSpacing + LabelWidth;
	DefaultsButton.AutoWidth(C);
	DefaultsButton.WinLeft = ButtonLeft + ButtonWidth - DefaultsButton.WinWidth;
	DesiredHeight = NoJoyDesiredHeight;
	JoystickHeading.HideWindow();
	JoyXCombo.HideWindow();
	JoyYCombo.HideWindow();
	for (GroupIndex = 0; GroupIndex < NumGroups; GroupIndex++)
	{
		if (KeyGroups[GroupIndex].LabelText != None)
		{
			KeyGroups[GroupIndex].LabelText.WinLeft = LabelHSpacing;
			KeyGroups[GroupIndex].LabelText.SetSize(WinWidth - 2 * LabelHSpacing, 1);
		}
		for (KeyIndex = 0; KeyIndex < KeyGroups[GroupIndex].NumKeys; KeyIndex++)
		{
			KeyGroups[GroupIndex].Keys[KeyIndex].KeyButton.SetSize(ButtonWidth, 1);
			KeyGroups[GroupIndex].Keys[KeyIndex].KeyButton.WinLeft = ButtonLeft;
			KeyGroups[GroupIndex].Keys[KeyIndex].KeyName.SetSize(LabelWidth, 1);
			KeyGroups[GroupIndex].Keys[KeyIndex].KeyName.WinLeft = LabelHSpacing;
		}
	}
	BindingLayoutWidth = WinWidth;
	bBindingLayoutValid = True;
	bBindingVisibilityValid = False;
}

function UpdateVisibleBindingRows()
{
	local int GroupIndex;
	local int KeyIndex;
	local float RowLeft;
	local float RowTop;
	local UWindowScrollingDialogClient Scrolling;
	local UWindowWindow Window;
	local float ViewLeft;
	local float ViewTop;
	local bool bVisible;

	for (Window = ParentWindow; Window != None && Window != Root; Window = Window.ParentWindow)
	{
		Scrolling = UWindowScrollingDialogClient(Window);
		if (Scrolling != None)
			break;
	}
	if (Scrolling == None)
		return;
	Scrolling.WindowToGlobal(0, 0, ViewLeft, ViewTop);
	for (GroupIndex = 0; GroupIndex < NumGroups; GroupIndex++)
	{
		for (KeyIndex = 0; KeyIndex < KeyGroups[GroupIndex].NumKeys; KeyIndex++)
		{
			KeyGroups[GroupIndex].Keys[KeyIndex].KeyButton.WindowToGlobal(0, 0, RowLeft, RowTop);
			bVisible = RowTop + KeyGroups[GroupIndex].Keys[KeyIndex].KeyButton.WinHeight >= ViewTop
				&& RowTop <= ViewTop + Scrolling.WinHeight;
			if (bVisible && !KeyGroups[GroupIndex].Keys[KeyIndex].KeyButton.bWindowVisible)
			{
				KeyGroups[GroupIndex].Keys[KeyIndex].KeyName.ShowWindow();
				KeyGroups[GroupIndex].Keys[KeyIndex].KeyButton.ShowWindow();
			}
			else if (!bVisible && KeyGroups[GroupIndex].Keys[KeyIndex].KeyButton.bWindowVisible)
			{
				KeyGroups[GroupIndex].Keys[KeyIndex].KeyName.HideWindow();
				KeyGroups[GroupIndex].Keys[KeyIndex].KeyButton.HideWindow();
			}
		}
	}
}

function BeforePaint(Canvas C, float X, float Y)
{
	if (!bBindingLayoutValid || BindingLayoutWidth != WinWidth)
		LayoutBindingControls(C);
	if (!bBindingVisibilityValid || LastBindingScrollTop != WinTop)
	{
		UpdateVisibleBindingRows();
		LastBindingScrollTop = WinTop;
		bBindingVisibilityValid = True;
	}
}

function CancelKeySelection(optional bool bEscape)
{
	Super.CancelKeySelection(bEscape);
	RefreshBindingButtonTexts();
}

function bool CaptureKeyboardBinding(int KeyNo)
{
	local string KeyName;

	if (!bPolling)
		return False;
	if (KeyNo == IK_Escape)
	{
		CancelKeySelection(True);
		return True;
	}
	KeyName = GetPlayerOwner().ConsoleCommand("KEYNAME" @ KeyNo);
	if (KeyName == "")
		return False;
	ProcessMenuKey(KeyNo, KeyName);
	return True;
}

function ProcessMenuKey(int KeyNo, string KeyName)
{
	local string Alias;

	if (Selection[0] == ConsoleButtonGroupIdx && Selection[1] == ConsoleButtonKeyIdx
		|| Selection[0] == ConsoleCharacterGroupIdx && Selection[1] == ConsoleCharacterKeyIdx)
	{
		Super.ProcessMenuKey(KeyNo, KeyName);
		return;
	}
	Alias = NormalizeBindingAlias(GetPlayerOwner().ConsoleCommand("KEYBINDING" @ KeyName));
	if (KeyGroups[Selection[0]].Keys[Selection[1]].AliasString ~= Alias)
	{
		CancelKeySelection(True);
		return;
	}
	if (!bErasing && CountSelectedBindings() >= 3)
	{
		CancelKeySelection(True);
		return;
	}
	if (bErasing)
		UnbindSelectedItem();
	GetPlayerOwner().ConsoleCommand("SET Input" @ KeyName @ KeyGroups[Selection[0]].Keys[Selection[1]].AliasString);
	LoadExistingKeys();
	RefreshThirdBindings();
	CancelKeySelection(True);
}

function Notify(UWindowDialogControl C, byte E)
{
	if (E == DE_MClick && UMenuRaisedButton(C) != None)
	{
		C.ActivateWindow(0, False);
		if (ClearFocusedBinding())
			return;
	}
	Super.Notify(C, E);
	if (UMenuRaisedButton(C) != None && (E == DE_Click || E == DE_RClick))
		RefreshBindingButtonTexts();
	if (C == DefaultsButton && E == DE_Click)
	{
		RestoreDefaultControllerBindings();
		LoadExistingKeys();
		RefreshThirdBindings();
	}
}

function Close(optional bool bByParent)
{
	if (ModernRootWindow(Root) != None && ModernRootWindow(Root).ControllerBindings == Self)
		ModernRootWindow(Root).ControllerBindings = None;
	Super.Close(bByParent);
}

defaultproperties
{
	VRRecenterText="Recenter VR View"
	CustomizeHelp="Add up to three bindings, replace, or clear. Canceling leaves the current bindings unchanged."
}
