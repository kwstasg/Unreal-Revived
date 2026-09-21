// Test fixture: run the real binding handlers with an isolated input store.
class ModernBindingsTestWindow extends ModernBindingsClientWindow;

var string Inputs[255];
var int HistorySaves;

function InitTest()
{
	local int I;
	Root = new class'ModernRootWindow';
	NumGroups = 1;
	KeyGroups[0].NumKeys = 1;
	KeyGroups[0].Keys[0].AliasString = "Duck";
	KeyGroups[0].Keys[0].KeyButton = new class'UMenuRaisedButton';
	KeyGroups[0].Keys[0].KeyName = new class'UMenuLabelControl';
	DefaultsButton = new class'UWindowSmallButton';
	Root.KeyFocusWindow = KeyGroups[0].Keys[0].KeyButton;
	ConsoleButtonGroupIdx = -1;
	ConsoleCharacterGroupIdx = -1;
	NextBindingAge = 0;
	for (I = 0; I < 255; I++)
	{
		BindingAge[I] = 0;
		BaseLocalizedKeyName[I] = string(I);
		RealKeyName[I] = string(I);
	}
}

function string ReadBinding(int KeyNo)
{
	return Inputs[KeyNo];
}

function WriteBinding(int KeyNo, string Alias)
{
	Inputs[KeyNo] = Alias;
}

function SaveBindingHistory()
{
	HistorySaves++;
}

function ReloadBindingDisplay()
{
	RefreshThirdBindings();
}

function FocusSelectedBinding()
{
	Root.KeyFocusWindow = SelectedButton;
}
