#define XR_NO_PROTOTYPES
#include "../OpenXRPoseMath.h"
#include <cstdlib>
#include <iostream>

// FVector-compatible arithmetic lets the production helpers run without the host SDK.
struct Vector
{
	float X, Y, Z;
	Vector(float X, float Y, float Z) : X(X), Y(Y), Z(Z) {}
	Vector operator+(Vector B) const { return {X+B.X,Y+B.Y,Z+B.Z}; }
	Vector operator*(float S) const { return {X*S,Y*S,Z*S}; }
	Vector operator^(Vector B) const { return {Y*B.Z-Z*B.Y,Z*B.X-X*B.Z,X*B.Y-Y*B.X}; }
};
void Check(bool Passed, const char* Message)
{
	if (!Passed) { std::cerr << Message << '\n'; std::exit(1); }
}
bool Near(float A, float B) { return std::abs(A-B) < 0.0001f; }
bool Near(Vector A, Vector B) { return Near(A.X,B.X) && Near(A.Y,B.Y) && Near(A.Z,B.Z); }
float Dot(Vector A, Vector B) { return A.X*B.X+A.Y*B.Y+A.Z*B.Z; }

int main()
{
	Check(Near(OpenXRVectorToUnreal(Vector(0,0,-1)), Vector(1,0,0)), "forward coordinate conversion");
	Check(Near(OpenXRVectorToUnreal(Vector(1,0,0)), Vector(0,1,0)), "right coordinate conversion");
	Check(Near(OpenXRVectorToUnreal(Vector(0,1,0)), Vector(0,0,1)), "up coordinate conversion");
	const auto Identity = NormalizeOpenXRQuaternion({0,0,0,0});
	Check(Near(Identity.w,1), "invalid quaternion has safe identity fallback");
	const XrQuaternionf LeftEye = {0,-std::sin(0.05f),0,std::cos(0.05f)};
	const XrQuaternionf RightEye = {0,std::sin(0.05f),0,std::cos(0.05f)};
	const auto Center = OpenXRHeadOrientationFromViews(LeftEye,RightEye);
	Check(Near(Center.y,0) && Near(Center.w,1), "canted eye fallback does not inherit the left eye yaw");
	const auto Parallel = OpenXRHeadOrientationFromViews(LeftEye,LeftEye);
	Check(!OpenXREyesHaveDifferentOrientations(LeftEye,LeftEye), "parallel eyes retain the original head path");
	Check(Near(Parallel.y,LeftEye.y) && Near(Parallel.w,LeftEye.w), "parallel-eye baseline unchanged");
	const XrQuaternionf NegativeRight = {-RightEye.x,-RightEye.y,-RightEye.z,-RightEye.w};
	Check(Near(OpenXRHeadOrientationFromViews(LeftEye,NegativeRight).w,1), "head midpoint accepts opposite quaternion signs");
	for (float Yaw : {-2.0f, 0.0f, 1.5f})
		for (float Pitch : {-1.2f, 0.0f, 1.2f})
			for (float Roll : {-0.7f, 0.0f, 0.7f})
			{
				const XrQuaternionf Heading = {0,std::sin(Yaw/2),0,std::cos(Yaw/2)};
				const auto Tilt = MultiplyOpenXRQuaternions(
					{std::sin(Pitch/2),0,0,std::cos(Pitch/2)},
					{0,0,std::sin(Roll/2),std::cos(Roll/2)});
				const auto Head = MultiplyOpenXRQuaternions(Heading,Tilt);
				const auto Base = OpenXRWorldHeading(Head,Identity);
				Check(Near(RotateOpenXRVector(Base,Vector(0,1,0)),Vector(0,1,0)), "recenter reference preserves gravity");
				const auto Relative = OpenXREyeToHeadOrientation(Base,Head);
				Check(Near(RotateOpenXRVector(Relative,Vector(0,1,0)),RotateOpenXRVector(Tilt,Vector(0,1,0))), "recenter retains natural pitch and roll");
				const auto Straightened = OpenXREyeToHeadOrientation(Base,Heading);
				Check(Near(RotateOpenXRVector(Straightened,Vector(0,0,-1)),Vector(0,0,-1)) &&
					Near(RotateOpenXRVector(Straightened,Vector(0,1,0)),Vector(0,1,0)), "straightening after tilted recenter leaves no world tilt");
				const XrQuaternionf Turn = {0,std::sin(0.3f),0,std::cos(0.3f)};
				const auto Turned = OpenXREyeToHeadOrientation(Base,MultiplyOpenXRQuaternions(Heading,Turn));
				Check(Near(RotateOpenXRVector(Turned,Vector(0,0,-1)),RotateOpenXRVector(Turn,Vector(0,0,-1))), "yaw turning survives recenter");
				const auto Scripted = MultiplyOpenXRQuaternions(Tilt,Straightened);
				Check(Near(RotateOpenXRVector(Scripted,Vector(0,1,0)),RotateOpenXRVector(Tilt,Vector(0,1,0))), "authored camera tilt remains in base-camera composition");
				for (float Vertical : {-1.570796327f,1.570796327f})
				{
					const auto LookingVertical = MultiplyOpenXRQuaternions(Heading,
						{std::sin(Vertical/2),0,0,std::cos(Vertical/2)});
					const auto Stable = OpenXRWorldHeading(LookingVertical,Base);
					Check(Near(RotateOpenXRVector(Stable,Vector(0,0,-1)),RotateOpenXRVector(Base,Vector(0,0,-1))), "vertical recenter retains previous heading");
				}
			}
	for (float Yaw : {-2.0f,0.0f,1.5f})
		for (float Pitch : {-0.8f,0.0f,0.8f})
			for (float Cant : {-0.2f,-0.08726646f,0.0f,0.08726646f,0.2f})
			{
				const XrQuaternionf Heading = {0,std::sin(Yaw/2),0,std::cos(Yaw/2)};
				const XrQuaternionf Tilt = {std::sin(Pitch/2),0,0,std::cos(Pitch/2)};
				const auto Head = MultiplyOpenXRQuaternions(Heading,Tilt);
				const XrQuaternionf EyeOffset = {0,std::sin(Cant/2),0,std::cos(Cant/2)};
				const auto Eye = NormalizeOpenXRQuaternion(MultiplyOpenXRQuaternions(Head,EyeOffset));
				const auto Relative = OpenXREyeToHeadOrientation(Head,Eye);
				const auto Forward = RotateOpenXRVector(Relative,Vector(0,0,-1));
				Check(Near(Forward,Vector(-std::sin(Cant),0,-std::cos(Cant))), "independent eye cant survives head-relative conversion");
				const auto Right = RotateOpenXRVector(Eye,Vector(1,0,0));
				const auto Up = RotateOpenXRVector(Eye,Vector(0,1,0));
				const auto WorldForward = RotateOpenXRVector(Eye,Vector(0,0,-1));
				Check(Near(Dot(Right,Up),0) && Near(Dot(Up,WorldForward),0) && Near(Dot(Right,WorldForward),0), "eye basis remains orthogonal");
				Check(Near(Dot(Right,Right),1) && Near(Dot(Up,Up),1) && Near(Dot(WorldForward,WorldForward),1), "eye basis retains unit scale");
				const XrQuaternionf Negative = {-Eye.x,-Eye.y,-Eye.z,-Eye.w};
				Check(Near(RotateOpenXRVector(Negative,Vector(0,0,-1)),WorldForward), "equivalent quaternion signs do not flip the view");
			}
	std::cout << "Rotated eye basis, cant and coordinate conversion checks passed\n";
}
