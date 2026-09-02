class ModernBindingsScrollClient extends UMenuCustomizeScrollClient;

function Created()
{
	ClientClass = class'ModernBindingsClientWindow';
	FixedAreaClass = None;
	Super(UWindowScrollingDialogClient).Created();
}