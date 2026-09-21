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
	C = WindowConsole(TestPlayer.Player.Console);
	Options = ModernOptionsWindow(C.Root.CreateWindow(class'ModernOptionsWindow', 20, 20, 420, 500));
	Video = ModernVideoClientWindow(ModernVideoScrollClient(UWindowPageControlPage(ModernOptionsClientWindow(Options.ClientArea).Pages.SelectedTab).Page).ClientArea);
	Check(Video.BrightnessSlider.Value == 120, "initial default is 120 percent");
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
	Log("VIDEOTEST completed");
	TestPlayer.ConsoleCommand("quit");
}
