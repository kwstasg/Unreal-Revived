// Exercise production capture, clear, cancel, and oldest-first replacement logic.
class ModernBindingsTestCommandlet extends Commandlet;

var int Failures;

function Check(bool Result, string Description)
{
	if (!Result)
	{
		Log("FAIL: " $ Description);
		Failures++;
	}
}

event int Main(string Params)
{
	local ModernBindingsTestWindow W;
	local UMenuRaisedButton Row;
	local ModernBindingsClientWindow History;
	// Use a disposable userini for these separate-process persistence checks.
	if (InStr(Params, "history-") >= 0)
	{
		History = new class'ModernBindingsClientWindow';
		if (InStr(Params, "history-write") >= 0)
		{
			History.NextBindingAge = 122;
			History.RememberBinding(70);
		}
		else
			Check(History.GetBindingAge(70) == 123 && History.NextBindingAge == 123, "history survives a fresh engine process");
		Log("Binding history regression failures: " $ Failures);
		return Failures;
	}
	W = new class'ModernBindingsTestWindow';
	W.InitTest();
	Row = W.KeyGroups[0].Keys[0].KeyButton;
	// Reproduce the user's full Crouch row: Ctrl, C, left stick click.
	W.Inputs[17] = "Duck";
	W.Inputs[67] = "Duck";
	W.Inputs[208] = "Duck";
	W.ReloadBindingDisplay();
	W.Notify(Row, W.DE_Click);
	Check(W.bPolling && Row.Text == W.CaptureText, "left click shows capture prompt");
	W.KeyUp(1, 0, 0);
	Check(W.bPolling, "initiating mouse release preserves capture");
	W.ProcessMenuKey(70, "F");
	Check(W.Inputs[17] == "" && W.Inputs[67] == "Duck" && W.Inputs[208] == "Duck" && W.Inputs[70] == "Duck", "fourth input replaces oldest Crouch binding");
	Check(!W.bPolling && W.KeyGroups[0].Keys[0].BoundKey1 == 67 && W.ThirdBoundKeys[0] == 70, "display follows oldest-to-newest order");
	W.BeginFocusedBindingCapture();
	W.ProcessMenuKey(71, "G");
	Check(W.Inputs[67] == "" && W.Inputs[70] == "Duck" && W.Inputs[71] == "Duck", "successive additions rotate rather than replacing newest");
	W.BeginFocusedBindingCapture();
	W.ProcessMenuKey(71, "G");
	Check(W.HistorySaves == 2 && W.Inputs[208] == "Duck", "duplicate changes nothing");
	W.BeginFocusedBindingCapture();
	W.CancelKeySelection();
	Check(!W.bPolling && W.Inputs[208] == "Duck", "ordinary cancellation preserves bindings");
	W.Notify(Row, W.DE_RClick);
	Check(!W.bPolling && W.Inputs[208] == "" && W.Inputs[70] == "" && W.Inputs[71] == "", "right click clears without starting capture");
	W.Inputs[70] = "Fire";
	W.BeginFocusedBindingCapture();
	W.ProcessMenuKey(70, "F");
	Check(W.Inputs[70] == "Duck", "input reassigned from another action");
	W.Notify(Row, W.DE_MClick);
	Check(W.Inputs[70] == "Duck" && !W.bPolling, "idle middle click does not clear");
	W.BeginFocusedBindingCapture();
	W.Notify(Row, W.DE_MClick);
	Check(W.Inputs[4] == "Duck" && W.Inputs[70] == "Duck", "middle mouse can be captured as an input");
	W.ClearFocusedBinding();
	Check(W.Inputs[4] == "" && W.Inputs[70] == "", "focused clear removes every assignment");
	W.BeginFocusedBindingCapture();
	W.Notify(Row, W.DE_Click);
	Check(W.Inputs[1] == "Duck" && !W.bPolling, "second left click assigns left mouse");
	W.BeginFocusedBindingCapture();
	W.Notify(Row, W.DE_RClick);
	Check(W.Inputs[1] == "Duck" && W.Inputs[2] == "Duck", "right click during capture adds right mouse instead of clearing");
	W.BeginFocusedBindingCapture();
	W.ProcessMenuKey(27, "Escape");
	Check(!W.bPolling && W.Inputs[1] == "Duck" && W.Inputs[2] == "Duck", "Escape cancels without changes");
	Log("Binding regression failures: " $ Failures);
	return Failures;
}

defaultproperties
{
	IsClient=False
	IsServer=False
	IsEditor=True
	LogToStdout=True
}
