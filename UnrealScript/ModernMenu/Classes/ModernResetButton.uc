class ModernResetButton extends UWindowComboButton;

function BeforePaint(Canvas C, float X, float Y)
{
	LookAndFeel.Combo_GetButtonBitmaps(Self);
	WinWidth = UpRegion.W;
	WinHeight = UpRegion.H;
}

function Paint(Canvas C, float X, float Y)
{
	DrawUpBevel(C, 0, 0, WinWidth, WinHeight, GetLookAndFeelTexture());
}

function LMouseDown(float X, float Y)
{
	if (!bDisabled)
	{
		ActivateWindow(0, False);
		bMouseDown = True;
	}
}

function Click(float X, float Y)
{
	Notify(DE_Click);
}

defaultproperties
{
	bNoKeyboard=True
}