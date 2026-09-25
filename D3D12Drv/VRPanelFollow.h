#pragma once
#include <algorithm>
#include <cmath>

// Automatic, upright panel recovery. Small seated motion leaves the anchor fixed.
class VRPanelFollow
{
public:
	struct Position { float x, y, z; };
	static float Difference(float A, float B) { return std::atan2(std::sin(A-B), std::cos(A-B)); }
	void Reset() { PositionDelay = YawDelay = 0; MovePosition = MoveYaw = WasMenu = false; }
	void Update(float Seconds, bool Active, bool Menu, Position Head, float HeadYaw, Position& Anchor, float& Yaw)
	{
		if (!Active || !std::isfinite(Seconds) || Seconds <= 0 || Seconds > 0.25f)
		{
			PositionDelay = YawDelay = 0;
			MovePosition = MoveYaw = false;
			WasMenu = Menu;
			return;
		}
		const Position Delta = {Head.x-Anchor.x, Head.y-Anchor.y, Head.z-Anchor.z};
		const float Distance = std::sqrt(Delta.x*Delta.x + Delta.y*Delta.y + Delta.z*Delta.z);
		const float Angle = Difference(HeadYaw, Yaw);
		constexpr float StartYaw = 35.0f * 3.14159265f / 180.0f;
		constexpr float StopYaw = 15.0f * 3.14159265f / 180.0f;
		if (Menu)
		{
			// Opening a lost menu explicitly summons it once. Normal seated menu
			// transitions and all interaction within an open menu stay stationary.
			if (!WasMenu && (Distance > 0.20f || std::abs(Angle) > StartYaw))
			{
				Anchor = Head;
				Yaw = HeadYaw;
			}
			PositionDelay = YawDelay = 0;
			MovePosition = MoveYaw = false;
			WasMenu = true;
			return;
		}
		WasMenu = false;
		PositionDelay = Distance > 0.20f ? PositionDelay + Seconds : 0;
		YawDelay = std::abs(Angle) > StartYaw ? YawDelay + Seconds : 0;
		MovePosition = (MovePosition || PositionDelay >= 0.30f) && Distance > 0.02f;
		MoveYaw = (MoveYaw || YawDelay >= 0.30f) && std::abs(Angle) > StopYaw;
		if (!MovePosition && !MoveYaw)
			return;
		const float Blend = 1.0f - std::exp(-6.0f * Seconds);
		if (MovePosition)
		{
			const float Fraction = std::min(Blend, 1.5f * Seconds / Distance);
			Anchor.x += Delta.x * Fraction;
			Anchor.y += Delta.y * Fraction;
			Anchor.z += Delta.z * Fraction;
		}
		if (MoveYaw)
		{
			const float Step = std::min({std::abs(Angle)*Blend, 1.57079633f*Seconds, std::abs(Angle)-StopYaw});
			Yaw += Angle < 0 ? -Step : Step;
		}
	}
private:
	float PositionDelay = 0, YawDelay = 0;
	bool MovePosition = false, MoveYaw = false, WasMenu = false;
};
