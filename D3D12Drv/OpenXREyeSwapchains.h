#pragma once
#include "VRRenderSizing.h"
#include <openxr/openxr.h>

namespace OpenXREyeSwapchains
{
// Own creation of the pair as one transaction: a rejected optional eye size
// must not leave one eye at a different quality from the other.
struct Pair
{
	XrSwapchain Handles[2] = { XR_NULL_HANDLE, XR_NULL_HANDLE };
	VRRenderSizing::Size Sizes[2] = {};
	int Quality = 0;
	bool FellBack = false;
};

inline bool Create(XrSession Session, const XrViewConfigurationView* Views, int Quality,
	int64_t Format, PFN_xrCreateSwapchain CreateSwapchain, PFN_xrDestroySwapchain DestroySwapchain,
	Pair& Result)
{
	Result = {};
	Result.Quality = VRRenderSizing::NormalizeQuality(Quality);
	for (;;)
	{
		bool Success = true;
		for (int Eye = 0; Eye < 2; ++Eye)
		{
			const auto& View = Views[Eye];
			const VRRenderSizing::Size Recommended = {
				static_cast<int>(View.recommendedImageRectWidth), static_cast<int>(View.recommendedImageRectHeight) };
			Result.Sizes[Eye] = VRRenderSizing::EyeSize(Result.Quality, Recommended,
				View.recommendedImageRectWidth, View.recommendedImageRectHeight,
				View.maxImageRectWidth, View.maxImageRectHeight);
			XrSwapchainCreateInfo Info = { XR_TYPE_SWAPCHAIN_CREATE_INFO };
			Info.usageFlags = XR_SWAPCHAIN_USAGE_COLOR_ATTACHMENT_BIT;
			Info.format = Format;
			Info.sampleCount = Info.faceCount = Info.arraySize = Info.mipCount = 1;
			Info.width = Result.Sizes[Eye].Width;
			Info.height = Result.Sizes[Eye].Height;
			if (XR_FAILED(CreateSwapchain(Session, &Info, &Result.Handles[Eye])) ||
				Result.Handles[Eye] == XR_NULL_HANDLE)
			{
				Result.Handles[Eye] = XR_NULL_HANDLE;
				Success = false;
				break;
			}
		}
		if (Success)
			return true;
		for (auto& Handle : Result.Handles)
		{
			if (Handle != XR_NULL_HANDLE)
				DestroySwapchain(Handle);
			Handle = XR_NULL_HANDLE;
		}
		if (!Result.Quality)
			return false;
		Result.Quality = 0;
		Result.FellBack = true;
	}
}
}
