// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived

// VR-only hooks for the original PlayerPawn aim functions. This preserves the
// serialized pawn class used by existing saves and leaves flat play untouched.

class ModernVRAimHook extends ScriptHook;

function bool InstallHooks()
{
	local bool bAimInstalled;
	local bool bTossInstalled;

	if (bHasHooks)
		return True;
	bAimInstalled = SetHook(class'PlayerPawn'.static.FindFunction('AdjustAim'),
		HookAdjustAim);
	bTossInstalled = SetHook(class'PlayerPawn'.static.FindFunction('AdjustToss'),
		HookAdjustToss);
	return bAimInstalled && bTossInstalled;
}

function bool GetVRAimRotation(PlayerPawn Player, out rotator AimRotation)
{
	local rotator HeadRotation;

	if (Player == None
		|| !class'ModernVRAimSupport'.static.ReadHeadRotation(Player, HeadRotation))
		return False;
	AimRotation = class'ModernVRAimSupport'.static.ComposeRotation(
		Player.ViewRotation, HeadRotation);
	return True;
}

function bool HookAdjustAim(Object Context, out rotator Result,
	float ProjectileSpeed, vector ProjectileStart, int AimError,
	bool bLeadTarget, bool bWarnTarget)
{
	local PlayerPawn Player;
	local rotator AimRotation;
	local vector FireDirection, AimSpot, HitNormal, HitLocation;
	local actor BestTarget, HitActor;
	local float BestAim, BestDistance;

	Player = PlayerPawn(Context);
	if (!GetVRAimRotation(Player, AimRotation))
		return False;

	// Stock PlayerPawn.AdjustAim, using the headset-composed rotation.
	FireDirection = vector(AimRotation);
	HitActor = Player.Trace(HitLocation, HitNormal,
		ProjectileStart + 4000.0 * FireDirection, ProjectileStart, True);
	if (HitActor != None && HitActor.bProjTarget)
	{
		if (bWarnTarget && Pawn(HitActor) != None)
			Pawn(HitActor).WarnTarget(Player, ProjectileSpeed, FireDirection);
		Result = AimRotation;
		return True;
	}

	BestAim = FMin(0.93, Player.MyAutoAim);
	BestTarget = Player.PickTarget(BestAim, BestDistance, FireDirection,
		ProjectileStart);
	if (bWarnTarget && Pawn(BestTarget) != None)
		Pawn(BestTarget).WarnTarget(Player, ProjectileSpeed, FireDirection);

	if (Player.Level.NetMode != NM_Standalone
		|| Player.Level.Game.Difficulty > 2
		|| Player.bAlwaysMouseLook
		|| (BestTarget != None && BestAim < Player.MyAutoAim)
		|| Player.MyAutoAim >= 1)
	{
		Result = AimRotation;
		return True;
	}

	if (BestTarget == None)
	{
		BestAim = Player.MyAutoAim;
		BestTarget = Player.PickAnyTarget(BestAim, BestDistance,
			FireDirection, ProjectileStart);
		if (BestTarget == None)
		{
			Result = AimRotation;
			return True;
		}
	}

	AimSpot = ProjectileStart + FireDirection * BestDistance;
	AimSpot.Z = BestTarget.Location.Z + 0.3 * BestTarget.CollisionHeight;
	Result = rotator(AimSpot - ProjectileStart);
	return True;
}

function bool HookAdjustToss(Object Context, out rotator Result,
	float ProjectileSpeed, vector ProjectileStart, int AimError,
	bool bLeadTarget, bool bWarnTarget)
{
	local PlayerPawn Player;
	local rotator AimRotation;
	local vector FireDirection, Velocity, Gravity, Position, OldPosition;
	local vector HitNormal, HitLocation;
	local byte Step;
	local actor HitActor;
	local float BestAim, BestDistance;

	Player = PlayerPawn(Context);
	if (!GetVRAimRotation(Player, AimRotation))
		return False;

	// Stock PlayerPawn.AdjustToss warning path, using VR gaze.
	if (bWarnTarget && Player.Level.Game != None
		&& Player.Level.Game.Difficulty > 3)
	{
		FireDirection = vector(AimRotation);
		Velocity = FireDirection * ProjectileSpeed;
		Gravity = Player.Region.Zone.ZoneGravity;
		Position = ProjectileStart;
		OldPosition = ProjectileStart;
		for (Step = 0; Step < 8; ++Step)
		{
			Position += Velocity * 0.2;
			Velocity += Gravity * 0.2;
			HitActor = Player.Trace(HitLocation, HitNormal, Position,
				OldPosition, True);
			OldPosition = Position;
			if (HitActor != None)
			{
				if (HitActor.bProjTarget && Pawn(HitActor) != None)
					Pawn(HitActor).WarnTarget(Player, ProjectileSpeed,
						FireDirection);
				break;
			}
		}
		BestAim = 0.93;
		HitActor = Player.PickTarget(BestAim, BestDistance, FireDirection,
			ProjectileStart);
		if (Pawn(HitActor) != None)
			Pawn(HitActor).WarnTarget(Player, ProjectileSpeed, FireDirection);
	}
	Result = AimRotation;
	return True;
}
