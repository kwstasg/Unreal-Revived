// Shared physical sizes for gaze and tracked first-person meshes.
class ModernVRWeaponGeometry extends Object;

struct WeaponGeometry
{
	var class<Weapon> WeaponClass;
	var Mesh ViewMesh;
	var float ViewScale;
	var float DrawScale;
	var vector Muzzle;
	var vector ModelOffset;
	var int BarrelPowerLevel;
};
var array<WeaponGeometry> Cache;

static function float LengthMetres(class<Weapon> Type)
{
	if (ClassIsChildOf(Type, class'AutoMag')) return 0.4032;
	if (ClassIsChildOf(Type, class'DispersionPistol')) return 0.48;
	if (ClassIsChildOf(Type, class'Rifle')) return 1.10;
	if (ClassIsChildOf(Type, class'Eightball')) return 0.85;
	if (ClassIsChildOf(Type, class'FlakCannon')) return 0.75;
	if (ClassIsChildOf(Type, class'Stinger')) return 0.56;
	if (ClassIsChildOf(Type, class'ASMD')) return 0.80;
	if (ClassIsChildOf(Type, class'Minigun')) return 0.90;
	if (ClassIsChildOf(Type, class'QuadShot')) return 0.90;
	if (ClassIsChildOf(Type, class'CARifle')) return 0.90;
	if (ClassIsChildOf(Type, class'GrenadeLauncher')) return 0.80;
	if (ClassIsChildOf(Type, class'RocketLauncher')) return 1.00;
	return 0.65;
}

function bool GetDispersionMuzzle(Weapon WeaponActor, float ModelScale, out vector Muzzle)
{
	local DispersionPistol Pistol;
	local Mesh SavedMesh;
	local float SavedScale, SavedFrame;
	local name SavedSequence, IdleSequence;
	local rotator SavedRotation;
	local array<vector> Vertices;
	local vector Barrel;
	Pistol = DispersionPistol(WeaponActor);
	if (Pistol == None || WeaponActor.PlayerViewMesh != class'DispersionPistol'.default.PlayerViewMesh)
		return False;
	switch (Clamp(Pistol.PowerLevel, 0, 4))
	{
		case 0: IdleSequence = 'Idle1'; break;
		case 1: IdleSequence = 'Idle2'; break;
		case 2: IdleSequence = 'Idle3'; break;
		case 3: IdleSequence = 'Idle4'; break;
		case 4: IdleSequence = 'Idle5'; break;
	}
	SavedMesh = WeaponActor.Mesh;
	SavedScale = WeaponActor.DrawScale;
	SavedSequence = WeaponActor.AnimSequence;
	SavedFrame = WeaponActor.AnimFrame;
	SavedRotation = WeaponActor.Rotation;
	WeaponActor.Mesh = WeaponActor.PlayerViewMesh;
	WeaponActor.DrawScale = ModelScale;
	WeaponActor.AnimSequence = IdleSequence;
	WeaponActor.AnimFrame = 0;
	WeaponActor.SetRotation(rot(0,0,0));
	WeaponActor.AllFrameVerts(Vertices);
	WeaponActor.SetRotation(SavedRotation);
	WeaponActor.Mesh = SavedMesh;
	WeaponActor.DrawScale = SavedScale;
	WeaponActor.AnimSequence = SavedSequence;
	WeaponActor.AnimFrame = SavedFrame;
	if (Array_Size(Vertices) != 195) return False;
	if (Pistol.PowerLevel < 2)
		Barrel = (Vertices[2] + Vertices[13] + Vertices[10] + Vertices[11]) * 0.25;
	else
		Barrel = (Vertices[29] + Vertices[156]) * 0.5;
	Muzzle = Barrel - WeaponActor.Location + vect(1,0,0);
	return True;
}

function bool GetStockBarrel(Weapon W, out vector Barrel)
{
	local int VertexCount, FirstVertex, SecondVertex, VertexIndex;
	local name Sequence;
	local array<vector> Vertices;
	local vector FaceMin, FaceMax;
	Sequence = 'Still';
	if (AutoMag(W) != None && (W.PlayerViewMesh == mesh'AutoMagL' || W.PlayerViewMesh == mesh'AutoMagR'))
	{ VertexCount = 208; FirstVertex = 78; SecondVertex = 181; }
	else if (Eightball(W) != None && W.PlayerViewMesh == class'Eightball'.default.PlayerViewMesh)
	{ VertexCount = 219; FirstVertex = 149; SecondVertex = 151; Sequence = 'Idle'; }
	else if (FlakCannon(W) != None && W.PlayerViewMesh == class'FlakCannon'.default.PlayerViewMesh)
	{ VertexCount = 192; FirstVertex = 7; SecondVertex = 133; }
	else if (Rifle(W) != None && W.PlayerViewMesh == class'Rifle'.default.PlayerViewMesh)
	{ VertexCount = 177; FirstVertex = 19; SecondVertex = 129; }
	else if (Minigun(W) != None && W.PlayerViewMesh == class'Minigun'.default.PlayerViewMesh)
	{ VertexCount = 248; FirstVertex = 84; SecondVertex = 122; }
	else if (RazorJack(W) != None && W.PlayerViewMesh == class'RazorJack'.default.PlayerViewMesh)
	{ VertexCount = 136; FirstVertex = 103; SecondVertex = 115; Sequence = 'Idle'; }
	else if (GESBioRifle(W) != None && W.PlayerViewMesh == class'GESBioRifle'.default.PlayerViewMesh)
	{ VertexCount = 181; FirstVertex = 59; SecondVertex = 60; }
	else if (QuadShot(W) != None && (W.PlayerViewMesh == mesh'QuadShotHeldR' || W.PlayerViewMesh == mesh'QuadShotHeldL'))
	{ VertexCount = 1056; Sequence = 'Idle'; }
	else if (CARifle(W) != None && W.PlayerViewMesh == class'CARifle'.default.PlayerViewMesh)
	{ VertexCount = 175; FirstVertex = 124; SecondVertex = 125; }
	else if (GrenadeLauncher(W) != None && W.PlayerViewMesh == class'GrenadeLauncher'.default.PlayerViewMesh)
	{ VertexCount = 208; FirstVertex = 34; SecondVertex = 37; }
	else if (RocketLauncher(W) != None && W.PlayerViewMesh == class'RocketLauncher'.default.PlayerViewMesh)
	{ VertexCount = 164; FirstVertex = 103; SecondVertex = 104; }
	else if (Stinger(W) != None && W.PlayerViewMesh == class'Stinger'.default.PlayerViewMesh)
	{ VertexCount = 235; FirstVertex = 113; SecondVertex = 158; }
	else if (ASMD(W) != None && W.PlayerViewMesh == class'ASMD'.default.PlayerViewMesh)
	{ VertexCount = 154; FirstVertex = 0; SecondVertex = 6; }
	else return False;
	W.AnimSequence = Sequence;
	W.AnimFrame = 0;
	W.AllFrameVerts(Vertices);
	if (Array_Size(Vertices) != VertexCount) return False;
	if (QuadShot(W) != None)
	{
		FaceMin = Vertices[0];
		FaceMax = Vertices[0];
		for (VertexIndex = 1; VertexIndex < VertexCount; VertexIndex++)
		{
			if (Vertices[VertexIndex].X > FaceMax.X + 0.001)
			{
				FaceMin = Vertices[VertexIndex];
				FaceMax = Vertices[VertexIndex];
			}
			else if (Abs(Vertices[VertexIndex].X - FaceMax.X) <= 0.001)
			{
				FaceMin.Y = FMin(FaceMin.Y, Vertices[VertexIndex].Y);
				FaceMin.Z = FMin(FaceMin.Z, Vertices[VertexIndex].Z);
				FaceMax.Y = FMax(FaceMax.Y, Vertices[VertexIndex].Y);
				FaceMax.Z = FMax(FaceMax.Z, Vertices[VertexIndex].Z);
			}
		}
		Barrel = (FaceMin + FaceMax) * 0.5 - W.Location;
		return True;
	}
	Barrel = (Vertices[FirstVertex] + Vertices[SecondVertex]) * 0.5 - W.Location;
	return True;
}

function UpdateAnimatedRazorMuzzle(Weapon W, float ModelScale, out vector Muzzle)
{
	local Mesh SavedMesh;
	local float SavedScale;
	local rotator SavedRotation;
	local vector Barrel;
	if (RazorJack(W) == None || W.PlayerViewMesh != class'RazorJack'.default.PlayerViewMesh
		|| (W.AnimSequence != 'AltFire1' && W.AnimSequence != 'AltFire2' && W.AnimSequence != 'AltFire3'))
		return;
	SavedMesh = W.Mesh;
	SavedScale = W.DrawScale;
	SavedRotation = W.Rotation;
	W.Mesh = W.PlayerViewMesh;
	W.DrawScale = ModelScale;
	W.SetRotation(rot(0,0,0));
	if (W.GetVertexCount() == 136)
	{
		Barrel = (W.GetVertexPos(103) + W.GetVertexPos(115)) * 0.5 - W.Location;
		Muzzle = Barrel + vect(1,0,0);
	}
	W.SetRotation(SavedRotation);
	W.Mesh = SavedMesh;
	W.DrawScale = SavedScale;
}

function GetGeometry(Weapon W, out float DrawScale, out vector Muzzle, out vector ModelOffset)
{
	local int I;
	local Mesh SavedMesh;
	local float SavedScale, Extent, Factor;
	local float SavedFrame;
	local name SavedSequence;
	local rotator SavedRotation;
	local BoundingBox Bounds;
	local vector Size, Grip;
	local vector Barrel;
	local bool bStockBarrel;
	ModelOffset = vect(0,0,0);
	for (I = 0; I < Array_Size(Cache); I++)
		if (Cache[I].WeaponClass == W.Class && Cache[I].ViewMesh == W.PlayerViewMesh
			&& Cache[I].ViewScale == W.PlayerViewScale)
		{
			if (DispersionPistol(W) != None && Cache[I].BarrelPowerLevel != DispersionPistol(W).PowerLevel)
			{
				GetDispersionMuzzle(W, Cache[I].DrawScale, Cache[I].Muzzle);
				Cache[I].BarrelPowerLevel = DispersionPistol(W).PowerLevel;
			}
			DrawScale = Cache[I].DrawScale;
			Muzzle = Cache[I].Muzzle;
			ModelOffset = Cache[I].ModelOffset;
			UpdateAnimatedRazorMuzzle(W, DrawScale, Muzzle);
			return;
		}
	SavedMesh = W.Mesh;
	SavedScale = W.DrawScale;
	SavedRotation = W.Rotation;
	SavedSequence = W.AnimSequence;
	SavedFrame = W.AnimFrame;
	W.Mesh = W.PlayerViewMesh;
	W.DrawScale = W.PlayerViewScale;
	W.SetRotation(rot(0,0,0));
	// Stock barrel sampling selects the family's resting pose. Measure bounds
	// in that same pose, never the equip/fire frame encountered on first use.
	// Otherwise a motion-mode cache can change gaze size/centering after load.
	bStockBarrel = GetStockBarrel(W, Barrel);
	if (!bStockBarrel)
	{
		W.AnimSequence = SavedSequence;
		W.AnimFrame = SavedFrame;
	}
	// Keep the pistol's base size independent of its upgrade animation. Its
	// power-specific muzzle is refreshed separately below, as before.
	if (DispersionPistol(W) != None
		&& W.PlayerViewMesh == class'DispersionPistol'.default.PlayerViewMesh)
	{
		W.AnimSequence = 'Still';
		W.AnimFrame = 0;
	}
	Bounds = W.GetBoundingBox(True);
	W.SetRotation(SavedRotation);
	W.AnimSequence = SavedSequence;
	W.AnimFrame = SavedFrame;
	W.Mesh = SavedMesh;
	W.DrawScale = SavedScale;
	Size = Bounds.Max - Bounds.Min;
	Extent = FMax(Size.X, FMax(Size.Y, Size.Z));
	if (Bounds.IsValid == 0 || Extent < 0.01)
	{
		DrawScale = W.PlayerViewScale;
		Muzzle = W.Default.FireOffset;
		return;
	}
	// At world size 100%, the existing tracking conversion is 50 units/metre.
	Factor = 50.0 * LengthMetres(W.Class) / Extent;
	DrawScale = W.PlayerViewScale * Factor;
	Muzzle.X = (Bounds.Max.X - W.Location.X) * Factor + 1.0;
	Muzzle.Y = ((Bounds.Min.Y + Bounds.Max.Y) * 0.5 - W.Location.Y) * Factor;
	Muzzle.Z = ((Bounds.Min.Z + Bounds.Max.Z) * 0.5 - W.Location.Z) * Factor;
	if (bStockBarrel)
		Muzzle = Barrel * Factor + vect(1,0,0);
	GetDispersionMuzzle(W, DrawScale, Muzzle);
	if (ClassIsChildOf(W.Class, class'AutoMag'))
	{
		// Initial grip calibration: rear/lower part of the pistol, centered
		// laterally for either handed mesh. Keep this fixed through animation.
		Grip = Bounds.Min - W.Location;
		Grip.X += Size.X * 0.20;
		Grip.Y += Size.Y * 0.50;
		Grip.Z += Size.Z * 0.25;
		ModelOffset = -Grip * Factor;
		Muzzle += ModelOffset;
	}
	I = Array_Size(Cache);
	Array_Size(Cache, I + 1);
	Cache[I].WeaponClass = W.Class;
	Cache[I].ViewMesh = W.PlayerViewMesh;
	Cache[I].ViewScale = W.PlayerViewScale;
	Cache[I].DrawScale = DrawScale;
	Cache[I].Muzzle = Muzzle;
	Cache[I].ModelOffset = ModelOffset;
	if (DispersionPistol(W) != None)
		Cache[I].BarrelPowerLevel = DispersionPistol(W).PowerLevel;
	UpdateAnimatedRazorMuzzle(W, DrawScale, Muzzle);
}
