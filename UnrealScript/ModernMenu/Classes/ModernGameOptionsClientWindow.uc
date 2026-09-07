// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived

class ModernGameOptionsClientWindow extends UMenuGameOptionsClientWindow;

var bool bRebuildingLanguageCombo;

function Created()
{
	Super.Created();

	RebuildLanguageCombo();
	ConsoleCombo.SetValue("Standard Unreal Console", "ModernMenu.ModernConsole");
	ConsoleCombo.SetDisabled(True);
}

function RebuildLanguageCombo()
{
	local string CurrentLanguage;
	local string NextDefault;
	local string NextDesc;

	CurrentLanguage = class'Locale'.Static.GetLanguage();
	bRebuildingLanguageCombo = True;
	LanguageCombo.Clear();

	LanguageCombo.AddItem("English", "int", -200);
	LanguageCombo.AddItem(GetLanguageDescription("elt", "Ελληνικά"), "elt", -100);

	foreach GetPlayerOwner().IntDescIterator(string(class'Engine.Language'), NextDefault, NextDesc)
	{
		if (NextDefault ~= "int" || NextDefault ~= "elt")
			continue;
		if (Len(NextDesc) == 0)
			NextDesc = GetLanguageDescription(NextDefault, NextDefault);
		LanguageCombo.AddItem(NextDesc, NextDefault);
	}

	LanguageCombo.Sort();
	if (LanguageCombo.FindItemIndex2(CurrentLanguage, True) >= 0)
		LanguageCombo.SetSelectedIndex(LanguageCombo.FindItemIndex2(CurrentLanguage, True));
	else
		LanguageCombo.SetValue(CurrentLanguage, CurrentLanguage);
	Language = CurrentLanguage;
	class'UMenuGameOptionsClientWindow'.Default.Language = CurrentLanguage;
	bRebuildingLanguageCombo = False;
}

function LanguageComboChanged()
{
	local string SelectedLanguage;
	local ModernOptionsClientWindow OptionsClient;

	if (bRebuildingLanguageCombo)
		return;

	SelectedLanguage = LanguageCombo.GetValue2();
	if (Len(SelectedLanguage) == 0)
		return;

	Language = SelectedLanguage;
	class'UMenuGameOptionsClientWindow'.Default.Language = SelectedLanguage;

	if (!(SelectedLanguage ~= class'Locale'.Static.GetLanguage()))
	{
		OptionsClient = ModernOptionsClientWindow(GetParent(class'ModernOptionsClientWindow'));
		if (OptionsClient != None && OptionsClient.Confirm == None)
			OptionsClient.RestartButtonChange();
	}
}

function string GetLanguageDescription(string LanguageCode, string Fallback)
{
	local string Result;

	Result = class'Locale'.Static.GetDisplayLanguage(LanguageCode);
	if (Len(Result) == 0)
		Result = Fallback;
	return Result;
}
