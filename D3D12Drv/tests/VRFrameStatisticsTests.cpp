#include "../VRFrameStatistics.h"
#include <cmath>
#include <cstdlib>
#include <iostream>
void Check(bool OK, const char* Message)
{
	if (!OK) { std::cerr << Message << '\n'; std::exit(1); }
}
int main()
{
	VRFrameStatistics Stats;
	Check(Stats.Value(0, 0) == 0, "No frames must report zero");
	for (int Frame = 0; Frame <= 180; ++Frame) Stats.Submit(Frame / 90.0);
	Check(std::abs(Stats.Value(0, 2) - 90) < 0.01, "90 stereo pairs must report 90 FPS");
	Check(std::abs(Stats.Value(1, 2) - 90) < 0.01, "Average uses elapsed wall time");
	Check(Stats.Value(0, 5) == 0, "Stopped submission must not retain live FPS");
	Stats.Submit(5);
	Check(Stats.Value(0, 5) < 1, "Stalls must be included in frame time");
	Check(Stats.Value(2, 5) < 1 && Stats.Value(3, 5) > 89, "Extremes track sampling windows");
	Stats = {};
	Check(Stats.Value(1, 10) == 0, "Reset removes previous session samples");
}
