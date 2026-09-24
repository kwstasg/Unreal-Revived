// Runs with disposable INIs and exercises the real controller event path.
class ModernMenuBackTestGame extends SinglePlayer;

var PlayerPawn TestPlayer;

event PostLogin(PlayerPawn NewPlayer)
{
	Super.PostLogin(NewPlayer);
	TestPlayer = NewPlayer;
	WindowConsole(NewPlayer.Player.Console).LaunchUWindow();
	NewPlayer.SetPause(False);
	SetTimer(1, False);
}

function Check(bool Passed, string Description)
{
	if (!Passed) Log("MENUBACKTEST FAIL: " $ Description);
}

function Back(ModernConsole C)
{
	C.KeyEvent(IK_Joy2, IST_Press, 0);
	C.KeyEvent(IK_Joy2, IST_Release, 0);
}

event Timer()
{
	local ModernConsole C;
	local ModernRootWindow R;
	local ModernOptionsWindow Options;
	local ModernVideoClientWindow Video;
	local UWindowMessageBox Message;
	local UWindowComboBoxControl ArrayCombo;

	C = ModernConsole(TestPlayer.Player.Console);
	R = ModernRootWindow(C.Root);
	Options = ModernOptionsWindow(R.CreateWindow(class'ModernOptionsWindow',20,20,420,500));
	Video = ModernVideoClientWindow(ModernVideoScrollClient(UWindowPageControlPage(ModernOptionsClientWindow(Options.ClientArea).Pages.SelectedTab).Page).ClientArea);
	Check(Video.GuiSkinCombo.GetValue2() == R.LookAndFeelClass, "active skin survives saving Preferences");
	TestPlayer.SetPause(True);
	Video.ResolutionCombo.EditBox.ActivateWindow(0,False);
	R.KeyFocusWindow = R.CheckKeyFocusWindow();
	Video.ResolutionCombo.DropDown();
	Back(C);
	Check(!Video.ResolutionCombo.bListVisible && Options.bWindowVisible, "B closes only the dropdown");
	Check(C.bUWindowActive && Level.Pauser != "", "dropdown back keeps menu and pause");
	ArrayCombo = UWindowComboBoxControl(UWindowDialogClientWindow(Options.ClientArea).CreateControl(class'UWindowComboBoxControl',20,20,160,1));
	ArrayCombo.AddItem("First", "0");
	ArrayCombo.SetSelectedIndex(0);
	ArrayCombo.DropDown();
	R.KeyFocusWindow = ArrayCombo.ListWindow;
	Back(C);
	Check(!ArrayCombo.bListVisible && Options.bWindowVisible, "B closes an array-backed dropdown with list focus");
	ArrayCombo.Close();
	Message = Options.MessageBox("Back regression", "Cancel this dialog", MB_YesNo, MR_No);
	Back(C);
	Check(!Message.bWindowVisible && Options.bWindowVisible, "B closes only the modal dialog");
	R.ActiveWindow = None;
	R.bHandledWindowEvent = True;
	Back(C);
	Check(!Options.bWindowVisible, "B closes visible Preferences despite stale root focus");
	R.CheckUWindowActivation();
	Check(C.bUWindowActive && Level.Pauser != "", "closing Preferences leaves the menu paused");
	R.OpenControllerMenuBar();
	Back(C);
	Check(R.MenuBar.Selected == None && C.bUWindowActive, "B closes the menu dropdown before resuming");
	Back(C);
	Check(!C.bUWindowActive && Level.Pauser == "", "B at the root resumes the game");
	Log("MENUBACKTEST completed");
	TestPlayer.ConsoleCommand("quit");
}
