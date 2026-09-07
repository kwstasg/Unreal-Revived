// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived

class ModernVideoScrollClient extends UMenuVideoScrollClient;

function Created()
{
	ClientClass = class'ModernVideoClientWindow';
	FixedAreaClass = None;
	Super(UWindowScrollingDialogClient).Created();
}

defaultproperties
{
	bAllowsMouseWheelScrolling=True
}