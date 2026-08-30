class ModernRootWindow extends UMenuRootWindow;

function Created()
{
	local class<GameInfo> GameClass;

	if (GetLevel().Game != None)
	{
		GameClass = GetLevel().Game.Class;
		GameClass.Default.GameOptionsMenuType = "ModernMenu.ModernOptionsMenu";
	}

	Super.Created();

	if (class'ModernVideoClientWindow'.Default.bShowFPS)
		GetPlayerOwner().ConsoleCommand("TIMEDEMO 1");
}