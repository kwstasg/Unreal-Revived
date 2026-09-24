// Uses disposable INIs. Checks startup sizing with the connected OpenXR runtime.
class ModernVRQualityTestGame extends SinglePlayer;

var PlayerPawn TestPlayer;
var int LiveStep;
var string LowSize;

event PostLogin(PlayerPawn NewPlayer)
{
	Super.PostLogin(NewPlayer);
	TestPlayer = NewPlayer;
	SetTimer(3, False);
}

event Timer()
{
	local string Size;
	if (LiveStep > 0)
	{
		Size = TestPlayer.ConsoleCommand("D3D12 VRRENDERSIZE 0");
		if (TestPlayer.ConsoleCommand("D3D12 VRQUALITYSTATUS") != "ready")
			Log("VRQUALITYTEST FAIL live quality was not applied");
		if (LiveStep == 1)
		{
			LowSize = Size;
			TestPlayer.ConsoleCommand("D3D12 VRRENDERQUALITY 4");
		}
		else if (LiveStep == 2)
		{
			if (Size == LowSize)
				Log("VRQUALITYTEST FAIL live 75 to 150 did not change dimensions");
			TestPlayer.ConsoleCommand("D3D12 VRRENDERQUALITY 2");
		}
		else if (LiveStep == 3)
		{
			if (TestPlayer.ConsoleCommand("D3D12 VRRENDERQUALITY") != "2" || Size == LowSize)
				Log("VRQUALITYTEST FAIL live return to Balanced");
			Log("VRQUALITYTEST live completed");
			Log("VRQUALITYTEST completed");
			TestPlayer.ConsoleCommand("quit");
			return;
		}
		LiveStep++;
		SetTimer(2, False);
		return;
	}
	if (TestPlayer.ConsoleCommand("GetCurrentRes") != "1280x1024")
		Log("VRQUALITYTEST FAIL startup layout is not locked");
	TestPlayer.ConsoleCommand("SetRes 1600x1280");
	if (TestPlayer.ConsoleCommand("GetCurrentRes") != "1280x1024")
		Log("VRQUALITYTEST FAIL 1600x1280 bypassed layout lock");
	TestPlayer.ConsoleCommand("SetRes 1920x1536");
	if (TestPlayer.ConsoleCommand("GetCurrentRes") != "1280x1024")
		Log("VRQUALITYTEST FAIL 1920x1536 bypassed layout lock");
	if (TestPlayer.ConsoleCommand("GetRes") != "1280x1024")
		Log("VRQUALITYTEST FAIL VR resolution list is not locked");
	Log("VRQUALITYTEST layout=" $ TestPlayer.ConsoleCommand("GetCurrentRes"));
	Log("VRQUALITYTEST fps=" $ TestPlayer.ConsoleCommand("D3D12 VRFPS 0"));
	Log("VRQUALITYTEST left=" $ TestPlayer.ConsoleCommand("D3D12 VRRENDERSIZE 0"));
	Log("VRQUALITYTEST right=" $ TestPlayer.ConsoleCommand("D3D12 VRRENDERSIZE 1"));
	Log("VRQUALITYTEST status=" $ TestPlayer.ConsoleCommand("D3D12 VRQUALITYSTATUS"));
	if (TestPlayer.ConsoleCommand("D3D12 VRRENDERSIZE 0") != "")
	{
		TestPlayer.ConsoleCommand("D3D12 VRRENDERQUALITY 1");
		LiveStep = 1;
		SetTimer(2, False);
		return;
	}
	Log("VRQUALITYTEST completed");
	TestPlayer.ConsoleCommand("quit");
}
