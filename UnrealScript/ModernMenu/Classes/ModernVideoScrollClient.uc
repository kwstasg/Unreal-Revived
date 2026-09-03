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