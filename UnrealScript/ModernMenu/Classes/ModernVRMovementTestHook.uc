// Deterministic headset pose for the real PlayerPawn movement hooks.
class ModernVRMovementTestHook extends ModernVRAimHook;
var rotator TestHead;
var bool bPoseActive;
function bool GetMovementRotation(PlayerPawn Player, out rotator Aim)
{
	if (!bPoseActive) return False;
	Aim = class'ModernVRAimSupport'.static.ComposeRotation(Player.ViewRotation, TestHead);
	return True;
}
