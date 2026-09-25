#include "../VRTurning.h"
#include <cstdlib>
#include <iostream>
#include <limits>

void Check(bool OK, const char* Message)
{
	if (!OK) { std::cerr << Message << '\n'; std::exit(1); }
}
int main()
{
	VRTurning Turn;
	const int Thirty = static_cast<int>(std::round(30 * 65536.0 / 360));
	Check(Turn.Step(1, .01f, 1, 30, true) == 0, "held stick on activation must not snap");
	Turn.Step(0, .01f, 1, 30, true);
	Check(Turn.Step(.65f, .01f, 1, 30, true) == 0, "threshold rejects small deflection");
	Check(Turn.Step(1, .01f, 1, 30, true) == Thirty, "instant snap completes in one update");
	for (int I = 0; I < 100; ++I) Check(Turn.Step(1, .01f, 1, 30, true) == 0, "held stick must not repeat");
	Check(Turn.Step(-1, .01f, 1, 30, true) == 0, "reversal requires neutral too");
	Turn.Step(0, .01f, 1, 30, true);
	Check(Turn.Step(-1, .01f, 1, 30, true) == -Thirty, "left snap retains sign");
	for (int FPS : {30, 72, 90, 144, 1000})
		for (int Angle : {15, 30, 45, 60, 75, 90})
		{
			Turn.Reset();
			const float DT = 1.0f / FPS;
			Turn.Step(0, DT, 2, Angle, true);
			int Total = 0;
			for (int I = 0; I < FPS; ++I) {
				const int Delta = Turn.Step(1, DT, 2, Angle, true);
				Check(Delta >= 0, "animation never reverses");
				Total += Delta;
			}
			Check(Total == static_cast<int>(std::round(Angle * 65536.0 / 360)), "animated snap ends at exact angle at every frame rate");
		}
	Turn.Reset(); Turn.Step(0, .01f, 2, 30, true);
	const int First = Turn.Step(1, .01f, 2, 30, true);
	Check(First > 0 && First < Thirty, "animated snap starts gradually");
	Check(Turn.Step(1, .01f, 2, 30, false) == 0, "menu, pause or tracking loss cancels animation");
	Check(Turn.Step(1, .01f, 2, 30, true) == 0, "resume requires neutral");
	Turn.Step(0, .01f, 2, 30, true);
	Check(Turn.Step(1, .5f, 2, 30, true) == 0, "long input gap cancels turn");
	Turn.Step(0, .01f, 1, 30, true);
	Check(Turn.Step(1, .01f, 0, 30, true) == 0, "smooth mode leaves original axis path untouched");
	Check(Turn.Step(std::numeric_limits<float>::quiet_NaN(), .01f, 1, 30, true) == 0, "nonfinite input cancels safely");
	Check(VRTurning::Angle(31) == 30 && VRTurning::Angle(200) == 90 && VRTurning::Angle(-1) == 15, "snap angle bounds and steps");
}
