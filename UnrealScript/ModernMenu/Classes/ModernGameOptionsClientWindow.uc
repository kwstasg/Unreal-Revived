class ModernGameOptionsClientWindow extends UMenuGameOptionsClientWindow;

function Created()
{
	Super.Created();

	ConsoleCombo.SetValue("Standard Unreal Console", "ModernMenu.ModernConsole");
	ConsoleCombo.SetDisabled(True);
}