// Run on a disposable map/profile, never selected by normal game startup.
class ModernVRMotionTestGame extends SinglePlayer;

var int Failures;
var PlayerPawn TestPlayer;
var ModernVRMotionTestHook TestHook;
var ModernVRAimHook AimHook;

function Check(bool Passed, string Description)
{
	if (!Passed) Failures++;
	Log("VRMOTION " $ string(Passed) @ Description);
}

event PostLogin(PlayerPawn NewPlayer)
{
	Super.PostLogin(NewPlayer);
	TestPlayer = NewPlayer;
	SetTimer(1, False);
}

function RunTests()
{
	local ModernVRMotionTestWeapon W;
	local ModernVRWeaponTuning SavedSettings, NeutralSettings;
	local int HookCount, ResolverCount;
	Log("VRMOTION network mode " $ string(Level.NetMode));
	Log("VRMOTION listen server " $ string(Level.NetMode == NM_ListenServer));
	SavedSettings = class'ModernVRWeaponTuning'.static.GetSettings();
	Log("VRMOTION runtime tuning profile count: " $ Array_Size(SavedSettings.Profiles));
	NeutralSettings = new class'ModernVRWeaponTuning';
	Array_Size(NeutralSettings.Profiles, 0);
	class'ModernVRWeaponTuning'.default.Settings = NeutralSettings;
	TestHook = new class'ModernVRMotionTestHook';
	AimHook = new class'ModernVRAimHook';
	Check(AimHook.InstallHooks(), "production aim hooks installed for firing direction checks");
	Check(TestHook.SetHook(class'Pawn'.static.FindFunction('TraceShot'), TestHook.CaptureTrace),
		"real hitscan trace observation hook installed");
	W = Spawn(class'ModernVRMotionTestWeapon', TestPlayer);
	TestPlayer.Weapon = W;
	TestHook.EnsureHooks(TestPlayer);
	TestHook.BindWeaponClass(class'Eightball');
	TestHook.BindWeaponClass(class'RazorJack');
	TestHook.BindWeaponClass(class'GrenadeLauncher');
	HookCount = Array_Size(TestHook.BoundFunctions);
	ResolverCount = Array_Size(TestHook.ResolvedFunctions);
	Check(HookCount >= 10, "stock and UPak state hooks register through the native resolver");
	TestHook.BindWeaponClass(class'Eightball');
	TestHook.BindWeaponClass(class'RazorJack');
	TestHook.BindWeaponClass(class'GrenadeLauncher');
	Check(HookCount == Array_Size(TestHook.BoundFunctions), "state hook registration does not accumulate duplicates");
	Check(ResolverCount == Array_Size(TestHook.ResolvedFunctions), "repeated binding reuses resolved state functions");
	W.GotoState('TestFiring');
	W.RefireGlobal();
	W.RefireGlobal();
	Check(W.Shots == 2, "Global.Fire reaches class implementation during a firing state");
	W.RefireAltGlobal();
	W.RefireAltGlobal();
	Check(W.AltShots == 2, "Global.AltFire reaches class implementation during a firing state");
	W.Fire(0);
	Check(W.Shots == 2, "direct state Fire remains ignored");
	TestHook.bDenyShot = True;
	TestPlayer.bFire = 1;
	W.RefireGlobal();
	Check(W.IsInState('Idle') && TestPlayer.bFire == 0, "blocked refire leaves a usable idle weapon");
	W.GotoState('TestFiring');
	W.bChangeWeapon = True;
	W.RefireGlobal();
	Check(W.IsInState('DownWeapon'), "blocked refire honours a pending weapon switch");
	TestHook.bDenyShot = False;
	W.Destroy();
	TestPlayer.Weapon = None;
	TestRefire(class'DispersionPistol');
	TestRefire(class'AutoMag');
	TestRefire(class'ASMD');
	TestRefire(class<Weapon>(DynamicLoadObject("OldWeapons.OldDispersionPistol", class'Class')));
	TestRefire(class<Weapon>(DynamicLoadObject("OldWeapons.OldAutoMag", class'Class')));
	TestProjectileOrigin(class'DispersionPistol');
	TestProjectileOrigin(class'Stinger');
	TestProjectileOrigin(class'ASMD');
	TestProjectileOrigin(class'RazorJack');
	TestProjectileOrigin(class'GESBioRifle');
	TestProjectileOrigin(class'RocketLauncher');
	TestHook.GazeInteraction = ModernVRInteraction(TestPlayer.AddInteraction(class'ModernVRWeaponTestInteraction', True));
	TestGazeHandedOffsets();
	TestRocketHandedBarrel(class'RocketLauncher', 0.8);
	TestRocketHandedBarrel(class'Eightball', 1.1);
	TestRazorAnimatedBarrel();
	TestProjectileOrigin(class'DispersionPistol', True);
	TestProjectileOrigin(class'Stinger', True);
	TestProjectileOrigin(class'ASMD', True);
	TestProjectileOrigin(class'RazorJack', True);
	TestProjectileOrigin(class'GESBioRifle', True);
	TestProjectileOrigin(class'RocketLauncher', True);
	LogBounds(class'DispersionPistol');
	LogBounds(class'AutoMag');
	LogBounds(class'Stinger');
	LogBounds(class'ASMD');
	TestStockBarrelCalibration(class'Stinger');
	TestStockBarrelCalibration(class'ASMD');
	TestDispersionBarrel();
	TestRemainingBarrels(SavedSettings);
	LogBounds(class'Eightball');
	LogBounds(class'FlakCannon');
	LogBounds(class'Rifle');
	TestPistolCalibration(class'AutoMag');
	TestPistolCalibration(class<Weapon>(DynamicLoadObject("OldWeapons.OldAutoMag", class'Class')));
	TestWeaponTuning();
	TestIndependentSizes(SavedSettings);
	BenchmarkProfileLookup();
	BenchmarkFunctionResolution();
	TestFreeMovement();
	class'ModernVRWeaponTuning'.default.Settings = SavedSettings;
	Log("VRMOTION regression failures: " $ Failures);
}

function TestFreeMovement()
{
	local ModernVRMovementTestHook MoveHook;
	local int StateIndex, Direction;
	local name MoveState;
	local vector Expected;
	local rotator SavedView;
	MoveHook = new class'ModernVRMovementTestHook';
	Check(MoveHook.InstallHooks(TestPlayer), "movement hooks installed");
	MoveHook.bPoseActive = True;
	SavedView = TestPlayer.ViewRotation;
	TestPlayer.ViewRotation = rot(12000,16384,4000);
	TestPlayer.aLookUp = 100;
	TestPlayer.aMouseY = 50;
	class'ModernVRAimSupport'.static.LevelBasePitch(TestPlayer);
	Check(TestPlayer.ViewRotation == rot(0,16384,0), "VR pitch recovery levels mouse-play saves and preserves yaw");
	Check(TestPlayer.aLookUp == 0 && TestPlayer.aMouseY == 0, "pitch recovery clears pending vertical input");
	for (StateIndex = 0; StateIndex < 3; StateIndex++)
	{
		if (StateIndex == 0) MoveState = 'PlayerSwimming';
		else if (StateIndex == 1) MoveState = 'PlayerFlying';
		else MoveState = 'CheatFlying';
		for (Direction = 0; Direction < 4; Direction++)
		{
			TestPlayer.GotoState(MoveState);
			TestPlayer.ViewRotation = rot(0,0,0);
			TestPlayer.aForward = 100;
			TestPlayer.aStrafe = 0;
			TestPlayer.aUp = 0;
			TestPlayer.aTurn = 0;
			TestPlayer.aLookup = 0;
			MoveHook.TestHead = rot(0,16384,0);
			if (Direction == 1) MoveHook.TestHead.Pitch = 8192;
			if (Direction == 2) MoveHook.TestHead.Pitch = -8192;
			if (Direction == 3) TestPlayer.aForward = -100;
			Expected = vector(MoveHook.TestHead);
			if (Direction == 3) Expected *= -1;
			TestPlayer.PlayerTick(0);
			Log("VRMOVE state=" $ TestPlayer.GetStateName() $ " acceleration=" $ TestPlayer.Acceleration $ " expected=" $ Expected);
			Check(VSize(Normal(TestPlayer.Acceleration) - Expected) < 0.01,
				string(MoveState) $ " follows gaze, direction " $ Direction);
			Check(TestPlayer.ViewRotation == rot(0,0,0), "movement preserves base view rotation");
		}
	}
	MoveHook.bPoseActive = False;
	TestPlayer.GotoState('PlayerFlying');
	TestPlayer.aForward = 100;
	TestPlayer.aStrafe = 0;
	TestPlayer.aUp = 0;
	TestPlayer.PlayerTick(0);
	Check(Normal(TestPlayer.Acceleration) Dot vect(1,0,0) > 0.99, "inactive VR keeps stock flying direction");
	TestPlayer.GotoState('PlayerWalking');
	TestPlayer.ViewRotation = SavedView;
}

function TestGazeHandedOffsets()
{
	local ModernVRWeaponTuning SavedSettings, Settings;
	local Weapon TestWeapon;
	local vector BaseOffset, TunedOffset, ExpectedOffset, MotionOffset, SavedViewOffset;
	local float SavedHand, Scale;
	local int HandIndex;
	SavedSettings = class'ModernVRWeaponTuning'.default.Settings;
	Settings = new class'ModernVRWeaponTuning';
	Array_Size(Settings.Profiles, 1);
	Settings.Profiles[0].WeaponClass = "UnrealShare.AutoMag";
	Settings.Profiles[0].Scale = 1.1;
	Settings.Profiles[0].MotionOffsetCM = vect(-10,3,2);
	class'ModernVRWeaponTuning'.default.Settings = Settings;
	SavedHand = TestPlayer.Handedness;
	TestWeapon = Spawn(class'AutoMag', TestPlayer);
	for (HandIndex = -1; HandIndex <= 1; HandIndex++)
	{
		TestPlayer.Handedness = HandIndex;
		TestWeapon.SetHand(HandIndex);
		SavedViewOffset = TestWeapon.PlayerViewOffset;
		Settings.Profiles[0].GazeOffsetCM = vect(0,0,0);
		BaseOffset = TestHook.GazeInteraction.GetGazeViewOffset(TestWeapon, rot(1000,12000,0),
			rot(2000,15000,0), vect(2,3,1), 2, 0.9);
		Settings.Profiles[0].GazeOffsetCM = vect(45,5,-25);
		TunedOffset = TestHook.GazeInteraction.GetGazeViewOffset(TestWeapon, rot(1000,12000,0),
			rot(2000,15000,0), vect(2,3,1), 2, 0.9);
		ExpectedOffset = vect(45,5,-25);
		ExpectedOffset.Y *= -HandIndex;
		Check(VSize(TunedOffset - BaseOffset - ExpectedOffset * 45) < 0.01,
			"gaze calibration adapts only Y for hand " $ HandIndex);
		Check(TestWeapon.PlayerViewOffset == SavedViewOffset,
			"gaze handedness preserves stock view placement");
		Settings.GetAdjustment(TestWeapon.Class, True, Scale, MotionOffset);
		Check(Scale == 1.1 && MotionOffset == vect(-5,1.5,1),
			"motion calibration and scale unchanged by gaze handedness");
	}
	TestPlayer.Handedness = SavedHand;
	class'ModernVRWeaponTuning'.default.Settings = SavedSettings;
	TestWeapon.Destroy();
}

function TestRocketHandedBarrel(class<Weapon> WeaponClass, float ProfileScale)
{
	local ModernVRWeaponTuning SavedSettings, Settings;
	local Weapon TestWeapon;
	local vector ViewOffset, Muzzle, ModelOffset, LocalBarrel;
	local rotator ModelRotation;
	local float SavedHand, BaseScale, RightY, Scale;
	local int HandIndex, ScaleIndex;
	SavedSettings = class'ModernVRWeaponTuning'.default.Settings;
	Settings = new class'ModernVRWeaponTuning';
	Array_Size(Settings.Profiles, 1);
	Settings.Profiles[0].WeaponClass = string(WeaponClass);
	Settings.Profiles[0].GazeOffsetCM = vect(45,15,-22);
	class'ModernVRWeaponTuning'.default.Settings = Settings;
	SavedHand = TestPlayer.Handedness;
	TestWeapon = Spawn(WeaponClass, TestPlayer);
	if (class'ModernVRMotionSupport'.default.Geometry == None)
		class'ModernVRMotionSupport'.default.Geometry = new class'ModernVRWeaponGeometry';
	for (ScaleIndex = 0; ScaleIndex < 2; ScaleIndex++)
	{
		Scale = ProfileScale + ScaleIndex * 0.4;
		Settings.Profiles[0].Scale = Scale;
		for (HandIndex = -1; HandIndex <= 1; HandIndex++)
		{
			TestPlayer.Handedness = HandIndex;
			TestWeapon.SetHand(HandIndex);
			ViewOffset = TestHook.GazeInteraction.GetGazeViewOffset(TestWeapon, rot(0,0,0),
				rot(0,0,0), vect(0,0,0), 0, 0.9);
			class'ModernVRMotionSupport'.default.Geometry.GetGeometry(TestWeapon, BaseScale, Muzzle, ModelOffset);
			if (HandIndex == 0) ModelRotation.Roll = -2 * TestWeapon.Default.Rotation.Roll;
			else ModelRotation.Roll = TestWeapon.Default.Rotation.Roll * HandIndex;
			LocalBarrel = (((Muzzle - ModelOffset - vect(1,0,0)) * Scale) >> ModelRotation) * 0.9 + ViewOffset * 0.01;
			if (HandIndex == -1)
			{
				RightY = LocalBarrel.Y;
				Check(Abs(ViewOffset.Y - (TestWeapon.PlayerViewOffset.Y + (2.2 + 7.5) * 100) * 0.9) < 0.01,
					WeaponClass $ " right gaze placement remains unchanged");
			}
			else Check(Abs(LocalBarrel.Y + HandIndex * RightY) < 0.01,
				WeaponClass $ " gaze barrel symmetry for hand " $ HandIndex);
		}
	}
	TestPlayer.Handedness = SavedHand;
	class'ModernVRWeaponTuning'.default.Settings = SavedSettings;
	TestWeapon.Destroy();
}

function TestRazorAnimatedBarrel()
{
	local Weapon TestWeapon;
	local ModernVRWeaponGeometry Geometry;
	local array<vector> Vertices;
	local vector Muzzle, ModelOffset, Expected, IdleMuzzle;
	local float ModelScale, SavedScale;
	local name Sequence;
	local int PoseIndex;
	TestWeapon = Spawn(class'RazorJack');
	Geometry = new class'ModernVRWeaponGeometry';
	TestWeapon.AnimSequence = 'Idle';
	Geometry.GetGeometry(TestWeapon, ModelScale, IdleMuzzle, ModelOffset);
	for (PoseIndex = 0; PoseIndex < 3; PoseIndex++)
	{
		if (PoseIndex == 0) Sequence = 'AltFire1';
		else if (PoseIndex == 1) Sequence = 'AltFire2';
		else Sequence = 'AltFire3';
		TestWeapon.AnimSequence = Sequence;
		if (PoseIndex == 0) TestWeapon.AnimFrame = 11.0 / 12.0;
		else TestWeapon.AnimFrame = 0.5;
		TestWeapon.Mesh = TestWeapon.PlayerViewMesh;
		TestWeapon.DrawScale = ModelScale;
		TestWeapon.SetRotation(rot(0,0,0));
		TestWeapon.AllFrameVerts(Vertices);
		Expected = (Vertices[103] + Vertices[115]) * 0.5 - TestWeapon.Location + vect(1,0,0);
		TestWeapon.Mesh = TestWeapon.default.Mesh;
		TestWeapon.DrawScale = TestWeapon.default.DrawScale;
		TestWeapon.SetRotation(rot(1000,4000,500));
		SavedScale = ModelScale;
		Geometry.GetGeometry(TestWeapon, ModelScale, Muzzle, ModelOffset);
		Check(VSize(Muzzle - Expected) < 0.01 && ModelScale == SavedScale,
			"RazorJack live alternate barrel matches independent frame measurement: " $ Sequence);
		Check(TestWeapon.Mesh == TestWeapon.default.Mesh && TestWeapon.DrawScale == TestWeapon.default.DrawScale
			&& TestWeapon.Rotation == rot(1000,4000,500) && TestWeapon.AnimSequence == Sequence,
			"RazorJack sampling restores live actor state");
		Log("VRRAZOR " $ Sequence $ " delta=" $ (Muzzle - IdleMuzzle));
	}
	TestWeapon.AnimSequence = 'Idle';
	Geometry.GetGeometry(TestWeapon, ModelScale, Muzzle, ModelOffset);
	Check(Muzzle == IdleMuzzle && Array_Size(Geometry.Cache) == 1, "RazorJack animation leaves idle cache unchanged");
	TestWeapon.Destroy();
}

function TestRefire(class<Weapon> WeaponClass)
{
	local Weapon W;
	local int I, BeforeAmmo;
	Check(WeaponClass != None, "refire test weapon class available");
	if (WeaponClass == None) return;
	W = Spawn(WeaponClass, TestPlayer);
	W.GiveTo(TestPlayer);
	W.GiveAmmo(TestPlayer);
	TestPlayer.Weapon = W;
	TestPlayer.ViewRotation = rot(16384,0,0);
	TestHook.BindWeaponClass(W.Class);
	W.AmmoType.AmmoAmount = 1000;
	W.GotoState('Idle');
	TestPlayer.bFire = 1;
	W.Fire(0);
	TestHook.BindWeaponClass(W.Class, W.GetStateName());
	BeforeAmmo = W.AmmoType.AmmoAmount;
	for (I = 0; I < 5; I++) W.Finish();
	Check(W.AmmoType.AmmoAmount < BeforeAmmo - 3, "repeated stock Finish/refire: " $ WeaponClass);
	W.PutDown();
	TestPlayer.bFire = 0;
	W.Finish();
	Check(W.IsInState('DownWeapon'), "weapon switch after sustained fire: " $ WeaponClass);
	TestPlayer.DeleteInventory(W);
	W.Destroy();
	TestPlayer.Weapon = None;
}

function TestProjectileOrigin(class<Weapon> WeaponClass, optional bool bGaze)
{
	local Weapon W;
	local Projectile Shot;
	local vector OriginalOffset;
	local rotator OriginalView;
	local rotator Aim;
	local int Blocked, ShotCount;
	local vector ExpectedMuzzle;
	local vector BeamForward, BeamRight, BeamUp, DesktopBeamStart;
	local ModernVRInteraction Interaction;
	foreach AllActors(class'Projectile', Shot)
		if (Shot.Instigator == TestPlayer) Shot.Destroy();
	W = Spawn(WeaponClass, TestPlayer);
	W.GiveTo(TestPlayer);
	W.GiveAmmo(TestPlayer);
	W.AmmoType.AmmoAmount = 100;
	TestPlayer.Weapon = W;
	TestPlayer.ViewRotation = rot(0,12000,0);
	TestHook.EnsureHooks(TestPlayer);
	TestHook.bForceMuzzle = True;
	TestHook.bUseGazePose = bGaze;
	TestHook.ForcedMuzzle = TestPlayer.Location + vect(0,0,60);
	ExpectedMuzzle = TestHook.ForcedMuzzle;
	if (bGaze)
	{
		Interaction = TestHook.GazeInteraction;
		Check(Interaction != None, "gaze fixture interaction available");
		if (Interaction != None)
			Check(Interaction.GetGazeMuzzle(ExpectedMuzzle, Aim, Blocked) && Blocked == 0,
				"gaze muzzle available with translated head and non-default world scale");
	}
	OriginalOffset = W.FireOffset;
	OriginalView = TestPlayer.ViewRotation;
	if (!bGaze) Aim = OriginalView;
	if (ClassIsChildOf(WeaponClass, class'ASMD'))
		Shot = W.ProjectileFire(W.AltProjectileClass, W.AltProjectileSpeed, False);
	else
		Shot = W.ProjectileFire(W.ProjectileClass, W.ProjectileSpeed, False);
	Check(W.FireOffset == OriginalOffset && TestPlayer.ViewRotation == OriginalView,
		"firing restores weapon offset and player view: " $ WeaponClass);
	Check(Shot != None, "projectile spawned: " $ WeaponClass);
	if (Shot != None)
	{
		Log("VRMUZZLE " $ WeaponClass $ " gaze=" $ bGaze $ " error=" $ VSize(Shot.Location - ExpectedMuzzle));
		Check(VSize(Shot.Location - ExpectedMuzzle) < 0.1, "stock projectile begins at overridden muzzle: " $ WeaponClass);
		Check((vector(Shot.Rotation) dot vector(Aim)) > 0.9999, "straight projectile follows the computed aim ray: " $ WeaponClass);
		Shot.Destroy();
	}
	if (ClassIsChildOf(WeaponClass, class'DispersionPistol'))
	{
		DispersionPistol(W).ChargeSize = 1;
		Check(string(TestHook.FindWeaponFunction(W.Class, 'BeginState', 'ShootLoad'))
			== "UnrealShare.DispersionPistol.ShootLoad.BeginState", "charged-shot hook resolves the state-owned function");
		W.GotoState('ShootLoad');
		foreach AllActors(class'Projectile', Shot)
			if (Shot.Instigator == TestPlayer && !Shot.bDeleteMe)
			{
				ShotCount++;
				Check(VSize(Shot.Location - ExpectedMuzzle) < 0.1, "charged dispersion shot starts at muzzle");
				Shot.Destroy();
			}
		Check(ShotCount == 1, "charged dispersion projectile inspected");
	}
	else if (ClassIsChildOf(WeaponClass, class'ASMD'))
	{
		Check(TestHook.SetHook(class'ASMD'.static.FindFunction('SpawnEffect'), TestHook.CaptureASMDBeam),
			"ASMD beam observation hook registered");
		TestHook.BeamSamples = 0;
		W.TraceFire(0);
		Check(TestHook.BeamSamples > 0, "ASMD primary beam inspected");
		Log("VRBEAM gaze=" $ bGaze $ " error=" $ VSize(TestHook.BeamStart - ExpectedMuzzle));
		Check(VSize(TestHook.BeamStart - ExpectedMuzzle) < 0.1, "ASMD primary beam begins at corrected muzzle");
		TestHook.bForceMuzzle = False;
		TestHook.bUseGazePose = False;
		TestHook.BeamSamples = 0;
		W.TraceFire(0);
		GetAxes(TestPlayer.ViewRotation, BeamForward, BeamRight, BeamUp);
		DesktopBeamStart = TestPlayer.Location + W.CalcDrawOffset()
			+ W.FireOffset.X * vector(W.AdjustedAim) + W.FireOffset.Y * 3.3 * BeamRight + W.FireOffset.Z * 3.0 * BeamUp;
		Check(TestHook.BeamSamples > 0 && VSize(TestHook.BeamStart - DesktopBeamStart) < 0.1,
			"ASMD desktop beam retains the stock visual offset");
		TestHook.RemoveHook(class'ASMD'.static.FindFunction('SpawnEffect'), TestHook.CaptureASMDBeam);
	}
	else if (ClassIsChildOf(WeaponClass, class'Stinger'))
	{
		W.GotoState('AltFiring');
		TestHook.EnsureHooks(TestPlayer);
		Check(string(TestHook.FindWeaponFunction(W.Class, 'ProjectileFire', 'AltFiring'))
			== "UnrealShare.Stinger.AltFiring.ProjectileFire", "burst hook resolves the state-owned function");
		Shot = W.ProjectileFire(W.AltProjectileClass, W.AltProjectileSpeed, False);
		Check(Shot != None, "Stinger alternate burst spawns");
		foreach AllActors(class'Projectile', Shot)
			if (Shot.Instigator == TestPlayer && !Shot.bDeleteMe)
			{
				ShotCount++;
				Check(VSize(Shot.Location - ExpectedMuzzle) <= 2.1, "Stinger burst retains stock spread around corrected muzzle");
				Shot.Destroy();
			}
		Check(ShotCount == 5, "all five Stinger burst projectiles inspected");
	}
	Check(W.FireOffset == OriginalOffset && TestPlayer.ViewRotation == OriginalView,
		"alternate firing restores offset and view");
	TestHook.bForceMuzzle = False;
	TestHook.bUseGazePose = False;
	TestPlayer.DeleteInventory(W);
	TestPlayer.Weapon = None;
	W.Destroy();
}

function TestRemainingBarrels(ModernVRWeaponTuning UserSettings)
{
	local class<Weapon> Types[11];
	local Weapon TestWeapon;
	local vector Landmarks[11], ActualMuzzle, ModelOffset;
	local float MeshScale;
	local ModernVRWeaponGeometry Geometry;
	local ModernVRWeaponTuning NeutralSettings;
	local int WeaponIndex;
	Types[0] = class'AutoMag';
	Types[1] = class'Eightball';
	Types[2] = class'FlakCannon';
	Types[3] = class'Rifle';
	Types[4] = class'Minigun';
	Types[5] = class'RazorJack';
	Types[6] = class'GESBioRifle';
	Types[7] = class'QuadShot';
	Types[8] = class'CARifle';
	Types[9] = class'GrenadeLauncher';
	Types[10] = class'RocketLauncher';
	Landmarks[0] = vect(0.14,-0.1575,1.8425);
	Landmarks[1] = vect(0.5287665,0,1.160455);
	Landmarks[2] = vect(1.93,0,0);
	Landmarks[3] = vect(1.66,0.015,0.31);
	Landmarks[4] = vect(0.608646,0.0254675,0.162857);
	Landmarks[5] = vect(1.371671,-0.015,-0.155386);
	Landmarks[6] = vect(0.72,-0.0225,-0.05);
	Landmarks[7] = vect(4.956,0,-0.224);
	Landmarks[8] = vect(2.55,0,-0.17);
	Landmarks[9] = vect(5.01,0.16875,0.0375);
	Landmarks[10] = vect(1.045,-0.791,0.63);
	NeutralSettings = class'ModernVRWeaponTuning'.default.Settings;
	for (WeaponIndex = 0; WeaponIndex < 11; WeaponIndex++)
	{
		TestWeapon = Spawn(Types[WeaponIndex]);
		TestWeapon.AnimSequence = 'Select';
		TestWeapon.AnimFrame = 0.5;
		TestWeapon.SetRotation(rot(1000,4000,500));
		Geometry = new class'ModernVRWeaponGeometry';
		Geometry.GetGeometry(TestWeapon, MeshScale, ActualMuzzle, ModelOffset);
		Check(VSize(ActualMuzzle - (Landmarks[WeaponIndex] * MeshScale + ModelOffset + vect(1,0,0))) < 0.01,
			"remaining stock barrel landmark: " $ Types[WeaponIndex]);
		Check(TestWeapon.AnimSequence == 'Select' && TestWeapon.AnimFrame == 0.5
			&& TestWeapon.Rotation == rot(1000,4000,500) && TestWeapon.Mesh == TestWeapon.default.Mesh
			&& TestWeapon.DrawScale == TestWeapon.default.DrawScale, "barrel measurement restores live state: " $ Types[WeaponIndex]);
		if (WeaponIndex == 0 || WeaponIndex == 7)
		{
			if (WeaponIndex == 0) TestWeapon.PlayerViewMesh = mesh'AutoMagR';
			else TestWeapon.PlayerViewMesh = mesh'QuadShotHeldL';
			Geometry.GetGeometry(TestWeapon, MeshScale, ActualMuzzle, ModelOffset);
			Landmarks[WeaponIndex].Y = -Landmarks[WeaponIndex].Y;
			Log("VRBARREL mirrored " $ TestWeapon.PlayerViewMesh $ " landmark="
				$ ((ActualMuzzle - ModelOffset - vect(1,0,0)) / MeshScale));
			Check(VSize(ActualMuzzle - (Landmarks[WeaponIndex] * MeshScale + ModelOffset + vect(1,0,0))) < 0.01,
				"mirrored stock barrel landmark: " $ Types[WeaponIndex]);
		}
		TestWeapon.Destroy();
		TestRemainingFiring(Types[WeaponIndex], False);
		TestRemainingFiring(Types[WeaponIndex], True);
	}
	class'ModernVRWeaponTuning'.default.Settings = UserSettings;
	Log("VRMOTION checking the saved runtime tuning without writing it");
	for (WeaponIndex = 0; WeaponIndex < 11; WeaponIndex++)
		TestRemainingFiring(Types[WeaponIndex], True);
	class'ModernVRWeaponTuning'.default.Settings = NeutralSettings;
}

function CheckProjectiles(vector ExpectedMuzzle, int ExpectedCount, float Tolerance, string Description)
{
	local Projectile Shot;
	local int Count;
	foreach AllActors(class'Projectile', Shot)
		if (Shot.Instigator == TestPlayer && !Shot.bDeleteMe)
		{
			Count++;
			Log("VRORIGIN " $ Description $ " " $ Shot.Class $ " error=" $ VSize(Shot.Location - ExpectedMuzzle));
			Check(VSize(Shot.Location - ExpectedMuzzle) <= Tolerance, Description $ " origin");
			Shot.Destroy();
		}
	Check(Count == ExpectedCount, Description $ " shot count=" $ Count);
}

function TestRemainingFiring(class<Weapon> WeaponType, bool bGaze)
{
	local Weapon W;
	local Projectile Shot;
	local vector ExpectedMuzzle, SavedOffset;
	local rotator Aim, SavedView;
	local int Blocked, BarrelIndex;
	local string Description;
	foreach AllActors(class'Projectile', Shot)
		if (Shot.Instigator == TestPlayer) Shot.Destroy();
	W = Spawn(WeaponType, TestPlayer);
	W.GiveTo(TestPlayer);
	W.GiveAmmo(TestPlayer);
	W.AmmoType.AmmoAmount = 100;
	TestPlayer.Weapon = W;
	TestPlayer.ViewRotation = rot(1000,12000,0);
	TestHook.EnsureHooks(TestPlayer);
	TestHook.bForceMuzzle = True;
	TestHook.bUseGazePose = bGaze;
	TestHook.ForcedMuzzle = TestPlayer.Location + vect(12,18,60);
	ExpectedMuzzle = TestHook.ForcedMuzzle;
	Aim = TestPlayer.ViewRotation;
	if (bGaze)
		Check(TestHook.GazeInteraction.GetGazeMuzzle(ExpectedMuzzle, Aim, Blocked) && Blocked == 0,
			"remaining gaze muzzle available: " $ WeaponType);
	SavedOffset = W.FireOffset;
	SavedView = TestPlayer.ViewRotation;
	Description = string(WeaponType) $ " gaze=" $ bGaze;
	W.GotoState('Idle');
	if (Eightball(W) != None)
	{
		Eightball(W).RocketsLoaded = 6;
		Eightball(W).bFireLoad = True;
		W.GotoState('FireRockets');
		CheckProjectiles(ExpectedMuzzle, 6, 0.1, Description $ " rockets");
		W.GotoState('Idle');
		Eightball(W).RocketsLoaded = 6;
		Eightball(W).bFireLoad = False;
		W.GotoState('FireRockets');
		CheckProjectiles(ExpectedMuzzle, 6, 0.1, Description $ " grenades");
	}
	else if (GrenadeLauncher(W) != None)
	{
		W.Fire(0);
		CheckProjectiles(ExpectedMuzzle, 1, 0.1, Description $ " primary");
		W.GotoState('Idle');
		GrenadeLauncher(W).bAltFireOff = True;
		W.AltFire(0);
		Check(GrenadeLauncher(W).DetGrenade != None && GrenadeLauncher(W).DetGrenade.GL == W,
			Description $ " remote grenade ownership retained");
		CheckProjectiles(ExpectedMuzzle, 1, 0.1, Description $ " remote");
		GrenadeLauncher(W).DetGrenade = None;
		GrenadeLauncher(W).bDetGrenadeActive = False;
	}
	else if (FlakCannon(W) != None)
	{
		W.Fire(0);
		CheckProjectiles(ExpectedMuzzle, 8, 2.3, Description $ " fragments");
		W.GotoState('Idle');
		W.AltFire(0);
		CheckProjectiles(ExpectedMuzzle, 1, 0.1, Description $ " shell");
	}
	else if (RazorJack(W) != None || GESBioRifle(W) != None || RocketLauncher(W) != None)
	{
		W.Fire(0);
		CheckProjectiles(ExpectedMuzzle, 1, 0.1, Description $ " nested primary");
		W.GotoState('Idle');
		if (GESBioRifle(W) != None)
		{
			GESBioRifle(W).ChargeSize = 3;
			W.GotoState('ShootLoad');
			CheckProjectiles(ExpectedMuzzle, 1, 0.1, Description $ " charged");
		}
		else if (RazorJack(W) != None)
		{
			W.GotoState('AltFiring');
			W.AnimSequence = 'AltFire1';
			W.AnimFrame = 11.0 / 12.0;
			if (bGaze)
				Check(TestHook.GazeInteraction.GetGazeMuzzle(ExpectedMuzzle, Aim, Blocked) && Blocked == 0,
					Description $ " rotated alternate muzzle available");
			TestHook.EnsureHooks(TestPlayer);
			W.ProjectileFire(W.AltProjectileClass, W.AltProjectileSpeed, False);
			CheckProjectiles(ExpectedMuzzle, 1, 0.1, Description $ " alternate blade");
		}
		else
		{
			W.AltFire(0);
			CheckProjectiles(ExpectedMuzzle, 1, 0.1, Description $ " alternate rocket");
		}
	}
	else
	{
		TestHook.TraceSamples = 0;
		W.TraceFire(0);
		Check(TestHook.TraceSamples > 0 && VSize(TestHook.TraceStart - ExpectedMuzzle) < 0.1,
			Description $ " real hitscan starts at muzzle");
		Check((TestHook.TraceDirection dot vector(Aim)) > 0.9999,
			Description $ " zero-spread hitscan follows aim ray");
		if (CARifle(W) != None)
		{
			W.ProjectileFire(W.AltProjectileClass, W.AltProjectileSpeed, False);
			CheckProjectiles(ExpectedMuzzle, 1, 0.1, Description $ " alternate round");
		}
		if (AutoMag(W) != None || Minigun(W) != None)
		{
			W.GotoState('AltFiring');
			TestHook.EnsureHooks(TestPlayer);
			TestHook.TraceSamples = 0;
			W.TraceFire(0);
			Check(TestHook.TraceSamples > 0 && VSize(TestHook.TraceStart - ExpectedMuzzle) < 0.1
				&& (TestHook.TraceDirection dot vector(Aim)) > 0.9999,
				Description $ " alternate-state hitscan origin and aim");
		}
		if (QuadShot(W) != None)
		{
			for (BarrelIndex = 0; BarrelIndex < 4; BarrelIndex++)
			{
				QuadShot(W).SetShotPattern(4, BarrelIndex);
				TestHook.TraceSamples = 0;
				W.TraceFire(0);
				Check(TestHook.TraceSamples > 0 && VSize(TestHook.TraceStart - ExpectedMuzzle) < 0.1,
					Description $ " loaded barrel pattern " $ BarrelIndex);
			}
			W.FireOffset = SavedOffset;
		}
		if (Rifle(W) != None || QuadShot(W) != None)
		{
			TestHook.bDenyShot = True;
			W.AltFire(0);
			Check((Rifle(W) != None && W.IsInState('AltFiring')) || (QuadShot(W) != None && W.IsInState('Reload')),
				Description $ " non-firing alternate action survives blocked muzzle");
			TestHook.bDenyShot = False;
		}
	}
	Check(W.FireOffset == SavedOffset && TestPlayer.ViewRotation == SavedView,
		Description $ " firing restores view and offset");
	TestHook.bForceMuzzle = False;
	TestHook.bUseGazePose = False;
	TestPlayer.DeleteInventory(W);
	TestPlayer.Weapon = None;
	W.Destroy();
}

function LogBounds(class<Weapon> WeaponClass)
{
	local Weapon W;
	local BoundingBox Bounds;
	local float MeshScale, ExpectedSize;
	local vector Muzzle, Size, ModelOffset, Grip, RotatedGrip;
	W = Spawn(WeaponClass);
	W.Mesh = W.PlayerViewMesh;
	// Physical length is defined at rest, not during equip/fire animation.
	if (ClassIsChildOf(WeaponClass, class'Eightball')) W.AnimSequence = 'Idle';
	else W.AnimSequence = 'Still';
	W.AnimFrame = 0;
	W.DrawScale = W.PlayerViewScale;
	W.SetRotation(rot(0,0,0));
	Bounds = W.GetBoundingBox(True);
	Log("VRMOTION size " $ WeaponClass $ " extent=" $ (Bounds.Max - Bounds.Min) $ " viewscale=" $ W.PlayerViewScale);
	class'ModernVRMotionSupport'.static.GetWeaponGeometry(W, MeshScale, Muzzle, ModelOffset);
	Check(W.DrawScale == W.PlayerViewScale, "geometry query restores weapon scale: " $ WeaponClass);
	W.DrawScale = MeshScale;
	Bounds = W.GetBoundingBox(True);
	Size = Bounds.Max - Bounds.Min;
	ExpectedSize = class'ModernVRWeaponGeometry'.static.LengthMetres(WeaponClass) * 50;
	Check(Abs(FMax(Size.X, FMax(Size.Y, Size.Z)) - ExpectedSize) < 0.02,
		"physical mesh size: " $ WeaponClass);
	if (ClassIsChildOf(WeaponClass, class'AutoMag'))
	{
		Grip = Bounds.Min - W.Location;
		Grip.X += Size.X * 0.20;
		Grip.Y += Size.Y * 0.50;
		Grip.Z += Size.Z * 0.25;
		RotatedGrip = (Grip + ModelOffset) >> rot(6000,14000,9000);
		Check(VSize(RotatedGrip) < 0.02, "pistol grip remains at tracked hand during wrist rotation");
	}
	else
		Check(VSize(ModelOffset) == 0, "other weapon pivots preserved: " $ WeaponClass);
	W.Destroy();
}

function BenchmarkFunctionResolution()
{
	local int LookupIndex, CachedIndex, NativeIndex;
	local float StartTime, CachedTime, NativeTime;
	TestHook.FindWeaponFunction(class'RazorJack', 'ProjectileFire', 'AltFiring');
	StartTime = AppSeconds();
	for (LookupIndex = 0; LookupIndex < 10000; LookupIndex++)
		CachedIndex = TestHook.FindWeaponFunction(class'RazorJack', 'ProjectileFire', 'AltFiring').ObjectIndex;
	CachedTime = AppSeconds() - StartTime;
	StartTime = AppSeconds();
	for (LookupIndex = 0; LookupIndex < 10000; LookupIndex++)
		NativeIndex = int(TestPlayer.ConsoleCommand("D3D12 VRWEAPONFUNCTION UnrealI.RazorJack AltFiring ProjectileFire"));
	NativeTime = AppSeconds() - StartTime;
	Check(CachedIndex == NativeIndex, "cached firing resolver matches the native function");
	Log("VRPERF 10000 function resolutions cached_ms=" $ (CachedTime * 1000) $ " native_ms=" $ (NativeTime * 1000));
}

function TestStockBarrelCalibration(class<Weapon> WeaponType)
{
	local Weapon TestWeapon;
	local array<vector> Vertices;
	local vector ExpectedMuzzle, ActualMuzzle, ModelOffset;
	local float MeshScale;
	local ModernVRWeaponGeometry Geometry;
	TestWeapon = Spawn(WeaponType);
	TestWeapon.Mesh = TestWeapon.PlayerViewMesh;
	TestWeapon.DrawScale = TestWeapon.PlayerViewScale;
	TestWeapon.AnimSequence = 'Still';
	TestWeapon.AnimFrame = 0;
	TestWeapon.SetRotation(rot(0,0,0));
	TestWeapon.AllFrameVerts(Vertices);
	Check(Array_Size(Vertices) > 0, "stock barrel mesh vertices available: " $ WeaponType);
	if (Array_Size(Vertices) > 0)
	{
		if (WeaponType == class'Stinger')
			ExpectedMuzzle = vect(7.463,0,-0.0085);
		else
			ExpectedMuzzle = vect(1.8375,-0.014,0.105);
		TestWeapon.AnimSequence = 'Select';
		TestWeapon.AnimFrame = 0.5;
		Geometry = new class'ModernVRWeaponGeometry';
		Geometry.GetGeometry(TestWeapon, MeshScale, ActualMuzzle, ModelOffset);
		ExpectedMuzzle = ExpectedMuzzle * (MeshScale / TestWeapon.PlayerViewScale) + vect(1,0,0);
		Check(VSize(ActualMuzzle - ExpectedMuzzle) < 0.01,
			"muzzle follows measured stock barrel landmark: " $ WeaponType);
		Check(TestWeapon.AnimSequence == 'Select' && TestWeapon.AnimFrame == 0.5
			&& TestWeapon.DrawScale == TestWeapon.PlayerViewScale,
			"barrel calibration preserves live animation and scale: " $ WeaponType);
		Log("VRBARREL " $ WeaponType $ " muzzle=" $ ActualMuzzle);
	}
	TestWeapon.Destroy();
}

function TestDispersionBarrel()
{
	local DispersionPistol TestWeapon;
	local ModernVRWeaponGeometry Geometry;
	local int PowerIndex;
	local float ModelScale, InitialScale;
	local vector Muzzle, ModelOffset, Landmark;
	TestWeapon = Spawn(class'DispersionPistol');
	TestWeapon.AnimSequence = 'Shoot1';
	TestWeapon.AnimFrame = 0.5;
	TestWeapon.SetRotation(rot(1000,4000,500));
	Geometry = new class'ModernVRWeaponGeometry';
	for (PowerIndex = 0; PowerIndex < 6; PowerIndex++)
	{
		TestWeapon.PowerLevel = PowerIndex % 5;
		if (TestWeapon.PowerLevel == 0) Landmark = vect(2.5875,0.015,-0.26);
		else if (TestWeapon.PowerLevel == 1) Landmark = vect(2.25375,0.0025,-0.25);
		else Landmark = vect(3.2675,0.005,0.245);
		Geometry.GetGeometry(TestWeapon, ModelScale, Muzzle, ModelOffset);
		if (PowerIndex == 0) InitialScale = ModelScale;
		Check(VSize(Muzzle - (Landmark * ModelScale + vect(1,0,0))) < 0.01,
			"dispersion muzzle follows the barrel at power " $ TestWeapon.PowerLevel);
		Check(ModelScale == InitialScale && Array_Size(Geometry.Cache) == 1,
			"dispersion power changes update only the cached muzzle");
		Check(TestWeapon.AnimSequence == 'Shoot1' && TestWeapon.AnimFrame == 0.5
			&& TestWeapon.Rotation == rot(1000,4000,500) && TestWeapon.Mesh == TestWeapon.default.Mesh
			&& TestWeapon.DrawScale == TestWeapon.default.DrawScale,
			"dispersion landmark measurement restores live weapon state");
	}
	TestWeapon.Destroy();
}

function int LegacyProfileLookup(ModernVRWeaponTuning Settings, class<Weapon> WeaponType)
{
	local class<Object> Type;
	local int I;
	for (Type = WeaponType; Type != None; Type = GetParentClass(Type))
		for (I = 0; I < Array_Size(Settings.Profiles); I++)
			if (Settings.Profiles[I].WeaponClass ~= string(Type)) return I;
	return -1;
}

function BenchmarkProfileLookup()
{
	local ModernVRWeaponTuning Settings;
	local class<Weapon> Types[4];
	local int I, J, BeforeSum, AfterSum;
	local float Start, BeforeSeconds, AfterSeconds;
	Settings = new class'ModernVRWeaponTuning';
	Types[0] = class'AutoMag';
	Types[1] = class<Weapon>(DynamicLoadObject("OldWeapons.OldAutoMag", class'Class'));
	Types[2] = class'Rifle';
	Types[3] = class'ModernVRMotionTestWeapon';
	for (J = 0; J < 4; J++)
		Check(Settings.ResolveProfile(Types[J]) == LegacyProfileLookup(Settings, Types[J]), "cached lookup matches legacy class selection");
	Start = AppSeconds();
	for (I = 0; I < 2000; I++)
		for (J = 0; J < 4; J++) BeforeSum += LegacyProfileLookup(Settings, Types[J]);
	BeforeSeconds = AppSeconds() - Start;
	Start = AppSeconds();
	for (I = 0; I < 2000; I++)
		for (J = 0; J < 4; J++) AfterSum += Settings.ResolveProfile(Types[J]);
	AfterSeconds = AppSeconds() - Start;
	Check(BeforeSum == AfterSum && Array_Size(Settings.ResolvedProfiles) == 4,
		"warm lookup remains equivalent without growing the cache");
	Log("VRPERF 8000 profile lookups legacy_ms=" $ (BeforeSeconds * 1000) $ " cached_ms=" $ (AfterSeconds * 1000));
}

function TestIndependentSizes(ModernVRWeaponTuning Settings)
{
	local class<Weapon> Types[17];
	local Weapon W;
	local int Index;
	local float BaseScale, GazeScale, MotionScale, Scale;
	local vector Muzzle, ModelOffset, Offset;
	local ModernVRWeaponTuning SavedSettings, NeutralSettings;
	local ModernVRWeaponGeometry Geometry;
	Types[0] = class'DispersionPistol';
	Types[1] = class'AutoMag';
	Types[2] = class'Stinger';
	Types[3] = class'ASMD';
	Types[4] = class'Eightball';
	Types[5] = class'FlakCannon';
	Types[6] = class'Rifle';
	Types[7] = class'Minigun';
	Types[8] = class'RazorJack';
	Types[9] = class'GESBioRifle';
	Types[10] = class'QuadShot';
	Types[11] = class'CARifle';
	Types[12] = class'GrenadeLauncher';
	Types[13] = class'RocketLauncher';
	Types[14] = class<Weapon>(DynamicLoadObject("OldWeapons.OldDispersionPistol", class'Class'));
	Types[15] = class<Weapon>(DynamicLoadObject("OldWeapons.OldAutoMag", class'Class'));
	Types[16] = class'ModernVRMotionTestWeapon';
	Geometry = new class'ModernVRWeaponGeometry';
	NeutralSettings = new class'ModernVRWeaponTuning';
	Array_Size(NeutralSettings.Profiles, 0);
	SavedSettings = class'ModernVRWeaponTuning'.default.Settings;
	for (Index = 0; Index < 17; Index++)
	{
		Check(Types[Index] != None, "shared-size weapon class available at index " $ Index);
		if (Types[Index] == None) continue;
		W = Spawn(Types[Index]);
		if (Index < 16) TestGeometryHistory(W);
		if (Types[Index] == class'ModernVRMotionTestWeapon')
		{
			W.PlayerViewMesh = class'Stinger'.default.PlayerViewMesh;
			W.PlayerViewScale = 2;
			W.AnimSequence = 'Still';
		}
		Geometry.GetGeometry(W, BaseScale, Muzzle, ModelOffset);
		class'ModernVRWeaponTuning'.default.Settings = NeutralSettings;
		GazeScale = class'ModernVRMotionSupport'.static.GetGazeDrawScale(W);
		class'ModernVRMotionSupport'.static.GetWeaponGeometry(W, MotionScale, Muzzle, ModelOffset);
		Check(BaseScale > 0 && Abs(GazeScale - BaseScale) < 0.0001 && GazeScale == MotionScale,
			"neutral gaze and motion share one physical size: " $ W.Class);
		class'ModernVRWeaponTuning'.default.Settings = Settings;
		Settings.GetAdjustment(W.Class, False, Scale, Offset);
		GazeScale = class'ModernVRMotionSupport'.static.GetGazeDrawScale(W);
		Check(Abs(GazeScale - BaseScale * Scale) < 0.0001,
			"gaze applies its profile to the shared physical baseline: " $ W.Class);
		Settings.GetAdjustment(W.Class, True, Scale, Offset);
		class'ModernVRMotionSupport'.static.GetWeaponGeometry(W, MotionScale, Muzzle, ModelOffset);
		Check(Abs(MotionScale - BaseScale * Scale) < 0.0001 && GazeScale == MotionScale,
			"one profile scale produces equal sizes in both modes: " $ W.Class);
		Log("VRSIZE " $ W.Class $ " gaze=" $ GazeScale $ " motion=" $ MotionScale);
		if (Types[Index] == class'ModernVRMotionTestWeapon')
		{
			W.PlayerViewMesh = class'AutoMag'.default.PlayerViewMesh;
			W.PlayerViewScale = 0.7;
			class'ModernVRWeaponTuning'.default.Settings = NeutralSettings;
			Geometry.GetGeometry(W, BaseScale, Muzzle, ModelOffset);
			GazeScale = class'ModernVRMotionSupport'.static.GetGazeDrawScale(W);
			class'ModernVRMotionSupport'.static.GetWeaponGeometry(W, MotionScale, Muzzle, ModelOffset);
			Check(Abs(GazeScale - BaseScale) < 0.0001 && GazeScale == MotionScale,
				"replacement mesh and view scale invalidate both modes' shared geometry");
		}
		W.Destroy();
	}
	class'ModernVRWeaponTuning'.default.Settings = SavedSettings;
}

function TestGeometryHistory(Weapon W)
{
	local ModernVRWeaponGeometry Fresh;
	local name Poses[8], SavedSequence;
	local float SavedFrame, ReferenceScale, Scale;
	local vector Muzzle, Offset, ReferenceOffset;
	local Mesh SavedMesh;
	local int I;
	SavedMesh = W.Mesh;
	SavedSequence = W.AnimSequence;
	SavedFrame = W.AnimFrame;
	W.Mesh = W.PlayerViewMesh;
	Poses[0] = 'Still'; Poses[1] = 'Idle'; Poses[2] = 'Idle1';
	Poses[3] = 'Select'; Poses[4] = 'Fire'; Poses[5] = 'Down';
	Poses[6] = 'Reload'; Poses[7] = 'Sway';
	for (I = 0; I < 8; I++)
	{
		if (!W.HasAnim(Poses[I])) continue;
		W.AnimSequence = Poses[I];
		W.AnimFrame = 0.5;
		Fresh = new class'ModernVRWeaponGeometry';
		Fresh.GetGeometry(W, Scale, Muzzle, Offset);
		if (ReferenceScale == 0) { ReferenceScale = Scale; ReferenceOffset = Offset; }
		Check(Abs(Scale - ReferenceScale) < 0.0001 && VSize(Offset - ReferenceOffset) < 0.01,
			"geometry independent of first animation: " $ W.Class $ " " $ Poses[I]);
		Log("VRHISTORY " $ W.Class $ " " $ Poses[I] $ " scale=" $ Scale);
		Check(W.AnimSequence == Poses[I] && W.AnimFrame == 0.5,
			"geometry history query restores animation: " $ W.Class);
	}
	W.Mesh = SavedMesh;
	W.AnimSequence = SavedSequence;
	W.AnimFrame = SavedFrame;
}

function TestWeaponTuning()
{
	local ModernVRWeaponTuningTestConfig Settings;
	local float Scale;
	local vector Offset, Muzzle, ModelOffset;
	local class<Weapon> OldPistol;
	Settings = new class'ModernVRWeaponTuningTestConfig';
	Check(Array_Size(Settings.Profiles) == 2, "weapon tuning loads profiles from disposable INI");
	Settings.GetAdjustment(class'AutoMag', False, Scale, Offset);
	Check(Abs(Scale - 1.2) < 0.001 && Offset == vect(1,2,-3), "shared scale and gaze centimetre offsets read");
	Settings.GetAdjustment(class'AutoMag', True, Scale, Offset);
	Check(Abs(Scale - 1.2) < 0.001 && Offset == vect(2,-1,3), "same scale and independent motion centimetre offsets read");
	Scale = 2;
	ModelOffset = vect(3,4,5);
	Muzzle = vect(11,2,3);
	Settings.ApplyMotion(class'AutoMag', Scale, Muzzle, ModelOffset);
	Check(Abs(Scale - 2.4) < 0.001 && VSize(ModelOffset - vect(5.6,3.8,9)) < 0.001
		&& VSize(Muzzle - vect(15,1.4,6.6)) < 0.001, "motion tuning aligns mesh and muzzle with constant clearance");
	OldPistol = class<Weapon>(DynamicLoadObject("OldWeapons.OldAutoMag", class'Class'));
	Settings.GetAdjustment(OldPistol, True, Scale, Offset);
	Check(Abs(Scale - 0.8) < 0.001, "exact mod profile overrides parent regardless of entry order");
	Array_Size(Settings.Profiles, 1);
	Settings.GetAdjustment(OldPistol, True, Scale, Offset);
	Check(Abs(Scale - 1.2) < 0.001, "Old Weapons inherits base profile when no override exists");
	Settings.GetAdjustment(class'Stinger', True, Scale, Offset);
	Check(Scale == 1 && Offset == vect(0,0,0), "missing weapon profile leaves baseline unchanged");
	Settings.Profiles[0].Scale = 0;
	Settings.GetAdjustment(class'AutoMag', True, Scale, Offset);
	Check(Scale == 1, "zero or missing scale uses neutral size");
}

function TestPistolCalibration(class<Weapon> WeaponClass)
{
	local Weapon W;
	local ModernVRWeaponGeometry Fresh;
	local float BaseScale, TestScale;
	local vector BaseMuzzle, BaseOffset, TestMuzzle, TestOffset;
	local name Sequence;
	local int I;
	Check(WeaponClass != None, "pistol calibration class available");
	if (WeaponClass == None) return;
	W = Spawn(WeaponClass);
	W.AnimSequence = 'Still';
	W.AnimFrame = 0;
	Fresh = new class'ModernVRWeaponGeometry';
	Fresh.GetGeometry(W, BaseScale, BaseMuzzle, BaseOffset);
	Log("VRMOTION idle baseline " $ WeaponClass $ " scale=" $ BaseScale $ " muzzle=" $ BaseMuzzle $ " offset=" $ BaseOffset);
	// Recorded before the offset fix, with the requested 20% enlargement.
	// The one-unit clearance ahead of the barrel remains constant.
	Check(Abs(BaseScale - 3.529412 * 1.20) < 0.001
		&& VSize(BaseMuzzle - (vect(0.14,-0.1575,1.8425) * BaseScale + BaseOffset + vect(1,0,0))) < 0.01
		&& VSize(BaseOffset - vect(12.628235,0.506471,-3.114706) * 1.20) < 0.01,
		"pistol resting geometry preserves calibration at 120% size");
	for (I = 0; I < 4; I++)
	{
		if (I == 0) Sequence = 'Select';
		if (I == 1) Sequence = 'Down';
		if (I == 2) Sequence = 'Eject';
		if (I == 3) Sequence = 'Twirl';
		W.AnimSequence = Sequence;
		W.AnimFrame = 0.5;
		Fresh = new class'ModernVRWeaponGeometry';
		Fresh.GetGeometry(W, TestScale, TestMuzzle, TestOffset);
		Check(Abs(TestScale - BaseScale) < 0.001 && VSize(TestOffset - BaseOffset) < 0.01
			&& VSize(TestMuzzle - BaseMuzzle) < 0.01, "pistol cache matches idle during " $ Sequence);
		Check(W.AnimSequence == Sequence && W.AnimFrame == 0.5,
			"pistol calibration preserves live animation");
	}
	W.Destroy();
}

event Timer()
{
	RunTests();
	TestPlayer.ConsoleCommand("quit");
}
