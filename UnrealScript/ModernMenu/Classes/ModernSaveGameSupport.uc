class ModernSaveGameSupport extends Object;

// Canonical package name, original English title, and Greek title.  These
// aliases let old saves keep their original on-disk metadata while the menu
// resolves the title for the language that is active now.
var string MapTitleAliases[70];

struct SaveEntry
{
	var GameInfo.SavedGameInfo Info;
	var int Index;
	var int SortKey;
};

static function string PadTwoDigits(int Value)
{
	if (Value < 10)
		return "0" $ string(Value);
	return string(Value);
}

// GameInfo stores timestamps as YYYY-M-D H:MM.  Keep that storage format
// untouched and normalize only the language-independent menu presentation.
static function bool ParseTimestamp(string Timestamp, out int Year, out int Month,
	out int Day, out int Hour, out int Minute)
{
	local int SpacePos, FirstDash, SecondDash, ColonPos;
	local string DatePart, MonthAndDay, TimePart;

	SpacePos = InStr(Timestamp, " ");
	if (SpacePos < 0)
		return False;
	DatePart = Left(Timestamp, SpacePos);
	TimePart = Mid(Timestamp, SpacePos + 1);
	FirstDash = InStr(DatePart, "-");
	if (FirstDash < 0)
		return False;
	MonthAndDay = Mid(DatePart, FirstDash + 1);
	SecondDash = InStr(MonthAndDay, "-");
	ColonPos = InStr(TimePart, ":");
	if (SecondDash < 0 || ColonPos < 0)
		return False;

	Year = int(Left(DatePart, FirstDash));
	Month = int(Left(MonthAndDay, SecondDash));
	Day = int(Mid(MonthAndDay, SecondDash + 1));
	Hour = int(Left(TimePart, ColonPos));
	Minute = int(Mid(TimePart, ColonPos + 1));
	return Year > 0 && Month >= 1 && Month <= 12 && Day >= 1 && Day <= 31
		&& Hour >= 0 && Hour <= 23 && Minute >= 0 && Minute <= 59;
}

static function string FormatTimestamp(string Timestamp)
{
	local int Year, Month, Day, Hour, Minute;

	if (!ParseTimestamp(Timestamp, Year, Month, Day, Hour, Minute))
		return Timestamp;
	return PadTwoDigits(Day) $ "/" $ PadTwoDigits(Month) $ "/" $ string(Year)
		@ PadTwoDigits(Hour) $ ":" $ PadTwoDigits(Minute);
}

static function int TimestampSortKey(string Timestamp)
{
	local int Year, Month, Day, Hour, Minute;

	if (!ParseTimestamp(Timestamp, Year, Month, Day, Hour, Minute))
		return -1;
	return (((Year * 12 + Month) * 31 + Day) * 24 + Hour) * 60 + Minute;
}

static function string LocalizeSavedMapTitle(string StoredTitle)
{
	local int I, FirstSeparator, SecondSeparator;
	local string Alias, PackageName, EnglishTitle, GreekTitle, Remaining;
	local string LocalizedTitle, Language;

	Language = class'Locale'.Static.GetLanguage();

	for (I = 0; I < 70; ++I)
	{
		Alias = Default.MapTitleAliases[I];
		FirstSeparator = InStr(Alias, "|");
		if (FirstSeparator < 0)
			continue;
		PackageName = Left(Alias, FirstSeparator);
		Remaining = Mid(Alias, FirstSeparator + 1);
		SecondSeparator = InStr(Remaining, "|");
		if (SecondSeparator < 0)
			continue;
		EnglishTitle = Left(Remaining, SecondSeparator);
		GreekTitle = Mid(Remaining, SecondSeparator + 1);
		if (!(StoredTitle ~= PackageName) && !(StoredTitle ~= EnglishTitle)
			&& !(StoredTitle ~= GreekTitle))
			continue;

		if (Language ~= "int")
			return EnglishTitle;
		if (Language ~= "elt")
			return GreekTitle;
		LocalizedTitle = Localize("LevelInfo0", "Title", PackageName, "");
		if (LocalizedTitle == "")
			LocalizedTitle = Localize("LevelSummary", "Title", PackageName, "");
		if (LocalizedTitle != "")
			return LocalizedTitle;
		return StoredTitle;
	}
	return StoredTitle;
}

static function bool ShouldComeBefore(SaveEntry A, SaveEntry B)
{
	// Slot zero is QuickSave and remains pinned above the normal save history.
	if (A.Index == 0)
		return B.Index != 0;
	if (B.Index == 0)
		return False;
	if (A.SortKey < 0 || B.SortKey < 0 || A.SortKey == B.SortKey)
		return False;
	return A.SortKey > B.SortKey;
}

static function RefreshSlots(UMenuSlotClientWindow Client)
{
	local array<SaveEntry> Entries;
	local SaveEntry Entry, Temp;
	local GameInfo.SavedGameInfo SaveInfo;
	local int Index, I, J;
	local string Label;

	foreach class'GameInfo'.Static.AllSavedGames(SaveInfo, Index)
	{
		if (Client.bSaveGame && Index == 0)
			continue;
		Entry.Info = SaveInfo;
		Entry.Index = Index;
		Entry.SortKey = TimestampSortKey(SaveInfo.Timestamp);
		Entries[Entries.Size()] = Entry;
	}

	// Stable newest-first ordering. Equal or legacy timestamps retain the
	// engine's original order.
	for (I = 1; I < Entries.Size(); ++I)
		for (J = I; J > 0 && ShouldComeBefore(Entries[J], Entries[J - 1]); --J)
		{
			Temp = Entries[J - 1];
			Entries[J - 1] = Entries[J];
			Entries[J] = Temp;
		}

	for (I = 0; I < Entries.Size() && I < Client.Slots.Size(); ++I)
	{
		Label = LocalizeSavedMapTitle(Entries[I].Info.MapTitle)
			@ FormatTimestamp(Entries[I].Info.Timestamp);
		if (Entries[I].Info.ExtraInfo != "")
			Label = "[" $ Entries[I].Info.ExtraInfo $ "] " $ Label;
		Client.Slots[I].SetText(Label);
		Client.Slots[I].SetHelpText(Client.SlotHelp @ "["
			$ LocalizeSavedMapTitle(Entries[I].Info.MapTitle) $ "]");
		Client.Slots[I].Index = Entries[I].Index;
		Client.SlotImages[I].FitTexture((Entries[I].Info.Screenshot != None)
			? Entries[I].Info.Screenshot : Texture'UMenu.S_Flag');
	}
}

defaultproperties
{
	MapTitleAliases(0)="Abyss|Gala's Peak|Κορυφή της Gala"
	MapTitleAliases(1)="Bluff|Bluff Eversmoking|Ο Αιώνια Καπνισμένος Γκρεμός"
	MapTitleAliases(2)="Ceremony|The Ceremonial Chambers|Οι Τελετουργικοί Θάλαμοι"
	MapTitleAliases(3)="Chizra|Chizra - Nali Water God|Chizra — Θεός του Νερού των Nali"
	MapTitleAliases(4)="Crashsite|Approaching UMS Prometheus|Προσέγγιση στο UMS Prometheus"
	MapTitleAliases(5)="Crashsite1|UMS Prometheus|UMS Prometheus"
	MapTitleAliases(6)="Crashsite2|Inside UMS Prometheus|Μέσα στο UMS Prometheus"
	MapTitleAliases(7)="Dark|Dark Arena|Σκοτεινή Αρένα"
	MapTitleAliases(8)="DasaCellars|Cellars at Dasa Pass|Τα Κελάρια του Περάσματος Dasa"
	MapTitleAliases(9)="DasaPass|Dasa Mountain Pass|Ορεινό Πέρασμα Dasa"
	MapTitleAliases(10)="DCrater|Demon Crater|Κρατήρας των Δαιμόνων"
	MapTitleAliases(11)="Dig|Rrajigar Mine|Ορυχείο Rrajigar"
	MapTitleAliases(12)="Dug|Depths of Rrajigar|Τα Βάθη του Rrajigar"
	MapTitleAliases(13)="DuskFalls|Edge of Na Pali|Άκρη του Na Pali"
	MapTitleAliases(14)="Eldora|The Eldora Well|Το Πηγάδι της Eldora"
	MapTitleAliases(15)="End|End|Τέλος"
	MapTitleAliases(16)="Endgame|Ending Sequence|Τελική Σκηνή"
	MapTitleAliases(17)="ExtremeBeg|MotherShip Basement|Υπόγειο του Μητρικού Σκάφους"
	MapTitleAliases(18)="ExtremeCore|MotherShip Core|Πυρήνας του Μητρικού Σκάφους"
	MapTitleAliases(19)="ExtremeDark|The Darkening|Το Σκοτάδι"
	MapTitleAliases(20)="ExtremeDGen|Illumination|Φωταγώγηση"
	MapTitleAliases(21)="ExtremeEnd|The Source Antechamber|Ο Προθάλαμος της Πηγής"
	MapTitleAliases(22)="ExtremeGen|Skaarj Generator|Γεννήτρια των Skaarj"
	MapTitleAliases(23)="ExtremeLab|MotherShip Lab|Εργαστήριο του Μητρικού Σκάφους"
	MapTitleAliases(24)="Foundry|Foundry Tarydium Plant|Χυτήριο Επεξεργασίας Tarydium"
	MapTitleAliases(25)="Gateway|The Gateway|Η Πύλη"
	MapTitleAliases(26)="Glacena|Watcher of the Skies|Παρατηρητής των Ουρανών"
	MapTitleAliases(27)="Glathriel1|Glathriel Village|Χωριό Glathriel"
	MapTitleAliases(28)="Glathriel2|Glathriel Village|Χωριό Glathriel"
	MapTitleAliases(29)="Harobed|Harobed Village|Χωριό Harobed"
	MapTitleAliases(30)="Inter1|Intermission 1|Διάλειμμα 1"
	MapTitleAliases(31)="Inter2|Intermission 2|Διάλειμμα 2"
	MapTitleAliases(32)="Inter3|Intermission 3|Διάλειμμα 3"
	MapTitleAliases(33)="Inter4|Yousa follow me now, okiday?|Θα με ακολουθήσεις τώρα, εντάξει;"
	MapTitleAliases(34)="Inter5|Intermission 5|Διάλειμμα 5"
	MapTitleAliases(35)="Inter6|Intermission 6|Διάλειμμα 6"
	MapTitleAliases(36)="Inter7|Intermission 7|Διάλειμμα 7"
	MapTitleAliases(37)="Inter8|Intermission 8|Διάλειμμα 8"
	MapTitleAliases(38)="Inter9|Intermission 9|Διάλειμμα 9"
	MapTitleAliases(39)="Inter10|Intermission 10|Διάλειμμα 10"
	MapTitleAliases(40)="Inter11|Intermission 11|Διάλειμμα 11"
	MapTitleAliases(41)="Inter12|Intermission 12|Διάλειμμα 12"
	MapTitleAliases(42)="Inter13|Intermission 13|Διάλειμμα 13"
	MapTitleAliases(43)="Inter14|Intermission 14|Διάλειμμα 14"
	MapTitleAliases(44)="InterCrashsite|Auf der Reeperbahn nachts um halb 2...|Στο Reeperbahn στις μιάμιση τη νύχτα..."
	MapTitleAliases(45)="InterIntro|First Intermission|Πρώτο Διάλειμμα"
	MapTitleAliases(46)="Intro1|Intro 1|Εισαγωγή 1"
	MapTitleAliases(47)="Intro2|Intro 2|Εισαγωγή 2"
	MapTitleAliases(48)="IsvDeck1|ISV-KRAN Deck 1|ISV-KRAN Κατάστρωμα 1"
	MapTitleAliases(49)="IsvKran4|ISV-KRAN Deck 4|ISV-KRAN Κατάστρωμα 4"
	MapTitleAliases(50)="IsvKran32|ISV-KRAN Decks 3 and 2|ISV-KRAN Καταστρώματα 3 και 2"
	MapTitleAliases(51)="Nagomi|Nagomi Passage|Πέρασμα Nagomi"
	MapTitleAliases(52)="NagomiSun|Nagomi Passage|Πέρασμα Nagomi"
	MapTitleAliases(53)="NaliC|Nali Castle|Κάστρο των Nali"
	MapTitleAliases(54)="Nalic2|Escape from Na Pali|Απόδραση από το Na Pali"
	MapTitleAliases(55)="NaliLord|Demonlord's Lair|Η Φωλιά του Άρχοντα των Δαιμόνων"
	MapTitleAliases(56)="Nevec|Neve's Crossing|Το Πέρασμα της Neve"
	MapTitleAliases(57)="Noork|Noork's Elbow|Η Καμπή του Noork"
	MapTitleAliases(58)="Nyleve|NyLeve's Falls|Οι Καταρράκτες της NyLeve"
	MapTitleAliases(59)="Passage|Sacred Passage|Ιερό Πέρασμα"
	MapTitleAliases(60)="QueenEnd|The Source|Η Πηγή"
	MapTitleAliases(61)="Ruins|Temple of Vandora|Ναός της Vandora"
	MapTitleAliases(62)="SpireLand|Spire Valley|Κοιλάδα του Πύργου"
	MapTitleAliases(63)="SpireVillage|Spire Village|Χωριό του Πύργου"
	MapTitleAliases(64)="Terraniux|Terraniux|Terraniux"
	MapTitleAliases(65)="TheSunspire|The Sunspire|Το Sunspire"
	MapTitleAliases(66)="Toxic|Bounds of Foundry|Περίμετρος του Χυτηρίου"
	MapTitleAliases(67)="Trench|The Trench|Η Τάφρος"
	MapTitleAliases(68)="Velora|Velora Temple|Ναός της Velora"
	MapTitleAliases(69)="Vortex2|Vortex Rikers|Vortex Rikers"
}
