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