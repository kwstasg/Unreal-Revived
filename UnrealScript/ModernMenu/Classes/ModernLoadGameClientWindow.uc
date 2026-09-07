// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived

class ModernLoadGameClientWindow extends UMenuLoadGameClientWindow;

function WindowShown()
{
	Super.WindowShown();
	class'ModernSaveGameSupport'.Static.RefreshSlots(Self);
}

