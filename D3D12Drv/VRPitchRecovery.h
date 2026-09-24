#pragma once

struct VRPitchRecovery
{
	bool HasPresenceEvents = false;
	bool WasPresent = false;
	bool WasHidden = true;
	bool Pending = true;
	void Presence(bool Present)
	{
		if (Present && !WasPresent) Pending = true;
		WasPresent = Present;
	}
	void Hidden() { WasHidden = true; }
	void Focused()
	{
		if (!HasPresenceEvents && WasHidden) Pending = true;
		WasHidden = false;
	}
};
