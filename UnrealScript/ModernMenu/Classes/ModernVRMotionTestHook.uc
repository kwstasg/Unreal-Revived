// Force the production synchronous wrapper on without requiring a headset.
class ModernVRMotionTestHook extends ModernVRMotionHook;
var bool bDenyShot;
var bool bForceMuzzle;
var bool bUseGazePose;
var ModernVRInteraction GazeInteraction;
var vector ForcedMuzzle;
var vector BeamStart;
var int BeamSamples;
var int TraceSamples;
var vector TraceStart, TraceDirection;

function bool CaptureTrace(Object Context, out Actor Result, out vector HitLocation, out vector HitNormal,
	vector EndTrace, vector StartTrace)
{
	if (Context == HookPlayer && class'ModernVRMotionSupport'.default.FiringPlayer == HookPlayer)
	{
		TraceSamples++;
		TraceStart = StartTrace;
		TraceDirection = Normal(EndTrace - StartTrace);
	}
	return False;
}

function bool CaptureASMDBeam(Object Context, vector DVector, int NumPoints, rotator SmokeRotation, vector SmokeLocation)
{
	if (NumPoints > 0)
	{
		BeamStart = SmokeLocation - DVector / NumPoints;
		BeamSamples++;
	}
	return False;
}

function ModernVRInteraction FindGazeInteraction(PlayerPawn Player)
{
	return GazeInteraction;
}

function bool GetShotPose(Weapon W, out vector Start, out rotator Aim, out int Blocked)
{
	if (bUseGazePose)
	{
		if (!Super.GetShotPose(W, Start, Aim, Blocked)) return False;
		if (bDenyShot) Blocked = 1;
		return True;
	}
	if (!bForceMuzzle) return False;
	Start = ForcedMuzzle;
	Aim = Pawn(W.Owner).ViewRotation;
	Blocked = int(bDenyShot);
	return True;
}

function bool BeginWeapon(Weapon W, out rotator Saved, out int Allow)
{
	if (bForceMuzzle || bUseGazePose) return Super.BeginWeapon(W, Saved, Allow);
	if (bInsideWeapon) return False;
	if (bDenyShot)
	{
		Allow = 0;
		return True;
	}
	Allow = 1;
	bInsideWeapon = True;
	return True;
}
