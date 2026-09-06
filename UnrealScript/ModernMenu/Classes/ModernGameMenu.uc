class ModernGameMenu extends UMenuGameMenu;

function ExecuteItem(UWindowPulldownMenuItem I)
{
	if (I == Load)
	{
		Root.CreateWindow(class'ModernLoadGameWindow', 100, 100, 300, 660, Self, True);
		Super(UWindowPulldownMenu).ExecuteItem(I);
		return;
	}
	if (I == Save)
	{
		Root.CreateWindow(class'ModernSaveGameWindow', 100, 100, 300, 660, Self, True);
		Super(UWindowPulldownMenu).ExecuteItem(I);
		return;
	}
	Super.ExecuteItem(I);
}

