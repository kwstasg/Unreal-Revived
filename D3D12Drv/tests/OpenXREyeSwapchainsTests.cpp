#define XR_NO_PROTOTYPES
#include "../OpenXREyeSwapchains.h"
#include <cstdlib>
#include <iostream>
#include <vector>

namespace {
std::vector<XrSwapchainCreateInfo> Requests;
int Destroyed = 0, FailCall = 0;
bool AlwaysFail = false;
void Check(bool Passed, const char* Message)
{
	if (!Passed) { std::cerr << Message << '\n'; std::exit(1); }
}
XrResult XRAPI_PTR Create(XrSession, const XrSwapchainCreateInfo* Info, XrSwapchain* Handle)
{
	Requests.push_back(*Info);
	if (AlwaysFail || static_cast<int>(Requests.size()) == FailCall)
		return XR_ERROR_SWAPCHAIN_FORMAT_UNSUPPORTED;
	*Handle = reinterpret_cast<XrSwapchain>(static_cast<uintptr_t>(Requests.size()));
	return XR_SUCCESS;
}
XrResult XRAPI_PTR Destroy(XrSwapchain Handle)
{
	Check(Handle != XR_NULL_HANDLE, "never destroy null handles");
	++Destroyed;
	return XR_SUCCESS;
}
void Reset() { Requests.clear(); Destroyed = 0; FailCall = 0; AlwaysFail = false; }
}

int main()
{
	XrViewConfigurationView Views[2] = { {XR_TYPE_VIEW_CONFIGURATION_VIEW}, {XR_TYPE_VIEW_CONFIGURATION_VIEW} };
	for (auto& View : Views)
	{
		View.recommendedImageRectWidth = 1344;
		View.recommendedImageRectHeight = 1600;
		View.maxImageRectWidth = View.maxImageRectHeight = 4096;
	}
	OpenXREyeSwapchains::Pair Pair;
	const uint32_t Widths[] = {1344,1008,1344,1680,2016};
	const uint32_t Heights[] = {1600,1200,1600,2000,2400};
	for (int Quality = 0; Quality <= 4; ++Quality)
	{
		Reset();
		Check(OpenXREyeSwapchains::Create(XR_NULL_HANDLE, Views, Quality, 29, Create, Destroy, Pair), "pair created");
		Check(Requests.size() == 2 && Destroyed == 0 && !Pair.FellBack, "normal path creates exactly two eyes");
		for (const auto& Request : Requests)
		{
			Check(Request.width == Widths[Quality] && Request.height == Heights[Quality],
				"actual runtime output must scale with preset, including Ultra");
			Check(Request.format == 29 && Request.sampleCount == 1 && Request.arraySize == 1 &&
				Request.usageFlags == XR_SWAPCHAIN_USAGE_COLOR_ATTACHMENT_BIT, "preserve swapchain format and flags");
		}
	}
	Reset(); FailCall = 2;
	Check(OpenXREyeSwapchains::Create(XR_NULL_HANDLE, Views, 4, 29, Create, Destroy, Pair), "second eye failure recovers");
	Check(Destroyed == 1 && Requests.size() == 4 && Pair.Quality == 0 && Pair.FellBack,
		"release partial pair before retrying both at current profile");
	Check(Requests[2].width == 1344 && Requests[3].height == 1600, "fallback keeps both eyes at recommendations");
	Reset(); FailCall = 1;
	Check(OpenXREyeSwapchains::Create(XR_NULL_HANDLE, Views, 3, 29, Create, Destroy, Pair), "first eye failure recovers");
	Check(Destroyed == 0 && Requests.size() == 3 && Pair.FellBack, "first eye failure leaves no partial allocation");
	Reset(); AlwaysFail = true;
	Check(!OpenXREyeSwapchains::Create(XR_NULL_HANDLE, Views, 4, 29, Create, Destroy, Pair), "baseline failure is reported");
	Check(Requests.size() == 2 && Pair.Handles[0] == XR_NULL_HANDLE && Pair.Handles[1] == XR_NULL_HANDLE,
		"failed fallback terminates without live handles");
	Reset();
	Views[1].recommendedImageRectWidth = 1400;
	Views[1].maxImageRectHeight = 1800;
	Check(OpenXREyeSwapchains::Create(XR_NULL_HANDLE, Views, 4, 29, Create, Destroy, Pair), "asymmetric size pair");
	Check(Requests[0].width == 2016 && Requests[1].width == 1575 && Requests[1].height == 1800,
		"clamp each view uniformly without assuming identical eyes");
	// Synthetic runtime recommendations, not panel specifications or headset certification.
	for (uint32_t Width : {1024u, 1832u, 2448u, 2880u, 4200u, 6000u})
		for (int Quality = 1; Quality <= 4; ++Quality)
		{
			Reset();
			for (int Eye = 0; Eye < 2; ++Eye)
			{
				Views[Eye].recommendedImageRectWidth = Width + Eye * 32;
				Views[Eye].recommendedImageRectHeight = Width + 256;
				Views[Eye].maxImageRectWidth = 8192;
				Views[Eye].maxImageRectHeight = 7000;
			}
			Check(OpenXREyeSwapchains::Create(XR_NULL_HANDLE, Views, Quality, 29, Create, Destroy, Pair),
				"varied runtime dimensions supported");
			for (int Eye = 0; Eye < 2; ++Eye)
			{
				const auto& Request = Requests[Eye];
				Check(Request.width > 0 && Request.width <= 8192 && Request.height > 0 && Request.height <= 7000,
					"both dimensions respect runtime limits across quality range");
				const double Ratio = double(Views[Eye].recommendedImageRectWidth) / Views[Eye].recommendedImageRectHeight;
				Check(std::abs(double(Request.width) / Request.height - Ratio) < 0.002,
					"clamping never independently stretches either eye");
			}
		}
	std::cout << "OpenXR output sizing and stereo allocation fallback checks passed\n";
}
