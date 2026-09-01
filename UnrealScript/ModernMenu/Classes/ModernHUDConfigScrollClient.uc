class ModernHUDConfigScrollClient extends UMenuHUDConfigScrollClient;

function Created()
{
	ClientClass = class'ModernHUDConfigCW';
	FixedAreaClass = None;
	Super(UWindowScrollingDialogClient).Created();
}