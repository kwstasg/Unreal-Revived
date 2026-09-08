// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived

class ModernNewGameClientWindow extends UMenuNewGameClientWindow;

#exec TEXTURE IMPORT NAME=UnrealRevivedCampaignLogo FILE=Textures\UnrealRevivedCampaignLogoRuntime.png GROUP="Icons" MIPS=OFF FLAGS=2

function OnCampignChange()
{
	ScreenshotPreview.FitTexture(Texture'UnrealRevivedCampaignLogo');
	if (!ScreenshotPreview.bWindowVisible)
		ScreenshotPreview.ShowWindow();
}

function AdvancedClicked()
{
	Root.CreateWindow(class'UMenuNewStandaloneGameWindow', 100, 100, 200, 200, OwnerWindow, True);
}
