class ModernGameOptionsClientWindow extends UMenuGameOptionsClientWindow;

function Created()
{
	Super.Created();

	ConsoleCombo.SetValue("Standard Unreal Console", "UMenu.UnrealConsole");
	ConsoleCombo.SetDisabled(True);
}