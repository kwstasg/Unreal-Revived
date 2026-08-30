class ModernOptionsMenu extends UMenuOptionsMenu;

function ShowPreferences(optional bool bNetworkSettings)
{
	local ModernOptionsWindow OptionsWindow;

	OptionsWindow = ModernOptionsWindow(Root.CreateWindow(class'ModernOptionsWindow', 100, 100, 200, 200, Self, True));
	if (bNetworkSettings)
		ModernOptionsClientWindow(OptionsWindow.ClientArea).ShowNetworkTab();
}