// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived

class ModernCreditsWindow extends UnrealCreditsWindow;

function Created()
{
	Super.Created();

	SetSize(Min(360, Root.WinWidth - 50), Min(480, Root.WinHeight - 50));
	WinLeft = Root.WinWidth / 2 - WinWidth / 2;
	WinTop = Root.WinHeight / 2 - WinHeight / 2;
	Resized();
}

defaultproperties
{
	ClientClass=Class'ModernCreditsCW'
}
