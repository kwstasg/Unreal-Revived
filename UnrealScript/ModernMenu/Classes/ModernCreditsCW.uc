// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived

class ModernCreditsCW extends UnrealCreditsCW;

var localized string ProjectText;
var localized string ProjectRoleText;
var localized string ProjectDeveloperText;
var localized string ProjectWebsiteText;
var ModernCreditsLink ProjectWebsiteLink;

function UMenuLabelControl AddProjectCredit(string CreditText, float Top,
	float Left, float Width, bool bHeader)
{
	local UMenuLabelControl Label;

	Label = UMenuLabelControl(CreateWindow(class'UMenuLabelControl', Left, Top,
		Width, 1));
	Label.SetText(CreditText);
	Label.SetFont(bHeader ? F_Bold : F_Normal);
	Label.Align = TA_Left;
	AllLabels.Add(Label);
	return Label;
}

function Created()
{
	local int i;
	local float Bottom;
	local float CenterWidth;
	local float CenterPos;

	Super.Created();

	for (i = 0; i < AllLabels.Size(); i++)
		if (AllLabels[i].WinTop > Bottom)
			Bottom = AllLabels[i].WinTop;

	CenterWidth = WinWidth * 0.925;
	CenterPos = (WinWidth - CenterWidth) / 2;
	// Leave one complete blank text row between the existing credits and the
	// Unreal Revived section, matching the separation used by the stock list.
	Bottom += 20;
	AddProjectCredit(ProjectText, Bottom, CenterPos, CenterWidth, True);
	Bottom += 10;
	AddProjectCredit(ProjectRoleText, Bottom, CenterPos, CenterWidth, False);
	Bottom += 10;
	AddProjectCredit(ProjectDeveloperText, Bottom, CenterPos, CenterWidth, False);
	Bottom += 10;
	ProjectWebsiteLink = ModernCreditsLink(CreateWindow(class'ModernCreditsLink',
		CenterPos, Bottom, CenterWidth, 1));
	ProjectWebsiteLink.SetText(ProjectWebsiteText);
	ProjectWebsiteLink.SetFont(F_Normal);
	ProjectWebsiteLink.Align = TA_Left;
	ProjectWebsiteLink.URL = "https://github.com/kwstasg/Unreal-Revived";
	AllLabels.Add(ProjectWebsiteLink);
}

defaultproperties
{
	ProjectText="Unreal Revived"
	ProjectRoleText="Project Creator"
	ProjectDeveloperText="Kwstasg - Kostas Giannakakis"
	ProjectWebsiteText="github.com/kwstasg/Unreal-Revived"
}
