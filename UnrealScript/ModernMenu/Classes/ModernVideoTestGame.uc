// Run with disposable engine/user INIs: exercises the real video preferences.
class ModernVideoTestGame extends SinglePlayer;

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
		Log("VIDEOTEST FAIL: " $ Description);
}

event Timer()
{
	local ModernOptionsWindow Options;
	local ModernVideoClientWindow Video;
	local WindowConsole C;
	local int I;
	local float Started, Saved;
	local string OriginalResolution;
	local ModernVRConfigCW VRSettings;
	C = WindowConsole(TestPlayer.Player.Console);
	Options = ModernOptionsWindow(C.Root.CreateWindow(class'ModernOptionsWindow', 20, 20, 420, 500));
	Video = ModernVideoClientWindow(ModernVideoScrollClient(UWindowPageControlPage(ModernOptionsClientWindow(Options.ClientArea).Pages.SelectedTab).Page).ClientArea);
	Check(Video.BrightnessSlider.Value == 120, "initial default is 120 percent");
	OriginalResolution = TestPlayer.ConsoleCommand("GetCurrentRes");
	Check(Video.ResolutionCombo.GetValue2() == OriginalResolution, "resolution label preserves raw selected value");
	Check(class'ModernVideoClientWindow'.static.ResolutionLabel("1920x1536") ==
		"1920 " $ Chr(215) $ " 1536 (5:4)", "5:4 resolution label");
	Check(class'ModernVideoClientWindow'.static.ResolutionLabel("3840x2160") ==
		"3840 " $ Chr(215) $ " 2160 (16:9)", "4K resolution label");
	Check(class'ModernVideoClientWindow'.static.ResolutionLabel("1024x768") ==
		"1024 " $ Chr(215) $ " 768 (4:3)", "4:3 resolution label");
	Video.LoadAvailableSettings();
	Check(TestPlayer.ConsoleCommand("GetCurrentRes") == OriginalResolution, "loading labels does not change resolution");
	Check(class'ModernVideoClientWindow'.static.ResolutionLabel("1366x768") ==
		"1366 " $ Chr(215) $ " 768 (16:9)", "rounded standard ratio uses familiar label");
	Check(class'ModernVideoClientWindow'.static.ResolutionLabel("1920x1200") ==
		"1920 " $ Chr(215) $ " 1200 (16:10)", "16:10 label");
	Check(class'ModernVideoClientWindow'.static.ResolutionLabel("3440x1440") ==
		"3440 " $ Chr(215) $ " 1440 (2.39:1)", "custom ultrawide ratio is readable and accurate");
	Check(Video.ConfirmSettings == None, "loading labels does not request a mode change");
	Video.BrightnessSlider.SetValue(137);
	Video.LoadAvailableSettings();
	Check(Video.BrightnessSlider.Value == 137, "refresh preserves 137 percent");
	Saved = float(TestPlayer.ConsoleCommand("get ini:Engine.Engine.ViewportManager Brightness"));
	Check(Abs(Saved - 0.685) < 0.0001, "refresh does not change saved brightness");
	Video.ResetControllerSlider(Video.BrightnessSlider);
	Check(Video.BrightnessSlider.Value == 120, "reset restores 120 percent");
	Video.LoadAvailableSettings();
	Check(Video.BrightnessSlider.Value == 120, "refresh preserves default");
	Video.BrightnessSlider.ActivateWindow(0, False);
	C.Root.KeyFocusWindow = C.Root.CheckKeyFocusWindow();
	C.Root.WindowEvent(WM_KeyDown, None, 0, 0, TestPlayer.EInputKey.IK_Right);
	Check(Video.BrightnessSlider.Value == 125, "right arrow advances five percent");
	ModernRootWindow(C.Root).ControllerNavigate(2);
	Check(Video.BrightnessSlider.Value == 120, "controller left returns five percent");
	Video.ContrastSlider.ActivateWindow(0, False);
	Video.ContrastSlider.SetValue(100);
	C.Root.WindowEvent(WM_KeyDown, None, 0, 0, TestPlayer.EInputKey.IK_Right);
	Check(Video.ContrastSlider.Value == 101, "other slider increments unchanged");
	Check(Video.BrightnessSlider.Value == 120, "unfocused brightness unchanged");
	Video.BrightnessSlider.SetValue(50);
	Video.LoadAvailableSettings();
	Check(Video.BrightnessSlider.Value == 50, "minimum survives refresh");
	Video.BrightnessSlider.SetValue(200);
	Video.LoadAvailableSettings();
	Check(Video.BrightnessSlider.Value == 200, "maximum survives refresh");
	Video.BrightnessSlider.SetValue(137);
	Video.HideWindow();
	Video.ShowWindow();
	Check(Video.BrightnessSlider.Value == 137, "reopening preserves custom brightness");
	Started = AppSeconds();
	for (I = 0; I < 20; I++) Video.BrightnessSlider.SetValue(120 + (I % 2));
	Log("VIDEOTEST brightness 20 updates ms=" $ ((AppSeconds() - Started) * 1000));
	Started = AppSeconds();
	for (I = 0; I < 20; I++) Video.ContrastSlider.SetValue(100 + (I % 2));
	Log("VIDEOTEST contrast 20 updates ms=" $ ((AppSeconds() - Started) * 1000));
	Video.BrightnessSlider.SetValue(120);
	Video.ContrastSlider.SetValue(100);
	VRSettings = ModernVRConfigCW(C.Root.CreateWindow(class'ModernVRConfigCW', 20, 20, 400, 320));
	Check(VRSettings.RenderQualityCombo.GetValue2() == "2", "VR defaults to Balanced");
	Check(VRSettings.TurnModeCombo.GetSelectedIndex() == 0, "VR defaults to smooth turning");
	Check(VRSettings.SnapAngleSlider.Value == 30, "snap angle defaults to 30 degrees");
	for (I = 1; I <= 2; I++)
	{
		VRSettings.TurnModeCombo.SetSelectedIndex(I);
		VRSettings.SnapAngleSlider.SetValue(60);
		VRSettings.LoadSettings();
		Check(VRSettings.TurnModeCombo.GetSelectedIndex() == I && VRSettings.SnapAngleSlider.Value == 60,
			"turn mode and snap angle persist through reload");
		Saved = TestPlayer.ViewRotation.Yaw;
		TestPlayer.ConsoleCommand("D3D12 VRTURNINPUT AXIS=0 DT=0.016 ENABLED=1");
		TestPlayer.ConsoleCommand("D3D12 VRTURNINPUT AXIS=1 DT=0.016 ENABLED=1");
		Check(TestPlayer.ViewRotation.Yaw == Saved, "snap command leaves desktop yaw unchanged");
	}
	VRSettings.ResetControllerSlider(VRSettings.SnapAngleSlider);
	Check(VRSettings.SnapAngleSlider.Value == 30, "snap angle controller reset returns to 30");
	VRSettings.TurnModeCombo.SetSelectedIndex(0);
	VRSettings.RenderQualityCombo.SetSelectedIndex(3);
	VRSettings.LoadSettings();
	Check(VRSettings.RenderQualityCombo.GetValue2() == "4", "VR quality preference persists");
	Check(TestPlayer.ConsoleCommand("D3D12 VRSTATSACTIVE") == "0", "desktop uses desktop FPS counters");
	Check(TestPlayer.ConsoleCommand("GetCurrentRes") == OriginalResolution, "VR preset leaves desktop resolution unchanged");
	VRSettings.RenderQualityCombo.SetSelectedIndex(0);
	VRSettings.Close();
	Video.DisplayModeCombo.SetSelectedIndex(Video.DisplayModeCombo.FindItemIndex2("Windowed"));
	Video.LoadAvailableSettings();
	Check(Video.ResolutionCombo.FindItemIndex2("1024x768") >= 0, "windowed 1024x768 available");
	Check(Video.ResolutionCombo.FindItemIndex2("1280x720") >= 0, "windowed 1280x720 available");
	Check(Video.ResolutionCombo.FindItemIndex2("1280x1024") >= 0, "windowed 1280x1024 available");
	Check(Video.ResolutionCombo.FindItemIndex2("1600x900") >= 0, "windowed 1600x900 available");
	Check(Video.ResolutionCombo.FindItemIndex2("1600x1200") >= 0, "windowed 1600x1200 available");
	Check(Video.ResolutionCombo.FindItemIndex2("1600x1280") >= 0, "windowed 1600x1280 available");
	Check(Video.ResolutionCombo.FindItemIndex2("1920x1080") >= 0, "windowed 1920x1080 available");
	Check(Video.ResolutionCombo.FindItemIndex2("1920x1536") >= 0, "windowed 1920x1536 available");
	Check(Video.ResolutionCombo.FindItemIndex2("2560x1440") >= 0, "windowed 2560x1440 available");
	Check(Video.ResolutionCombo.FindItemIndex2("3840x2160") >= 0, "windowed 3840x2160 available");
	OriginalResolution = TestPlayer.ConsoleCommand("GetCurrentRes");
	if (OriginalResolution == "1024x768")
		Video.ResolutionCombo.SetSelectedIndex(Video.ResolutionCombo.FindItemIndex2("1280x720"));
	else
		Video.ResolutionCombo.SetSelectedIndex(Video.ResolutionCombo.FindItemIndex2("1024x768"));
	Check(TestPlayer.ConsoleCommand("GetCurrentRes") != OriginalResolution, "formatted selection applies raw resolution");
	Check(Video.ConfirmSettings != None, "mode change keeps confirmation");
	if (Video.ConfirmSettings != None)
	{
		Check(Video.ConfirmSettings.TimeOut == 10, "mode change keeps ten second timeout");
		Video.ConfirmSettings.Close();
	}
	Check(TestPlayer.ConsoleCommand("GetCurrentRes") == OriginalResolution, "rejecting resolution restores previous mode");
	Log("VIDEOTEST completed");
	TestPlayer.ConsoleCommand("quit");
}
