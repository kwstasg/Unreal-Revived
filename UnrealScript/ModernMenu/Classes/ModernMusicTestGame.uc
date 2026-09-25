// Run with disposable INIs; verifies navigation through the actual stock menu.
class ModernMusicTestGame extends SinglePlayer;

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
	if (!Passed)
		Log("MUSICTEST FAIL: " $ Description);
}

event Timer()
{
	local ModernConsole C;
	local ModernRootWindow R;
	local MMMainClientWindow Client;
	local MMControlsClient Controls;
	local UWindowWindow Expected[13];
	local int I;

	C = ModernConsole(TestPlayer.Player.Console);
	C.ShowUMusicMenu();
	R = ModernRootWindow(C.Root);
	Client = MMMainClientWindow(C.MusicMenu.ClientArea);
	Controls = Client.ClientControls;
	Expected[0] = Controls.PlayButton;
	Expected[1] = Controls.StopButton;
	Expected[2] = Controls.PriorButton;
	Expected[3] = Controls.NextButton;
	Expected[4] = Controls.MusicVolumeSlider;
	Expected[5] = Controls.SectionEdit;
	Expected[6] = Controls.TimeLimitEdit;
	Expected[7] = Controls.MusicShuffleCBox;
	Expected[8] = Controls.BrowseButton;
	Expected[9] = Controls.AddAllButton;
	Expected[10] = Controls.AddMusicButton;
	Expected[11] = Controls.AddMusicEdit;
	Expected[12] = Client.Grid;
	R.FocusAdjacentControl(True);
	Controls.PlayButton.ActivateWindow(0, False);
	for (I = 1; I <= 13; I++)
	{
		R.KeyFocusWindow = R.CheckKeyFocusWindow();
		C.KeyEvent(IK_Tab, IST_Press, 0);
		R.KeyFocusWindow = R.CheckKeyFocusWindow();
		Check(R.KeyFocusWindow == Expected[I % 13]
			|| R.KeyFocusWindow.ParentWindow == Expected[I % 13], "Tab control " $ I);
	}
	for (I = 12; I >= 0; I--)
	{
		R.FocusAdjacentControl(False);
		R.KeyFocusWindow = R.CheckKeyFocusWindow();
		Check(R.KeyFocusWindow == Expected[I]
			|| R.KeyFocusWindow.ParentWindow == Expected[I], "gamepad reverse control " $ I);
	}
	Controls.StopButton.bDisabled = True;
	R.ControllerNavigate(1);
	R.KeyFocusWindow = R.CheckKeyFocusWindow();
	Check(R.KeyFocusWindow == Controls.PriorButton, "skip disabled button");
	Controls.StopButton.bDisabled = False;
	Controls.BrowseButton.ActivateWindow(0, False);
	R.KeyFocusWindow = R.CheckKeyFocusWindow();
	R.ControllerConfirm();
	Check(Client.bMusicFBrowsOpen, "gamepad activates Browse");
	R.FocusMusicWindow(Client.Grid);
	R.KeyFocusWindow = R.CheckKeyFocusWindow();
	R.ControllerNavigate(3);
	R.KeyFocusWindow = R.CheckKeyFocusWindow();
	Check(R.GetFocusedMusicGrid() == Client.FGrid, "gamepad enters browser");
	R.ControllerNavigate(1);
	Check(Client.FGrid.SelectedRow == Min(1, Client.FGrid.ListCount - 1), "browser row selection");
	R.ControllerNavigate(2);
	R.KeyFocusWindow = R.CheckKeyFocusWindow();
	Check(R.GetFocusedMusicGrid() == Client.Grid, "gamepad returns to playlist");
	Controls.BrowseButton.ActivateWindow(0, False);
	R.KeyFocusWindow = R.CheckKeyFocusWindow();
	R.ControllerConfirm();
	Check(!Client.bMusicFBrowsOpen, "gamepad closes Browse");
	Client.Grid.LoadedMusicList.SetSize(2);
	Client.Grid.ListCount = 2;
	Client.Grid.LoadedMusicList[0].SongPackage = "Dusk";
	Client.Grid.LoadedMusicList[0].SongName = "Dusk";
	Client.Grid.LoadedMusicList[1] = Client.Grid.LoadedMusicList[0];
	Client.Grid.SelectedRow = -1;
	R.FocusMusicWindow(Client.Grid);
	R.KeyFocusWindow = R.CheckKeyFocusWindow();
	C.KeyEvent(IK_Down, IST_Press, 0);
	Check(Client.Grid.SelectedRow == 1, "keyboard selects second track");
	R.ControllerConfirm();
	Check(Client.Grid.CurrentTrackIndex == 1 && Controls.LastPlayedSong != None,
		"gamepad plays selected track");
	R.ControllerNavigate(0);
	C.KeyEvent(IK_Enter, IST_Press, 0);
	Check(Client.Grid.CurrentTrackIndex == 0, "Enter plays selected track");
	Controls.StopMusic();
	Client.Grid.ListCount = 0;
	R.ControllerNavigate(1);
	R.ControllerConfirm();
	Check(Controls.LastPlayedSong == None, "empty playlist confirm is harmless");
	Log("MUSICTEST completed");
	TestPlayer.ConsoleCommand("quit");
}
