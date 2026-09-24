class ModernMultiplayerMenu extends UMenuMultiplayerMenu;

function ExecuteItem(UWindowPulldownMenuItem I)
{
	if (I == Patch)
	{
		GetPlayerOwner().ConsoleCommand("start https://github.com/kwstasg/Unreal-Revived/releases/latest");
		Super(UWindowPulldownMenu).ExecuteItem(I);
	}
	else
		Super.ExecuteItem(I);
}

defaultproperties
{
	PatchHelp="Open the latest Unreal Revived release on GitHub."
}
