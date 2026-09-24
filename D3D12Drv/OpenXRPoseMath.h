// Shared by the renderer and standalone pose regressions.
#pragma once
#include <cmath>
#include <openxr/openxr.h>

inline XrQuaternionf MultiplyOpenXRQuaternions(const XrQuaternionf& A, const XrQuaternionf& B)
{
	return {
		A.w * B.x + A.x * B.w + A.y * B.z - A.z * B.y,
		A.w * B.y - A.x * B.z + A.y * B.w + A.z * B.x,
		A.w * B.z + A.x * B.y - A.y * B.x + A.z * B.w,
		A.w * B.w - A.x * B.x - A.y * B.y - A.z * B.z
	};
}

inline XrQuaternionf NormalizeOpenXRQuaternion(const XrQuaternionf& Q)
{
	const float Length = std::sqrt(Q.x * Q.x + Q.y * Q.y + Q.z * Q.z + Q.w * Q.w);
	if (Length <= 0.00001f)
		return { 0.0f, 0.0f, 0.0f, 1.0f };
	const float InverseLength = 1.0f / Length;
	return { Q.x * InverseLength, Q.y * InverseLength, Q.z * InverseLength, Q.w * InverseLength };
}

template<class VectorType>
inline VectorType RotateOpenXRVector(const XrQuaternionf& Q, const VectorType& Vector)
{
	const VectorType QuaternionVector(Q.x, Q.y, Q.z);
	const VectorType TwiceCross = (QuaternionVector ^ Vector) * 2.0f;
	return Vector + TwiceCross * Q.w + (QuaternionVector ^ TwiceCross);
}

template<class VectorType>
inline VectorType OpenXRVectorToUnreal(const VectorType& Vector)
{
	// OpenXR is +X right, +Y up, -Z forward. UE1 is +X forward, +Y right, +Z up.
	return VectorType(-Vector.Z, Vector.X, Vector.Y);
}
