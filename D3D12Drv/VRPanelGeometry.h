// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived

// Shared, engine-independent geometry for the upright VR UI panel.
#pragma once
#include <cmath>

namespace VRPanelGeometry
{
	struct Quaternion { float x, y, z, w; };
	inline Quaternion Upright(float ForwardX, float ForwardZ, Quaternion Previous)
	{
		if (ForwardX * ForwardX + ForwardZ * ForwardZ <= 0.0001f)
			return Previous;
		const float HalfYaw = 0.5f * std::atan2(-ForwardX, -ForwardZ);
		return { 0.0f, std::sin(HalfYaw), 0.0f, std::cos(HalfYaw) };
	}
	inline float Width(float Scale)
	{
		return 2.0f * 1.75f * std::tan(64.0f * 3.14159265f / 360.0f) * Scale;
	}
	inline float Height(float PanelWidth, int SourceWidth, int SourceHeight)
	{
		return PanelWidth * SourceHeight / (SourceWidth > 0 ? SourceWidth : 1);
	}
}
