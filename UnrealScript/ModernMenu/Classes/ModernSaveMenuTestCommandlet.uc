// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived

class ModernSaveMenuTestCommandlet extends Commandlet;

event int Main(string Params)
{
	local int Failures, I, FirstSeparator, SecondSeparator;
	local string ExpectedTitle, ActualTitle, Alias, PackageName, Remaining;
	local string EnglishTitle, GreekTitle;

	if (class'ModernSaveGameSupport'.Static.FormatTimestamp("2026-9-6 4:05")
		!= "06/09/2026 04:05")
	{
		Log("Save timestamp formatting failed");
		++Failures;
	}

	for (I = 0; I < 70; ++I)
	{
		Alias = class'ModernSaveGameSupport'.Default.MapTitleAliases[I];
		FirstSeparator = InStr(Alias, "|");
		Remaining = Mid(Alias, FirstSeparator + 1);
		SecondSeparator = InStr(Remaining, "|");
		PackageName = Left(Alias, FirstSeparator);
		EnglishTitle = Left(Remaining, SecondSeparator);
		GreekTitle = Mid(Remaining, SecondSeparator + 1);
		if (class'Locale'.Static.GetLanguage() ~= "elt")
			ExpectedTitle = GreekTitle;
		else
			ExpectedTitle = EnglishTitle;
		ActualTitle = class'ModernSaveGameSupport'.Static.LocalizeSavedMapTitle(EnglishTitle);
		if (ActualTitle != ExpectedTitle)
		{
			Log("English save title localization failed for " $ PackageName);
			++Failures;
		}
		ActualTitle = class'ModernSaveGameSupport'.Static.LocalizeSavedMapTitle(GreekTitle);
		if (ActualTitle != ExpectedTitle)
		{
			Log("Greek save title localization failed for " $ PackageName);
			++Failures;
		}
	}

	if (Failures == 0)
		Log("Save menu localization checks passed for " $ class'Locale'.Static.GetLanguage());
	return Failures;
}

defaultproperties
{
	ShowBanner=False
	ShowErrorCount=True
	LogToStdout=True
	IsClient=False
	IsEditor=False
}
