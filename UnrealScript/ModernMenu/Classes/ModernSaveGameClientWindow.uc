class ModernSaveGameClientWindow extends UMenuSaveGameClientWindow;

function WindowShown()
{
	Super.WindowShown();
	class'ModernSaveGameSupport'.Static.RefreshSlots(Self);
}

