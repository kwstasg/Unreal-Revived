// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived

class ModernCreditsCW extends UnrealCreditsCW;

#exec TEXTURE IMPORT NAME=UnrealRevivedAboutLogo FILE=Textures\UnrealRevivedAboutLogoRuntime.png GROUP="Icons" MIPS=OFF

const ABOUT_BANNER_SOURCE_WIDTH = 512;
const ABOUT_BANNER_SOURCE_HEIGHT = 171;
const ABOUT_BANNER_TOP = 8;
const ABOUT_CREDIT_OFFSET = 118;

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

	// Make room above the stock credits for the Unreal Revived banner.
	for (i = 0; i < AllLabels.Size(); i++)
		AllLabels[i].WinTop += ABOUT_CREDIT_OFFSET;

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

function Paint(Canvas C, float X, float Y)
{
	local float BannerWidth;
	local float BannerHeight;
	local float BannerLeft;

	Super.Paint(C, X, Y);
	BannerWidth = WinWidth * 0.925;
	BannerHeight = BannerWidth * ABOUT_BANNER_SOURCE_HEIGHT / ABOUT_BANNER_SOURCE_WIDTH;
	BannerLeft = (WinWidth - BannerWidth) / 2;
	DrawStretchedTextureSegment(C, BannerLeft, ABOUT_BANNER_TOP,
		BannerWidth, BannerHeight, 0, 0,
		ABOUT_BANNER_SOURCE_WIDTH, ABOUT_BANNER_SOURCE_HEIGHT,
		Texture'UnrealRevivedAboutLogo');
}

defaultproperties
{
	ProjectText="Unreal Revived"
	ProjectRoleText="Project Creator: Kwstasg - Kostas Giannakakis"
	ProjectDeveloperText="Developers: Kostas & Nikos Giannakakis"
	ProjectWebsiteText="github.com/kwstasg/Unreal-Revived"
}
