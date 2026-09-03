class ModernGameOptionsScrollClient extends UMenuGameOptionsScrollClient;

function Created()
{
	ClientClass = class'ModernGameOptionsClientWindow';
	FixedAreaClass = None;
	Super(UWindowScrollingDialogClient).Created();
}

defaultproperties
{
	bAllowsMouseWheelScrolling=True
}