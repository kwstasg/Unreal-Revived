// Unreal Revived
// Regression checks against the installed UWindow slider implementation.
class ModernSliderTestCommandlet extends Commandlet;

var int Failures;

function CheckValue(UWindowHSliderControl Slider, float Expected)
{
	if (Slider.Value != Expected)
	{
		Log("FAIL: expected " $ Expected $ ", got " $ Slider.Value);
		++Failures;
	}
}

event int Main(string Params)
{
	local UWindowHSliderControl Slider;
	local int Expected;
	Slider = new class'ModernSignedSliderControl';
	Slider.SetRange(-75, 150, 5);
	Slider.SetValue(-1000, True);
	CheckValue(Slider, -75);
	// The analog-stick path uses the same Value +/- Step updates as KeyDown.
	for (Expected = -70; Expected <= 150; Expected += 5)
	{
		Slider.SetValue(Slider.Value + Slider.Step, True);
		CheckValue(Slider, Expected);
	}
	Slider.SetValue(1000, True);
	CheckValue(Slider, 150);
	for (Expected = 145; Expected >= -75; Expected -= 5)
	{
		Slider.SetValue(Slider.Value - Slider.Step, True);
		CheckValue(Slider, Expected);
	}
	Slider.SetValue(-72, True);
	CheckValue(Slider, -70);
	Slider.SetValue(-73, True);
	CheckValue(Slider, -75);
	Slider.SetValue(0, True);
	CheckValue(Slider, 0);
	Log("Signed slider regression failures: " $ Failures);
	return Failures;
}

defaultproperties
{
	IsClient=False
	IsServer=False
	IsEditor=True
	LogToStdout=True
}
