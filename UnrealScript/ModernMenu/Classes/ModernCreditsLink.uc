// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived

class ModernCreditsLink extends UMenuLabelControl;

var string URL;
var color NormalTextColor;
var color HoverTextColor;

function Created()
{
	Super.Created();
	NormalTextColor = TextColor;
	HoverTextColor.R = 32;
	HoverTextColor.G = 72;
	HoverTextColor.B = 192;
}

function MouseEnter()
{
	Super.MouseEnter();
	SetCursor(Root.HandCursor);
	SetTextColor(HoverTextColor);
}

function MouseLeave()
{
	Super.MouseLeave();
	SetCursor(Root.NormalCursor);
	SetTextColor(NormalTextColor);
}

function Click(float X, float Y)
{
	if (URL != "")
		GetPlayerOwner().ConsoleCommand("start" @ URL);
}

defaultproperties
{
	bNoKeyboard=True
	bIgnoreLDoubleClick=True
}
