#pragma once
#include <chrono>

// One sample per successfully submitted stereo frame, measured in wall time.
struct VRFrameStatistics
{
	double Start = -1, WindowStart = -1, Last = -1;
	double FPS = 0, Low = 0, High = 0;
	unsigned long long Frames = 0, WindowFrames = 0;
	static double Now()
	{
		return std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();
	}
	void Submit(double Time)
	{
		if (Start < 0) { Start = WindowStart = Last = Time; return; }
		Last = Time;
		++Frames;
		++WindowFrames;
		const double Elapsed = Time - WindowStart;
		if (Elapsed >= 1.0)
		{
			FPS = WindowFrames / Elapsed;
			if (Low == 0 || FPS < Low) Low = FPS;
			if (FPS > High) High = FPS;
			WindowFrames = 0;
			WindowStart = Time;
		}
	}
	double Value(int Index, double Time) const
	{
		if (Index == 1) return Start >= 0 && Time > Start ? Frames / (Time - Start) : 0;
		if (Index == 2) return Low;
		if (Index == 3) return High;
		return Last >= 0 && Time - Last < 2.0 ? FPS : 0;
	}
};
