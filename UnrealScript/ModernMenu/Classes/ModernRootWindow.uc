class ModernRootWindow extends UMenuRootWindow;

var ModernBindingsClientWindow ControllerBindings;
var UMenuNewGameClientWindow FocusedNewGameClient;
var bool bSuppressFocusIndicator;

#exec TEXTURE IMPORT NAME=ModernBg11 FILE=Textures\ModernBg11.bmp GROUP="Icons" MIPS=OFF VClampMode=VClamp UClampMode=UClamp
#exec TEXTURE IMPORT NAME=ModernBg21 FILE=Textures\ModernBg21.bmp GROUP="Icons" MIPS=OFF VClampMode=VClamp UClampMode=UClamp
#exec TEXTURE IMPORT NAME=ModernBg31 FILE=Textures\ModernBg31.bmp GROUP="Icons" MIPS=OFF VClampMode=VClamp UClampMode=UClamp
#exec TEXTURE IMPORT NAME=ModernBg41 FILE=Textures\ModernBg41.bmp GROUP="Icons" MIPS=OFF VClampMode=VClamp UClampMode=UClamp
#exec TEXTURE IMPORT NAME=ModernBg12 FILE=Textures\ModernBg12.bmp GROUP="Icons" MIPS=OFF VClampMode=VClamp UClampMode=UClamp
#exec TEXTURE IMPORT NAME=ModernBg22 FILE=Textures\ModernBg22.bmp GROUP="Icons" MIPS=OFF VClampMode=VClamp UClampMode=UClamp
#exec TEXTURE IMPORT NAME=ModernBg32 FILE=Textures\ModernBg32.bmp GROUP="Icons" MIPS=OFF VClampMode=VClamp UClampMode=UClamp
#exec TEXTURE IMPORT NAME=ModernBg42 FILE=Textures\ModernBg42.bmp GROUP="Icons" MIPS=OFF VClampMode=VClamp UClampMode=UClamp
#exec TEXTURE IMPORT NAME=ModernBg13 FILE=Textures\ModernBg13.bmp GROUP="Icons" MIPS=OFF VClampMode=VClamp UClampMode=UClamp
#exec TEXTURE IMPORT NAME=ModernBg23 FILE=Textures\ModernBg23.bmp GROUP="Icons" MIPS=OFF VClampMode=VClamp UClampMode=UClamp
#exec TEXTURE IMPORT NAME=ModernBg33 FILE=Textures\ModernBg33.bmp GROUP="Icons" MIPS=OFF VClampMode=VClamp UClampMode=UClamp
#exec TEXTURE IMPORT NAME=ModernBg43 FILE=Textures\ModernBg43.bmp GROUP="Icons" MIPS=OFF VClampMode=VClamp UClampMode=UClamp

function Created()
{
	local class<GameInfo> GameClass;

	if (class'UMenuHelpMenu'.Default.SupportURLName == "-")
		class'UMenuHelpMenu'.Default.SupportURLName = "Technical Support";

	if (GetLevel().Game != None)
	{
		GameClass = GetLevel().Game.Class;
		GameClass.Default.GameUMenuType = "ModernMenu.ModernGameMenu";
		GameClass.Default.GameOptionsMenuType = "ModernMenu.ModernOptionsMenu";
	}

	Super.Created();

	if (class'ModernVideoClientWindow'.Default.bShowFPS)
		SetFPSStatistics(True);
}

function SetFPSStatistics(bool bEnabled)
{
	ModernConsole(Console).SetFPSStatisticsPreference(bEnabled);
}

function Tick(float Delta)
{
	local UMenuNewGameClientWindow NewGameClient;

	Super.Tick(Delta);
	NewGameClient = FindActiveNewGameClient(Self);
	if (NewGameClient == None)
	{
		FocusedNewGameClient = None;
		return;
	}
	if (NewGameClient != FocusedNewGameClient)
	{
		ConfigureNewGameTabOrder(NewGameClient);
		NewGameClient.OKButton.SetAcceptsFocus();
		NewGameClient.OKButton.ActivateWindow(0, False);
		FocusedNewGameClient = NewGameClient;
	}
}

function ControllerConfirm()
{
	local PlayerPawn Player;
	local UWindowComboControl Combo;
	local UWindowComboBoxControl ComboBox;
	local UWindowHSliderControl Slider;
	local UWindowListBox ListBox;
	local UWindowMessageBox MessageBox;
	local UWindowSmallButton MessageButton;

	Player = GetPlayerOwner();
	MessageBox = FindActiveMessageBox(Self);
	if (MessageBox != None)
	{
		MessageButton = GetFocusedMessageButton(UWindowMessageBoxCW(MessageBox.ClientArea));
		if (MessageButton == None)
			MessageButton = GetDefaultMessageButton(UWindowMessageBoxCW(MessageBox.ClientArea));
		if (MessageButton != None)
		{
			MessageButton.ActivateWindow(0, False);
			MessageButton.KeyDown(Player.EInputKey.IK_Space, 0, 0);
		}
		return;
	}
	if (MenuBar != None && MenuBar.Selected != None && MenuBar.Selected.Menu != None)
	{
		MenuBar.Selected.Menu.KeyDown(Player.EInputKey.IK_Enter, 0, 0);
		return;
	}
	ListBox = GetFocusedListBox();
	if (ListBox != None)
	{
		if (ListBox.SelectedItem == None)
			MoveControllerListSelection(ListBox, True);
		if (ListBox.SelectedItem != None)
			ListBox.DoubleClickItem(ListBox.SelectedItem);
		return;
	}
	Slider = GetFocusedSlider();
	if (Slider != None)
	{
		if (ModernVideoClientWindow(Slider.NotifyWindow) != None
			&& ModernVideoClientWindow(Slider.NotifyWindow).ResetControllerSlider(Slider))
			return;
		if (ModernHUDConfigCW(Slider.NotifyWindow) != None
			&& ModernHUDConfigCW(Slider.NotifyWindow).ResetControllerSlider(Slider))
			return;
		if (ModernInputOptionsClientWindow(Slider.NotifyWindow) != None
			&& ModernInputOptionsClientWindow(Slider.NotifyWindow).ResetControllerSlider(Slider))
			return;
	}
	Combo = GetFocusedCombo();
	ComboBox = UWindowComboBoxControl(Combo);
	if (ComboBox != None && !ComboBox.bDisabled)
	{
		if (ComboBox.bListVisible)
			ComboBox.ListWindow.ExecuteSelectedItem();
		else if (ComboBox.ItemsCount() > 0)
		{
			ComboBox.DropDown();
			ComboBox.ListWindow.SelectedItemIndex = ComboBox.ListWindow.ClampRelevantItemIndex(ComboBox.GetSelectedIndex());
			Root.CaptureMouse(ComboBox.ListWindow);
		}
		return;
	}
	if (Combo != None && !Combo.bDisabled)
	{
		if (Combo.bListVisible)
		{
			if (Combo.List.Selected == None)
				Combo.List.Selected = UWindowComboListItem(Combo.List.Items.Next);
			if (Combo.List.Selected != None)
				Combo.List.ExecuteItem(Combo.List.Selected);
		}
		else if (!Combo.bCanEdit && Combo.ItemsCount() > 0)
		{
			Combo.DropDown();
			Combo.List.Selected = UWindowComboListItem(Combo.List.Items.FindEntry(Combo.GetSelectedIndex()));
			if (Combo.List.Selected == None)
				Combo.List.Selected = UWindowComboListItem(Combo.List.Items.Next);
			Root.CaptureMouse(Combo.List);
		}
		return;
	}
	if (UWindowFramedWindow(ActiveWindow) == None)
	{
		OpenControllerMenuBar();
		return;
	}
	WindowEvent(WM_KeyDown, None, 0, 0, Player.EInputKey.IK_Space);
	WindowEvent(WM_KeyUp, None, 0, 0, Player.EInputKey.IK_Space);
}

function PrepareControllerMenuClose()
{
	if (ControllerBindings != None && ControllerBindings.bPolling)
		ControllerBindings.CancelKeySelection(True);
}

function ControllerBack()
{
	if (FindActiveMessageBox(Self) != None)
		CloseActiveWindow();
	else if (MenuBar != None && MenuBar.Selected != None)
		MenuBar.CloseUp();
	else
		CloseActiveWindow();
}

function OpenControllerMenuBar()
{
	if (MenuBar != None && MenuBar.Selected == None)
	{
		MenuBar.Selected = MenuBar.GameItem;
		MenuBar.Selected.Select();
		MenuBar.Select(MenuBar.Selected);
	}
}

function ControllerNavigate(int Direction)
{
	local PlayerPawn Player;
	local int Key;
	local UWindowComboControl Combo;
	local UWindowComboBoxControl ComboBox;
	local UWindowMessageBox MessageBox;
	local UWindowListBox ListBox;

	Player = GetPlayerOwner();
	MessageBox = FindActiveMessageBox(Self);
	if (MessageBox != None)
	{
		if (MenuBar != None && MenuBar.Selected != None)
			MenuBar.CloseUp();
		FocusAdjacentMessageButton(UWindowMessageBoxCW(MessageBox.ClientArea), Direction == 1 || Direction == 3);
		return;
	}
	Combo = GetFocusedCombo();
	ComboBox = UWindowComboBoxControl(Combo);
	if (ComboBox != None && ComboBox.bListVisible && (Direction == 0 || Direction == 1))
	{
		if (Direction == 1)
			ComboBox.ListWindow.KeyboardScrolling(1, False, 0, 0);
		else
			ComboBox.ListWindow.KeyboardScrolling(-1, False, 0, 0);
		return;
	}
	if (Combo != None && Combo.bListVisible && (Direction == 0 || Direction == 1))
	{
		MoveControllerComboSelection(Combo, Direction == 1);
		return;
	}
	ListBox = GetFocusedListBox();
	if (ListBox != None)
	{
		if (Direction == 0 || Direction == 1)
			MoveControllerListSelection(ListBox, Direction == 1);
		else
			FocusAdjacentControl(Direction == 3);
		return;
	}
	if ((MenuBar == None || MenuBar.Selected == None) && UWindowFramedWindow(ActiveWindow) == None)
	{
		OpenControllerMenuBar();
		return;
	}
	if ((Direction == 0 || Direction == 1) && (MenuBar == None || MenuBar.Selected == None))
	{
		FocusAdjacentControl(Direction == 1);
		return;
	}

	switch (Direction)
	{
	case 0:
		Key = Player.EInputKey.IK_Up;
		break;
	case 1:
		Key = Player.EInputKey.IK_Down;
		break;
	case 2:
		Key = Player.EInputKey.IK_Left;
		break;
	case 3:
		Key = Player.EInputKey.IK_Right;
		break;
	}
	if (MenuBar != None && MenuBar.Selected != None && MenuBar.Selected.Menu != None)
	{
		MenuBar.Selected.Menu.KeyDown(Key, 0, 0);
		return;
	}
	WindowEvent(WM_KeyDown, None, 0, 0, Key);
	WindowEvent(WM_KeyUp, None, 0, 0, Key);
}

function UWindowMessageBox FindActiveMessageBox(UWindowWindow Window)
{
	local UWindowWindow Child;
	local UWindowMessageBox MessageBox;

	MessageBox = UWindowMessageBox(Window);
	if (MessageBox != None && MessageBox.bWindowVisible)
		return MessageBox;
	for (Child = Window.LastChildWindow; Child != None; Child = Child.PrevSiblingWindow)
	{
		if (Child.bWindowVisible)
		{
			MessageBox = FindActiveMessageBox(Child);
			if (MessageBox != None)
				return MessageBox;
		}
	}
	return None;
}

function UWindowSmallButton GetFocusedMessageButton(UWindowMessageBoxCW Client)
{
	if (Client == None)
		return None;
	if (KeyFocusWindow == Client.YesButton)
		return Client.YesButton;
	if (KeyFocusWindow == Client.NoButton)
		return Client.NoButton;
	if (KeyFocusWindow == Client.OKButton)
		return Client.OKButton;
	if (KeyFocusWindow == Client.CancelButton)
		return Client.CancelButton;
	return None;
}

function UWindowSmallButton GetDefaultMessageButton(UWindowMessageBoxCW Client)
{
	if (Client == None)
		return None;
	if (Client.EnterResult == MR_Yes && Client.YesButton != None)
		return Client.YesButton;
	if (Client.EnterResult == MR_No && Client.NoButton != None)
		return Client.NoButton;
	if (Client.EnterResult == MR_OK && Client.OKButton != None)
		return Client.OKButton;
	if (Client.EnterResult == MR_Cancel && Client.CancelButton != None)
		return Client.CancelButton;
	if (Client.YesButton != None)
		return Client.YesButton;
	if (Client.OKButton != None)
		return Client.OKButton;
	if (Client.NoButton != None)
		return Client.NoButton;
	return Client.CancelButton;
}

function FocusAdjacentMessageButton(UWindowMessageBoxCW Client, bool bForward)
{
	local UWindowSmallButton Current;
	local UWindowSmallButton Candidate;
	local int Attempts;

	if (Client == None)
		return;
	Current = GetFocusedMessageButton(Client);
	if (Current == None)
		Current = GetDefaultMessageButton(Client);
	if (Current != None)
	{
		if (bForward)
			Candidate = UWindowSmallButton(Current.TabNext);
		else
			Candidate = UWindowSmallButton(Current.TabPrev);
		while (Candidate != None && !IsMessageButton(Client, Candidate) && Attempts < 8)
		{
			Attempts++;
			if (bForward)
				Candidate = UWindowSmallButton(Candidate.TabNext);
			else
				Candidate = UWindowSmallButton(Candidate.TabPrev);
		}
	}
	if (Candidate == None || !IsMessageButton(Client, Candidate))
		Candidate = GetDefaultMessageButton(Client);
	if (Candidate != None)
	{
		Candidate.SetAcceptsFocus();
		Candidate.ActivateWindow(0, False);
	}
}

function bool IsMessageButton(UWindowMessageBoxCW Client, UWindowSmallButton Button)
{
	return Button != None && Button.bWindowVisible && !Button.bDisabled
		&& (Button == Client.YesButton || Button == Client.NoButton
			|| Button == Client.OKButton || Button == Client.CancelButton);
}

function UWindowComboControl GetFocusedCombo()
{
	local UWindowWindow Window;
	local UWindowComboList List;

	List = UWindowComboList(KeyFocusWindow);
	if (List != None)
		return List.Owner;
	for (Window = KeyFocusWindow; Window != None && Window != Self; Window = Window.ParentWindow)
		if (UWindowComboControl(Window) != None)
			return UWindowComboControl(Window);
	return None;
}

function UWindowListBox GetFocusedListBox()
{
	local UWindowWindow Window;

	for (Window = KeyFocusWindow; Window != None && Window != Self; Window = Window.ParentWindow)
		if (UWindowListBox(Window) != None)
			return UWindowListBox(Window);
	return None;
}

function MoveControllerListSelection(UWindowListBox ListBox, bool bForward)
{
	local UWindowListBoxItem Candidate;
	local int Attempts;

	if (ListBox.SelectedItem == None)
	{
		if (bForward)
			Candidate = UWindowListBoxItem(ListBox.Items.Next);
		else
			Candidate = UWindowListBoxItem(ListBox.Items.Last);
	}
	else if (bForward)
		Candidate = UWindowListBoxItem(ListBox.SelectedItem.Next);
	else
		Candidate = UWindowListBoxItem(ListBox.SelectedItem.Prev);
	while (Candidate != None && Candidate != ListBox.Items && !Candidate.ShowThisItem() && Attempts < 256)
	{
		Attempts++;
		if (bForward)
			Candidate = UWindowListBoxItem(Candidate.Next);
		else
			Candidate = UWindowListBoxItem(Candidate.Prev);
	}
	if (Candidate == None || Candidate == ListBox.Items)
	{
		if (bForward)
			Candidate = UWindowListBoxItem(ListBox.Items.Next);
		else
			Candidate = UWindowListBoxItem(ListBox.Items.Last);
	}
	if (Candidate != None && Candidate != ListBox.Items)
	{
		ListBox.SetSelectedItem(Candidate);
		ListBox.MakeSelectedVisible();
	}
}

function UWindowHSliderControl GetFocusedSlider()
{
	local UWindowWindow Window;

	for (Window = KeyFocusWindow; Window != None && Window != Self; Window = Window.ParentWindow)
		if (UWindowHSliderControl(Window) != None)
			return UWindowHSliderControl(Window);
	return None;
}

	function bool HasFocusedControllerSlider()
	{
		return GetFocusedSlider() != None;
	}

function MoveControllerComboSelection(UWindowComboControl Combo, bool bForward)
{
	local UWindowComboListItem Item;
	local UWindowComboListItem Iterator;
	local int ItemIndex;

	Item = Combo.List.Selected;
	if (bForward)
	{
		if (Item == None || Item.Next == None)
			Item = UWindowComboListItem(Combo.List.Items.Next);
		else
			Item = UWindowComboListItem(Item.Next);
	}
	else
	{
		if (Item == None || Item.Prev == None || Item.Prev == Combo.List.Items)
			Item = UWindowComboListItem(Combo.List.Items.Last);
		else
			Item = UWindowComboListItem(Item.Prev);
	}
	Combo.List.Selected = Item;
	for (Iterator = UWindowComboListItem(Combo.List.Items.Next); Iterator != None && Iterator != Item; Iterator = UWindowComboListItem(Iterator.Next))
		ItemIndex++;
	Combo.List.VertSB.Show(ItemIndex);
}

function FocusAdjacentControl(bool bForward)
{
	local UWindowDialogControl Current;
	local UWindowDialogControl Candidate;
	local UWindowWindow Parent;
	local int Attempts;
	local UMenuNewGameClientWindow NewGameClient;
	local UMenuSlotClientWindow SlotClient;
	local UMenuBotmatchClientWindow BotmatchClient;
	local UMenuMutatorCW MutatorClient;

	NewGameClient = FindActiveNewGameClient(Self);
	if (NewGameClient != None)
		ConfigureNewGameTabOrder(NewGameClient);
	SlotClient = FindActiveSlotClient(Self);
	if (SlotClient != None)
		ConfigureSlotTabOrder(SlotClient);
	BotmatchClient = FindActiveBotmatchClient(Self);
	if (BotmatchClient != None)
		ConfigureBotmatchTabOrder(BotmatchClient);
	MutatorClient = FindActiveMutatorClient(Self);
	if (MutatorClient != None)
		ConfigureMutatorTabOrder(MutatorClient);

	for (Parent = KeyFocusWindow; Parent != None && Parent != Self; Parent = Parent.ParentWindow)
	{
		Current = UWindowDialogControl(Parent);
		if (Current != None && Current.TabNext != None)
			break;
	}
	if (Current == None || !IsControllerFocusable(Current))
	{
		Candidate = FindFirstControllerControl(Self);
	}
	else
	{
		if (bForward)
			Candidate = Current.TabNext;
		else
			Candidate = Current.TabPrev;
		while (Candidate != None && Candidate != Current && !IsControllerFocusable(Candidate) && Attempts < 256)
		{
			Attempts++;
			if (bForward)
				Candidate = Candidate.TabNext;
			else
				Candidate = Candidate.TabPrev;
		}
	}

	if (Candidate != None && IsControllerFocusable(Candidate))
	{
		if (UWindowSmallButton(Candidate) != None && !Candidate.bAcceptsFocus)
			Candidate.SetAcceptsFocus();
		Candidate.ActivateWindow(0, False);
		RevealControllerControl(Candidate);
	}
}

function bool IsControllerFocusable(UWindowDialogControl Control)
{
	local UWindowWindow Parent;

	if (Control == None || (!Control.bAcceptsFocus && UWindowSmallButton(Control) == None)
		|| IsControllerControlDisabled(Control))
		return False;
	for (Parent = Control; Parent != None && Parent != Self; Parent = Parent.ParentWindow)
		if (!Parent.bWindowVisible)
			return False;
	return Parent == Self;
}

function bool IsControllerControlDisabled(UWindowDialogControl Control)
{
	if (UWindowButton(Control) != None)
		return UWindowButton(Control).bDisabled;
	if (UWindowComboControl(Control) != None)
		return UWindowComboControl(Control).bDisabled;
	if (UWindowEditControl(Control) != None)
		return UWindowEditControl(Control).bDisabled;
	if (UWindowHSliderControl(Control) != None)
		return UWindowHSliderControl(Control).bDisabled;
	return False;
}

function UMenuNewGameClientWindow FindActiveNewGameClient(UWindowWindow Window)
{
	local UWindowWindow Child;
	local UMenuNewGameClientWindow NewGameClient;

	NewGameClient = UMenuNewGameClientWindow(Window);
	if (NewGameClient != None && NewGameClient.bWindowVisible)
		return NewGameClient;
	for (Child = Window.LastChildWindow; Child != None; Child = Child.PrevSiblingWindow)
	{
		if (Child.bWindowVisible)
		{
			NewGameClient = FindActiveNewGameClient(Child);
			if (NewGameClient != None)
				return NewGameClient;
		}
	}
	return None;
}

function ConfigureNewGameTabOrder(UMenuNewGameClientWindow Client)
{
	Client.GameCombo.TabNext = Client.SkillCombo;
	Client.SkillCombo.TabPrev = Client.GameCombo;
	Client.SkillCombo.TabNext = Client.UseClassicCheck;
	Client.UseClassicCheck.TabPrev = Client.SkillCombo;
	Client.UseClassicCheck.TabNext = Client.UseMutatorsCheck;
	Client.UseMutatorsCheck.TabPrev = Client.UseClassicCheck;
	Client.UseMutatorsCheck.TabNext = Client.MutatorButton;
	Client.MutatorButton.TabPrev = Client.UseMutatorsCheck;
	Client.MutatorButton.TabNext = Client.MirrorModeCheck;
	Client.MirrorModeCheck.TabPrev = Client.MutatorButton;
	Client.MirrorModeCheck.TabNext = Client.OKButton;
	Client.OKButton.TabPrev = Client.MirrorModeCheck;
	Client.OKButton.TabNext = Client.AdvancedButton;
	Client.AdvancedButton.TabPrev = Client.OKButton;
	Client.AdvancedButton.TabNext = Client.GameCombo;
	Client.GameCombo.TabPrev = Client.AdvancedButton;
	Client.TabLast = Client.AdvancedButton;
}

function UMenuSlotClientWindow FindActiveSlotClient(UWindowWindow Window)
{
	local UWindowWindow Child;
	local UMenuSlotClientWindow SlotClient;

	SlotClient = UMenuSlotClientWindow(Window);
	if (SlotClient != None && SlotClient.bWindowVisible)
		return SlotClient;
	for (Child = Window.LastChildWindow; Child != None; Child = Child.PrevSiblingWindow)
		if (Child.bWindowVisible)
		{
			SlotClient = FindActiveSlotClient(Child);
			if (SlotClient != None)
				return SlotClient;
		}
	return None;
}

function ConfigureSlotTabOrder(UMenuSlotClientWindow Client)
{
	local UWindowDialogControl First;
	local UWindowDialogControl Previous;
	local UMenuRaisedButton RestartButton;
	local int Index;

	for (Index = 0; Index < Client.Slots.Size(); Index++)
		if (Client.Slots[Index] != None && Client.Slots[Index].bWindowVisible)
		{
			if (First == None)
				First = Client.Slots[Index];
			if (Previous != None)
			{
				Previous.TabNext = Client.Slots[Index];
				Client.Slots[Index].TabPrev = Previous;
			}
			Previous = Client.Slots[Index];
		}
	if (UMenuLoadGameClientWindow(Client) != None)
		RestartButton = UMenuLoadGameClientWindow(Client).RestartButton;
	if (RestartButton != None && RestartButton.bWindowVisible)
	{
		if (First == None)
			First = RestartButton;
		if (Previous != None)
		{
			Previous.TabNext = RestartButton;
			RestartButton.TabPrev = Previous;
		}
		Previous = RestartButton;
	}
	if (First != None && Previous != None)
	{
		Previous.TabNext = First;
		First.TabPrev = Previous;
		Client.TabLast = Previous;
		Client.ScrollPage.TabLast = Previous;
	}
}

function UMenuBotmatchClientWindow FindActiveBotmatchClient(UWindowWindow Window)
{
	local UWindowWindow Child;
	local UMenuBotmatchClientWindow BotmatchClient;

	BotmatchClient = UMenuBotmatchClientWindow(Window);
	if (BotmatchClient != None && BotmatchClient.bWindowVisible)
		return BotmatchClient;
	for (Child = Window.LastChildWindow; Child != None; Child = Child.PrevSiblingWindow)
		if (Child.bWindowVisible)
		{
			BotmatchClient = FindActiveBotmatchClient(Child);
			if (BotmatchClient != None)
				return BotmatchClient;
		}
	return None;
}

function UWindowDialogClientWindow FindVisibleDialogWithControls(UWindowWindow Window)
{
	local UWindowWindow Child;
	local UWindowDialogClientWindow Dialog;

	for (Child = Window.LastChildWindow; Child != None; Child = Child.PrevSiblingWindow)
		if (Child.bWindowVisible)
		{
			Dialog = FindVisibleDialogWithControls(Child);
			if (Dialog != None)
				return Dialog;
		}
	Dialog = UWindowDialogClientWindow(Window);
	if (Dialog != None && Dialog.TabLast != None)
		return Dialog;
	return None;
}

function ConfigureBotmatchTabOrder(UMenuBotmatchClientWindow Client)
{
	local UWindowDialogClientWindow PageDialog;
	local UWindowDialogControl First;

	if (Client.Pages == None || Client.Pages.SelectedTab == None)
		return;
	PageDialog = FindVisibleDialogWithControls(UWindowPageControlPage(Client.Pages.SelectedTab).Page);
	if (PageDialog == None || PageDialog.TabLast == None)
		return;
	First = PageDialog.TabLast.TabNext;
	PageDialog.TabLast.TabNext = Client.StartButton;
	Client.StartButton.TabPrev = PageDialog.TabLast;
	Client.StartButton.TabNext = Client.CloseButton;
	Client.CloseButton.TabPrev = Client.StartButton;
	Client.CloseButton.TabNext = First;
	First.TabPrev = Client.CloseButton;
	Client.TabLast = Client.CloseButton;
}

function UMenuMutatorCW FindActiveMutatorClient(UWindowWindow Window)
{
	local UWindowWindow Child;
	local UMenuMutatorCW MutatorClient;

	MutatorClient = UMenuMutatorCW(Window);
	if (MutatorClient != None && MutatorClient.bWindowVisible)
		return MutatorClient;
	for (Child = Window.LastChildWindow; Child != None; Child = Child.PrevSiblingWindow)
		if (Child.bWindowVisible)
		{
			MutatorClient = FindActiveMutatorClient(Child);
			if (MutatorClient != None)
				return MutatorClient;
		}
	return None;
}

function ConfigureMutatorTabOrder(UMenuMutatorCW Client)
{
	local UMenuMutatorWindow MutatorWindow;

	MutatorWindow = UMenuMutatorWindow(Client.GetParent(class'UMenuMutatorWindow'));
	if (MutatorWindow == None)
		return;
	Client.KeepCheck.TabNext = Client.Exclude;
	Client.Exclude.TabPrev = Client.KeepCheck;
	Client.Exclude.TabNext = Client.Include;
	Client.Include.TabPrev = Client.Exclude;
	Client.Include.TabNext = MutatorWindow.CloseButton;
	MutatorWindow.CloseButton.TabPrev = Client.Include;
	MutatorWindow.CloseButton.TabNext = Client.KeepCheck;
	Client.KeepCheck.TabPrev = MutatorWindow.CloseButton;
	Client.TabLast = MutatorWindow.CloseButton;
}

function UWindowDialogControl FindFirstControllerControl(UWindowWindow Window)
{
	local UWindowDialogClientWindow Dialog;
	local UWindowDialogControl Candidate;
	local UWindowWindow Child;
	local int Attempts;

	for (Child = Window.LastChildWindow; Child != None; Child = Child.PrevSiblingWindow)
	{
		if (Child.bWindowVisible)
		{
			Candidate = FindFirstControllerControl(Child);
			if (Candidate != None)
				return Candidate;
		}
	}
	Dialog = UWindowDialogClientWindow(Window);
	if (Dialog != None && Dialog.TabLast != None)
	{
		Candidate = Dialog.TabLast.TabNext;
		while (Candidate != None && Candidate != Dialog.TabLast && !IsControllerFocusable(Candidate) && Attempts < 256)
		{
			Attempts++;
			Candidate = Candidate.TabNext;
		}
		if (IsControllerFocusable(Candidate))
			return Candidate;
	}
	return None;
}

function RevealControllerControl(UWindowDialogControl Control)
{
	local UWindowScrollingDialogClient Scrolling;
	local UWindowWindow Parent;
	local float ControlTop;

	ControlTop = Control.WinTop;
	for (Parent = Control.ParentWindow; Parent != None && Parent != Self; Parent = Parent.ParentWindow)
	{
		Scrolling = UWindowScrollingDialogClient(Parent);
		if (Scrolling != None)
		{
			Scrolling.VertSB.Show(ControlTop);
			Scrolling.VertSB.Show(ControlTop + Control.WinHeight);
			return;
		}
		Scrolling = UWindowScrollingDialogClient(Parent.ParentWindow);
		if (Scrolling != None && Scrolling.ClientArea == Parent)
		{
			Scrolling.VertSB.Show(ControlTop);
			Scrolling.VertSB.Show(ControlTop + Control.WinHeight);
			return;
		}
		ControlTop += Parent.WinTop;
	}
}

function SwitchOptionsTab(bool bNext)
{
	local ModernOptionsClientWindow Options;
	local UMenuBotmatchClientWindow BotmatchClient;
	local UWindowPageControl Pages;
	local UWindowPageControlPage NewPage;
	local UWindowDialogControl FirstControl;

	Options = FindVisibleOptionsClient(Self);
	if (Options != None)
		Pages = Options.Pages;
	else
	{
		BotmatchClient = FindActiveBotmatchClient(Self);
		if (BotmatchClient != None)
			Pages = BotmatchClient.Pages;
	}
	if (Pages == None || Pages.SelectedTab == None)
		return;

	if (bNext)
	{
		NewPage = UWindowPageControlPage(Pages.SelectedTab.Next);
		if (NewPage == None)
			NewPage = Pages.FirstPage();
	}
	else
	{
		NewPage = UWindowPageControlPage(Pages.SelectedTab.Prev);
		if (NewPage == None)
			NewPage = UWindowPageControlPage(Pages.Items.Last);
	}
	Pages.GotoTab(NewPage, True);
	if (BotmatchClient != None)
	{
		ConfigureBotmatchTabOrder(BotmatchClient);
		FirstControl = FindFirstControllerControl(NewPage.Page);
		if (FirstControl != None)
		{
			if (UWindowSmallButton(FirstControl) != None && !FirstControl.bAcceptsFocus)
				FirstControl.SetAcceptsFocus();
			FirstControl.ActivateWindow(0, False);
			RevealControllerControl(FirstControl);
		}
	}
}

function bool ScrollVisibleOptions(int Direction)
{
	local ModernOptionsClientWindow Options;
	local UWindowPageControlPage SelectedPage;
	local UWindowScrollingDialogClient Scrolling;

	Options = FindVisibleOptionsClient(Self);
	if (Options == None || Options.Pages == None || Options.Pages.SelectedTab == None)
		return False;
	SelectedPage = UWindowPageControlPage(Options.Pages.SelectedTab);
	if (SelectedPage == None)
		return False;
	Scrolling = UWindowScrollingDialogClient(SelectedPage.Page);
	if (Scrolling == None || Scrolling.VertSB == None || !Scrolling.bShowVertSB)
		return False;
	Scrolling.VertSB.Scroll(Direction * Scrolling.MouseWheelScrollingSpeed);
	bSuppressFocusIndicator = True;
	return True;
}

function ModernOptionsClientWindow FindVisibleOptionsClient(UWindowWindow Window)
{
	local UWindowWindow Child;
	local ModernOptionsClientWindow Options;

	Options = ModernOptionsClientWindow(Window);
	if (Options != None)
		return Options;
	for (Child = Window.LastChildWindow; Child != None; Child = Child.PrevSiblingWindow)
	{
		if (Child.bWindowVisible)
		{
			Options = FindVisibleOptionsClient(Child);
			if (Options != None)
				return Options;
		}
	}
	return None;
}

function WindowEvent(WinMessage Msg, Canvas C, float X, float Y, int Key)
{
	if (Msg == WM_Paint)
	{
		if (GetPlayerOwner().MyHUD == None)
			Console.bNoDrawWorld = False;
		else
			Console.bNoDrawWorld = !class'ModernHUDConfigCW'.Default.bShowGameBehindMenus;
		PaintModernBackground(C);
		if (ModernConsole(Console) != None && ModernConsole(Console).bShowFPSStatistics)
			ModernConsole(Console).DrawFPSStatistics(C);
		PaintClients(C, X, Y);
		DrawFocusIndicator(C);
	}
	else
		Super.WindowEvent(Msg, C, X, Y, Key);
}

function DrawFocusIndicator(Canvas C)
{
	local UWindowWindow FocusedControl;
	local UWindowWindow Parent;
	local UWindowMessageBox MessageBox;
	local UWindowMessageBoxCW MessageClient;
	local UWindowHSliderControl Slider;
	local UWindowCheckbox Checkbox;
	local UWindowComboControl Combo;
	local UWindowEditControl EditControl;
	local float FocusLeft;
	local float FocusTop;
	local float FocusWidth;
	local float FocusHeight;
	local float ParentLeft;
	local float ParentTop;
	local float VisibleLeft;
	local float VisibleTop;
	local float VisibleRight;
	local float VisibleBottom;

	if (bSuppressFocusIndicator)
		return;
	MessageBox = FindActiveMessageBox(Self);
	if (MessageBox != None)
	{
		MessageClient = UWindowMessageBoxCW(MessageBox.ClientArea);
		FocusedControl = GetFocusedMessageButton(MessageClient);
		if (FocusedControl == None)
			FocusedControl = GetDefaultMessageButton(MessageClient);
	}
	else
		FocusedControl = Root.KeyFocusWindow;
	if (FocusedControl == None)
		return;
	for (Parent = FocusedControl; Parent != None && Parent != Self; Parent = Parent.ParentWindow)
		if (UWindowPulldownMenu(Parent) != None || UWindowComboList(Parent) != None)
			return;

	while (FocusedControl.ParentWindow != None && UWindowDialogControl(FocusedControl.ParentWindow) != None)
		FocusedControl = FocusedControl.ParentWindow;
	if (UWindowDialogControl(FocusedControl) == None || !FocusedControl.bWindowVisible)
		return;

	FocusLeft = FocusedControl.WinLeft;
	FocusTop = FocusedControl.WinTop;
	FocusWidth = FocusedControl.WinWidth;
	FocusHeight = FocusedControl.WinHeight;
	Slider = UWindowHSliderControl(FocusedControl);
	Checkbox = UWindowCheckbox(FocusedControl);
	Combo = UWindowComboControl(FocusedControl);
	EditControl = UWindowEditControl(FocusedControl);
	if (Slider != None)
	{
		FocusLeft += Slider.SliderDrawX;
		FocusTop += Slider.SliderDrawY - 4;
		FocusWidth = Slider.SliderWidth;
		FocusHeight = 10;
	}
	else if (Checkbox != None)
	{
		FocusLeft += Checkbox.ImageX;
		FocusTop += Checkbox.ImageY;
		FocusWidth = 16;
		FocusHeight = 16;
	}
	else if (Combo != None)
	{
		if (Combo.bListVisible)
			return;
		FocusLeft += Combo.EditAreaDrawX;
		FocusWidth = Combo.EditBoxWidth;
	}
	else if (EditControl != None)
	{
		FocusLeft += EditControl.EditAreaDrawX;
		FocusWidth = EditControl.EditBoxWidth;
	}
	for (Parent = FocusedControl.ParentWindow; Parent != None && Parent != Self; Parent = Parent.ParentWindow)
	{
		if (!Parent.bWindowVisible)
			return;
		FocusLeft += Parent.WinLeft;
		FocusTop += Parent.WinTop;
	}
	if (Parent != Self || FocusWidth <= 0 || FocusHeight <= 0)
		return;

	VisibleLeft = 0;
	VisibleTop = 0;
	VisibleRight = WinWidth;
	VisibleBottom = WinHeight;
	for (Parent = FocusedControl.ParentWindow; Parent != None && Parent != Self; Parent = Parent.ParentWindow)
	{
		Parent.WindowToGlobal(0, 0, ParentLeft, ParentTop);
		VisibleLeft = FMax(VisibleLeft, ParentLeft);
		VisibleTop = FMax(VisibleTop, ParentTop);
		VisibleRight = FMin(VisibleRight, ParentLeft + Parent.WinWidth);
		VisibleBottom = FMin(VisibleBottom, ParentTop + Parent.WinHeight);
	}
	FocusWidth = FMin(FocusLeft + FocusWidth, VisibleRight) - FMax(FocusLeft, VisibleLeft);
	FocusHeight = FMin(FocusTop + FocusHeight, VisibleBottom) - FMax(FocusTop, VisibleTop);
	FocusLeft = FMax(FocusLeft, VisibleLeft);
	FocusTop = FMax(FocusTop, VisibleTop);
	if (FocusWidth <= 0 || FocusHeight <= 0)
		return;

	C.Style = GetPlayerOwner().ERenderStyle.STY_Normal;
	C.DrawColor.R = 255;
	C.DrawColor.G = 196;
	C.DrawColor.B = 64;
	DrawStretchedTexture(C, FocusLeft - 2, FocusTop - 2, FocusWidth + 4, 2, Texture'WhiteTexture');
	DrawStretchedTexture(C, FocusLeft - 2, FocusTop + FocusHeight, FocusWidth + 4, 2, Texture'WhiteTexture');
	DrawStretchedTexture(C, FocusLeft - 2, FocusTop, 2, FocusHeight, Texture'WhiteTexture');
	DrawStretchedTexture(C, FocusLeft + FocusWidth, FocusTop, 2, FocusHeight, Texture'WhiteTexture');
}

function PaintModernBackground(Canvas C)
{
	local float XOffset, YOffset, W, H;

	if (Console.bNoDrawWorld)
	{
		DrawStretchedTexture(C, 0, 0, WinWidth, WinHeight, Texture'UMenu.Icons.MenuBlack');

		if (Console.bBlackOut)
			return;

		H = ((WinWidth + 3) * 3) / 16;

		if ((WinHeight + 2) / 3 > H)
			H = (WinHeight + 2) / 3;

		W = (H * 4) / 3;

		XOffset = (WinWidth - ((4 * W) - 3)) / 2;
		YOffset = (WinHeight - ((3 * H) - 2)) / 2;

		C.bNoSmooth = False;

		DrawStretchedTexture(C, XOffset + (3 * (W - 1)), YOffset + (2 * (H - 1)), W, H, Texture'ModernBg43');
		DrawStretchedTexture(C, XOffset + (2 * (W - 1)), YOffset + (2 * (H - 1)), W, H, Texture'ModernBg33');
		DrawStretchedTexture(C, XOffset + (W - 1), YOffset + (2 * (H - 1)), W, H, Texture'ModernBg23');
		DrawStretchedTexture(C, XOffset, YOffset + (2 * (H - 1)), W, H, Texture'ModernBg13');

		DrawStretchedTexture(C, XOffset + (3 * (W - 1)), YOffset + (H - 1), W, H, Texture'ModernBg42');
		DrawStretchedTexture(C, XOffset + (2 * (W - 1)), YOffset + (H - 1), W, H, Texture'ModernBg32');
		DrawStretchedTexture(C, XOffset + (W - 1), YOffset + (H - 1), W, H, Texture'ModernBg22');
		DrawStretchedTexture(C, XOffset, YOffset + (H - 1), W, H, Texture'ModernBg12');

		DrawStretchedTexture(C, XOffset + (3 * (W - 1)), YOffset, W, H, Texture'ModernBg41');
		DrawStretchedTexture(C, XOffset + (2 * (W - 1)), YOffset, W, H, Texture'ModernBg31');
		DrawStretchedTexture(C, XOffset + (W - 1), YOffset, W, H, Texture'ModernBg21');
		DrawStretchedTexture(C, XOffset, YOffset, W, H, Texture'ModernBg11');

		C.bNoSmooth = True;
	}
}
