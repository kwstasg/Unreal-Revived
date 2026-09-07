// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived

class ModernSaveGameClientWindow extends UMenuSaveGameClientWindow;

function WindowShown()
{
	Super.WindowShown();
	class'ModernSaveGameSupport'.Static.RefreshSlots(Self);
}

