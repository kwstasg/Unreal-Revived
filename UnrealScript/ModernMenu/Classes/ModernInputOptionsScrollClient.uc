// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived

class ModernInputOptionsScrollClient extends UMenuInputOptionsScrollClient;

function Created()
{
	ClientClass = class'ModernInputOptionsClientWindow';
	FixedAreaClass = None;
	Super(UWindowScrollingDialogClient).Created();
}

defaultproperties
{
	bAllowsMouseWheelScrolling=True
}