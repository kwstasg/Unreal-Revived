// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived

class ModernBindingsScrollClient extends UMenuCustomizeScrollClient;

function Created()
{
	ClientClass = class'ModernBindingsClientWindow';
	FixedAreaClass = None;
	Super(UWindowScrollingDialogClient).Created();
}