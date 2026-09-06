class ModernLoadGameClientWindow extends UMenuLoadGameClientWindow;

function WindowShown()
{
	Super.WindowShown();
	class'ModernSaveGameSupport'.Static.RefreshSlots(Self);
}

