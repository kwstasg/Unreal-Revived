// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived

class ModernVRConfigScrollClient extends UWindowScrollingDialogClient;

function Created()
{
	ClientClass = class'ModernVRConfigCW';
	FixedAreaClass = None;
	Super.Created();
}

defaultproperties
{
	bAllowsMouseWheelScrolling=True
}
