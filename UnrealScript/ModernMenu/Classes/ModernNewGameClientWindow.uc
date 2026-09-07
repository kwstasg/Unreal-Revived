class ModernNewGameClientWindow extends UMenuNewGameClientWindow;

function AdvancedClicked()
{
	Root.CreateWindow(class'UMenuNewStandaloneGameWindow', 100, 100, 200, 200, OwnerWindow, True);
}
