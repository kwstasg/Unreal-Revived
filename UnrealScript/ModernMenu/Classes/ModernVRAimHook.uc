// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived

// VR-only hooks for the original PlayerPawn aim functions. This preserves the
// serialized pawn class used by existing saves and leaves flat play untouched.

class ModernVRAimHook extends ScriptHook;

function bool InstallHooks(optional PlayerPawn Player)
{
	local bool bAimInstalled;
	local bool bTossInstalled;

	if (bHasHooks)
		return True;
	bAimInstalled = SetHook(class'PlayerPawn'.static.FindFunction('AdjustAim'),
		HookAdjustAim);
	bTossInstalled = SetHook(class'PlayerPawn'.static.FindFunction('AdjustToss'),
		HookAdjustToss);
	if (Player != None)
	{
		bAimInstalled = BindMovement(Player, 'PlayerSwimming') && bAimInstalled;
		bAimInstalled = BindMovement(Player, 'PlayerFlying') && bAimInstalled;
		bAimInstalled = BindMovement(Player, 'CheatFlying') && bAimInstalled;
	}
	return bAimInstalled && bTossInstalled;
}

function bool BindMovement(PlayerPawn Player, name StateName)
{
	local int Index;
	// Use the same native state resolver as weapon hooks: 227's script
	// FindFunction does not find these state-local PlayerMove functions.
	Index = int(Player.ConsoleCommand("D3D12 VRSTATEFUNCTION Engine.PlayerPawn" @ string(StateName) @ "PlayerMove"));
	return Index >= 0 && SetHook(Function(FindObjectIndex(Index)), HookFreeMovement);
}

function bool GetMovementRotation(PlayerPawn Player, out rotator Aim)
{
	local rotator Head;
	if (Player == None || Player.Health <= 0 || Player.bBehindView
		|| Player.ViewTarget != None || Player.bShowMenu || Player.bFreeLook)
		return False;
	if (!class'ModernVRAimSupport'.static.ReadHeadRotation(Player, Head, True))
		return False;
	Aim = class'ModernVRAimSupport'.static.ComposeRotation(Player.ViewRotation, Head);
	return True;
}

function bool HookFreeMovement(Object Context, float DeltaTime)
{
	local PlayerPawn P;
	local rotator Aim, OldRotation;
	local vector X, Y, Z, NewAccel;
	local float Speed2D;
	local bool bSwimming, bFlying;
	P = PlayerPawn(Context);
	if (!GetMovementRotation(P, Aim)) return False;
	bSwimming = P.IsInState('PlayerSwimming');
	bFlying = P.IsInState('PlayerFlying');
	if (!bSwimming && !bFlying && !P.IsInState('CheatFlying')) return False;

	// Stock state movement and replication, using the head-composed basis
	// only for acceleration. Mouse/stick turning still updates the body view.
	GetAxes(Aim, X, Y, Z);
	P.aLookup *= 0.24;
	P.aTurn *= 0.24;
	if (bFlying)
	{
		P.aForward *= 0.2;
		P.aStrafe *= 0.2;
		NewAccel = P.aForward * X + P.aStrafe * Y + P.aUp * Z;
		if (P.bPressedJump && P.aUp <= 0.01) P.bPressedJump = False;
	}
	else
	{
		if (bSwimming) P.aForward *= 0.2;
		else P.aForward *= 0.1;
		P.aStrafe *= 0.1;
		P.aUp *= 0.1;
		NewAccel = P.aForward * X + P.aStrafe * Y + P.aUp * vect(0,0,1);
		if (bSwimming)
		{
			Speed2D = Sqrt(P.Velocity.X * P.Velocity.X + P.Velocity.Y * P.Velocity.Y);
			P.WalkBob = Y * P.Bob * 0.5 * Speed2D * sin(4.0 * P.Level.TimeSeconds);
			P.WalkBob.Z = P.Bob * 1.5 * Speed2D * sin(8.0 * P.Level.TimeSeconds);
		}
	}
	OldRotation = P.Rotation;
	if (!bSwimming) P.Acceleration = NewAccel;
	if (bSwimming || bFlying) P.UpdateRotation(DeltaTime, 2);
	else P.UpdateRotation(DeltaTime, 1);
	if (!bFlying)
	{
		if (!bSwimming || P.SupportsRealCrouching()) P.bPressedJump = False;
		if (P.SupportsRealCrouching()) P.RealCrouchInfo.HandleVerticalMovement(P.aUp);
	}
	if (bSwimming) OldRotation -= P.Rotation;
	else OldRotation = rot(0,0,0);
	if (P.Role < ROLE_Authority)
		P.ReplicateMove(DeltaTime, NewAccel, DODGE_None, OldRotation);
	else
		P.ProcessMove(DeltaTime, NewAccel, DODGE_None, OldRotation);
	if (bSwimming && !P.SupportsRealCrouching()) P.bPressedJump = False;
	return True;
}

function bool GetVRAimRotation(PlayerPawn Player, out rotator AimRotation)
{
	local rotator HeadRotation;
	local vector Hand;
	local float Scale;

	if (Player != None && class'ModernVRMotionSupport'.default.FiringPlayer == Player)
	{
		AimRotation = Player.ViewRotation;
		return True;
	}
	if (class'ModernVRMotionSupport'.static.IsSelected(Player))
		return class'ModernVRMotionSupport'.static.ReadFrame(Player, AimRotation, Hand, Scale);

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

	if (class'ModernVRMotionSupport'.default.FiringPlayer == Player
		|| Player.Level.NetMode != NM_Standalone
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
