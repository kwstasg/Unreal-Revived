// Deterministic regression fixture for global refire while a state masks Fire.
class ModernVRMotionTestWeapon extends Weapon;

var int Shots;
var int AltShots;

function Fire(float Value) { Shots++; }
function AltFire(float Value) { AltShots++; }
function RefireGlobal() { Global.Fire(0); }
function RefireAltGlobal() { Global.AltFire(0); }

state TestFiring
{
	function Fire(float Value) {}
	function AltFire(float Value) {}
}

defaultproperties
{
	RemoteRole=ROLE_None
}
