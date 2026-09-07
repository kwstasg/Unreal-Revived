// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived

class ModernHelpMenu extends UMenuHelpMenu;

var UWindowPulldownMenuItem UnrealRevivedURL;
var localized string UnrealRevivedURLName;
var localized string UnrealRevivedURLHelp;

function Created()
{
	Super(UWindowPulldownMenu).Created();

	Context = AddMenuItem(ContextName, None);
	AddMenuItem("-", None);
	AboutButton = AddMenuItem(AboutName, None);
	SupportURL = AddMenuItem(SupportURLName, None);
	UnrealRevivedURL = AddMenuItem(UnrealRevivedURLName, None);
	AddMenuItem("-", None);
	EpicURL = AddMenuItem(EpicGamesURLName, None);
}

function ExecuteItem(UWindowPulldownMenuItem I)
{
	if (I == UnrealRevivedURL)
		GetPlayerOwner().ConsoleCommand("start https://github.com/kwstasg/Unreal-Revived");
	Super.ExecuteItem(I);
}

function Select(UWindowPulldownMenuItem I)
{
	if (I == UnrealRevivedURL)
		UMenuMenuBar(GetMenuBar()).SetHelp(UnrealRevivedURLHelp);
	else
		Super.Select(I);
}

defaultproperties
{
	SupportURLName="&OldUnreal"
	SupportURLHelp="Open the OldUnreal website for patches, support, and community resources."
	UnrealRevivedURLName="Unreal &Revived"
	UnrealRevivedURLHelp="Open the Unreal Revived project page on GitHub."
}
