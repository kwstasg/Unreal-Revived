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

inline XrQuaternionf OpenXREyeToHeadOrientation(const XrQuaternionf& Head, const XrQuaternionf& Eye)
{
	const auto H = NormalizeOpenXRQuaternion(Head);
	return NormalizeOpenXRQuaternion(MultiplyOpenXRQuaternions({-H.x,-H.y,-H.z,H.w},
		NormalizeOpenXRQuaternion(Eye)));
}

inline bool OpenXREyesHaveDifferentOrientations(const XrQuaternionf& Left, const XrQuaternionf& Right)
{
	const auto A = NormalizeOpenXRQuaternion(Left);
	const auto B = NormalizeOpenXRQuaternion(Right);
	return std::abs(A.x*B.x + A.y*B.y + A.z*B.z + A.w*B.w) < 0.999999f;
}

inline XrQuaternionf OpenXRHeadOrientationFromViews(const XrQuaternionf& Left, const XrQuaternionf& Right)
{
	const auto A = NormalizeOpenXRQuaternion(Left);
	if (!OpenXREyesHaveDifferentOrientations(Left,Right)) return A;
	const auto B = NormalizeOpenXRQuaternion(Right);
	const float Sign = A.x*B.x + A.y*B.y + A.z*B.z + A.w*B.w < 0 ? -1.0f : 1.0f;
	return NormalizeOpenXRQuaternion({A.x+Sign*B.x,A.y+Sign*B.y,A.z+Sign*B.z,A.w+Sign*B.w});
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
