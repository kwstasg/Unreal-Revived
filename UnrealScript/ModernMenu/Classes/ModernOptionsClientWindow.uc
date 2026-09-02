class ModernOptionsClientWindow extends UMenuOptionsClientWindow
	config;

var config string RestartIni;
var config string RestartUserIni;
var localized string BindingsTab;

function Created()
{
	Super(UWindowDialogClientWindow).Created();

	Pages = UMenuPageControl(CreateWindow(class'UMenuPageControl', 0, 0, WinWidth, WinHeight - 48));
	Pages.SetMultiLine(True);
	Pages.AddPage(VideoTab, class'ModernVideoScrollClient');
	Pages.AddPage(AudioTab, class'UMenuAudioScrollClient');
	Pages.AddPage(GamePlayTab, class'ModernGameOptionsScrollClient');
	Pages.AddPage(InputTab, class'ModernInputOptionsScrollClient');
	Pages.AddPage(BindingsTab, class'ModernBindingsScrollClient');
	Pages.AddPage(HUDTab, class'ModernHUDConfigScrollClient');
	Network = Pages.AddPage(NetworkTab, class'UMenuNetworkScrollClient');
	CloseButton = UWindowSmallCloseButton(CreateControl(class'UWindowSmallCloseButton', WinWidth - 56, WinHeight - 24, 48, 16));
	RestartButton = UWindowSmallRestartButton(CreateControl(class'UWindowSmallRestartButton', WinWidth - 56, WinHeight - 24, 48, 16));
	RestartButton.SetText(RestartButtonText);
	RestartButton.SetFont(F_Normal);
	RestartButton.SetHelpText(RestartButtonHelp);

	bInitialized = True;
}

function MessageBoxDone(UWindowMessageBox W, MessageBoxResult Result)
{
	local string SelectedLanguage, SelectedAudioDevice, SelectedVideoDevice;

	if (W == Confirm)
	{
		Confirm = None;
		if (Result == MR_Yes)
		{
			SelectedAudioDevice = class'UMenuAudioClientWindow'.Default.Driver;
			if (SelectedAudioDevice != "")
				GetPlayerOwner().ConsoleCommand("SETAUDIODEVICE" @ SelectedAudioDevice);

			SelectedVideoDevice = class'UMenuVideoClientWindow'.Default.Driver;
			if (SelectedVideoDevice != "")
				GetPlayerOwner().ConsoleCommand("SETGAMERENDERDEVICE" @ SelectedVideoDevice);

			SelectedLanguage = class'UMenuGameOptionsClientWindow'.Default.Language;
			if (SelectedLanguage != "")
				class'Locale'.Static.SetLanguage(SelectedLanguage);

			GetParent(class'UWindowFramedWindow').Close();
			Root.Console.CloseUWindow();
			GetPlayerOwner().ConsoleCommand("RELAUNCH Unreal.unr?Game=ModernMenu.ModernIntro ini=" $ RestartIni $ " userini=" $ RestartUserIni);
		}
	}
}

defaultproperties
{
	RestartIni="D3D12Test.ini"
	RestartUserIni="D3D12TestUser.ini"
	BindingsTab="Bindings"
}