// Unreal Revived - VR weapon firing hooks, inert in desktop mode.
class ModernVRMotionHook extends ScriptHook;

var bool bInsideWeapon;
var bool bInsidePostRender;
var bool bInsideASMDTraceHit;
var class<Weapon> LastWeaponClass;
var name LastWeaponState;
var array<Function> BoundFunctions;
var vector SavedFireOffset;
var vector ShotStart;
var rotator ShotAim;
var PlayerPawn HookPlayer;

struct ResolvedWeaponFunction
{
	var class<Weapon> WeaponClass;
	var name FunctionName, StateName;
	var Function Target;
};
var array<ResolvedWeaponFunction> ResolvedFunctions;

function BindOnce(Function Target, byte Kind)
{
	local int I;
	local bool Installed;
	if (Target == None) return;
	for (I = 0; I < Array_Size(BoundFunctions); I++)
		if (BoundFunctions[I] == Target) return;
	switch (Kind)
	{
		case 1: Installed = SetHook(Target, HookFire); break;
		case 2: Installed = SetHook(Target, HookAltFire); break;
		case 3: Installed = SetHook(Target, HookProjectileFire); break;
		case 4: Installed = SetHook(Target, HookTraceFire); break;
		case 5: Installed = SetHook(Target, HookBeginState); break;
		case 6: Installed = SetHook(Target, HookCheckTarget); break;
		case 7: Installed = SetHook(Target, HookWeaponPostRender); break;
		case 8: Installed = SetHook(Target, HookASMDTraceHit); break;
	}
	if (Installed)
	{
		I = Array_Size(BoundFunctions);
		Array_Size(BoundFunctions, I + 1);
		BoundFunctions[I] = Target;
	}
}

function Function FindWeaponFunction(class<Weapon> WeaponClass, name FunctionName, optional name StateName)
{
	local Function Target;
	local int FunctionIndex, CacheIndex;
	for (CacheIndex = 0; CacheIndex < Array_Size(ResolvedFunctions); CacheIndex++)
		if (ResolvedFunctions[CacheIndex].WeaponClass == WeaponClass
			&& ResolvedFunctions[CacheIndex].FunctionName == FunctionName
			&& ResolvedFunctions[CacheIndex].StateName == StateName)
			return ResolvedFunctions[CacheIndex].Target;
	if (StateName != '')
	{
		if (HookPlayer != None)
		{
			FunctionIndex = int(HookPlayer.ConsoleCommand("D3D12 VRWEAPONFUNCTION" @ string(WeaponClass) @ string(StateName) @ string(FunctionName)));
			if (FunctionIndex >= 0) Target = Function(FindObjectIndex(FunctionIndex));
		}
	}
	if (Target == None && (StateName == '' || FunctionName != 'BeginState'))
		Target = WeaponClass.static.FindFunction(FunctionName);
	if (StateName != '' && HookPlayer == None) return Target;
	CacheIndex = Array_Size(ResolvedFunctions);
	Array_Size(ResolvedFunctions, CacheIndex + 1);
	ResolvedFunctions[CacheIndex].WeaponClass = WeaponClass;
	ResolvedFunctions[CacheIndex].FunctionName = FunctionName;
	ResolvedFunctions[CacheIndex].StateName = StateName;
	ResolvedFunctions[CacheIndex].Target = Target;
	return Target;
}

function BindWeaponClass(class<Weapon> WeaponClass, optional name StateName)
{
	// Only class functions: state-specific Fire/AltFire are often intentional
	// no-ops. Keep their dispatch and all weapon state transitions untouched.
	BindOnce(WeaponClass.static.FindFunction('Fire'), 1);
	BindOnce(WeaponClass.static.FindFunction('AltFire'), 2);
	BindOnce(FindWeaponFunction(WeaponClass, 'ProjectileFire', StateName), 3);
	BindOnce(FindWeaponFunction(WeaponClass, 'TraceFire', StateName), 4);
	if (ClassIsChildOf(WeaponClass, class'ASMD'))
		BindOnce(class'ASMD'.static.FindFunction('ProcessTraceHit'), 8);
	// These stock/UPak weapons spawn directly when entering a firing state.
	if (ClassIsChildOf(WeaponClass, class'Eightball'))
	{
		BindOnce(FindWeaponFunction(WeaponClass, 'BeginState', 'FireRockets'), 5);
		BindOnce(WeaponClass.static.FindFunction('CheckTarget'), 6);
		BindOnce(WeaponClass.static.FindFunction('PostRender'), 7);
	}
	if (ClassIsChildOf(WeaponClass, class'DispersionPistol'))
		BindOnce(FindWeaponFunction(WeaponClass, 'BeginState', 'ShootLoad'), 5);
	if (ClassIsChildOf(WeaponClass, class'GrenadeLauncher'))
	{
		BindOnce(FindWeaponFunction(WeaponClass, 'BeginState', 'NormalFire'), 5);
		BindOnce(FindWeaponFunction(WeaponClass, 'BeginState', 'AltFiring'), 5);
	}
	// Bind before entering AltFiring, which can immediately call this override.
	if (ClassIsChildOf(WeaponClass, class'RazorJack') || ClassIsChildOf(WeaponClass, class'Stinger'))
		BindOnce(FindWeaponFunction(WeaponClass, 'ProjectileFire', 'AltFiring'), 3);
}

function EnsureHooks(PlayerPawn Player)
{
	HookPlayer = Player;
	if (!bHasHooks)
	{
		LastWeaponClass = None;
		Array_Size(BoundFunctions, 0);
		Array_Size(ResolvedFunctions, 0);
	}
	if (Player.Weapon == None || (LastWeaponClass == Player.Weapon.Class && LastWeaponState == Player.Weapon.GetStateName()))
		return;
	LastWeaponClass = Player.Weapon.Class;
	LastWeaponState = Player.Weapon.GetStateName();
	// Base and subclass entry points retain their original implementations.
	BindWeaponClass(LastWeaponClass);
	BindWeaponClass(LastWeaponClass, LastWeaponState);
}

function bool HookBeginState(Object Context)
{
	local Weapon W;
	local rotator Saved;
	local int Allow;
	W = Weapon(Context);
	if (W != None && bInsideWeapon && class'ModernVRMotionSupport'.default.FiringPlayer == W.Owner)
	{
		if (Eightball(W) != None && FindWeaponFunction(W.Class, 'BeginState', W.GetStateName())
			== FindWeaponFunction(class'Eightball', 'BeginState', 'FireRockets'))
		{
			FireEightballVolley(Eightball(W));
			return True;
		}
		if (GrenadeLauncher(W) != None && (W.IsInState('NormalFire') || W.IsInState('AltFiring'))
			&& FindWeaponFunction(W.Class, 'BeginState', W.GetStateName())
				== FindWeaponFunction(class'GrenadeLauncher', 'BeginState', W.GetStateName()))
		{
			FireLauncherGrenade(GrenadeLauncher(W));
			return True;
		}
	}
	if (W == None || !BeginWeapon(W, Saved, Allow)) return False;
	if (Allow != 0)
	{
		W.BeginState();
		EndWeapon(W, Saved);
	}
	else
		CancelBlockedShot(W);
	return True;
}

function FireEightballVolley(Eightball W)
{
	local PlayerPawn Player;
	local Pawn BestTarget;
	local Rocket Missile;
	local Grenade Bomb;
	local rotator FireRotation;
	local vector Forward, Right, Up;
	local float Angle;
	local int ExtraRockets;
	Player = PlayerPawn(W.Owner);
	ExtraRockets = Max(0, W.RocketsLoaded - 1);
	Player.ShakeView(W.ShakeTime, W.ShakeMag * W.RocketsLoaded, W.ShakeVert);
	Player.ClientInstantFlash(-0.4, vect(650,450,190));
	if (W.bFireLoad)
		W.AdjustedAim = Player.AdjustAim(W.ProjectileSpeed, ShotStart, W.AimError, True, W.bWarnTarget);
	else
		W.AdjustedAim = Player.AdjustToss(W.AltProjectileSpeed, ShotStart, W.AimError, True, W.bAltWarnTarget);
	GetAxes(W.AdjustedAim, Forward, Right, Up);
	W.PlayAnim('Fire', 0.6, 0.05);
	Player.MakeNoise(Player.SoundDampening);
	if (W.FiringSpeed > 0) Player.PlayRecoil(W.FiringSpeed);
	if (W.LockedTarget != None || !W.bFireLoad)
	{
		BestTarget = Pawn(W.CheckTarget());
		if (W.LockedTarget != None && W.LockedTarget != BestTarget)
		{
			W.LockedTarget = None;
			W.bLockedOn = False;
		}
	}
	FireRotation = W.AdjustedAim;
	W.bPointing = True;
	W.RocketRad = 4;
	if (W.bTightWad || !W.bFireLoad) W.RocketRad = 7;
	while (W.RocketsLoaded > 0)
	{
		if (W.bFireLoad)
		{
			if (Angle > 0 && !W.bTightWad)
			{
				if (W.Level.Game.bUseClassicBalance)
				{
					if (Angle < 3) FireRotation.Yaw = W.AdjustedAim.Yaw - Angle * 600;
					else if (Angle > 3.5) FireRotation.Yaw = W.AdjustedAim.Yaw + (Angle - 3) * 600;
					else FireRotation.Yaw = W.AdjustedAim.Yaw;
				}
				else if (Angle < 3) FireRotation = rotator(Forward - Right * (Angle / 16));
				else if (Angle > 3.5) FireRotation = rotator(Forward + Right * ((Angle - 3) / 16));
				else FireRotation = W.AdjustedAim;
			}
			if (W.LockedTarget != None)
			{
				Missile = W.Spawn(class'SeekingRocket',,, ShotStart, FireRotation);
				if (Missile != None) Missile.Seeking = W.LockedTarget;
			}
			else
			{
				Missile = W.Spawn(class'Rocket',,, ShotStart, FireRotation);
				if (Missile != None && W.RocketsLoaded > 5 && W.bTightWad) Missile.bRing = True;
			}
			if (Missile != None)
			{
				Missile.NumExtraRockets = ExtraRockets;
				if (Angle > 0) Missile.Velocity *= 0.9 + 0.2 * FRand();
			}
		}
		else
		{
			Bomb = W.Spawn(class'Grenade',,, ShotStart, W.AdjustedAim);
			if (Bomb != None)
			{
				Bomb.WarnTarget = ScriptedPawn(BestTarget);
				Bomb.NumExtraGrenades = ExtraRockets;
			}
			Player.PlaySound(W.AltFireSound, SLOT_None, 3 * Player.SoundDampening);
		}
		Angle += 2 * Pi / 6;
		W.RocketsLoaded--;
	}
	W.bTightWad = False;
}

function FireLauncherGrenade(GrenadeLauncher W)
{
	local PlayerPawn Player;
	Player = PlayerPawn(W.Owner);
	W.AdjustedAim = Player.AdjustToss(W.AltProjectileSpeed, ShotStart, W.AimError, True, W.bAltWarnTarget);
	W.AdjustedAim = ShotAim;
	if (W.IsInState('AltFiring'))
	{
		W.DetGrenade = W.Spawn(class'GLDetGrenade',,, ShotStart, W.AdjustedAim);
		if (W.DetGrenade != None) W.DetGrenade.GL = W;
		W.PlayAnim('Fire', 0.6, 0.05);
		W.TrapLocation = None;
		W.bDetGrenadeActive = W.DetGrenade != None;
		Player.bAltFire = 0;
		W.Disable('Tick');
		W.SetTimer(0.5, False);
	}
	else W.Spawn(class'GLGrenade',,, ShotStart, W.AdjustedAim);
	if (!Player.HeadRegion.Zone.bWaterZone)
		W.Spawn(class'GLFirePuff',,, ShotStart, W.AdjustedAim);
	Player.PlaySound(W.AltFireSound, SLOT_None, 3 * Player.SoundDampening);
	Player.ShakeView(W.ShakeTime, W.ShakeMag * 5, W.ShakeVert * 5);
}

function bool HookCheckTarget(Object Context, out Actor Result)
{
	local Eightball W;
	local rotator Saved;
	local int Allow;
	W = Eightball(Context);
	if (W == None || !BeginWeapon(W, Saved, Allow)) return False;
	Result = None;
	if (Allow != 0)
	{
		Result = W.CheckTarget();
		EndWeapon(W, Saved);
	}
	return True;
}

function bool HookWeaponPostRender(Object Context, Canvas C)
{
	local Weapon W;
	local PlayerPawn Player;
	local float X, Y, SavedX, SavedY;
	W = Weapon(Context);
	if (W == None || bInsidePostRender) return False;
	Player = PlayerPawn(W.Owner);
	if (Player == None) return False;
	if (class'ModernVRMotionSupport'.static.IsSelected(Player))
	{
		if (!class'ModernVRMotionSupport'.static.CrosshairPosition(Player, C, X, Y)) return True;
	}
	else
	{
		// Eightball owns its reticle instead of calling HUD.DrawCrossHair.
		if (Left(Player.ConsoleCommand("D3D12 OPENXRPOSE"), 1) != "1") return False;
		if (!class'ModernVRAimSupport'.static.CrosshairPosition(Player, C, X, Y)) return True;
	}
	SavedX = C.OrgX;
	SavedY = C.OrgY;
	C.SetOrigin(SavedX + X + 8 - C.ClipX * 0.5, SavedY + Y + 8 - C.ClipY * 0.5);
	bInsidePostRender = True;
	W.PostRender(C);
	bInsidePostRender = False;
	C.SetOrigin(SavedX, SavedY);
	return True;
}

function ModernVRInteraction FindGazeInteraction(PlayerPawn Player)
{
	return ModernVRInteraction(Player.FindInteraction(class'ModernVRInteraction'));
}

function bool GetShotPose(Weapon W, out vector Start, out rotator Aim, out int Blocked)
{
	local PlayerPawn Player;
	local ModernVRInteraction Interaction;
	Player = PlayerPawn(W.Owner);
	if (!class'ModernVRMotionSupport'.static.IsSelected(Player))
	{
		if (!class'ModernVRMotionSupport'.static.IsLocalPlayer(Player)
			|| (!ClassIsChildOf(W.Class, class'DispersionPistol') && !ClassIsChildOf(W.Class, class'Stinger')
				&& !ClassIsChildOf(W.Class, class'ASMD') && !ClassIsChildOf(W.Class, class'AutoMag')
				&& !ClassIsChildOf(W.Class, class'Eightball') && !ClassIsChildOf(W.Class, class'FlakCannon')
				&& !ClassIsChildOf(W.Class, class'Rifle') && !ClassIsChildOf(W.Class, class'Minigun')
				&& !ClassIsChildOf(W.Class, class'RazorJack') && !ClassIsChildOf(W.Class, class'GESBioRifle')
				&& !ClassIsChildOf(W.Class, class'QuadShot') && !ClassIsChildOf(W.Class, class'CARifle')
				&& !ClassIsChildOf(W.Class, class'GrenadeLauncher') && !ClassIsChildOf(W.Class, class'RocketLauncher')))
			return False;
		Interaction = FindGazeInteraction(Player);
		return Interaction != None && Interaction.GetGazeMuzzle(Start, Aim, Blocked);
	}
	Blocked = 1;
	class'ModernVRMotionSupport'.static.GetMuzzle(Player, Start, Aim, Blocked);
	return True;
}

function bool BeginWeapon(Weapon W, out rotator Saved, out int Allow)
{
	local PlayerPawn Player;
	local rotator Aim;
	local vector Start;
	local int Blocked;
	Player = PlayerPawn(W.Owner);
	if (bInsideWeapon || Player == None || Player.Weapon != W || W.Role < ROLE_Authority)
		return False;
	if (!GetShotPose(W, Start, Aim, Blocked)) return False;
	Allow = int(Blocked == 0);
	if (Allow == 0)
		return True;
	Saved = Player.ViewRotation;
	class'ModernVRMotionSupport'.default.BodyRotation = Saved;
	class'ModernVRMotionSupport'.default.FiringPlayer = Player;
	Player.ViewRotation = Aim;
	bInsideWeapon = True;
	SavedFireOffset = W.FireOffset;
	ShotStart = Start;
	ShotAim = Aim;
	W.FireOffset = (Start - Player.Location - W.CalcDrawOffset()) << Aim;
	return True;
}

function EndWeapon(Weapon W, rotator Saved)
{
	if (class'ModernVRMotionSupport'.default.FiringPlayer != None)
	{
		W.FireOffset = SavedFireOffset;
		class'ModernVRMotionSupport'.default.FiringPlayer.ViewRotation = Saved;
	}
	class'ModernVRMotionSupport'.default.FiringPlayer = None;
	bInsideWeapon = False;
}

function CancelBlockedShot(Weapon W)
{
	// A swallowed Global.Fire must still leave the finished firing state.
	// Otherwise its latent script ends there and PutDown can remain deferred.
	if (Pawn(W.Owner) != None)
	{
		Pawn(W.Owner).bFire = 0;
		Pawn(W.Owner).bAltFire = 0;
	}
	W.GotoState('Idle');
	if (W.bChangeWeapon)
		W.PutDown();
}

function bool HookFire(Object Context, float Value)
{
	local Weapon W;
	local rotator Saved;
	local int Allow;
	W = Weapon(Context);
	if (W == None || !BeginWeapon(W, Saved, Allow)) return False;
	if (Allow != 0)
	{
		PlayerPawn(W.Owner).ConsoleCommand("D3D12 VRWEAPONFIRE 0" @ Value);
		EndWeapon(W, Saved);
	}
	else
		CancelBlockedShot(W);
	return True;
}

function bool HookAltFire(Object Context, float Value)
{
	local Weapon W;
	local rotator Saved;
	local int Allow;
	W = Weapon(Context);
	if (Rifle(W) != None || QuadShot(W) != None
		|| (GrenadeLauncher(W) != None && GrenadeLauncher(W).DetGrenade != None
			&& (GrenadeLauncher(W).bDetGrenadeActive || !GrenadeLauncher(W).bAltFireOff)))
		return False;
	if (W == None || !BeginWeapon(W, Saved, Allow)) return False;
	if (Allow != 0)
	{
		PlayerPawn(W.Owner).ConsoleCommand("D3D12 VRWEAPONFIRE 1" @ Value);
		EndWeapon(W, Saved);
	}
	else
		CancelBlockedShot(W);
	return True;
}

function bool HookProjectileFire(Object Context, out Projectile Result, class<Projectile> ProjClass, float ProjSpeed, bool bWarn)
{
	local Weapon W;
	local rotator Saved;
	local int Allow;
	W = Weapon(Context);
	if (W != None && bInsideWeapon && class'ModernVRMotionSupport'.default.FiringPlayer == W.Owner
		&& ((ClassIsChildOf(W.Class, class'RazorJack') && !W.IsInState('AltFiring')
			&& FindWeaponFunction(W.Class, 'ProjectileFire', W.GetStateName()) == class'RazorJack'.static.FindFunction('ProjectileFire'))
			|| (ClassIsChildOf(W.Class, class'RocketLauncher')
				&& FindWeaponFunction(W.Class, 'ProjectileFire', W.GetStateName()) == class'RocketLauncher'.static.FindFunction('ProjectileFire'))))
	{
		if (RazorJack(W) != None)
			PlayerPawn(W.Owner).ClientInstantFlash(-0.4, vect(500,0,650));
		W.Owner.MakeNoise(Pawn(W.Owner).SoundDampening);
		W.AdjustedAim = Pawn(W.Owner).AdjustAim(ProjSpeed, ShotStart, W.AimError, True, bWarn);
		if (RocketLauncher(W) != None)
			Result = W.Spawn(ProjClass, W.Owner,, ShotStart, W.AdjustedAim);
		else
			Result = W.Spawn(ProjClass,,, ShotStart, W.AdjustedAim);
		return True;
	}
	if (W == None || !BeginWeapon(W, Saved, Allow)) return False;
	Result = None;
	if (Allow != 0)
	{
		Result = W.ProjectileFire(ProjClass, ProjSpeed, bWarn);
		EndWeapon(W, Saved);
	}
	return True;
}

function bool HookASMDTraceHit(Object Context, Actor Other, vector HitLocation, vector HitNormal, vector X, vector Y, vector Z)
{
	local ASMD W;
	local vector OriginalOffset;
	W = ASMD(Context);
	if (W == None || bInsideASMDTraceHit || !bInsideWeapon
		|| class'ModernVRMotionSupport'.default.FiringPlayer != W.Owner)
		return False;
	OriginalOffset = W.FireOffset;
	W.FireOffset.Y /= 3.3;
	W.FireOffset.Z /= 3.0;
	bInsideASMDTraceHit = True;
	W.ProcessTraceHit(Other, HitLocation, HitNormal, X, Y, Z);
	bInsideASMDTraceHit = False;
	W.FireOffset = OriginalOffset;
	return True;
}

function bool HookTraceFire(Object Context, float Accuracy)
{
	local Weapon W;
	local rotator Saved;
	local int Allow;
	W = Weapon(Context);
	if (W == None || !BeginWeapon(W, Saved, Allow)) return False;
	if (Allow != 0)
	{
		W.TraceFire(Accuracy);
		EndWeapon(W, Saved);
	}
	return True;
}
