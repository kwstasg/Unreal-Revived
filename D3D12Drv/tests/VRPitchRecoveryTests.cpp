#include "../VRPitchRecovery.h"
#include <cstdlib>
#include <iostream>
void Check(bool Passed, const char* Message)
{
	if (!Passed) { std::cerr << Message << '\n'; std::exit(1); }
}
int main()
{
	VRPitchRecovery Fallback;
	Check(Fallback.Pending, "First VR frame must level desktop-save tilt");
	Fallback.Focused(); Fallback.Pending = false;
	Fallback.Focused();
	Check(!Fallback.Pending, "Overlay focus return alone must not trigger recovery");
	Fallback.Hidden(); Fallback.Focused();
	Check(Fallback.Pending, "Hidden-to-focused fallback must recover pitch");
	VRPitchRecovery Presence;
	Presence.HasPresenceEvents = true;
	Presence.Presence(true); Presence.Pending = false;
	Presence.Hidden(); Presence.Focused();
	Check(!Presence.Pending, "Presence-capable runtimes must ignore visibility for remount");
	Presence.Presence(true);
	Check(!Presence.Pending, "Duplicate present event must not reset pitch");
	Presence.Presence(false); Presence.Presence(true);
	Check(Presence.Pending, "Actual remount must recover pitch");
}
