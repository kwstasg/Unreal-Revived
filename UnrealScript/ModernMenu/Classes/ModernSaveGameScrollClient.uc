// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived

class ModernSaveGameScrollClient extends UWindowScrollingDialogClient;

function Created()
{
	ClientClass = class'ModernSaveGameClientWindow';
	Super.Created();
}

