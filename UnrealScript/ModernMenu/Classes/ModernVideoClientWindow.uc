class ModernVideoClientWindow extends UMenuVideoClientWindow
	config;

var UWindowCheckbox ShowFPSCheck;
var localized string ShowFPSText;
var localized string ShowFPSHelp;
var config bool bShowFPS;

function Created()
{
	local UWindowWindow Child;
	local float ShowFPSTop;

	Super.Created();

	ShowFPSTop = ShowWindowedCheck.WinTop + 25;
	for (Child = FirstChildWindow; Child != None; Child = Child.NextSiblingWindow)
		if (Child.WinTop >= ShowFPSTop)
			Child.WinTop += 25;

	ShowFPSCheck = UWindowCheckbox(CreateControl(class'UWindowCheckbox', ShowWindowedCheck.WinLeft, ShowFPSTop, ShowWindowedCheck.WinWidth, 1));
	ShowFPSCheck.SetText(ShowFPSText);
	ShowFPSCheck.SetHelpText(ShowFPSHelp);
	ShowFPSCheck.SetFont(F_Normal);
	ShowFPSCheck.Align = TA_Left;
	ShowFPSCheck.bChecked = bShowFPS;
	ControlOffset += 25;
}

function BeforePaint(Canvas C, float X, float Y)
{
	Super.BeforePaint(C, X, Y);
	ShowFPSCheck.WinLeft = ShowWindowedCheck.WinLeft;
	ShowFPSCheck.SetSize(ShowWindowedCheck.WinWidth, 1);
}

function WindowShown()
{
	Super.WindowShown();
	ShowFPSCheck.bChecked = bShowFPS;
}

function Notify(UWindowDialogControl C, byte E)
{
	Super.Notify(C, E);

	if (E == DE_Change && C == ShowFPSCheck)
	{
		bShowFPS = ShowFPSCheck.bChecked;
		SaveConfig();
		if (bShowFPS)
			GetPlayerOwner().ConsoleCommand("TIMEDEMO 1");
		else
			GetPlayerOwner().ConsoleCommand("TIMEDEMO 0");
	}
}

defaultproperties
{
	ShowFPSText="Show FPS Statistics"
	ShowFPSHelp="Display live frame-rate statistics while playing."
	bShowFPS=False
}