#include "../VRControllerInput.h"
#include <cstdint>
#include <cstdlib>
#include <iostream>

struct State {
	uint32_t Buttons = 0;
	uint8_t LeftTrigger = 0, RightTrigger = 0;
	int16_t LeftX = 0, LeftY = 0, RightX = 0, RightY = 0;
};
void Check(bool Passed, const char* Message) {
	if (!Passed) { std::cerr << Message << '\n'; std::exit(1); }
}
int main() {
	State touch, xbox;
	touch.Buttons = 0x100; touch.RightTrigger = 200;
	touch.LeftX = 24000; touch.LeftY = 16000;
	xbox.Buttons = 0x1000; xbox.LeftTrigger = 120;
	xbox.RightX = -32768; xbox.RightY = -32768;
	VRControllerInput::Merge(touch, xbox);
	Check(touch.Buttons == 0x1100, "both devices' buttons survive merging");
	Check(touch.LeftTrigger == 120 && touch.RightTrigger == 200, "both devices' held triggers survive");
	Check(touch.LeftX == 24000 && touch.LeftY == 16000, "idle Xbox stick cannot suppress Touch movement");
	Check(touch.RightX == -32768 && touch.RightY == -32768, "full-range diagonal cannot overflow magnitude");
	State heldTouch; heldTouch.RightTrigger = 255;
	VRControllerInput::Merge(heldTouch, State{});
	Check(heldTouch.RightTrigger == 255, "Xbox release cannot release a held Touch trigger");
	State disconnectedTouch;
	VRControllerInput::Merge(disconnectedTouch, xbox);
	Check(disconnectedTouch.Buttons == xbox.Buttons && disconnectedTouch.RightX == xbox.RightX,
		"Xbox retains input after Touch disconnects");
	std::cout << "VR gamepad input merge tests passed\n";
}
