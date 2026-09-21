class ModernVRWeaponTestInteraction extends ModernVRInteraction;

function bool ReadHeadPose(out rotator HeadRotation, out vector EyeOffset, out vector HeadOffset,
	out float HeightOffset, out float BodyScale, optional bool bHeadCenter)
{
	HeadRotation = rot(1000,3000,0);
	HeadOffset = vect(2,3,1);
	EyeOffset = HeadOffset;
	HeightOffset = 2;
	BodyScale = 0.9;
	return True;
}

defaultproperties
{
	bPlayerCalcView=False
	bRenderOverlays=False
}