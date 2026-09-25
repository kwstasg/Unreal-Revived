#include "../VRPanelFollow.h"
#include <cstdlib>
#include <iostream>

void Check(bool OK, const char* Message)
{
	if (!OK) { std::cerr << Message << '\n'; std::exit(1); }
}
bool Near(float A, float B) { return std::abs(A-B) < 0.0001f; }
int main()
{
	VRPanelFollow Follow;
	VRPanelFollow::Position Anchor = {0,1.2f,0};
	float Yaw = 0;
	for (int I=0; I<900; ++I)
		Follow.Update(1.0f/90, true, false, {0.05f,1.25f,0.03f},0.3f,Anchor,Yaw);
	Check(Near(Anchor.x,0) && Near(Anchor.y,1.2f) && Near(Yaw,0), "small seated motion leaves accepted anchor fixed");
	for (int I=0; I<20; ++I)
		Follow.Update(1.0f/90,true,false,{0,1.8f,0},1.5f,Anchor,Yaw);
	Check(Near(Anchor.y,1.2f) && Near(Yaw,0), "brief movement/glance does not trigger follow");
	Follow.Reset();
	for (int I=0; I<180; ++I) {
		const float PreviousY = Anchor.y, PreviousYaw = Yaw;
		Follow.Update(1.0f/90,true,false,{0,1.8f,0},1.5f,Anchor,Yaw);
		Check(Anchor.y >= PreviousY && Anchor.y <= 1.8f && Anchor.y-PreviousY <= 1.5f/90+0.0001f, "standing catch-up is bounded without overshoot");
		Check(Yaw >= PreviousYaw && Yaw-PreviousYaw <= 1.57079633f/90+0.0001f, "yaw catch-up is bounded");
	}
	Check(std::abs(Anchor.y-1.8f) <= .02f && std::abs(Yaw-1.5f) < .262f, "standing panel returns near the player and into view");
	// Open menu already within reach: no jump; all later manipulation freezes pose.
	const auto Saved = Anchor; const float SavedYaw = Yaw;
	Follow.Update(.01f,true,true,{0,1.8f,0},1.5f,Anchor,Yaw);
	for (int I=0; I<100; ++I) Follow.Update(.01f,true,true,{2,1.8f,0},-1.5f,Anchor,Yaw);
	Check(Near(Anchor.y,Saved.y) && Near(Anchor.x,Saved.x) && Near(Yaw,SavedYaw), "open menu and sliders remain stationary");
	Follow.Update(.01f,true,false,Saved,SavedYaw,Anchor,Yaw);
	Follow.Update(.01f,true,true,{2,1.8f,0},-1.5f,Anchor,Yaw);
	Check(Near(Anchor.x,2) && Near(Yaw,-1.5f), "explicit opening of a lost menu summons it once");
	Follow.Reset(); Anchor={0,1.2f,0}; Yaw=3.13f;
	for (int I=0; I<100; ++I) Follow.Update(.01f,true,false,Anchor,-3.13f,Anchor,Yaw);
	Check(Near(Yaw,3.13f), "heading wrap does not cause an almost full-circle turn");
	for (int I=0; I<100; ++I) Follow.Update(.01f,false,false,{2,1.8f,0},0,Anchor,Yaw);
	Check(Near(Anchor.x,0) && Near(Yaw,3.13f), "invalid tracking/focus freezes panel");
	Follow.Update(.5f,true,false,{2,1.8f,0},0,Anchor,Yaw);
	Check(Near(Anchor.x,0), "long tracking gap does not jump panel");
	for (int FPS : {30,72,90,144,1000}) {
		Follow.Reset(); Anchor={0,1.2f,0}; Yaw=0;
		for (int I=0; I<3*FPS; ++I) Follow.Update(1.0f/FPS,true,false,{1,1.8f,1},1.5f,Anchor,Yaw);
		Check(std::abs(Anchor.x-1)<.02f && std::abs(Anchor.y-1.8f)<.02f && std::abs(Yaw-1.5f)<.262f, "follow converges at varied frame rates");
	}
}
