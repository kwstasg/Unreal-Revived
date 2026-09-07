class ModernOptionsWindow extends UMenuOptionsWindow;

function AfterCreate()
{
	local ModernOptionsClientWindow OptionsClient;
	local ModernVideoScrollClient VideoPage;

	Super.AfterCreate();
	OptionsClient = ModernOptionsClientWindow(ClientArea);
	VideoPage = ModernVideoScrollClient(UWindowPageControlPage(OptionsClient.Pages.SelectedTab).Page);
	if (VideoPage != None)
		ModernVideoClientWindow(VideoPage.ClientArea).VideoCombo.EditBox.ActivateWindow(0, False);
}

defaultproperties
{
	ClientClass=Class'ModernMenu.ModernOptionsClientWindow'
	WindowWidth=420
}
