// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived


#include "Precomp.h"
#include "UD3D12RenderDevice.h"
#include "CachedTexture.h"
#include "UTF16.h"
#include "FileResource.h"
#include "halffloat.h"
#include "VRPanelGeometry.h"
#include "VRRenderSizing.h"
#include "OpenXREyeSwapchains.h"

IMPLEMENT_CLASS(UD3D12RenderDevice);

#if defined(UNREAL_227)
class FViewportOutputAccessor : public UViewport
{
public:
	static FViewportCallback*& Get(UViewport* InViewport)
	{
		return InViewport->*(&FViewportOutputAccessor::OutputDev);
	}
};

class FD3D12ViewportCallback final : public FViewportCallback
{
public:
	FD3D12ViewportCallback(UViewport* InViewport, UD3D12RenderDevice* InRenderer, FViewportCallback* InOriginal)
		: FViewportCallback(InViewport), Renderer(InRenderer), Original(InOriginal)
	{
	}

	void ViewportDestroyed() override { Original->ViewportDestroyed(); }
	void Draw(UBOOL Blit) override { Renderer->DrawViewportWithOpenXR(Original, Blit); }
	UBOOL InputEvent(EInputKey Key, EInputAction State, FLOAT Delta) override { return Original->InputEvent(Key, State, Delta); }
	UBOOL Key(EInputKey Key, INT KeyValue) override { return Original->Key(Key, KeyValue); }

	void Click(DWORD Buttons, FLOAT X, FLOAT Y) override
	{
		Renderer->MapMenuCoordinates(X, Y);
		Original->Click(Buttons, X, Y);
	}

	void MouseDelta(DWORD Buttons, FLOAT DX, FLOAT DY) override { Original->MouseDelta(Buttons, DX, DY); }

	void MousePosition(DWORD Buttons, FLOAT X, FLOAT Y) override
	{
		Renderer->MapMenuCoordinates(X, Y);
		Original->MousePosition(Buttons, X, Y);
	}

	void edSetClickLocation(FVector& Point) override { Original->edSetClickLocation(Point); }
	BYTE GetCursor() override { return Original->GetCursor(); }
	const TCHAR* GetWindowName() override { return Original->GetWindowName(); }

private:
	UD3D12RenderDevice* Renderer;
	FViewportCallback* Original;
};

#include "OpenXRPoseMath.h"

static FRotator RelativeOpenXRRotation(const XrQuaternionf& BaseOrientation,
	const XrQuaternionf& Orientation)
{
	const XrQuaternionf BaseInverse = {
		-BaseOrientation.x, -BaseOrientation.y, -BaseOrientation.z, BaseOrientation.w
	};
	const XrQuaternionf RelativeOrientation = NormalizeOpenXRQuaternion(
		MultiplyOpenXRQuaternions(BaseInverse, NormalizeOpenXRQuaternion(Orientation)));
	const FVector Forward = OpenXRVectorToUnreal(
		RotateOpenXRVector(RelativeOrientation, FVector(0.0f, 0.0f, -1.0f)));
	const FVector Right = OpenXRVectorToUnreal(
		RotateOpenXRVector(RelativeOrientation, FVector(1.0f, 0.0f, 0.0f)));
	const FVector Up = OpenXRVectorToUnreal(
		RotateOpenXRVector(RelativeOrientation, FVector(0.0f, 1.0f, 0.0f)));
	return FCoords(FVector(0.0f, 0.0f, 0.0f), Forward, Right, Up).OrthoRotation();
}
#endif

UD3D12RenderDevice::UD3D12RenderDevice()
{
	QueryPerformanceFrequency(&Performance.Frequency);
}

#if defined(UNREAL_227)
void UD3D12RenderDevice::DrawViewportWithOpenXR(FViewportCallback* Original, UBOOL Blit)
{
	APlayerPawn* Player = Viewport ? Viewport->Actor : nullptr;
	if (!Original)
		return;

	PollOpenXRSession();
	ApplyPendingVRQuality();
	const UBOOL OpenXRFramePending = Player && OpenXRSessionRunning && PrepareOpenXRFrame();
	if (!OpenXRFramePending || !OpenXRViewsValid || !OpenXRHeadPoseValid || !OpenXRBaseOrientationValid)
	{
		LastVREyeBuffer = -1;
		Original->Draw(Blit);
		if (OpenXRFramePending)
			FinishOpenXRFrame();
		return;
	}

	const FLOAT SavedFovAngle = Player->FovAngle;
	if (VRPitch.Pending && OpenXRSessionState == XR_SESSION_STATE_FOCUSED
		&& (!VRPitch.HasPresenceEvents || VRPitch.WasPresent)
		&& Player->Health > 0 && !Player->bBehindView && !Player->ViewTarget)
	{
		Player->ViewRotation.Pitch = Player->ViewRotation.Roll = 0;
		Player->aLookUp = Player->aMouseY = 0;
		VRPitch.Pending = false;
	}
	const bool UseQualityBuffers = PrepareVRQualityBuffers();
	try
	{
		for (uint32_t ViewIndex = 0; ViewIndex < OpenXRViews.size() && OpenXRSessionRunning; ViewIndex++)
		{
			const XrFovf& EyeFov = OpenXRViews[ViewIndex].fov;
			const FLOAT HorizontalTangent = Max(-appTan(EyeFov.angleLeft), appTan(EyeFov.angleRight));
			const FLOAT VerticalTangent = Max(-appTan(EyeFov.angleDown), appTan(EyeFov.angleUp));
			const FLOAT SourceAspect = CurrentSizeX > 0 ? CurrentSizeY / static_cast<FLOAT>(CurrentSizeX) : 0.75f;
			const FLOAT CullingTangent = Max(HorizontalTangent, VerticalTangent / Max(SourceAspect, 0.01f));
			Player->FovAngle = Clamp(degrees(2.0f * appAtan(CullingTangent)), 5.0f, 170.0f);
			OpenXRStereoDrawEye = static_cast<INT>(ViewIndex);
			// The camera hook supplies fresh collision state for this draw.
			VRHeadCollisionFade = 0.0f;
			if (UseQualityBuffers)
			{
				ActiveVREyeBuffer = VREyeBuffers[1].Width > 0 ? static_cast<INT>(ViewIndex) : 0;
				std::swap(SceneBuffers, VREyeBuffers[ActiveVREyeBuffer]);
			}
			Original->Draw(Blit);
			if (ActiveVREyeBuffer >= 0)
			{
				LastVREyeBuffer = ActiveVREyeBuffer;
				std::swap(SceneBuffers, VREyeBuffers[ActiveVREyeBuffer]);
				ActiveVREyeBuffer = -1;
			}
		}
	}
	catch (...)
	{
		if (ActiveVREyeBuffer >= 0)
		{
			std::swap(SceneBuffers, VREyeBuffers[ActiveVREyeBuffer]);
			ActiveVREyeBuffer = -1;
		}
		Player->FovAngle = SavedFovAngle;
		OpenXRStereoDrawEye = -1;
		FinishOpenXRFrame();
		throw;
	}
	Player->FovAngle = SavedFovAngle;
	OpenXRStereoDrawEye = -1;
	const UBOOL StereoSubmitted = OpenXRSubmitLayer;
	FinishOpenXRFrame();
	if (StereoSubmitted && !OpenXRStereoRenderingLogged)
	{
		OpenXRStereoRenderingLogged = 1;
		debugf(TEXT("Unreal Revived OpenXR: independent pre-culling left and right eye camera passes submitted"));
	}
}
#endif

void UD3D12RenderDevice::StaticConstructor()
{
	guard(UD3D12RenderDevice::StaticConstructor);

	SpanBased = 0;
	FullscreenOnly = 0;
	SupportsFogMaps = 1;
	SupportsDistanceFog = 0;
	SupportsTC = 1;
	SupportsNewBTC = 1;
	SupportsHDLightmaps = 1;
	SupportsAlphaBlend = 1;
	SupportsLazyTextures = 0;
	PrefersDeferredLoad = 0;
	UseVSync = 0;
	EnableVR = 0;
	VRHUDDistance = 1.75f;
	VRHUDScale = 1.0f;
	VRRenderQuality = 2; // Balanced uses the runtime-recommended eye resolution.
	VRTurnMode = 0;
	VRSnapAngle = 30;
	VRPlayerHeightOffset = 0.0f;
	VRWorldScale = 1.0f;
	VRAimMode = 0;
	AntialiasMode = 2;
	UsePrecache = 1;
	Coronas = 1;
	ShinySurfaces = 1;
#if !defined(UNREALGOLD)
	DetailTextures = 1;
#endif
	HighDetailActors = 1;
	VolumetricLighting = 1;

	#if defined(UNREAL_227)
	UseLightmapAtlas = 0;
	MaxTextureSize = 4096;
	NeedsMaskedFonts = 0;
	DescFlags |= RDDESCF_Certified;
#elif defined(OLDUNREAL469SDK)
	UseLightmapAtlas = 0; // Note: do not turn this on. It does not work and generates broken fogmaps.
	SupportsUpdateTextureRect = 1;
	MaxTextureSize = 4096;
	NeedsMaskedFonts = 0;
	DescFlags |= RDDESCF_Certified;
#endif

	GammaMode = 0;
	GammaOffset = 0.0f;
	GammaOffsetRed = 0.0f;
	GammaOffsetGreen = 0.0f;
	GammaOffsetBlue = 0.0f;

	LinearBrightness = 128; // 0.0f;
	Contrast = 128; // 1.0f;
	Saturation = 281; // 1.2f;
	GrayFormula = 1;

	Hdr = 0;
	HdrScale = 128;
#if !defined(OLDUNREAL469SDK)
	OccludeLines = 0;
#endif
	Bloom = 1;
	BloomAmount = 154;
	ChromaticAberration = 0;
	VignetteIntensity = 0;
	FilmGrainAmount = 0;
	ScanlineStrength = 0;

	LODBias = 0.0f;
	MaxAnisotropy = 4;
	LightMode = 0;

	GammaCorrectScreenshots = 1;
	UseDebugLayer = 0;

#if defined(OLDUNREAL469SDK)
	new(GetClass(), TEXT("UseLightmapAtlas"), RF_Public) UBoolProperty(CPP_PROPERTY(UseLightmapAtlas), TEXT("Display"), CPF_Config);
#endif

	new(GetClass(), TEXT("UseVSync"), RF_Public) UBoolProperty(CPP_PROPERTY(UseVSync), TEXT("Display"), CPF_Config);
	new(GetClass(), TEXT("EnableVR"), RF_Public) UBoolProperty(CPP_PROPERTY(EnableVR), TEXT("Display"), CPF_Config);
	new(GetClass(), TEXT("VRHUDDistance"), RF_Public) UFloatProperty(CPP_PROPERTY(VRHUDDistance), TEXT("Display"), CPF_Config);
	new(GetClass(), TEXT("VRHUDScale"), RF_Public) UFloatProperty(CPP_PROPERTY(VRHUDScale), TEXT("Display"), CPF_Config);
	new(GetClass(), TEXT("VRRenderQuality"), RF_Public) UIntProperty(CPP_PROPERTY(VRRenderQuality), TEXT("Display"), CPF_Config);
	new(GetClass(), TEXT("VRTurnMode"), RF_Public) UIntProperty(CPP_PROPERTY(VRTurnMode), TEXT("Display"), CPF_Config);
	new(GetClass(), TEXT("VRSnapAngle"), RF_Public) UIntProperty(CPP_PROPERTY(VRSnapAngle), TEXT("Display"), CPF_Config);
	new(GetClass(), TEXT("VRPlayerHeightOffset"), RF_Public) UFloatProperty(CPP_PROPERTY(VRPlayerHeightOffset), TEXT("Display"), CPF_Config);
	new(GetClass(), TEXT("VRWorldScale"), RF_Public) UFloatProperty(CPP_PROPERTY(VRWorldScale), TEXT("Display"), CPF_Config);
	new(GetClass(), TEXT("VRAimMode"), RF_Public) UIntProperty(CPP_PROPERTY(VRAimMode), TEXT("Display"), CPF_Config);
	new(GetClass(), TEXT("UsePrecache"), RF_Public) UBoolProperty(CPP_PROPERTY(UsePrecache), TEXT("Display"), CPF_Config);
	new(GetClass(), TEXT("GammaCorrectScreenshots"), RF_Public) UBoolProperty(CPP_PROPERTY(GammaCorrectScreenshots), TEXT("Display"), CPF_Config);
	new(GetClass(), TEXT("UseDebugLayer"), RF_Public) UBoolProperty(CPP_PROPERTY(UseDebugLayer), TEXT("Display"), CPF_Config);
	new(GetClass(), TEXT("GammaOffset"), RF_Public) UFloatProperty(CPP_PROPERTY(GammaOffset), TEXT("Display"), CPF_Config);
	new(GetClass(), TEXT("GammaOffsetRed"), RF_Public) UFloatProperty(CPP_PROPERTY(GammaOffsetRed), TEXT("Display"), CPF_Config);
	new(GetClass(), TEXT("GammaOffsetGreen"), RF_Public) UFloatProperty(CPP_PROPERTY(GammaOffsetGreen), TEXT("Display"), CPF_Config);
	new(GetClass(), TEXT("GammaOffsetBlue"), RF_Public) UFloatProperty(CPP_PROPERTY(GammaOffsetBlue), TEXT("Display"), CPF_Config);
	new(GetClass(), TEXT("LinearBrightness"), RF_Public) UByteProperty(CPP_PROPERTY(LinearBrightness), TEXT("Display"), CPF_Config);
	new(GetClass(), TEXT("Contrast"), RF_Public) UByteProperty(CPP_PROPERTY(Contrast), TEXT("Display"), CPF_Config);
	new(GetClass(), TEXT("Saturation"), RF_Public) UIntProperty(CPP_PROPERTY(Saturation), TEXT("Display"), CPF_Config);
	new(GetClass(), TEXT("GrayFormula"), RF_Public) UIntProperty(CPP_PROPERTY(GrayFormula), TEXT("Display"), CPF_Config);
	new(GetClass(), TEXT("Hdr"), RF_Public) UBoolProperty(CPP_PROPERTY(Hdr), TEXT("Display"), CPF_Config);
	new(GetClass(), TEXT("HdrScale"), RF_Public) UByteProperty(CPP_PROPERTY(HdrScale), TEXT("Display"), CPF_Config);
#if !defined(OLDUNREAL469SDK)
	new(GetClass(), TEXT("OccludeLines"), RF_Public) UBoolProperty(CPP_PROPERTY(OccludeLines), TEXT("Display"), CPF_Config);
#endif
	new(GetClass(), TEXT("Bloom"), RF_Public) UBoolProperty(CPP_PROPERTY(Bloom), TEXT("Display"), CPF_Config);
	new(GetClass(), TEXT("BloomAmount"), RF_Public) UByteProperty(CPP_PROPERTY(BloomAmount), TEXT("Display"), CPF_Config);
	new(GetClass(), TEXT("ChromaticAberration"), RF_Public) UByteProperty(CPP_PROPERTY(ChromaticAberration), TEXT("Display"), CPF_Config);
	new(GetClass(), TEXT("VignetteIntensity"), RF_Public) UByteProperty(CPP_PROPERTY(VignetteIntensity), TEXT("Display"), CPF_Config);
	new(GetClass(), TEXT("FilmGrainAmount"), RF_Public) UByteProperty(CPP_PROPERTY(FilmGrainAmount), TEXT("Display"), CPF_Config);
	new(GetClass(), TEXT("ScanlineStrength"), RF_Public) UByteProperty(CPP_PROPERTY(ScanlineStrength), TEXT("Display"), CPF_Config);
	new(GetClass(), TEXT("LODBias"), RF_Public) UFloatProperty(CPP_PROPERTY(LODBias), TEXT("Display"), CPF_Config);
	new(GetClass(), TEXT("MaxAnisotropy"), RF_Public) UIntProperty(CPP_PROPERTY(MaxAnisotropy), TEXT("Display"), CPF_Config);

	UEnum* AntialiasModes = new(GetClass(), TEXT("AntialiasModes"))UEnum(nullptr);
	new(AntialiasModes->Names)FName(TEXT("Off"));
	new(AntialiasModes->Names)FName(TEXT("MSAA_2x"));
	new(AntialiasModes->Names)FName(TEXT("MSAA_4x"));
	new(AntialiasModes->Names)FName(TEXT("MSAA_8x"));
	new(GetClass(), TEXT("AntialiasMode"), RF_Public) UByteProperty(CPP_PROPERTY(AntialiasMode), TEXT("Display"), CPF_Config, AntialiasModes);

	UEnum* GammaModes = new(GetClass(), TEXT("GammaModes"))UEnum(nullptr);
	new(GammaModes->Names)FName(TEXT("D3D9"));
	new(GammaModes->Names)FName(TEXT("XOpenGL"));
	new(GetClass(), TEXT("GammaMode"), RF_Public) UByteProperty(CPP_PROPERTY(GammaMode), TEXT("Display"), CPF_Config, GammaModes);

	UEnum* LightModes = new(GetClass(), TEXT("LightModes"))UEnum(nullptr);
	new(LightModes->Names)FName(TEXT("Normal"));
	new(LightModes->Names)FName(TEXT("OneXBlending"));
	new(LightModes->Names)FName(TEXT("BrighterActors"));
	new(GetClass(), TEXT("LightMode"), RF_Public) UByteProperty(CPP_PROPERTY(LightMode), TEXT("Display"), CPF_Config, LightModes);

	unguard;
}

int UD3D12RenderDevice::GetSettingsMultisample()
{
	switch (AntialiasMode)
	{
	default:
	case 0: return 0;
	case 1: return 2;
	case 2: return 4;
	case 3: return 8;
	}
}

int UD3D12RenderDevice::GetSupportedMultisample(int requestedMultisample)
{
	const DXGI_FORMAT formats[] =
	{
		DXGI_FORMAT_R16G16B16A16_FLOAT,
		DXGI_FORMAT_R32_UINT,
		DXGI_FORMAT_R8G8_UNORM,
		DXGI_FORMAT_D32_FLOAT
	};

	for (int multisample = std::max(requestedMultisample, 1); multisample > 1; multisample /= 2)
	{
		bool supported = true;
		for (DXGI_FORMAT format : formats)
		{
			D3D12_FEATURE_DATA_MULTISAMPLE_QUALITY_LEVELS levels = {};
			levels.Format = format;
			levels.SampleCount = multisample;
			levels.Flags = D3D12_MULTISAMPLE_QUALITY_LEVELS_FLAG_NONE;
			if (FAILED(Device->CheckFeatureSupport(D3D12_FEATURE_MULTISAMPLE_QUALITY_LEVELS, &levels, sizeof(levels))) || levels.NumQualityLevels == 0)
			{
				supported = false;
				break;
			}
		}

		if (supported)
			return multisample;
	}

	return 1;
}

UBOOL UD3D12RenderDevice::Init(UViewport* InViewport, INT NewX, INT NewY, INT NewColorBytes, UBOOL Fullscreen)
{
	guard(UD3D12RenderDevice::Init);

	Viewport = InViewport;
	ActiveHdr = Hdr;
	#if defined(UNREAL_227)
	HWND ViewportWindow = (HWND)Viewport->GetWindow();
	HDC WindowDC = GetDC(ViewportWindow);
	if (WindowDC)
	{
		RECT ClientRect = {};
		GetClientRect(ViewportWindow, &ClientRect);
		FillRect(WindowDC, &ClientRect, (HBRUSH)GetStockObject(BLACK_BRUSH));
		ReleaseDC(ViewportWindow, WindowDC);
	}
	#endif
	Performance.Enabled = GetEnvironmentVariableW(L"UNREAL_REVIVED_MEASURE_PERFORMANCE", nullptr, 0) > 0;
	if (Performance.Enabled)
		debugf(TEXT("D3D12Drv performance measurement enabled"));

	GetOutputRect();

	try
	{
		BufferCount = GetWantedSwapChainBufferCount();

		if (UseDebugLayer)
		{
			HRESULT result = D3D12GetDebugInterface(DebugController.GetIID(), DebugController.InitPtr());
			if (SUCCEEDED(result))
			{
				DebugController->EnableDebugLayer();
			}
		}

		ComPtr<IDXGIFactory4> factory;
		HRESULT result = CreateDXGIFactory1(factory.GetIID(), factory.InitPtr());
		ThrowIfFailed(result, "CreateDXGIFactory1 failed");

		ComPtr<IDXGIAdapter1> hardwareAdapter;
		result = factory->EnumAdapters1(0, hardwareAdapter.TypedInitPtr());
		ThrowIfFailed(result, "EnumAdapters1 failed");

		result = D3D12CreateDevice(hardwareAdapter, D3D_FEATURE_LEVEL_11_0, Device.GetIID(), Device.InitPtr());
		ThrowIfFailed(result, "D3D12CreateDevice failed");

		D3D12_COMMAND_QUEUE_DESC queueDesc = {};
		queueDesc.Flags = D3D12_COMMAND_QUEUE_FLAG_NONE;
		queueDesc.Type = D3D12_COMMAND_LIST_TYPE_DIRECT;
		result = Device->CreateCommandQueue(&queueDesc, GraphicsQueue.GetIID(), GraphicsQueue.InitPtr());
		ThrowIfFailed(result, "CreateCommandQueue failed");

		if (UseDebugLayer)
		{
			result = Device->QueryInterface(InfoQueue1.GetIID(), InfoQueue1.InitPtr());
			if (SUCCEEDED(result))
			{
				result = InfoQueue1->RegisterMessageCallback(&UD3D12RenderDevice::OnDebugMessage, D3D12_MESSAGE_CALLBACK_FLAG_NONE, this, &DebugMessageCookie);
				if (SUCCEEDED(result))
				{
					DebugMessageActive = true;
				}
				else
				{
					debugf(TEXT("D3D12InfoQueue1.RegisterMessageCallback failed"));
				}
			}
			else
			{
				debugf(TEXT("Could not aquire ID3D12InfoQueue1 object"));
			}
		}

		D3D12MA::ALLOCATOR_DESC allocatorDesc = {};
		allocatorDesc.pDevice = Device.get();
		allocatorDesc.pAdapter = hardwareAdapter.get();
		allocatorDesc.Flags = D3D12MA::ALLOCATOR_FLAG_MSAA_TEXTURES_ALWAYS_COMMITTED | D3D12MA::ALLOCATOR_FLAG_DEFAULT_POOLS_NOT_ZEROED;
		result = D3D12MA::CreateAllocator(&allocatorDesc, &MemAllocator);
		ThrowIfFailed(result, "D3D12MA::CreateAllocator failed");

		ComPtr<IDXGIFactory5> dxgiFactory5;
		result = factory->QueryInterface(dxgiFactory5.GetIID(), dxgiFactory5.InitPtr());
		if (SUCCEEDED(result))
		{
			INT support = 0;
			result = dxgiFactory5->CheckFeatureSupport(DXGI_FEATURE_PRESENT_ALLOW_TEARING, &support, sizeof(INT));
			if (SUCCEEDED(result))
			{
				DxgiSwapChainAllowTearing = support != 0;
			}
		}

		UINT flags = DXGI_SWAP_CHAIN_FLAG_ALLOW_MODE_SWITCH;
		if (DxgiSwapChainAllowTearing)
			flags |= DXGI_SWAP_CHAIN_FLAG_ALLOW_TEARING;

		DXGI_SWAP_CHAIN_DESC1 swapDesc = {};
		swapDesc.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
		swapDesc.Width = NewX;
		swapDesc.Height = NewY;
		swapDesc.Format = ActiveHdr ? DXGI_FORMAT_R16G16B16A16_FLOAT : DXGI_FORMAT_R8G8B8A8_UNORM;
		swapDesc.BufferCount = BufferCount;
		swapDesc.SampleDesc.Count = 1;
		swapDesc.Scaling = DXGI_SCALING_STRETCH;
		swapDesc.SwapEffect = DXGI_SWAP_EFFECT_FLIP_DISCARD;
		swapDesc.Flags = flags;
		swapDesc.AlphaMode = DXGI_ALPHA_MODE_IGNORE;

		ComPtr<IDXGISwapChain1> swapChain1;
		result = factory->CreateSwapChainForHwnd(GraphicsQueue, (HWND)Viewport->GetWindow(), &swapDesc, nullptr, nullptr, swapChain1.TypedInitPtr());
		ThrowIfFailed(result, "CreateSwapChainForHwnd failed");

		result = swapChain1->QueryInterface(SwapChain3.GetIID(), SwapChain3.InitPtr());
		ThrowIfFailed(result, "QueryInterface(IID_SwapChain3) failed");

		SetColorSpace();

		result = factory->MakeWindowAssociation((HWND)Viewport->GetWindow(), DXGI_MWA_NO_WINDOW_CHANGES | DXGI_MWA_NO_ALT_ENTER);
		ThrowIfFailed(result, "MakeWindowAssociation failed");

		Heaps.Common = std::make_unique<DescriptorHeap>(Device.get(), 64 * 1024, D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV, D3D12_DESCRIPTOR_HEAP_FLAG_SHADER_VISIBLE);
		Heaps.Sampler = std::make_unique<DescriptorHeap>(Device.get(), 64, D3D12_DESCRIPTOR_HEAP_TYPE_SAMPLER, D3D12_DESCRIPTOR_HEAP_FLAG_SHADER_VISIBLE);
		Heaps.RTV = std::make_unique<DescriptorHeap>(Device.get(), RenderTargetDescriptorCapacity, D3D12_DESCRIPTOR_HEAP_TYPE_RTV, D3D12_DESCRIPTOR_HEAP_FLAG_NONE);
		Heaps.DSV = std::make_unique<DescriptorHeap>(Device.get(), 64, D3D12_DESCRIPTOR_HEAP_TYPE_DSV, D3D12_DESCRIPTOR_HEAP_FLAG_NONE);

		for (int i = 0; i < 2; i++)
		{
			result = Device->CreateCommandAllocator(D3D12_COMMAND_LIST_TYPE_DIRECT, Commands.Batches[i].TransferAllocator.GetIID(), Commands.Batches[i].TransferAllocator.InitPtr());
			ThrowIfFailed(result, "CreateCommandAllocator failed");

			result = Device->CreateCommandAllocator(D3D12_COMMAND_LIST_TYPE_DIRECT, Commands.Batches[i].DrawAllocator.GetIID(), Commands.Batches[i].DrawAllocator.InitPtr());
			ThrowIfFailed(result, "CreateCommandAllocator failed");

			result = Device->CreateCommandList(0, D3D12_COMMAND_LIST_TYPE_DIRECT, Commands.Batches[i].TransferAllocator, nullptr, Commands.Batches[i].Transfer.GetIID(), Commands.Batches[i].Transfer.InitPtr());
			ThrowIfFailed(result, "CreateCommandList failed");

			result = Device->CreateCommandList(0, D3D12_COMMAND_LIST_TYPE_DIRECT, Commands.Batches[i].DrawAllocator, nullptr, Commands.Batches[i].Draw.GetIID(), Commands.Batches[i].Draw.InitPtr());
			ThrowIfFailed(result, "CreateCommandList failed");

			ID3D12DescriptorHeap* heaps[] = { Heaps.Common->GetHeap(), Heaps.Sampler->GetHeap() };
			Commands.Batches[i].Draw->SetDescriptorHeaps(2, heaps);
		}

		result = Device->CreateFence(Commands.FenceValue, D3D12_FENCE_FLAG_NONE, Commands.Fence.GetIID(), Commands.Fence.InitPtr());
		ThrowIfFailed(result, "CreateFence failed");

		Commands.FenceHandle = CreateEvent(nullptr, FALSE, FALSE, nullptr);
		if (!Commands.FenceHandle)
			throw std::runtime_error("CreateEvent failed");

		Commands.Current = &Commands.Batches[0];

		CreateUploadBuffer();
		CreatePresentPass();
		CreateBloomPass();

		Textures.reset(new TextureManager(this));
		Uploads.reset(new UploadManager(this));
	}
	catch (_com_error error)
	{
		debugf(TEXT("Could not create d3d12 renderer: [_com_error] %s"), error.ErrorMessage());
		Exit();
		return 0;
	}
	catch (const std::exception& e)
	{
		debugf(TEXT("Could not create d3d12 renderer: %s"), to_utf16(e.what()).c_str());
		Exit();
		return 0;
	}

	if (!SetRes(NewX, NewY, NewColorBytes, Fullscreen))
	{
		Exit();
		return 0;
	}

#if defined(UNREAL_227)
	OriginalViewportCallback = FViewportOutputAccessor::Get(Viewport);
	ViewportCallback = new FD3D12ViewportCallback(Viewport, this, OriginalViewportCallback);
	FViewportOutputAccessor::Get(Viewport) = ViewportCallback;
	InstallWindowProcedure();
	InitializeOpenXRFoundation();
#endif

	return 1;
	unguard;
}

void UD3D12RenderDevice::SetColorSpace()
{
	if (ActiveHdr)
	{
		UINT support = 0;
		HRESULT result = SwapChain3->CheckColorSpaceSupport(DXGI_COLOR_SPACE_RGB_FULL_G2084_NONE_P2020, &support);
		if (SUCCEEDED(result) && (support & DXGI_SWAP_CHAIN_COLOR_SPACE_SUPPORT_FLAG_PRESENT) == DXGI_SWAP_CHAIN_COLOR_SPACE_SUPPORT_FLAG_PRESENT)
		{
			result = SwapChain3->SetColorSpace1(DXGI_COLOR_SPACE_RGB_FULL_G2084_NONE_P2020);
			if (FAILED(result))
			{
				debugf(TEXT("D3D12Drv: IDXGISwapChain3.SetColorSpace1(DXGI_COLOR_SPACE_RGB_FULL_G2084_NONE_P2020) failed"));
			}
		}
		else
		{
			debugf(TEXT("D3D12Drv: Swap chain does not support DXGI_COLOR_SPACE_RGB_FULL_G2084_NONE_P2020"));
		}
	}
}

class SetResCallLock
{
public:
	SetResCallLock(bool& value) : value(value)
	{
		value = true;
	}
	~SetResCallLock()
	{
		value = false;
	}
	bool& value;
};

RECT UD3D12RenderDevice::GetOutputRect()
{
	RECT outputRect = { 0, 0, GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN) };
	if (Viewport && Viewport->GetWindow())
	{
		HMONITOR monitor = MonitorFromWindow((HWND)Viewport->GetWindow(), MONITOR_DEFAULTTONEAREST);
		MONITORINFO monitorInfo = {};
		monitorInfo.cbSize = sizeof(monitorInfo);
		if (monitor && GetMonitorInfo(monitor, &monitorInfo))
			outputRect = monitorInfo.rcMonitor;
	}

	DesktopResolution.Width = outputRect.right - outputRect.left;
	DesktopResolution.Height = outputRect.bottom - outputRect.top;
	return outputRect;
}

#if defined(UNREAL_227)
static const TCHAR* D3D12WindowProperty = TEXT("UnrealRevived.D3D12RenderDevice");

void UD3D12RenderDevice::InstallWindowProcedure()
{
	WindowHandle = (HWND)Viewport->GetWindow();
	if (!WindowHandle)
		return;

	if (!SetProp(WindowHandle, D3D12WindowProperty, this))
	{
		WindowHandle = nullptr;
		return;
	}
	OriginalWindowProcedure = (WNDPROC)SetWindowLongPtr(WindowHandle, GWLP_WNDPROC, (LONG_PTR)WindowProcedure);
	if (!OriginalWindowProcedure)
	{
		RemoveProp(WindowHandle, D3D12WindowProperty);
		WindowHandle = nullptr;
	}
}

void UD3D12RenderDevice::RestoreWindowProcedure()
{
	if (!WindowHandle)
		return;

	if ((WNDPROC)GetWindowLongPtr(WindowHandle, GWLP_WNDPROC) == WindowProcedure)
		SetWindowLongPtr(WindowHandle, GWLP_WNDPROC, (LONG_PTR)OriginalWindowProcedure);
	RemoveProp(WindowHandle, D3D12WindowProperty);
	OriginalWindowProcedure = nullptr;
	WindowHandle = nullptr;
}

LRESULT CALLBACK UD3D12RenderDevice::WindowProcedure(HWND Window, UINT Message, WPARAM WParam, LPARAM LParam)
{
	UD3D12RenderDevice* Renderer = (UD3D12RenderDevice*)GetProp(Window, D3D12WindowProperty);
	if (!Renderer || !Renderer->OriginalWindowProcedure)
		return DefWindowProc(Window, Message, WParam, LParam);
	if (Message == WM_ERASEBKGND)
	{
		RECT ClientRect = {};
		GetClientRect(Window, &ClientRect);
		FillRect((HDC)WParam, &ClientRect, (HBRUSH)GetStockObject(BLACK_BRUSH));
		return 1;
	}

	if (WParam == VK_RETURN && (LParam & (1 << 29)))
	{
		if (Message == WM_SYSKEYDOWN && !(LParam & (1 << 30)))
		{
			RECT OutputRect = Renderer->GetOutputRect();
			const UBOOL Borderless = !Renderer->FullscreenState.Enabled &&
				Renderer->CurrentSizeX == OutputRect.right - OutputRect.left &&
				Renderer->CurrentSizeY == OutputRect.bottom - OutputRect.top;
			Renderer->Viewport->Exec(Renderer->FullscreenState.Enabled || Borderless ?
				TEXT("SetScreenMode Windowed") : TEXT("SetScreenMode Borderless"), *GLog);
		}
		if (Message == WM_SYSKEYDOWN || Message == WM_SYSKEYUP || Message == WM_SYSCHAR)
			return 0;
	}

	return CallWindowProc(Renderer->OriginalWindowProcedure, Window, Message, WParam, LParam);
}

void UD3D12RenderDevice::MapMenuCoordinates(FLOAT& X, FLOAT& Y) const
{
	if (!FullscreenState.Enabled || !Viewport || CurrentSizeX <= 0 || CurrentSizeY <= 0)
		return;

	RECT ClientRect = {};
	if (!GetClientRect((HWND)Viewport->GetWindow(), &ClientRect))
		return;

	const FLOAT ClientWidth = (FLOAT)(ClientRect.right - ClientRect.left);
	const FLOAT ClientHeight = (FLOAT)(ClientRect.bottom - ClientRect.top);
	const FLOAT Scale = Min(ClientWidth / CurrentSizeX, ClientHeight / CurrentSizeY);
	if (Scale <= 0.0f)
		return;

	const FLOAT OffsetX = (ClientWidth - CurrentSizeX * Scale) * 0.5f;
	const FLOAT OffsetY = (ClientHeight - CurrentSizeY * Scale) * 0.5f;
	X = (X - OffsetX) / Scale;
	Y = (Y - OffsetY) / Scale;
}
#endif

UBOOL UD3D12RenderDevice::SetRes(INT NewX, INT NewY, INT NewColorBytes, UBOOL Fullscreen)
{
	guard(UD3D12RenderDevice::SetRes);

	if (InSetResCall)
		return TRUE;
	SetResCallLock lock(InSetResCall);

	if (!Fullscreen && IgnoreBorderlessResize && FullscreenState.Enabled && NewX == CurrentSizeX && NewY == CurrentSizeY)
	{
		IgnoreBorderlessResize = false;
		return TRUE;
	}
	IgnoreBorderlessResize = false;

	if (NewX == 0 || NewY == 0)
		return 1;

	// Keep the proven logical viewport independent of eye render quality.
	if (!ParseParam(appCmdLine(), TEXT("novr")) &&
		(ParseParam(appCmdLine(), TEXT("vr")) || EnableVR))
	{
		NewX = 1280;
		NewY = 1024;
	}

	SubmitCommands(false);
	WaitDeviceIdle();
	ReleaseSwapChainResources();

	HRESULT result;

	BufferCount = GetWantedSwapChainBufferCount();

	if (!Fullscreen && FullscreenState.Enabled) // Leaving fullscreen
	{
		// Restore old state
		SetWindowLong((HWND)Viewport->GetWindow(), GWL_STYLE, FullscreenState.Style);
		SetWindowLong((HWND)Viewport->GetWindow(), GWL_EXSTYLE, FullscreenState.ExStyle);
		SetWindowPos(
			(HWND)Viewport->GetWindow(),
			HWND_TOP,
			FullscreenState.WindowPos.left,
			FullscreenState.WindowPos.top,
			FullscreenState.WindowPos.right - FullscreenState.WindowPos.left,
			FullscreenState.WindowPos.bottom - FullscreenState.WindowPos.top,
			SWP_FRAMECHANGED | SWP_NOSENDCHANGING | SWP_NOACTIVATE | SWP_NOZORDER);

		FullscreenState.Enabled = false;
	}

	if (!Viewport->ResizeViewport(Fullscreen ? (BLIT_Fullscreen | BLIT_Direct3D) : (BLIT_HardwarePaint | BLIT_Direct3D), NewX, NewY, NewColorBytes))
	{
		debugf(TEXT("Viewport.ResizeViewport failed (%d, %d, %d, %d)"), NewX, NewY, NewColorBytes, (INT)Fullscreen);
		return FALSE;
	}

	CurrentSizeX = NewX;
	CurrentSizeY = NewY;

	if (Fullscreen && !FullscreenState.Enabled) // Entering fullscreen
	{
		// Save old state
		GetWindowRect((HWND)Viewport->GetWindow(), &FullscreenState.WindowPos);
		FullscreenState.Style = GetWindowLong((HWND)Viewport->GetWindow(), GWL_STYLE);
		FullscreenState.ExStyle = GetWindowLong((HWND)Viewport->GetWindow(), GWL_EXSTYLE);

		RECT outputRect = GetOutputRect();
		int screenWidth = outputRect.right - outputRect.left;
		int screenHeight = outputRect.bottom - outputRect.top;

		// Create borderless full screen window (our present shader will letterbox any resolution to fit)
		SetWindowLong((HWND)Viewport->GetWindow(), GWL_STYLE, WS_OVERLAPPED | WS_VISIBLE);
		SetWindowLong((HWND)Viewport->GetWindow(), GWL_EXSTYLE, WS_EX_APPWINDOW);
		SetWindowPos((HWND)Viewport->GetWindow(), HWND_TOP, outputRect.left, outputRect.top, screenWidth, screenHeight, SWP_FRAMECHANGED | SWP_NOSENDCHANGING | SWP_NOACTIVATE | SWP_NOZORDER);
		#if defined(UNREAL_227)
		Viewport->PhysicalSizeX = screenWidth;
		Viewport->PhysicalSizeY = screenHeight;
		#endif
		IgnoreBorderlessResize = true;

		DXGI_MODE_DESC modeDesc = {};
		modeDesc.Width = screenWidth;
		modeDesc.Height = screenHeight;
		modeDesc.Format = ActiveHdr ? DXGI_FORMAT_R16G16B16A16_FLOAT : DXGI_FORMAT_R8G8B8A8_UNORM;
		result = SwapChain3->ResizeTarget(&modeDesc);
		if (FAILED(result))
		{
			debugf(TEXT("SwapChain.ResizeTarget failed (%d, %d, %d, %d)"), NewX, NewY, NewColorBytes, (INT)Fullscreen);
		}

		FullscreenState.Enabled = true;
	}

	if (!Fullscreen)
	{
		DXGI_MODE_DESC modeDesc = {};
		modeDesc.Width = CurrentSizeX;
		modeDesc.Height = CurrentSizeY;
		modeDesc.Format = ActiveHdr ? DXGI_FORMAT_R16G16B16A16_FLOAT : DXGI_FORMAT_R8G8B8A8_UNORM;
		result = SwapChain3->ResizeTarget(&modeDesc);
		if (FAILED(result))
		{
			debugf(TEXT("SwapChain.ResizeTarget failed (%d, %d, %d, %d)"), NewX, NewY, NewColorBytes, (INT)Fullscreen);
		}
	}

	if (!UpdateSwapChain())
		return FALSE;

	SaveConfig();

#if defined(UNREALGOLD)
	Flush();
#else
	Flush(1);
#endif

	return 1;
	unguard;
}

void UD3D12RenderDevice::ReleaseSwapChainResources()
{
	FrameBuffers.clear();
	FrameBufferRTVs.reset();
	FrameFenceValues.clear();
}

bool UD3D12RenderDevice::UpdateSwapChain()
{
	int width = CurrentSizeX;
	int height = CurrentSizeY;
	if (FullscreenState.Enabled)
	{
		RECT outputRect = GetOutputRect();
		width = outputRect.right - outputRect.left;
		height = outputRect.bottom - outputRect.top;
	}

	UINT flags = DXGI_SWAP_CHAIN_FLAG_ALLOW_MODE_SWITCH;
	if (DxgiSwapChainAllowTearing)
		flags |= DXGI_SWAP_CHAIN_FLAG_ALLOW_TEARING;

	HRESULT result = SwapChain3->ResizeBuffers(BufferCount, width, height, ActiveHdr ? DXGI_FORMAT_R16G16B16A16_FLOAT : DXGI_FORMAT_R8G8B8A8_UNORM, flags);
	if (FAILED(result))
		return false;

	SetColorSpace();

	if (CurrentSizeX && CurrentSizeY)
	{
		try
		{
			ResizeSceneBuffers(CurrentSizeX, CurrentSizeY, GetSettingsMultisample());
		}
		catch (const std::exception& e)
		{
			debugf(TEXT("Could not resize scene buffers: %s"), to_utf16(e.what()).c_str());
			return false;
		}
	}

	for (int i = 0; i < BufferCount; i++)
	{
		ComPtr<ID3D12Resource> buffer;
		HRESULT result = SwapChain3->GetBuffer(i, buffer.GetIID(), buffer.InitPtr());
		if (FAILED(result))
		{
			debugf(TEXT("SwapChain3.GetBuffer failed"));
			return false;
		}
		FrameBuffers.push_back(std::move(buffer));
	}

	FrameBufferRTVs = Heaps.RTV->Alloc(BufferCount);
	for (int i = 0; i < BufferCount; i++)
	{
		Device->CreateRenderTargetView(FrameBuffers[i], nullptr, FrameBufferRTVs.CPUHandle(i));
	}

	FrameFenceValues.clear();
	FrameFenceValues.resize(FrameBuffers.size());
	BackBufferIndex = SwapChain3->GetCurrentBackBufferIndex();

	return true;
}

void UD3D12RenderDevice::SubmitCommands(bool present)
{
	HRESULT result = Commands.Current->Transfer->Close();
	ThrowIfFailed(result, "Could not close transfer command list!");

	result = Commands.Current->Draw->Close();
	ThrowIfFailed(result, "Could not close draw command list!");

	ID3D12CommandList* commandLists[] = { Commands.Current->Transfer.get(), Commands.Current->Draw.get() };
	GraphicsQueue->ExecuteCommandLists(2, commandLists);

	if (present)
	{
		UINT flags = 0;
		if (!UseVSync && DxgiSwapChainAllowTearing)
			flags |= DXGI_PRESENT_ALLOW_TEARING;

		DXGI_PRESENT_PARAMETERS presentParams = {};
		result = SwapChain3->Present1(UseVSync ? 1 : 0, flags, &presentParams);
		ThrowIfFailed(result, "SwapChain3.Present1 failed");
	}

	result = GraphicsQueue->Signal(Commands.Fence, Commands.FenceValue + 1);
	ThrowIfFailed(result, "GraphicsQueue.Signal failed");
	Commands.FenceValue++;
	Commands.Current->FenceValue = Commands.FenceValue;

	if (present)
	{
		FrameFenceValues[BackBufferIndex] = Commands.FenceValue;
		BackBufferIndex = SwapChain3->GetCurrentBackBufferIndex();
		WaitForFence(FrameFenceValues[BackBufferIndex]);
	}

	UINT64 nextBatch = Commands.FenceValue % 2;
	Commands.Current = &Commands.Batches[nextBatch];

	if (Commands.Current->FenceValue > 0)
	{
		WaitForFence(Commands.Current->FenceValue);
		Commands.Current->TransferAllocator->Reset();
		Commands.Current->DrawAllocator->Reset();
		Commands.Current->Transfer->Reset(Commands.Current->TransferAllocator, nullptr);
		Commands.Current->Draw->Reset(Commands.Current->DrawAllocator, nullptr);

		ID3D12DescriptorHeap* heaps[] = { Heaps.Common->GetHeap(), Heaps.Sampler->GetHeap() };
		Commands.Current->Draw->SetDescriptorHeaps(2, heaps);
	}

	Upload.Pos = 0;
	Upload.Base = nextBatch * Upload.Size;
	ScenePass.VertexPos = 0;
	ScenePass.VertexBase = nextBatch * ScenePass.VertexBufferSize;
	ScenePass.IndexPos = 0;
	ScenePass.IndexBase = nextBatch * ScenePass.IndexBufferSize;
	Stats.BuffersUsed++;
}

void UD3D12RenderDevice::WaitForFence(UINT64 value)
{
	if (!Commands.Fence)
		return;
	UINT64 completedValue = Commands.Fence->GetCompletedValue();
	if (completedValue < value)
	{
		HRESULT result = Commands.Fence->SetEventOnCompletion(value, Commands.FenceHandle);
		ThrowIfFailed(result, "GraphicsQueue.SetEventOnCompletion failed");
		WaitForSingleObjectEx(Commands.FenceHandle, INFINITE, FALSE);
	}
}

void UD3D12RenderDevice::WaitDeviceIdle()
{
	WaitForFence(Commands.FenceValue);
}

void UD3D12RenderDevice::TransitionResourceBarrier(ID3D12GraphicsCommandList* cmdlist, ID3D12Resource* resource, D3D12_RESOURCE_STATES before, D3D12_RESOURCE_STATES after)
{
	D3D12_RESOURCE_BARRIER barrier = {};
	barrier.Type = D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
	barrier.Transition.pResource = resource;
	barrier.Transition.StateBefore = before;
	barrier.Transition.StateAfter = after;
	barrier.Transition.Subresource = D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES;
	cmdlist->ResourceBarrier(1, &barrier);
}

void UD3D12RenderDevice::TransitionResourceBarrier(ID3D12GraphicsCommandList* cmdlist, ID3D12Resource* resource0, D3D12_RESOURCE_STATES before0, D3D12_RESOURCE_STATES after0, ID3D12Resource* resource1, D3D12_RESOURCE_STATES before1, D3D12_RESOURCE_STATES after1)
{
	D3D12_RESOURCE_BARRIER barriers[2] = {};
	barriers[0].Type = D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
	barriers[0].Transition.pResource = resource0;
	barriers[0].Transition.StateBefore = before0;
	barriers[0].Transition.StateAfter = after0;
	barriers[0].Transition.Subresource = D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES;
	barriers[1].Type = D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
	barriers[1].Transition.pResource = resource1;
	barriers[1].Transition.StateBefore = before1;
	barriers[1].Transition.StateAfter = after1;
	barriers[1].Transition.Subresource = D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES;
	cmdlist->ResourceBarrier(2, barriers);
}

void UD3D12RenderDevice::Exit()
{
	guard(UD3D12RenderDevice::Exit);

	WaitDeviceIdle();

#if defined(UNREAL_227)
	ReleaseOpenXRFoundation();
	RestoreWindowProcedure();

	FViewportCallback* InstalledCallback = ViewportCallback;
	ViewportCallback = nullptr;
	if (Viewport && InstalledCallback && Viewport->GetOutputAPI() == InstalledCallback)
		FViewportOutputAccessor::Get(Viewport) = OriginalViewportCallback;
	OriginalViewportCallback = nullptr;
	delete InstalledCallback;
#endif

	for (auto& it : Descriptors.Tex)
		it.second.reset();
	Descriptors.Tex.clear();

	Uploads.reset();
	Textures.reset();
	ReleasePresentPass();
	ReleaseBloomPass();
	ReleaseScenePass();
	ReleaseSceneBuffers();
	ReleaseUploadBuffer();
	for (SceneBufferSet& Buffers : VREyeBuffers)
		Buffers = {};
	Heaps.DSV.reset();
	Heaps.RTV.reset();
	Heaps.Sampler.reset();
	Heaps.Common.reset();
	FrameBuffers.clear();
	SwapChain3.reset();
	for (int i = 0; i < 2; i++)
	{
		Commands.Batches[i].Draw.reset();
		Commands.Batches[i].Transfer.reset();
		Commands.Batches[i].DrawAllocator.reset();
		Commands.Batches[i].TransferAllocator.reset();
	}
	Commands.Fence.reset();
	GraphicsQueue.reset();

	if (Commands.FenceHandle && Commands.FenceHandle != INVALID_HANDLE_VALUE)
	{
		CloseHandle(Commands.FenceHandle);
		Commands.FenceHandle = INVALID_HANDLE_VALUE;
	}

	if (MemAllocator)
		MemAllocator->Release();
	MemAllocator = nullptr;

	if (DebugMessageActive)
		InfoQueue1->UnregisterMessageCallback(DebugMessageCookie);
	InfoQueue1.reset();

	Device.reset();
	DebugController.reset();

	unguard;
}

#if defined(UNREAL_227)
void UD3D12RenderDevice::InitializeOpenXRFoundation()
{
	const UBOOL ForceVR = ParseParam(appCmdLine(), TEXT("vr"));
	const UBOOL ForceNoVR = ParseParam(appCmdLine(), TEXT("novr"));
	if (ForceVR && ForceNoVR)
		debugf(TEXT("Unreal Revived OpenXR: both -vr and -novr were specified; -novr takes precedence"));

	if (ForceNoVR || (!ForceVR && !EnableVR))
	{
		debugf(ForceNoVR ?
			TEXT("Unreal Revived OpenXR: disabled; loader not queried (command-line -novr)") :
			TEXT("Unreal Revived OpenXR: disabled; loader not queried (flat-screen default)"));
		return;
	}

	debugf(ForceVR ?
		TEXT("Unreal Revived OpenXR: requested by command-line -vr; probing loader") :
		TEXT("Unreal Revived OpenXR: requested by stored EnableVR; probing loader"));
	OpenXRLoader = LoadLibraryExW(L"openxr_loader.dll", nullptr,
		LOAD_LIBRARY_SEARCH_APPLICATION_DIR | LOAD_LIBRARY_SEARCH_SYSTEM32);
	if (!OpenXRLoader)
	{
		debugf(TEXT("Unreal Revived OpenXR: loader unavailable (Win32 error %u); continuing flat-screen D3D12"), GetLastError());
		return;
	}

	OpenXRGetInstanceProcAddr = reinterpret_cast<PFN_xrGetInstanceProcAddr>(
		GetProcAddress(OpenXRLoader, "xrGetInstanceProcAddr"));
	if (!OpenXRGetInstanceProcAddr)
	{
		debugf(TEXT("Unreal Revived OpenXR: loader entry point missing; continuing flat-screen D3D12"));
		ReleaseOpenXRFoundation();
		return;
	}

	PFN_xrVoidFunction RawFunction = nullptr;
	XrResult Result = OpenXRGetInstanceProcAddr(XR_NULL_HANDLE, "xrCreateInstance", &RawFunction);
	if (XR_FAILED(Result) || !RawFunction)
	{
		debugf(TEXT("Unreal Revived OpenXR: xrCreateInstance unavailable (result %d); continuing flat-screen D3D12"), Result);
		return;
	}

	const PFN_xrCreateInstance CreateInstance = reinterpret_cast<PFN_xrCreateInstance>(RawFunction);
	RawFunction = nullptr;
	Result = OpenXRGetInstanceProcAddr(XR_NULL_HANDLE, "xrEnumerateInstanceExtensionProperties", &RawFunction);
	if (XR_FAILED(Result) || !RawFunction)
	{
		debugf(TEXT("Unreal Revived OpenXR: extension enumeration unavailable (result %d); continuing flat-screen D3D12"), Result);
		return;
	}

	const PFN_xrEnumerateInstanceExtensionProperties EnumerateExtensions =
		reinterpret_cast<PFN_xrEnumerateInstanceExtensionProperties>(RawFunction);
	uint32_t ExtensionCount = 0;
	Result = EnumerateExtensions(nullptr, 0, &ExtensionCount, nullptr);
	if (XR_FAILED(Result))
	{
		debugf(TEXT("Unreal Revived OpenXR: extension count query failed (result %d); continuing flat-screen D3D12"), Result);
		return;
	}
	std::vector<XrExtensionProperties> Extensions(ExtensionCount, { XR_TYPE_EXTENSION_PROPERTIES });
	Result = EnumerateExtensions(nullptr, ExtensionCount, &ExtensionCount, Extensions.data());
	if (XR_FAILED(Result))
	{
		debugf(TEXT("Unreal Revived OpenXR: extension query failed (result %d); continuing flat-screen D3D12"), Result);
		return;
	}
	bool SupportsD3D12 = false;
	VRPresenceExtension = false;
	for (const XrExtensionProperties& Extension : Extensions)
	{
		if (strcmp(Extension.extensionName, XR_KHR_D3D12_ENABLE_EXTENSION_NAME) == 0)
		{
			SupportsD3D12 = true;
		}
		if (strcmp(Extension.extensionName, XR_EXT_USER_PRESENCE_EXTENSION_NAME) == 0)
			VRPresenceExtension = true;
	}
	if (!SupportsD3D12)
	{
		debugf(TEXT("Unreal Revived OpenXR: runtime does not support %ls; continuing flat-screen D3D12"), appFromAnsi(XR_KHR_D3D12_ENABLE_EXTENSION_NAME));
		return;
	}

	std::vector<const char*> EnabledExtensions = { XR_KHR_D3D12_ENABLE_EXTENSION_NAME };
	if (VRPresenceExtension) EnabledExtensions.push_back(XR_EXT_USER_PRESENCE_EXTENSION_NAME);
	for (const auto& Profile : OpenXRControllers::Profiles())
		if (Profile.Extension)
			for (const auto& Extension : Extensions)
				if (strcmp(Extension.extensionName, Profile.Extension) == 0)
					EnabledExtensions.push_back(Profile.Extension);
	XrInstanceCreateInfo CreateInfo = { XR_TYPE_INSTANCE_CREATE_INFO };
	strncpy_s(CreateInfo.applicationInfo.applicationName, "Unreal Revived", _TRUNCATE);
	CreateInfo.applicationInfo.applicationVersion = 6;
	strncpy_s(CreateInfo.applicationInfo.engineName, "Unreal Engine 1", _TRUNCATE);
	CreateInfo.applicationInfo.engineVersion = 227;
	CreateInfo.applicationInfo.apiVersion = XR_API_VERSION_1_0;
	CreateInfo.enabledExtensionCount = static_cast<uint32_t>(EnabledExtensions.size());
	CreateInfo.enabledExtensionNames = EnabledExtensions.data();
	Result = CreateInstance(&CreateInfo, &OpenXRInstance);
	if (XR_FAILED(Result) || OpenXRInstance == XR_NULL_HANDLE)
	{
		OpenXRInstance = XR_NULL_HANDLE;
		if (Result == XR_ERROR_RUNTIME_UNAVAILABLE)
			debugf(TEXT("Unreal Revived OpenXR: active runtime unavailable; start the headset software and connect or wake the HMD (result %d); continuing flat-screen D3D12"), Result);
		else if (Result == XR_ERROR_API_VERSION_UNSUPPORTED)
			debugf(TEXT("Unreal Revived OpenXR: active runtime does not support OpenXR 1.0 (result %d); continuing flat-screen D3D12"), Result);
		else
			debugf(TEXT("Unreal Revived OpenXR: instance creation failed (result %d); continuing flat-screen D3D12"), Result);
		return;
	}

	RawFunction = nullptr;
	Result = OpenXRGetInstanceProcAddr(OpenXRInstance, "xrGetInstanceProperties", &RawFunction);
	if (XR_SUCCEEDED(Result) && RawFunction)
	{
		XrInstanceProperties Properties = { XR_TYPE_INSTANCE_PROPERTIES };
		Result = reinterpret_cast<PFN_xrGetInstanceProperties>(RawFunction)(OpenXRInstance, &Properties);
		if (XR_SUCCEEDED(Result))
		{
			debugf(TEXT("Unreal Revived OpenXR: runtime=%ls version=%u.%u.%u"),
				appFromAnsi(Properties.runtimeName),
				(UINT)XR_VERSION_MAJOR(Properties.runtimeVersion),
				(UINT)XR_VERSION_MINOR(Properties.runtimeVersion),
				(UINT)XR_VERSION_PATCH(Properties.runtimeVersion));
		}
		else
			debugf(TEXT("Unreal Revived OpenXR: runtime properties query failed (result %d)"), Result);
	}
	else
		debugf(TEXT("Unreal Revived OpenXR: xrGetInstanceProperties unavailable (result %d)"), Result);

	RawFunction = nullptr;
	Result = OpenXRGetInstanceProcAddr(OpenXRInstance, "xrGetSystem", &RawFunction);
	if (XR_FAILED(Result) || !RawFunction)
	{
		debugf(TEXT("Unreal Revived OpenXR: xrGetSystem unavailable (result %d); continuing flat-screen D3D12"), Result);
		return;
	}

	XrSystemGetInfo SystemInfo = { XR_TYPE_SYSTEM_GET_INFO };
	SystemInfo.formFactor = XR_FORM_FACTOR_HEAD_MOUNTED_DISPLAY;
	Result = reinterpret_cast<PFN_xrGetSystem>(RawFunction)(OpenXRInstance, &SystemInfo, &OpenXRSystemId);
	if (Result == XR_ERROR_FORM_FACTOR_UNAVAILABLE)
	{
		debugf(TEXT("Unreal Revived OpenXR: headset unavailable; connect and wake the HMD before launching with -vr"));
	}
	else if (Result == XR_ERROR_FORM_FACTOR_UNSUPPORTED)
	{
		debugf(TEXT("Unreal Revived OpenXR: active runtime does not support a head-mounted display"));
	}
	else if (XR_FAILED(Result) || OpenXRSystemId == XR_NULL_SYSTEM_ID)
	{
		debugf(TEXT("Unreal Revived OpenXR: headset query failed (result %d)"), Result);
	}
	else
	{
		RawFunction = nullptr;
		Result = OpenXRGetInstanceProcAddr(OpenXRInstance, "xrGetSystemProperties", &RawFunction);
		if (XR_SUCCEEDED(Result) && RawFunction)
		{
			XrSystemProperties Properties = { XR_TYPE_SYSTEM_PROPERTIES };
			XrSystemUserPresencePropertiesEXT Presence = { XR_TYPE_SYSTEM_USER_PRESENCE_PROPERTIES_EXT };
			if (VRPresenceExtension) Properties.next = &Presence;
			Result = reinterpret_cast<PFN_xrGetSystemProperties>(RawFunction)(OpenXRInstance, OpenXRSystemId, &Properties);
			VRPitch.HasPresenceEvents = XR_SUCCEEDED(Result) && Presence.supportsUserPresence;
			if (XR_SUCCEEDED(Result))
			{
				debugf(TEXT("Unreal Revived OpenXR: headset detected=%ls vendor=%u orientationTracking=%s positionTracking=%s"),
					appFromAnsi(Properties.systemName), Properties.vendorId,
					Properties.trackingProperties.orientationTracking ? TEXT("true") : TEXT("false"),
					Properties.trackingProperties.positionTracking ? TEXT("true") : TEXT("false"));
			}
			else
				debugf(TEXT("Unreal Revived OpenXR: headset detected, but system properties failed (result %d)"), Result);
		}
		else
			debugf(TEXT("Unreal Revived OpenXR: headset detected, but xrGetSystemProperties is unavailable (result %d)"), Result);
	}

	if (OpenXRSystemId == XR_NULL_SYSTEM_ID)
	{
		debugf(TEXT("Unreal Revived OpenXR: detection incomplete; continuing flat-screen D3D12"));
		return;
	}

	RawFunction = nullptr;
	Result = OpenXRGetInstanceProcAddr(OpenXRInstance, "xrGetD3D12GraphicsRequirementsKHR", &RawFunction);
	if (XR_FAILED(Result) || !RawFunction)
	{
		debugf(TEXT("Unreal Revived OpenXR: D3D12 graphics requirements unavailable (result %d); continuing flat-screen D3D12"), Result);
		return;
	}
	XrGraphicsRequirementsD3D12KHR GraphicsRequirements = { XR_TYPE_GRAPHICS_REQUIREMENTS_D3D12_KHR };
	Result = reinterpret_cast<PFN_xrGetD3D12GraphicsRequirementsKHR>(RawFunction)(OpenXRInstance, OpenXRSystemId, &GraphicsRequirements);
	if (XR_FAILED(Result))
	{
		debugf(TEXT("Unreal Revived OpenXR: D3D12 graphics requirements query failed (result %d); continuing flat-screen D3D12"), Result);
		return;
	}
	const LUID DeviceLuid = Device->GetAdapterLuid();
	if (memcmp(&DeviceLuid, &GraphicsRequirements.adapterLuid, sizeof(LUID)) != 0)
	{
		debugf(TEXT("Unreal Revived OpenXR: runtime requires a different graphics adapter; continuing flat-screen D3D12"));
		return;
	}
	const D3D_FEATURE_LEVEL RequestedFeatureLevels[] = {
#if defined(D3D_FEATURE_LEVEL_12_2)
		D3D_FEATURE_LEVEL_12_2,
#endif
		D3D_FEATURE_LEVEL_12_1, D3D_FEATURE_LEVEL_12_0,
		D3D_FEATURE_LEVEL_11_1, D3D_FEATURE_LEVEL_11_0
	};
	D3D12_FEATURE_DATA_FEATURE_LEVELS SupportedFeatureLevels = {};
	SupportedFeatureLevels.NumFeatureLevels = sizeof(RequestedFeatureLevels) / sizeof(RequestedFeatureLevels[0]);
	SupportedFeatureLevels.pFeatureLevelsRequested = RequestedFeatureLevels;
	SupportedFeatureLevels.MaxSupportedFeatureLevel = D3D_FEATURE_LEVEL_11_0;
	const HRESULT FeatureResult = Device->CheckFeatureSupport(D3D12_FEATURE_FEATURE_LEVELS,
		&SupportedFeatureLevels, sizeof(SupportedFeatureLevels));
	if (FAILED(FeatureResult) || GraphicsRequirements.minFeatureLevel > SupportedFeatureLevels.MaxSupportedFeatureLevel)
	{
		debugf(TEXT("Unreal Revived OpenXR: runtime requires D3D feature level 0x%x, adapter supports 0x%x; continuing flat-screen D3D12"),
			(UINT)GraphicsRequirements.minFeatureLevel, (UINT)SupportedFeatureLevels.MaxSupportedFeatureLevel);
		return;
	}

	RawFunction = nullptr;
	Result = OpenXRGetInstanceProcAddr(OpenXRInstance, "xrCreateSession", &RawFunction);
	if (XR_FAILED(Result) || !RawFunction)
	{
		debugf(TEXT("Unreal Revived OpenXR: xrCreateSession unavailable (result %d); continuing flat-screen D3D12"), Result);
		return;
	}
	XrGraphicsBindingD3D12KHR GraphicsBinding = { XR_TYPE_GRAPHICS_BINDING_D3D12_KHR };
	GraphicsBinding.device = Device.get();
	GraphicsBinding.queue = GraphicsQueue.get();
	XrSessionCreateInfo SessionInfo = { XR_TYPE_SESSION_CREATE_INFO };
	SessionInfo.next = &GraphicsBinding;
	SessionInfo.systemId = OpenXRSystemId;
	Result = reinterpret_cast<PFN_xrCreateSession>(RawFunction)(OpenXRInstance, &SessionInfo, &OpenXRSession);
	if (XR_FAILED(Result) || OpenXRSession == XR_NULL_HANDLE)
	{
		OpenXRSession = XR_NULL_HANDLE;
		debugf(TEXT("Unreal Revived OpenXR: D3D12 session creation failed (result %d); continuing flat-screen D3D12"), Result);
		return;
	}

	UBOOL RenderingInitialized = 0;
	try
	{
		RenderingInitialized = InitializeOpenXRRendering();
	}
	catch (const std::exception& Error)
	{
		debugf(TEXT("Unreal Revived OpenXR: stereo rendering setup failed: %s"), to_utf16(Error.what()).c_str());
	}
	if (!RenderingInitialized)
	{
		debugf(TEXT("Unreal Revived OpenXR: D3D12 session created, but headset presentation initialization failed; continuing flat-screen D3D12"));
		return;
	}

	if (!MotionControllers.Initialize(OpenXRInstance, OpenXRSession, OpenXRGetInstanceProcAddr, EnabledExtensions))
	{
		MotionControllers.Release();
		debugf(TEXT("Unreal Revived OpenXR: motion input unavailable; gaze rendering remains available"));
	}
	debugf(TEXT("Unreal Revived OpenXR: D3D12 session and stereo game presentation initialized; monitor rendering remains active"));
	PollOpenXRSession();
}

UBOOL UD3D12RenderDevice::InitializeOpenXRRendering()
{
	auto Resolve = [this](const char* Name, PFN_xrVoidFunction* Function) -> UBOOL
	{
		*Function = nullptr;
		const XrResult Result = OpenXRGetInstanceProcAddr(OpenXRInstance, Name, Function);
		if (XR_FAILED(Result) || !*Function)
		{
			debugf(TEXT("Unreal Revived OpenXR: required function %ls unavailable (result %d)"), appFromAnsi(Name), Result);
			return 0;
		}
		return 1;
	};

#define RESOLVE_OPENXR_FUNCTION(Name) \
	if (!Resolve("xr" #Name, reinterpret_cast<PFN_xrVoidFunction*>(&OpenXRFunctions.Name))) return 0
	RESOLVE_OPENXR_FUNCTION(PollEvent);
	RESOLVE_OPENXR_FUNCTION(BeginSession);
	RESOLVE_OPENXR_FUNCTION(EndSession);
	RESOLVE_OPENXR_FUNCTION(CreateReferenceSpace);
	RESOLVE_OPENXR_FUNCTION(DestroySpace);
	RESOLVE_OPENXR_FUNCTION(LocateSpace);
	RESOLVE_OPENXR_FUNCTION(EnumerateViewConfigurationViews);
	RESOLVE_OPENXR_FUNCTION(EnumerateEnvironmentBlendModes);
	RESOLVE_OPENXR_FUNCTION(EnumerateSwapchainFormats);
	RESOLVE_OPENXR_FUNCTION(CreateSwapchain);
	RESOLVE_OPENXR_FUNCTION(DestroySwapchain);
	RESOLVE_OPENXR_FUNCTION(EnumerateSwapchainImages);
	RESOLVE_OPENXR_FUNCTION(WaitFrame);
	RESOLVE_OPENXR_FUNCTION(BeginFrame);
	RESOLVE_OPENXR_FUNCTION(LocateViews);
	RESOLVE_OPENXR_FUNCTION(AcquireSwapchainImage);
	RESOLVE_OPENXR_FUNCTION(WaitSwapchainImage);
	RESOLVE_OPENXR_FUNCTION(ReleaseSwapchainImage);
	RESOLVE_OPENXR_FUNCTION(EndFrame);
#undef RESOLVE_OPENXR_FUNCTION

	uint32_t ViewCount = 0;
	XrResult Result = OpenXRFunctions.EnumerateViewConfigurationViews(OpenXRInstance, OpenXRSystemId,
		XR_VIEW_CONFIGURATION_TYPE_PRIMARY_STEREO, 0, &ViewCount, nullptr);
	if (XR_FAILED(Result) || ViewCount != 2)
	{
		debugf(TEXT("Unreal Revived OpenXR: primary stereo view query returned count=%u result=%d; two views are required"), ViewCount, Result);
		return 0;
	}
	OpenXRConfigurationViews.assign(ViewCount, { XR_TYPE_VIEW_CONFIGURATION_VIEW });
	Result = OpenXRFunctions.EnumerateViewConfigurationViews(OpenXRInstance, OpenXRSystemId,
		XR_VIEW_CONFIGURATION_TYPE_PRIMARY_STEREO, ViewCount, &ViewCount, OpenXRConfigurationViews.data());
	if (XR_FAILED(Result) || ViewCount != OpenXRConfigurationViews.size())
	{
		debugf(TEXT("Unreal Revived OpenXR: primary stereo view configuration failed (result %d)"), Result);
		return 0;
	}
	OpenXRViews.assign(ViewCount, { XR_TYPE_VIEW });
	ActiveVRRenderQuality = VRRenderSizing::NormalizeQuality(VRRenderQuality);
	VRQualityBuffersFailed = false;

	uint32_t BlendModeCount = 0;
	Result = OpenXRFunctions.EnumerateEnvironmentBlendModes(OpenXRInstance, OpenXRSystemId,
		XR_VIEW_CONFIGURATION_TYPE_PRIMARY_STEREO, 0, &BlendModeCount, nullptr);
	if (XR_FAILED(Result) || BlendModeCount == 0)
	{
		debugf(TEXT("Unreal Revived OpenXR: environment blend mode query failed (result %d)"), Result);
		return 0;
	}
	std::vector<XrEnvironmentBlendMode> BlendModes(BlendModeCount);
	Result = OpenXRFunctions.EnumerateEnvironmentBlendModes(OpenXRInstance, OpenXRSystemId,
		XR_VIEW_CONFIGURATION_TYPE_PRIMARY_STEREO, BlendModeCount, &BlendModeCount, BlendModes.data());
	if (XR_FAILED(Result))
	{
		debugf(TEXT("Unreal Revived OpenXR: environment blend modes unavailable (result %d)"), Result);
		return 0;
	}
	OpenXRBlendMode = BlendModes[0];
	for (XrEnvironmentBlendMode Mode : BlendModes)
	{
		if (Mode == XR_ENVIRONMENT_BLEND_MODE_OPAQUE)
		{
			OpenXRBlendMode = Mode;
			break;
		}
	}

	XrReferenceSpaceCreateInfo SpaceInfo = { XR_TYPE_REFERENCE_SPACE_CREATE_INFO };
	SpaceInfo.referenceSpaceType = XR_REFERENCE_SPACE_TYPE_LOCAL;
	SpaceInfo.poseInReferenceSpace.orientation.w = 1.0f;
	Result = OpenXRFunctions.CreateReferenceSpace(OpenXRSession, &SpaceInfo, &OpenXRLocalSpace);
	if (XR_FAILED(Result) || OpenXRLocalSpace == XR_NULL_HANDLE)
	{
		OpenXRLocalSpace = XR_NULL_HANDLE;
		debugf(TEXT("Unreal Revived OpenXR: seated local reference space creation failed (result %d)"), Result);
		return 0;
	}

	SpaceInfo.referenceSpaceType = XR_REFERENCE_SPACE_TYPE_VIEW;
	if (XR_FAILED(OpenXRFunctions.CreateReferenceSpace(OpenXRSession, &SpaceInfo, &OpenXRHeadSpace)))
		OpenXRHeadSpace = XR_NULL_HANDLE;

	uint32_t FormatCount = 0;
	Result = OpenXRFunctions.EnumerateSwapchainFormats(OpenXRSession, 0, &FormatCount, nullptr);
	if (XR_FAILED(Result) || FormatCount == 0)
	{
		debugf(TEXT("Unreal Revived OpenXR: swapchain format query failed (result %d)"), Result);
		return 0;
	}
	std::vector<int64_t> Formats(FormatCount);
	Result = OpenXRFunctions.EnumerateSwapchainFormats(OpenXRSession, FormatCount, &FormatCount, Formats.data());
	if (XR_FAILED(Result))
	{
		debugf(TEXT("Unreal Revived OpenXR: swapchain formats unavailable (result %d)"), Result);
		return 0;
	}
	const DXGI_FORMAT PreferredFormats[] = {
		DXGI_FORMAT_R8G8B8A8_UNORM_SRGB,
		DXGI_FORMAT_B8G8R8A8_UNORM_SRGB,
		DXGI_FORMAT_R8G8B8A8_UNORM,
		DXGI_FORMAT_B8G8R8A8_UNORM
	};
	DXGI_FORMAT SelectedFormat = DXGI_FORMAT_UNKNOWN;
	for (DXGI_FORMAT Preferred : PreferredFormats)
	{
		if (std::find(Formats.begin(), Formats.end(), static_cast<int64_t>(Preferred)) != Formats.end())
		{
			SelectedFormat = Preferred;
			break;
		}
	}
	if (SelectedFormat == DXGI_FORMAT_UNKNOWN)
	{
		debugf(TEXT("Unreal Revived OpenXR: runtime offered no supported color swapchain format"));
		return 0;
	}

	VREyeFormat = SelectedFormat;
	OpenXRSwapchains.resize(ViewCount);
	OpenXREyeSwapchains::Pair EyePair;
	if (!OpenXREyeSwapchains::Create(OpenXRSession, OpenXRConfigurationViews.data(), ActiveVRRenderQuality,
		static_cast<int64_t>(SelectedFormat), OpenXRFunctions.CreateSwapchain,
		OpenXRFunctions.DestroySwapchain, EyePair))
	{
		debugf(TEXT("Unreal Revived OpenXR: eye swapchain creation failed, including current-profile fallback"));
		return 0;
	}
	ActiveVRRenderQuality = EyePair.Quality;
	VRQualityBuffersFailed = EyePair.FellBack;
	if (EyePair.FellBack)
		debugf(TEXT("Unreal Revived OpenXR: optional eye swapchain size rejected; using current profile for both eyes"));
	// Transfer both handles before image enumeration so teardown owns the pair
	// even if enumerating the first eye fails.
	for (uint32_t ViewIndex = 0; ViewIndex < ViewCount; ++ViewIndex)
	{
		OpenXRSwapchains[ViewIndex].Handle = EyePair.Handles[ViewIndex];
		OpenXRSwapchains[ViewIndex].Width = EyePair.Sizes[ViewIndex].Width;
		OpenXRSwapchains[ViewIndex].Height = EyePair.Sizes[ViewIndex].Height;
	}
	for (uint32_t ViewIndex = 0; ViewIndex < ViewCount; ViewIndex++)
	{
		OpenXRViewSwapchain& ViewSwapchain = OpenXRSwapchains[ViewIndex];
		const XrViewConfigurationView& View = OpenXRConfigurationViews[ViewIndex];
		debugf(TEXT("Unreal Revived OpenXR: eye=%u quality=%d output=%dx%d recommended=%ux%u max=%ux%u"),
			ViewIndex, ActiveVRRenderQuality, ViewSwapchain.Width, ViewSwapchain.Height,
			View.recommendedImageRectWidth, View.recommendedImageRectHeight,
			View.maxImageRectWidth, View.maxImageRectHeight);

		uint32_t ImageCount = 0;
		Result = OpenXRFunctions.EnumerateSwapchainImages(ViewSwapchain.Handle, 0, &ImageCount, nullptr);
		if (XR_FAILED(Result) || ImageCount == 0)
		{
			debugf(TEXT("Unreal Revived OpenXR: view %u swapchain image count failed (result %d)"), ViewIndex, Result);
			return 0;
		}
		ViewSwapchain.Images.assign(ImageCount, { XR_TYPE_SWAPCHAIN_IMAGE_D3D12_KHR });
		Result = OpenXRFunctions.EnumerateSwapchainImages(ViewSwapchain.Handle, ImageCount, &ImageCount,
			reinterpret_cast<XrSwapchainImageBaseHeader*>(ViewSwapchain.Images.data()));
		if (XR_FAILED(Result))
		{
			debugf(TEXT("Unreal Revived OpenXR: view %u swapchain image enumeration failed (result %d)"), ViewIndex, Result);
			return 0;
		}
		ViewSwapchain.RTVs = Heaps.RTV->Alloc(static_cast<INT>(ImageCount));
		for (uint32_t ImageIndex = 0; ImageIndex < ImageCount; ImageIndex++)
		{
			D3D12_RENDER_TARGET_VIEW_DESC RTVDesc = {};
			RTVDesc.Format = SelectedFormat;
			RTVDesc.ViewDimension = D3D12_RTV_DIMENSION_TEXTURE2D;
			Device->CreateRenderTargetView(ViewSwapchain.Images[ImageIndex].texture, &RTVDesc,
				ViewSwapchain.RTVs.CPUHandle(static_cast<INT>(ImageIndex)));
		}
	}

	OpenXRUISwapchain.Width = 1024;
	OpenXRUISwapchain.Height = 1024;
	XrSwapchainCreateInfo UISwapchainInfo = { XR_TYPE_SWAPCHAIN_CREATE_INFO };
	UISwapchainInfo.usageFlags = XR_SWAPCHAIN_USAGE_COLOR_ATTACHMENT_BIT;
	UISwapchainInfo.format = static_cast<int64_t>(SelectedFormat);
	UISwapchainInfo.sampleCount = 1;
	UISwapchainInfo.width = OpenXRUISwapchain.Width;
	UISwapchainInfo.height = OpenXRUISwapchain.Height;
	UISwapchainInfo.faceCount = 1;
	UISwapchainInfo.arraySize = 2;
	UISwapchainInfo.mipCount = 1;
	Result = OpenXRFunctions.CreateSwapchain(OpenXRSession, &UISwapchainInfo, &OpenXRUISwapchain.Handle);
	if (XR_FAILED(Result) || OpenXRUISwapchain.Handle == XR_NULL_HANDLE)
	{
		debugf(TEXT("Unreal Revived OpenXR: UI swapchain creation failed (result %d)"), Result);
		return 0;
	}
	uint32_t UIImageCount = 0;
	Result = OpenXRFunctions.EnumerateSwapchainImages(OpenXRUISwapchain.Handle, 0, &UIImageCount, nullptr);
	if (XR_FAILED(Result) || UIImageCount == 0)
		return 0;
	OpenXRUISwapchain.Images.assign(UIImageCount, { XR_TYPE_SWAPCHAIN_IMAGE_D3D12_KHR });
	Result = OpenXRFunctions.EnumerateSwapchainImages(OpenXRUISwapchain.Handle, UIImageCount, &UIImageCount,
		reinterpret_cast<XrSwapchainImageBaseHeader*>(OpenXRUISwapchain.Images.data()));
	if (XR_FAILED(Result))
		return 0;
	OpenXRUISwapchain.RTVs = Heaps.RTV->Alloc(static_cast<INT>(UIImageCount * 2));
	for (uint32_t ImageIndex = 0; ImageIndex < UIImageCount; ImageIndex++)
	{
		D3D12_RENDER_TARGET_VIEW_DESC RTVDesc = {};
		RTVDesc.Format = SelectedFormat;
		RTVDesc.ViewDimension = D3D12_RTV_DIMENSION_TEXTURE2DARRAY;
		RTVDesc.Texture2DArray.ArraySize = 1;
		for (uint32_t ViewIndex = 0; ViewIndex < 2; ViewIndex++)
		{
			RTVDesc.Texture2DArray.FirstArraySlice = ViewIndex;
			Device->CreateRenderTargetView(OpenXRUISwapchain.Images[ImageIndex].texture, &RTVDesc,
				OpenXRUISwapchain.RTVs.CPUHandle(static_cast<INT>(ImageIndex * 2 + ViewIndex)));
		}
	}

	std::vector<D3D12_INPUT_ELEMENT_DESC> Elements =
	{
		{ "AttrPos", 0, DXGI_FORMAT_R32G32_FLOAT, 0, 0, D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA, 0 }
	};
	const auto VertexShader = CompileHlsl("shaders/PPStep.vert", "vs");
	static const char* GammaModes[2] = { "GAMMA_MODE_D3D9", "GAMMA_MODE_XOPENGL" };
	static const char* ColorModes[4] = { nullptr, "COLOR_CORRECT_MODE0", "COLOR_CORRECT_MODE1", "COLOR_CORRECT_MODE2" };
	const UBOOL IsSRGB = SelectedFormat == DXGI_FORMAT_R8G8B8A8_UNORM_SRGB ||
		SelectedFormat == DXGI_FORMAT_B8G8R8A8_UNORM_SRGB;
	for (INT PipelineIndex = 0; PipelineIndex < 8; PipelineIndex++)
	{
		std::vector<std::string> Defines;
		Defines.push_back(GammaModes[PipelineIndex & 1]);
		if (ColorModes[(PipelineIndex >> 1) & 3])
			Defines.push_back(ColorModes[(PipelineIndex >> 1) & 3]);
		if (IsSRGB)
			Defines.push_back("OPENXR_SRGB_OUTPUT");
		const auto PixelShader = CompileHlsl("shaders/Present.frag", "ps", Defines);

		D3D12_GRAPHICS_PIPELINE_STATE_DESC PipelineDesc = {};
		PipelineDesc.pRootSignature = PresentPass.RootSignature;
		PipelineDesc.InputLayout.NumElements = static_cast<UINT>(Elements.size());
		PipelineDesc.InputLayout.pInputElementDescs = Elements.data();
		PipelineDesc.VS.pShaderBytecode = VertexShader.data();
		PipelineDesc.VS.BytecodeLength = VertexShader.size();
		PipelineDesc.PS.pShaderBytecode = PixelShader.data();
		PipelineDesc.PS.BytecodeLength = PixelShader.size();
		PipelineDesc.PrimitiveTopologyType = D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE;
		PipelineDesc.RasterizerState.FillMode = D3D12_FILL_MODE_SOLID;
		PipelineDesc.RasterizerState.CullMode = D3D12_CULL_MODE_NONE;
		PipelineDesc.BlendState.RenderTarget[0].RenderTargetWriteMask = D3D12_COLOR_WRITE_ENABLE_ALL;
		PipelineDesc.DepthStencilState.DepthFunc = D3D12_COMPARISON_FUNC_ALWAYS;
		PipelineDesc.SampleDesc.Count = 1;
		PipelineDesc.SampleMask = UINT_MAX;
		PipelineDesc.NumRenderTargets = 1;
		PipelineDesc.RTVFormats[0] = SelectedFormat;
		const HRESULT PipelineResult = Device->CreateGraphicsPipelineState(&PipelineDesc,
			OpenXRPresentPipelines[PipelineIndex].GetIID(), OpenXRPresentPipelines[PipelineIndex].InitPtr());
		ThrowIfFailed(PipelineResult, "CreateGraphicsPipelineState(OpenXRPresent) failed");
	}
	{
		std::vector<std::string> Defines = { "GAMMA_MODE_D3D9", "OPENXR_UI_LAYER" };
		if (IsSRGB)
			Defines.push_back("OPENXR_SRGB_OUTPUT");
		const auto UIPixelShader = CompileHlsl("shaders/Present.frag", "ps", Defines);
		D3D12_GRAPHICS_PIPELINE_STATE_DESC PipelineDesc = {};
		PipelineDesc.pRootSignature = PresentPass.RootSignature;
		PipelineDesc.InputLayout.NumElements = static_cast<UINT>(Elements.size());
		PipelineDesc.InputLayout.pInputElementDescs = Elements.data();
		PipelineDesc.VS = { VertexShader.data(), VertexShader.size() };
		PipelineDesc.PS = { UIPixelShader.data(), UIPixelShader.size() };
		PipelineDesc.PrimitiveTopologyType = D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE;
		PipelineDesc.RasterizerState.FillMode = D3D12_FILL_MODE_SOLID;
		PipelineDesc.RasterizerState.CullMode = D3D12_CULL_MODE_NONE;
		PipelineDesc.BlendState.RenderTarget[0].RenderTargetWriteMask = D3D12_COLOR_WRITE_ENABLE_ALL;
		PipelineDesc.DepthStencilState.DepthFunc = D3D12_COMPARISON_FUNC_ALWAYS;
		PipelineDesc.SampleDesc.Count = 1;
		PipelineDesc.SampleMask = UINT_MAX;
		PipelineDesc.NumRenderTargets = 1;
		PipelineDesc.RTVFormats[0] = SelectedFormat;
		ThrowIfFailed(Device->CreateGraphicsPipelineState(&PipelineDesc,
			OpenXRUIPresentPipeline.GetIID(), OpenXRUIPresentPipeline.InitPtr()),
			"CreateGraphicsPipelineState(OpenXRUI) failed");
	}

	OpenXRRenderingReady = 1;
	debugf(TEXT("Unreal Revived OpenXR: stereo swapchains ready views=%u size=%dx%d format=%d blendMode=%d"),
		ViewCount, OpenXRSwapchains[0].Width, OpenXRSwapchains[0].Height, (INT)SelectedFormat, (INT)OpenXRBlendMode);
	return 1;
}

void UD3D12RenderDevice::ApplyPendingVRQuality()
{
	if (!VRQualityPending || !OpenXRRenderingReady || OpenXRFrameBegun || OpenXRSwapchains.size() != 2)
		return;
	VRQualityPending = false;
	const INT Quality = VRRenderSizing::NormalizeQuality(VRRenderQuality);
	if (Quality == ActiveVRRenderQuality && !VRQualityBuffersFailed)
		return;

	// Prepare a complete replacement before retiring either working eye.
	std::vector<OpenXRViewSwapchain> Replacement(2);
	SceneBufferSet ReplacementBuffers[2];
	OpenXREyeSwapchains::Pair Pair;
	auto ReleaseReplacement = [&]()
	{
		for (auto& Eye : Replacement)
		{
			Eye.RTVs.reset();
			if (Eye.Handle != XR_NULL_HANDLE) OpenXRFunctions.DestroySwapchain(Eye.Handle);
			Eye.Handle = XR_NULL_HANDLE;
		}
		for (auto& Buffers : ReplacementBuffers)
		{
			std::swap(SceneBuffers, Buffers);
			ReleaseSceneBuffers();
			std::swap(SceneBuffers, Buffers);
			Buffers = {};
		}
	};
	try
	{
		if (!OpenXREyeSwapchains::Create(OpenXRSession, OpenXRConfigurationViews.data(), Quality,
			static_cast<int64_t>(VREyeFormat), OpenXRFunctions.CreateSwapchain,
			OpenXRFunctions.DestroySwapchain, Pair))
			throw std::runtime_error("eye swapchain creation failed");
		for (int Eye = 0; Eye < 2; ++Eye)
		{
			Replacement[Eye].Handle = Pair.Handles[Eye];
			Replacement[Eye].Width = Pair.Sizes[Eye].Width;
			Replacement[Eye].Height = Pair.Sizes[Eye].Height;
		}
		if (Pair.FellBack) throw std::runtime_error("requested eye size rejected");
		for (auto& Eye : Replacement)
		{
			uint32_t Count = 0;
			if (XR_FAILED(OpenXRFunctions.EnumerateSwapchainImages(Eye.Handle, 0, &Count, nullptr)) || !Count)
				throw std::runtime_error("eye image count unavailable");
			Eye.Images.assign(Count, { XR_TYPE_SWAPCHAIN_IMAGE_D3D12_KHR });
			if (XR_FAILED(OpenXRFunctions.EnumerateSwapchainImages(Eye.Handle, Count, &Count,
				reinterpret_cast<XrSwapchainImageBaseHeader*>(Eye.Images.data()))))
				throw std::runtime_error("eye image enumeration failed");
			Eye.RTVs = Heaps.RTV->Alloc(static_cast<INT>(Count));
			for (uint32_t Image = 0; Image < Count; ++Image)
			{
				D3D12_RENDER_TARGET_VIEW_DESC Desc = {};
				Desc.Format = VREyeFormat;
				Desc.ViewDimension = D3D12_RTV_DIMENSION_TEXTURE2D;
				Device->CreateRenderTargetView(Eye.Images[Image].texture, &Desc, Eye.RTVs.CPUHandle(Image));
			}
		}
		if (Quality)
		{
			const int Count = Pair.Sizes[0].Width == Pair.Sizes[1].Width &&
				Pair.Sizes[0].Height == Pair.Sizes[1].Height ? 1 : 2;
			for (int Eye = 0; Eye < Count; ++Eye)
			{
				std::swap(SceneBuffers, ReplacementBuffers[Eye]);
				try { ResizeSceneBuffers(Pair.Sizes[Eye].Width, Pair.Sizes[Eye].Height, GetSettingsMultisample()); }
				catch (...) { std::swap(SceneBuffers, ReplacementBuffers[Eye]); throw; }
				std::swap(SceneBuffers, ReplacementBuffers[Eye]);
			}
		}
		SubmitCommands(false);
		WaitDeviceIdle();
	}
	catch (const std::exception& Error)
	{
		SubmitCommands(false);
		WaitDeviceIdle();
		ReleaseReplacement();
		VRQualityChangeFailed = true;
		debugf(TEXT("Unreal Revived OpenXR: live quality change failed; keeping active quality %d: %s"),
			ActiveVRRenderQuality, to_utf16(Error.what()).c_str());
		return;
	}
	OpenXRSwapchains.swap(Replacement);
	for (int Eye = 0; Eye < 2; ++Eye) std::swap(VREyeBuffers[Eye], ReplacementBuffers[Eye]);
	ReleaseReplacement();
	ActiveVRRenderQuality = Quality;
	VRQualityBuffersFailed = false;
	VRQualityChangeFailed = false;
	LastVREyeBuffer = -1;
	VRStatistics = {};
	debugf(TEXT("Unreal Revived OpenXR: live quality=%d eye=%dx%d"), Quality,
		OpenXRSwapchains[0].Width, OpenXRSwapchains[0].Height);
}

void UD3D12RenderDevice::PollOpenXRSession()
{
	if (OpenXRInstance == XR_NULL_HANDLE || OpenXRSession == XR_NULL_HANDLE || !OpenXRGetInstanceProcAddr)
		return;
	if (!OpenXRFunctions.PollEvent)
		return;
	for (;;)
	{
		XrEventDataBuffer Event = { XR_TYPE_EVENT_DATA_BUFFER };
		XrResult Result = OpenXRFunctions.PollEvent(OpenXRInstance, &Event);
		if (Result == XR_EVENT_UNAVAILABLE)
			break;
		if (XR_FAILED(Result))
		{
			debugf(TEXT("Unreal Revived OpenXR: event polling failed (result %d)"), Result);
			break;
		}
		if (Event.type == XR_TYPE_EVENT_DATA_SESSION_STATE_CHANGED)
		{
			const XrEventDataSessionStateChanged* StateEvent =
				reinterpret_cast<const XrEventDataSessionStateChanged*>(&Event);
			OpenXRSessionState = StateEvent->state;
			if (OpenXRSessionState == XR_SESSION_STATE_SYNCHRONIZED ||
				OpenXRSessionState == XR_SESSION_STATE_STOPPING || OpenXRSessionState == XR_SESSION_STATE_IDLE)
				VRPitch.Hidden();
			if (OpenXRSessionState == XR_SESSION_STATE_FOCUSED) VRPitch.Focused();
			VRStatistics = {};
			debugf(TEXT("Unreal Revived OpenXR: session state=%d"), (INT)OpenXRSessionState);
			if (OpenXRSessionState == XR_SESSION_STATE_READY && OpenXRRenderingReady && !OpenXRSessionRunning)
			{
				XrSessionBeginInfo BeginInfo = { XR_TYPE_SESSION_BEGIN_INFO };
				BeginInfo.primaryViewConfigurationType = XR_VIEW_CONFIGURATION_TYPE_PRIMARY_STEREO;
				Result = OpenXRFunctions.BeginSession(OpenXRSession, &BeginInfo);
				if (XR_SUCCEEDED(Result))
				{
					OpenXRHeadOrientation = { 0.0f, 0.0f, 0.0f, 1.0f };
					OpenXRBaseOrientation = { 0.0f, 0.0f, 0.0f, 1.0f };
					OpenXRBaseHeadPosition = { 0.0f, 0.0f, 0.0f };
					OpenXRRelativeHeadRotation = FRotator(0, 0, 0);
					OpenXRHeadPoseValid = 0;
					OpenXRBaseOrientationValid = 0;
					OpenXRViewsValid = 0;
					OpenXRStereoRenderingLogged = 0;
					OpenXRFovLogged = 0;
					OpenXRStereoDrawEye = -1;
					OpenXRSessionRunning = 1;
					debugf(TEXT("Unreal Revived OpenXR: stereo session begun"));
				}
				else
					debugf(TEXT("Unreal Revived OpenXR: session begin failed (result %d)"), Result);
			}
			else if (OpenXRSessionState == XR_SESSION_STATE_STOPPING && OpenXRSessionRunning)
			{
				OpenXRSessionRunning = 0;
				OpenXRHeadPoseValid = 0;
				OpenXRBaseOrientationValid = 0;
				OpenXRViewsValid = 0;
				Result = OpenXRFunctions.EndSession(OpenXRSession);
				if (XR_FAILED(Result))
					debugf(TEXT("Unreal Revived OpenXR: session end failed (result %d)"), Result);
			}
			else if (OpenXRSessionState == XR_SESSION_STATE_EXITING || OpenXRSessionState == XR_SESSION_STATE_LOSS_PENDING)
			{
				OpenXRSessionRunning = 0;
				OpenXRHeadPoseValid = 0;
				OpenXRBaseOrientationValid = 0;
				OpenXRViewsValid = 0;
			}
		}
		else if (Event.type == XR_TYPE_EVENT_DATA_USER_PRESENCE_CHANGED_EXT && VRPitch.HasPresenceEvents)
		{
			const auto* Presence = reinterpret_cast<const XrEventDataUserPresenceChangedEXT*>(&Event);
			if (Presence->session == OpenXRSession) VRPitch.Presence(Presence->isUserPresent != 0);
		}
		else if (Event.type == XR_TYPE_EVENT_DATA_INSTANCE_LOSS_PENDING)
			debugf(TEXT("Unreal Revived OpenXR: runtime reported instance loss pending"));
	}
}

UBOOL UD3D12RenderDevice::PrepareOpenXRFrame()
{
	if (!OpenXRSessionRunning || !OpenXRRenderingReady || OpenXRFrameBegun)
		return 0;

	XrFrameWaitInfo WaitInfo = { XR_TYPE_FRAME_WAIT_INFO };
	XrFrameState FrameState = { XR_TYPE_FRAME_STATE };
	XrResult Result = OpenXRFunctions.WaitFrame(OpenXRSession, &WaitInfo, &FrameState);
	if (XR_FAILED(Result))
	{
		debugf(TEXT("Unreal Revived OpenXR: xrWaitFrame failed (result %d)"), Result);
		OpenXRSessionRunning = 0;
		return 0;
	}
	XrFrameBeginInfo BeginInfo = { XR_TYPE_FRAME_BEGIN_INFO };
	Result = OpenXRFunctions.BeginFrame(OpenXRSession, &BeginInfo);
	if (XR_FAILED(Result))
	{
		debugf(TEXT("Unreal Revived OpenXR: xrBeginFrame failed (result %d)"), Result);
		OpenXRSessionRunning = 0;
		return 0;
	}
	OpenXRFrameBegun = 1;
	OpenXRSubmitLayer = 0;
	OpenXRUILayerReady = 0;
	OpenXRUIEyeMask = 0;
	OpenXRViewsValid = 0;
	OpenXRPredictedDisplayTime = FrameState.predictedDisplayTime;
	VRShouldRender = FrameState.shouldRender != 0;
	MotionControllers.Update(OpenXRLocalSpace, OpenXRPredictedDisplayTime,
		OpenXRSessionState == XR_SESSION_STATE_FOCUSED && FrameState.shouldRender);
	MotionSampleTime = appSeconds();
	for (OpenXRViewSwapchain& Swapchain : OpenXRSwapchains)
		Swapchain.ImageReady = 0;
	OpenXRUISwapchain.ImageReady = 0;
	if (!FrameState.shouldRender)
		return 1;

	XrViewLocateInfo LocateInfo = { XR_TYPE_VIEW_LOCATE_INFO };
	LocateInfo.viewConfigurationType = XR_VIEW_CONFIGURATION_TYPE_PRIMARY_STEREO;
	LocateInfo.displayTime = OpenXRPredictedDisplayTime;
	LocateInfo.space = OpenXRLocalSpace;
	XrViewState ViewState = { XR_TYPE_VIEW_STATE };
	uint32_t ViewCount = 0;
	Result = OpenXRFunctions.LocateViews(OpenXRSession, &LocateInfo, &ViewState,
		static_cast<uint32_t>(OpenXRViews.size()), &ViewCount, OpenXRViews.data());
	if (XR_FAILED(Result) || ViewCount != OpenXRViews.size())
	{
		debugf(TEXT("Unreal Revived OpenXR: xrLocateViews failed count=%u result=%d"), ViewCount, Result);
		return 1;
	}
	if ((ViewState.viewStateFlags & XR_VIEW_STATE_ORIENTATION_VALID_BIT) != 0)
	{
		// Eye orientations can include optical cant. Prefer the actual head space.
		OpenXRHeadOrientation = OpenXRHeadOrientationFromViews(OpenXRViews[0].pose.orientation, OpenXRViews[1].pose.orientation);
		XrSpaceLocation HeadLocation = { XR_TYPE_SPACE_LOCATION };
		if (OpenXREyesHaveDifferentOrientations(OpenXRViews[0].pose.orientation, OpenXRViews[1].pose.orientation) &&
			OpenXRHeadSpace != XR_NULL_HANDLE &&
			XR_SUCCEEDED(OpenXRFunctions.LocateSpace(OpenXRHeadSpace, OpenXRLocalSpace, OpenXRPredictedDisplayTime, &HeadLocation)) &&
			(HeadLocation.locationFlags & XR_SPACE_LOCATION_ORIENTATION_VALID_BIT))
			OpenXRHeadOrientation = NormalizeOpenXRQuaternion(HeadLocation.pose.orientation);
		OpenXRHeadPoseValid = 1;
		const auto WorldHeading = OpenXRWorldHeading(OpenXRHeadOrientation, OpenXRBaseOrientation);
		if (OpenXRViewRecenterRequested &&
			(ViewState.viewStateFlags & XR_VIEW_STATE_POSITION_VALID_BIT) != 0)
		{
			// Apply between frames, before either eye is rendered. Preserve the
			// horizontal direction the user is facing while leveling software tilt.
			if (Viewport && Viewport->Actor)
			{
				FRotator ViewRotation = Viewport->Actor->ViewRotation;
				if (OpenXRBaseOrientationValid)
					ViewRotation.Yaw = static_cast<INT>((static_cast<DWORD>(ViewRotation.Yaw) +
						static_cast<DWORD>(RelativeOpenXRRotation(OpenXRBaseOrientation, WorldHeading).Yaw)) & 65535);
				ViewRotation.Pitch = ViewRotation.Roll = 0;
				Viewport->Actor->ViewRotation = ViewRotation;
				Viewport->Actor->aLookUp = Viewport->Actor->aMouseY = 0;
			}
			OpenXRBaseOrientationValid = 0;
			// Keep the HUD horizon level too: capture horizontal heading, never
			// the pitch/roll held during recenter. Later head motion stays tracked.
			OpenXRUIAnchorPose.orientation = WorldHeading;
			OpenXRUIAnchorHeadPosition = {
				(OpenXRViews[0].pose.position.x + OpenXRViews[1].pose.position.x) * 0.5f,
				(OpenXRViews[0].pose.position.y + OpenXRViews[1].pose.position.y) * 0.5f,
				(OpenXRViews[0].pose.position.z + OpenXRViews[1].pose.position.z) * 0.5f
			};
			OpenXRUIAnchorValid = 1;
			OpenXRViewRecenterRequested = 0;
		}
		if (!OpenXRBaseOrientationValid &&
			(ViewState.viewStateFlags & XR_VIEW_STATE_POSITION_VALID_BIT) != 0)
		{
			OpenXRBaseOrientation = WorldHeading;
			OpenXRBaseHeadPosition = {
				(OpenXRViews[0].pose.position.x + OpenXRViews[1].pose.position.x) * 0.5f,
				(OpenXRViews[0].pose.position.y + OpenXRViews[1].pose.position.y) * 0.5f,
				(OpenXRViews[0].pose.position.z + OpenXRViews[1].pose.position.z) * 0.5f
			};
			OpenXRBaseOrientationValid = 1;
			debugf(TEXT("Unreal Revived OpenXR: head orientation baseline captured for PlayerCalcView"));
		}

		OpenXRRelativeHeadRotation = RelativeOpenXRRotation(
			OpenXRBaseOrientation, OpenXRHeadOrientation);
	}
	else
		OpenXRHeadPoseValid = 0;
	if ((ViewState.viewStateFlags & XR_VIEW_STATE_POSITION_VALID_BIT) == 0 ||
		(ViewState.viewStateFlags & XR_VIEW_STATE_ORIENTATION_VALID_BIT) == 0)
		return 1;

	OpenXRViewsValid = 1;
	return 1;
}

UBOOL UD3D12RenderDevice::PresentOpenXREye(uint32_t ViewIndex)
{
	if (!OpenXRFrameBegun || !OpenXRViewsValid || ViewIndex >= OpenXRSwapchains.size())
		return 0;

	const FLOAT BackgroundColor[4] = { 0.005f, 0.012f, 0.025f, 1.0f };
	PresentPushConstants PushConstants = GetPresentPushConstants();
	PushConstants.VRHeadCollisionFade = Clamp(VRHeadCollisionFade, 0.0f, 1.0f);
	const auto& Eye = OpenXRViews[ViewIndex];
	PushConstants.VREyeTangents = vec4(appTan(Eye.fov.angleLeft), appTan(Eye.fov.angleRight),
		appTan(Eye.fov.angleDown), appTan(Eye.fov.angleUp));
	const auto EyeToHead = OpenXREyeToHeadOrientation(OpenXRHeadOrientation, Eye.pose.orientation);
	PushConstants.VRVignetteEyeToHead = vec4(EyeToHead.x, EyeToHead.y, EyeToHead.z, EyeToHead.w);
	INT PresentPipeline = GammaMode == 1 ? 1 : 0;
	if (PushConstants.Brightness != 0.0f || PushConstants.Contrast != 1.0f || PushConstants.Saturation != 1.0f)
		PresentPipeline |= (Clamp(GrayFormula, 0, 2) + 1) << 1;
	OpenXRViewSwapchain& Swapchain = OpenXRSwapchains[ViewIndex];
	XrResult Result;
	XrSwapchainImageAcquireInfo AcquireInfo = { XR_TYPE_SWAPCHAIN_IMAGE_ACQUIRE_INFO };
	Result = OpenXRFunctions.AcquireSwapchainImage(Swapchain.Handle, &AcquireInfo, &Swapchain.AcquiredImage);
	if (XR_FAILED(Result) || Swapchain.AcquiredImage >= Swapchain.Images.size())
	{
		debugf(TEXT("Unreal Revived OpenXR: view %u image acquire failed (result %d)"), ViewIndex, Result);
		return 0;
	}
	XrSwapchainImageWaitInfo ImageWaitInfo = { XR_TYPE_SWAPCHAIN_IMAGE_WAIT_INFO };
	ImageWaitInfo.timeout = XR_INFINITE_DURATION;
	Result = OpenXRFunctions.WaitSwapchainImage(Swapchain.Handle, &ImageWaitInfo);
	if (XR_FAILED(Result))
	{
		debugf(TEXT("Unreal Revived OpenXR: view %u image wait failed (result %d)"), ViewIndex, Result);
		return 0;
	}
	Swapchain.ImageReady = 1;
	const D3D12_CPU_DESCRIPTOR_HANDLE RTV =
		Swapchain.RTVs.CPUHandle(static_cast<INT>(Swapchain.AcquiredImage));
	Commands.Current->Draw->ClearRenderTargetView(RTV, BackgroundColor, 0, nullptr);
	Commands.Current->Draw->SetGraphicsRootSignature(PresentPass.RootSignature);
	Commands.Current->Draw->OMSetRenderTargets(1, &RTV, FALSE, nullptr);

	D3D12_VIEWPORT EyeViewport = {};
	EyeViewport.Width = static_cast<FLOAT>(Swapchain.Width);
	EyeViewport.Height = static_cast<FLOAT>(Swapchain.Height);
	EyeViewport.MaxDepth = 1.0f;
	Commands.Current->Draw->RSSetViewports(1, &EyeViewport);
	D3D12_RECT EyeScissor = { 0, 0, Swapchain.Width, Swapchain.Height };
	Commands.Current->Draw->RSSetScissorRects(1, &EyeScissor);
	Commands.Current->Draw->SetPipelineState(OpenXRPresentPipelines[PresentPipeline]);
	Commands.Current->Draw->IASetPrimitiveTopology(D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
	Commands.Current->Draw->IASetVertexBuffers(0, 1, &PresentPass.PPStepVertexBufferView);
	Commands.Current->Draw->SetGraphicsRootDescriptorTable(0, SceneBuffers.PresentSRVs.GPUHandle());
	Commands.Current->Draw->SetGraphicsRoot32BitConstants(1,
		sizeof(PresentPushConstants) / sizeof(uint32_t), &PushConstants, 0);
	Commands.Current->Draw->DrawInstanced(6, 1, 0, 0);

	OpenXRSubmitLayer = 1;
	for (const OpenXRViewSwapchain& EyeSwapchain : OpenXRSwapchains)
		OpenXRSubmitLayer = OpenXRSubmitLayer && EyeSwapchain.ImageReady;
	return 1;
}

UBOOL UD3D12RenderDevice::PresentOpenXRUI(uint32_t ViewIndex)
{
	if (!OpenXRFrameBegun || !OpenXRViewsValid || !VRUISeparatedThisFrame ||
		OpenXRUISwapchain.Handle == XR_NULL_HANDLE || !OpenXRUIPresentPipeline || ViewIndex >= 2)
		return 0;

	if (!OpenXRUISwapchain.ImageReady)
	{
		XrSwapchainImageAcquireInfo AcquireInfo = { XR_TYPE_SWAPCHAIN_IMAGE_ACQUIRE_INFO };
		XrResult Result = OpenXRFunctions.AcquireSwapchainImage(OpenXRUISwapchain.Handle, &AcquireInfo,
			&OpenXRUISwapchain.AcquiredImage);
		if (XR_FAILED(Result) || OpenXRUISwapchain.AcquiredImage >= OpenXRUISwapchain.Images.size())
			return 0;
		XrSwapchainImageWaitInfo WaitInfo = { XR_TYPE_SWAPCHAIN_IMAGE_WAIT_INFO };
		WaitInfo.timeout = XR_INFINITE_DURATION;
		Result = OpenXRFunctions.WaitSwapchainImage(OpenXRUISwapchain.Handle, &WaitInfo);
		if (XR_FAILED(Result))
			return 0;
		OpenXRUISwapchain.ImageReady = 1;
	}
	UpdateOpenXRUIAnchor();

	const D3D12_CPU_DESCRIPTOR_HANDLE RTV = OpenXRUISwapchain.RTVs.CPUHandle(
		static_cast<INT>(OpenXRUISwapchain.AcquiredImage * 2 + ViewIndex));
	const FLOAT Transparent[4] = { 0.0f, 0.0f, 0.0f, 0.0f };
	Commands.Current->Draw->ClearRenderTargetView(RTV, Transparent, 0, nullptr);
	Commands.Current->Draw->SetGraphicsRootSignature(PresentPass.RootSignature);
	Commands.Current->Draw->OMSetRenderTargets(1, &RTV, FALSE, nullptr);
	D3D12_VIEWPORT Viewport = {};
	Viewport.Width = static_cast<FLOAT>(OpenXRUISwapchain.Width);
	Viewport.Height = static_cast<FLOAT>(OpenXRUISwapchain.Height);
	Viewport.MaxDepth = 1.0f;
	Commands.Current->Draw->RSSetViewports(1, &Viewport);
	D3D12_RECT Scissor = { 0, 0, OpenXRUISwapchain.Width, OpenXRUISwapchain.Height };
	Commands.Current->Draw->RSSetScissorRects(1, &Scissor);
	Commands.Current->Draw->SetPipelineState(OpenXRUIPresentPipeline);
	Commands.Current->Draw->IASetPrimitiveTopology(D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
	Commands.Current->Draw->IASetVertexBuffers(0, 1, &PresentPass.PPStepVertexBufferView);
	Commands.Current->Draw->SetGraphicsRootDescriptorTable(0, SceneBuffers.OpenXRUISRVs.GPUHandle());
	PresentPushConstants PushConstants = GetPresentPushConstants();
	PushConstants.UseWorldPostProcess = 0.0f;
	PushConstants.UseVRUI = 0.0f;
	const XrView& Eye = OpenXRViews[ViewIndex];
	const XrQuaternionf EyeInverse = { -Eye.pose.orientation.x, -Eye.pose.orientation.y,
		-Eye.pose.orientation.z, Eye.pose.orientation.w };
	const FVector PanelOrigin = RotateOpenXRVector(EyeInverse,
		FVector(OpenXRUIAnchorPose.position.x - Eye.pose.position.x,
			OpenXRUIAnchorPose.position.y - Eye.pose.position.y,
			OpenXRUIAnchorPose.position.z - Eye.pose.position.z));
	const FLOAT PanelWidth = VRPanelGeometry::Width(Clamp(VRHUDScale, 0.5f, 2.0f));
	const FLOAT PanelHeight = VRPanelGeometry::Height(PanelWidth, CurrentSizeX, CurrentSizeY);
	const FVector PanelRight = RotateOpenXRVector(EyeInverse,
		RotateOpenXRVector(OpenXRUIAnchorPose.orientation, FVector(PanelWidth, 0.0f, 0.0f)));
	const FVector PanelUp = RotateOpenXRVector(EyeInverse,
		RotateOpenXRVector(OpenXRUIAnchorPose.orientation, FVector(0.0f, PanelHeight, 0.0f)));
	PushConstants.VRPanelOrigin = vec4(PanelOrigin.X, PanelOrigin.Y, PanelOrigin.Z,
		VRHeadCollisionFade > 0.0f ? 0.0f : 1.0f);
	PushConstants.VRPanelRight = vec4(PanelRight.X, PanelRight.Y, PanelRight.Z, 0.0f);
	PushConstants.VRPanelUp = vec4(PanelUp.X, PanelUp.Y, PanelUp.Z, 0.0f);
	PushConstants.VREyeTangents = vec4(appTan(Eye.fov.angleLeft), appTan(Eye.fov.angleRight),
		appTan(Eye.fov.angleDown), appTan(Eye.fov.angleUp));
	Commands.Current->Draw->SetGraphicsRoot32BitConstants(1,
		sizeof(PresentPushConstants) / sizeof(uint32_t), &PushConstants, 0);
	Commands.Current->Draw->DrawInstanced(6, 1, 0, 0);

	OpenXRUIEyeMask |= 1u << ViewIndex;
	OpenXRUILayerReady = OpenXRUIAnchorValid && OpenXRUIEyeMask == 3;
	return 1;
}

void UD3D12RenderDevice::UpdateOpenXRUIAnchor()
{
	if (!OpenXRUIAnchorValid && OpenXRViews.size() == 2)
	{
		// Start with an upright, eye-level anchor for HUD, menus and intro.
		// Explicit view recenter also stays upright; neither follows menus.
		const FVector Forward = RotateOpenXRVector(
			NormalizeOpenXRQuaternion(OpenXRViews[0].pose.orientation), FVector(0.0f, 0.0f, -1.0f));
		const auto& Previous = OpenXRUIAnchorPose.orientation;
		const auto Upright = VRPanelGeometry::Upright(Forward.X, Forward.Z,
			{ Previous.x, Previous.y, Previous.z, Previous.w });
		OpenXRUIAnchorPose.orientation = { Upright.x, Upright.y, Upright.z, Upright.w };
		OpenXRUIAnchorHeadPosition = {
			(OpenXRViews[0].pose.position.x + OpenXRViews[1].pose.position.x) * 0.5f,
			(OpenXRViews[0].pose.position.y + OpenXRViews[1].pose.position.y) * 0.5f,
			(OpenXRViews[0].pose.position.z + OpenXRViews[1].pose.position.z) * 0.5f
		};
		OpenXRUIAnchorValid = 1;
	}
	if (OpenXRUIAnchorValid)
	{
		const FLOAT UIDistance = Clamp(VRHUDDistance, 0.5f, 5.0f);
		const FVector Offset = RotateOpenXRVector(OpenXRUIAnchorPose.orientation,
			FVector(0.0f, 0.0f, -UIDistance));
		OpenXRUIAnchorPose.position = {
			OpenXRUIAnchorHeadPosition.x + Offset.X,
			OpenXRUIAnchorHeadPosition.y + Offset.Y,
			OpenXRUIAnchorHeadPosition.z + Offset.Z
		};
	}
}

void UD3D12RenderDevice::FinishOpenXRFrame()
{
	if (!OpenXRFrameBegun)
		return;

	std::vector<XrCompositionLayerProjectionView> LayerViews(OpenXRViews.size(),
		{ XR_TYPE_COMPOSITION_LAYER_PROJECTION_VIEW });
	UBOOL AllImagesReleased = OpenXRSubmitLayer;
	for (uint32_t ViewIndex = 0; ViewIndex < OpenXRSwapchains.size(); ViewIndex++)
	{
		OpenXRViewSwapchain& Swapchain = OpenXRSwapchains[ViewIndex];
		if (Swapchain.ImageReady)
		{
			XrSwapchainImageReleaseInfo ReleaseInfo = { XR_TYPE_SWAPCHAIN_IMAGE_RELEASE_INFO };
			const XrResult ReleaseResult = OpenXRFunctions.ReleaseSwapchainImage(Swapchain.Handle, &ReleaseInfo);
			if (XR_FAILED(ReleaseResult))
			{
				AllImagesReleased = 0;
				debugf(TEXT("Unreal Revived OpenXR: view %u image release failed (result %d)"), ViewIndex, ReleaseResult);
			}
			Swapchain.ImageReady = 0;
		}
		else
			AllImagesReleased = 0;

		LayerViews[ViewIndex].pose = OpenXRViews[ViewIndex].pose;
		LayerViews[ViewIndex].fov = OpenXRViews[ViewIndex].fov;
		LayerViews[ViewIndex].subImage.swapchain = Swapchain.Handle;
		LayerViews[ViewIndex].subImage.imageRect.offset = { 0, 0 };
		LayerViews[ViewIndex].subImage.imageRect.extent = { Swapchain.Width, Swapchain.Height };
	}

	XrCompositionLayerProjection Layer = { XR_TYPE_COMPOSITION_LAYER_PROJECTION };
	Layer.space = OpenXRLocalSpace;
	Layer.viewCount = AllImagesReleased ? static_cast<uint32_t>(LayerViews.size()) : 0;
	Layer.views = AllImagesReleased ? LayerViews.data() : nullptr;

	UBOOL UIReleased = OpenXRUILayerReady && OpenXRUISwapchain.ImageReady;
	if (OpenXRUISwapchain.ImageReady)
	{
		XrSwapchainImageReleaseInfo ReleaseInfo = { XR_TYPE_SWAPCHAIN_IMAGE_RELEASE_INFO };
		if (XR_FAILED(OpenXRFunctions.ReleaseSwapchainImage(OpenXRUISwapchain.Handle, &ReleaseInfo)))
			UIReleased = 0;
		OpenXRUISwapchain.ImageReady = 0;
	}
	XrCompositionLayerQuad UILayer = { XR_TYPE_COMPOSITION_LAYER_QUAD };
	UILayer.layerFlags = XR_COMPOSITION_LAYER_BLEND_TEXTURE_SOURCE_ALPHA_BIT;
	UILayer.space = OpenXRLocalSpace;
	UILayer.eyeVisibility = XR_EYE_VISIBILITY_LEFT;
	UILayer.subImage.swapchain = OpenXRUISwapchain.Handle;
	UILayer.subImage.imageRect.offset = { 0, 0 };
	UILayer.subImage.imageRect.extent = { OpenXRUISwapchain.Width, OpenXRUISwapchain.Height };
	UILayer.pose = OpenXRUIAnchorPose;
	const FLOAT UIScale = Clamp(VRHUDScale, 0.5f, 2.0f);
	// Preserve the accepted menu size at the default 1.75 m distance. Physical
	// size depends only on scale, so moving farther away visibly reduces size.
	const FLOAT UIWidth = VRPanelGeometry::Width(UIScale);
	const FLOAT UIHeight = VRPanelGeometry::Height(UIWidth, CurrentSizeX, CurrentSizeY);
	UILayer.size = { UIWidth, UIHeight };
	XrCompositionLayerQuad RightUILayer = UILayer;
	RightUILayer.eyeVisibility = XR_EYE_VISIBILITY_RIGHT;
	RightUILayer.subImage.imageArrayIndex = 1;
	const XrCompositionLayerBaseHeader* Layers[3] = {
		reinterpret_cast<const XrCompositionLayerBaseHeader*>(&Layer),
		reinterpret_cast<const XrCompositionLayerBaseHeader*>(&UILayer),
		reinterpret_cast<const XrCompositionLayerBaseHeader*>(&RightUILayer)
	};
	XrFrameEndInfo EndInfo = { XR_TYPE_FRAME_END_INFO };
	EndInfo.displayTime = OpenXRPredictedDisplayTime;
	EndInfo.environmentBlendMode = OpenXRBlendMode;
	EndInfo.layerCount = AllImagesReleased ? (UIReleased ? 3 : 1) : 0;
	EndInfo.layers = AllImagesReleased ? Layers : nullptr;
	const XrResult Result = OpenXRFunctions.EndFrame(OpenXRSession, &EndInfo);
	if (XR_SUCCEEDED(Result) && AllImagesReleased)
		VRStatistics.Submit(VRFrameStatistics::Now());
	if (XR_FAILED(Result))
		debugf(TEXT("Unreal Revived OpenXR: xrEndFrame failed (result %d)"), Result);
	else if (AllImagesReleased && !OpenXRFirstFrameLogged)
	{
		OpenXRFirstFrameLogged = 1;
		debugf(TEXT("Unreal Revived OpenXR: first independent stereo game frame submitted"));
	}
	OpenXRFrameBegun = 0;
	OpenXRSubmitLayer = 0;
	OpenXRUILayerReady = 0;
}

void UD3D12RenderDevice::ReleaseOpenXRFoundation()
{
	VRTurn.Reset();
	VRTurnPlayerIndex = -1;
	VRPitch = {};
	VRPresenceExtension = false;
	VRQualityPending = false;
	VRQualityChangeFailed = false;
	VRShouldRender = false;
	VRStatistics = {};
	LastVREyeBuffer = -1;
	ActiveVRRenderQuality = 0;
	for (auto& Buffers : VREyeBuffers)
		Buffers = {};
	MotionControllers.Release();
	MotionSampleTime = FTime();
	OpenXRSessionRunning = 0;
	OpenXRRenderingReady = 0;
	OpenXRViewRecenterRequested = 0;
	OpenXRHeadOrientation = { 0.0f, 0.0f, 0.0f, 1.0f };
	OpenXRBaseOrientation = { 0.0f, 0.0f, 0.0f, 1.0f };
	OpenXRBaseHeadPosition = { 0.0f, 0.0f, 0.0f };
	OpenXRRelativeHeadRotation = FRotator(0, 0, 0);
	OpenXRHeadPoseValid = 0;
	OpenXRBaseOrientationValid = 0;
	OpenXRViewsValid = 0;
	OpenXRStereoDrawEye = -1;
	OpenXRStereoRenderingLogged = 0;
	OpenXRFovLogged = 0;
	for (OpenXRViewSwapchain& Swapchain : OpenXRSwapchains)
	{
		if (Swapchain.ImageReady && Swapchain.Handle != XR_NULL_HANDLE && OpenXRFunctions.ReleaseSwapchainImage)
		{
			XrSwapchainImageReleaseInfo ReleaseInfo = { XR_TYPE_SWAPCHAIN_IMAGE_RELEASE_INFO };
			OpenXRFunctions.ReleaseSwapchainImage(Swapchain.Handle, &ReleaseInfo);
			Swapchain.ImageReady = 0;
		}
	}
	if (OpenXRUISwapchain.ImageReady && OpenXRUISwapchain.Handle != XR_NULL_HANDLE && OpenXRFunctions.ReleaseSwapchainImage)
	{
		XrSwapchainImageReleaseInfo ReleaseInfo = { XR_TYPE_SWAPCHAIN_IMAGE_RELEASE_INFO };
		OpenXRFunctions.ReleaseSwapchainImage(OpenXRUISwapchain.Handle, &ReleaseInfo);
		OpenXRUISwapchain.ImageReady = 0;
	}
	if (OpenXRFrameBegun && OpenXRFunctions.EndFrame)
	{
		XrFrameEndInfo EndInfo = { XR_TYPE_FRAME_END_INFO };
		EndInfo.displayTime = OpenXRPredictedDisplayTime;
		EndInfo.environmentBlendMode = OpenXRBlendMode;
		OpenXRFunctions.EndFrame(OpenXRSession, &EndInfo);
	}
	OpenXRFrameBegun = 0;
	OpenXRSubmitLayer = 0;
	OpenXRViewsValid = 0;
	for (OpenXRViewSwapchain& Swapchain : OpenXRSwapchains)
	{
		Swapchain.RTVs.reset();
		if (Swapchain.Handle != XR_NULL_HANDLE && OpenXRFunctions.DestroySwapchain)
			OpenXRFunctions.DestroySwapchain(Swapchain.Handle);
		Swapchain.Handle = XR_NULL_HANDLE;
		Swapchain.Images.clear();
	}
	OpenXRSwapchains.clear();
	OpenXRUISwapchain.RTVs.reset();
	if (OpenXRUISwapchain.Handle != XR_NULL_HANDLE && OpenXRFunctions.DestroySwapchain)
		OpenXRFunctions.DestroySwapchain(OpenXRUISwapchain.Handle);
	OpenXRUISwapchain = {};
	OpenXRUIPresentPipeline.reset();
	OpenXRUIAnchorValid = 0;
	OpenXRUILayerReady = 0;
	for (ComPtr<ID3D12PipelineState>& Pipeline : OpenXRPresentPipelines)
		Pipeline.reset();
	OpenXRViews.clear();
	OpenXRConfigurationViews.clear();
	if (OpenXRHeadSpace != XR_NULL_HANDLE && OpenXRFunctions.DestroySpace)
		OpenXRFunctions.DestroySpace(OpenXRHeadSpace);
	OpenXRHeadSpace = XR_NULL_HANDLE;
	if (OpenXRLocalSpace != XR_NULL_HANDLE && OpenXRFunctions.DestroySpace)
		OpenXRFunctions.DestroySpace(OpenXRLocalSpace);
	OpenXRLocalSpace = XR_NULL_HANDLE;
	if (OpenXRSession != XR_NULL_HANDLE && OpenXRInstance != XR_NULL_HANDLE && OpenXRGetInstanceProcAddr)
	{
		PFN_xrVoidFunction RawFunction = nullptr;
		const XrResult Result = OpenXRGetInstanceProcAddr(OpenXRInstance, "xrDestroySession", &RawFunction);
		if (XR_SUCCEEDED(Result) && RawFunction)
		{
			const XrResult DestroyResult = reinterpret_cast<PFN_xrDestroySession>(RawFunction)(OpenXRSession);
			if (XR_FAILED(DestroyResult))
				debugf(TEXT("Unreal Revived OpenXR: session destruction failed (result %d)"), DestroyResult);
		}
		else
			debugf(TEXT("Unreal Revived OpenXR: xrDestroySession unavailable during shutdown (result %d)"), Result);
		OpenXRSession = XR_NULL_HANDLE;
	}
	OpenXRSessionState = XR_SESSION_STATE_UNKNOWN;
	OpenXRSystemId = XR_NULL_SYSTEM_ID;
	OpenXRFunctions = {};
	if (OpenXRInstance != XR_NULL_HANDLE && OpenXRGetInstanceProcAddr)
	{
		PFN_xrVoidFunction RawFunction = nullptr;
		const XrResult Result = OpenXRGetInstanceProcAddr(OpenXRInstance, "xrDestroyInstance", &RawFunction);
		if (XR_SUCCEEDED(Result) && RawFunction)
		{
			const XrResult DestroyResult = reinterpret_cast<PFN_xrDestroyInstance>(RawFunction)(OpenXRInstance);
			if (XR_FAILED(DestroyResult))
				debugf(TEXT("Unreal Revived OpenXR: instance destruction failed (result %d)"), DestroyResult);
		}
		else
			debugf(TEXT("Unreal Revived OpenXR: xrDestroyInstance unavailable during shutdown (result %d)"), Result);
		OpenXRInstance = XR_NULL_HANDLE;
	}
	OpenXRGetInstanceProcAddr = nullptr;
	OpenXRFirstFrameLogged = 0;

	if (OpenXRLoader)
	{
		FreeLibrary(OpenXRLoader);
		OpenXRLoader = nullptr;
	}
}
#endif

void UD3D12RenderDevice::LogPerformanceSummary()
{
	std::vector<double> SortedFrameTimes = Performance.FrameTimesMs;
	std::sort(SortedFrameTimes.begin(), SortedFrameTimes.end());
	double TotalFrameTime = 0.0;
	for (double FrameTime : SortedFrameTimes)
		TotalFrameTime += FrameTime;
	auto Percentile = [&SortedFrameTimes](double Value)
	{
		size_t Index = (size_t)std::ceil(Value * SortedFrameTimes.size()) - 1;
		return SortedFrameTimes[Min(Index, SortedFrameTimes.size() - 1)];
	};
	double AverageFrameTime = TotalFrameTime / SortedFrameTimes.size();
	debugf(TEXT("D3D12Drv performance: samples=%u average_ms=%.3f median_ms=%.3f p95_ms=%.3f p99_ms=%.3f max_ms=%.3f average_fps=%.2f"),
		(unsigned int)SortedFrameTimes.size(), AverageFrameTime, Percentile(0.50), Percentile(0.95), Percentile(0.99), SortedFrameTimes.back(), 1000.0 / AverageFrameTime);
}

bool UD3D12RenderDevice::PrepareVRQualityBuffers()
{
	if (!ActiveVRRenderQuality || VRQualityBuffersFailed || OpenXRConfigurationViews.size() != 2 ||
		OpenXRSwapchains.size() != 2 || CurrentSizeX <= 0 || CurrentSizeY <= 0)
		return false;
	VRRenderSizing::Size Sizes[2];
	for (int Eye = 0; Eye < 2; ++Eye)
	{
		// Render directly at the accepted output size; do not discard the extra
		// scene detail in a fixed-size present texture before lens correction.
		Sizes[Eye] = { OpenXRSwapchains[Eye].Width, OpenXRSwapchains[Eye].Height };
	}
	// Sequential eye draws can reuse one set when their dimensions match.
	const int BufferCount = Sizes[0].Width == Sizes[1].Width && Sizes[0].Height == Sizes[1].Height ? 1 : 2;
	for (int Eye = 0; Eye < BufferCount; ++Eye)
	{
		std::swap(SceneBuffers, VREyeBuffers[Eye]);
		try
		{
			if (SceneBuffers.Width != Sizes[Eye].Width || SceneBuffers.Height != Sizes[Eye].Height)
				debugf(TEXT("Unreal Revived OpenXR: quality=%d buffer=%d scene=%dx%d runtime=%ux%u; profile/UI layout remains %dx%d"),
					ActiveVRRenderQuality, Eye, Sizes[Eye].Width, Sizes[Eye].Height,
					OpenXRConfigurationViews[Eye].recommendedImageRectWidth,
					OpenXRConfigurationViews[Eye].recommendedImageRectHeight, CurrentSizeX, CurrentSizeY);
			ResizeSceneBuffers(Sizes[Eye].Width, Sizes[Eye].Height, GetSettingsMultisample());
		}
		catch (const std::exception& Error)
		{
			std::swap(SceneBuffers, VREyeBuffers[Eye]);
			SubmitCommands(false);
			WaitDeviceIdle();
			for (auto& Buffers : VREyeBuffers)
				Buffers = {};
			VRQualityBuffersFailed = true;
			LastVREyeBuffer = -1;
			debugf(TEXT("Unreal Revived OpenXR: optional quality buffers failed; using current profile %dx%d for this session: %s"),
				CurrentSizeX, CurrentSizeY, to_utf16(Error.what()).c_str());
			return false;
		}
		std::swap(SceneBuffers, VREyeBuffers[Eye]);
	}
	return true;
}

void UD3D12RenderDevice::ResizeSceneBuffers(int width, int height, int multisample)
{
	multisample = std::max(multisample, 1);
	int requestedMultisample = multisample;
	if (SceneBuffers.Width == width && SceneBuffers.Height == height &&
		requestedMultisample == SceneBuffers.RequestedMultisample && AreSceneBuffersReady())
		return;

	multisample = GetSupportedMultisample(multisample);
	if (multisample != requestedMultisample)
		debugf(TEXT("D3D12Drv: requested MSAA %dx, using %dx because one or more scene formats do not support the requested sample count"), requestedMultisample, multisample);

	if (SceneBuffers.Width == width && SceneBuffers.Height == height &&
		multisample == SceneBuffers.Multisample && AreSceneBuffersReady())
	{
		SceneBuffers.RequestedMultisample = requestedMultisample;
		return;
	}

	debugf(TEXT("D3D12Drv: logical render size %dx%d, requested MSAA %dx, effective MSAA %dx"), width, height, requestedMultisample, multisample);

	SubmitCommands(false);
	WaitDeviceIdle();
	ReleaseSceneBuffers();

	SceneBuffers.Width = width;
	SceneBuffers.Height = height;
	SceneBuffers.RequestedMultisample = requestedMultisample;
	SceneBuffers.Multisample = multisample;

	D3D12_HEAP_PROPERTIES defaultHeapProps = {};
	defaultHeapProps.Type = D3D12_HEAP_TYPE_DEFAULT;

	D3D12_CLEAR_VALUE clearValue = {}, clearValueInt = {}, clearValueMask = {}, depthValue = {};
	clearValue.Format = DXGI_FORMAT_R16G16B16A16_FLOAT;
	clearValueInt.Format = DXGI_FORMAT_R32_UINT;
	clearValueMask.Format = DXGI_FORMAT_R8G8_UNORM;
	depthValue.Format = DXGI_FORMAT_D32_FLOAT;
	depthValue.DepthStencil.Depth = 1.0f;

	D3D12_RESOURCE_DESC texDesc = {};
	texDesc.Dimension = D3D12_RESOURCE_DIMENSION_TEXTURE2D;
	texDesc.Layout = D3D12_TEXTURE_LAYOUT_UNKNOWN;
	texDesc.Flags = D3D12_RESOURCE_FLAG_ALLOW_RENDER_TARGET;
	texDesc.Width = SceneBuffers.Width;
	texDesc.Height = SceneBuffers.Height;
	texDesc.DepthOrArraySize = 1;
	texDesc.MipLevels = 1;
	texDesc.SampleDesc.Count = SceneBuffers.Multisample;
	texDesc.SampleDesc.Quality = 0; // SceneBuffers.Multisample > 1 ? D3D12_STANDARD_MULTISAMPLE_PATTERN : 0;

	texDesc.Format = DXGI_FORMAT_R16G16B16A16_FLOAT;
	HRESULT result = Device->CreateCommittedResource(
		&defaultHeapProps,
		D3D12_HEAP_FLAG_NONE,
		&texDesc,
		D3D12_RESOURCE_STATE_RENDER_TARGET,
		&clearValue,
		SceneBuffers.ColorBuffer.GetIID(),
		SceneBuffers.ColorBuffer.InitPtr());
	ThrowIfFailed(result, "CreateCommittedResource(SceneBuffers.ColorBuffer) failed");
	SceneBuffers.ColorBuffer->SetName(TEXT("SceneBuffers.ColorBuffer"));

	texDesc.Format = DXGI_FORMAT_R32_UINT;
	result = Device->CreateCommittedResource(
		&defaultHeapProps,
		D3D12_HEAP_FLAG_NONE,
		&texDesc,
		D3D12_RESOURCE_STATE_RENDER_TARGET,
		&clearValueInt,
		SceneBuffers.HitBuffer.GetIID(),
		SceneBuffers.HitBuffer.InitPtr());
	ThrowIfFailed(result, "CreateCommittedResource(SceneBuffers.HitBuffer) failed");
	SceneBuffers.HitBuffer->SetName(TEXT("SceneBuffers.HitBuffer"));

	texDesc.Format = DXGI_FORMAT_R8G8_UNORM;
	result = Device->CreateCommittedResource(
		&defaultHeapProps,
		D3D12_HEAP_FLAG_NONE,
		&texDesc,
		D3D12_RESOURCE_STATE_RENDER_TARGET,
		&clearValueMask,
		SceneBuffers.UICompositionMaskBuffer.GetIID(),
		SceneBuffers.UICompositionMaskBuffer.InitPtr());
	ThrowIfFailed(result, "CreateCommittedResource(SceneBuffers.UICompositionMaskBuffer) failed");
	SceneBuffers.UICompositionMaskBuffer->SetName(TEXT("SceneBuffers.UICompositionMaskBuffer"));

	texDesc.Flags = D3D12_RESOURCE_FLAG_ALLOW_DEPTH_STENCIL;
	texDesc.Format = DXGI_FORMAT_D32_FLOAT;
	result = Device->CreateCommittedResource(
		&defaultHeapProps,
		D3D12_HEAP_FLAG_NONE,
		&texDesc,
		D3D12_RESOURCE_STATE_DEPTH_WRITE,
		&depthValue,
		SceneBuffers.DepthBuffer.GetIID(),
		SceneBuffers.DepthBuffer.InitPtr());
	ThrowIfFailed(result, "CreateCommittedResource(SceneBuffers.DepthBuffer) failed");
	SceneBuffers.DepthBuffer->SetName(TEXT("SceneBuffers.DepthBuffer"));

	texDesc.SampleDesc.Count = 1;
	texDesc.SampleDesc.Quality = 0;

	texDesc.Flags = D3D12_RESOURCE_FLAG_ALLOW_RENDER_TARGET;
	texDesc.Format = DXGI_FORMAT_R32_UINT;
	result = Device->CreateCommittedResource(
		&defaultHeapProps,
		D3D12_HEAP_FLAG_NONE,
		&texDesc,
		D3D12_RESOURCE_STATE_COPY_SOURCE,
		nullptr,
		SceneBuffers.PPHitBuffer.GetIID(),
		SceneBuffers.PPHitBuffer.InitPtr());
	ThrowIfFailed(result, "CreateCommittedResource(SceneBuffers.PPHitBuffer) failed");
	SceneBuffers.PPHitBuffer->SetName(TEXT("SceneBuffers.PPHitBuffer"));

	texDesc.Flags = D3D12_RESOURCE_FLAG_NONE;
	texDesc.Format = DXGI_FORMAT_R8G8_UNORM;
	result = Device->CreateCommittedResource(
		&defaultHeapProps,
		D3D12_HEAP_FLAG_NONE,
		&texDesc,
		D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE,
		nullptr,
		SceneBuffers.ResolvedUICompositionMask.GetIID(),
		SceneBuffers.ResolvedUICompositionMask.InitPtr());
	ThrowIfFailed(result, "CreateCommittedResource(SceneBuffers.ResolvedUICompositionMask) failed");
	SceneBuffers.ResolvedUICompositionMask->SetName(TEXT("SceneBuffers.ResolvedUICompositionMask"));

	texDesc.Flags = D3D12_RESOURCE_FLAG_ALLOW_RENDER_TARGET;
	texDesc.Format = DXGI_FORMAT_R16G16B16A16_FLOAT;
	const TCHAR* postProcessImageNames[PPI_Count] =
	{
		TEXT("SceneBuffers.FinalFrame"),
		TEXT("SceneBuffers.WorldScene"),
		TEXT("SceneBuffers.ScreenshotImage"),
		TEXT("SceneBuffers.VRUIBase"),
		TEXT("SceneBuffers.VRUI")
	};
	const int PostProcessImageCount = NeedsVRUIBuffers() ? PPI_Count : PPI_VRUIBase;
	debugf(TEXT("D3D12Drv: VR UI buffers %s at %dx%d"), NeedsVRUIBuffers() ? TEXT("enabled") : TEXT("disabled"), width, height);
	for (int i = 0; i < PostProcessImageCount; i++)
	{
		// Screenshots are returned to the engine at its logical viewport size.
		texDesc.Width = i == PPI_Screenshot ? CurrentSizeX : width;
		texDesc.Height = i == PPI_Screenshot ? CurrentSizeY : height;
		result = Device->CreateCommittedResource(
			&defaultHeapProps,
			D3D12_HEAP_FLAG_NONE,
			&texDesc,
			D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE,
			nullptr,
			SceneBuffers.PPImage[i].GetIID(),
			SceneBuffers.PPImage[i].InitPtr());
		ThrowIfFailed(result, "CreateCommittedResource(SceneBuffers.PPImage) failed");
		SceneBuffers.PPImage[i]->SetName(postProcessImageNames[i]);
	}

	SceneBuffers.SceneRTVs = Heaps.RTV->Alloc(3);
	Device->CreateRenderTargetView(SceneBuffers.ColorBuffer, nullptr, SceneBuffers.SceneRTVs.CPUHandle(0));
	Device->CreateRenderTargetView(SceneBuffers.HitBuffer, nullptr, SceneBuffers.SceneRTVs.CPUHandle(1));
	Device->CreateRenderTargetView(SceneBuffers.UICompositionMaskBuffer, nullptr, SceneBuffers.SceneRTVs.CPUHandle(2));

	SceneBuffers.SceneDSV = Heaps.DSV->Alloc(1);
	Device->CreateDepthStencilView(SceneBuffers.DepthBuffer, nullptr, SceneBuffers.SceneDSV.CPUHandle());

	SceneBuffers.HitBufferSRV = Heaps.Common->Alloc(1);
	Device->CreateShaderResourceView(SceneBuffers.HitBuffer, nullptr, SceneBuffers.HitBufferSRV.CPUHandle());

	SceneBuffers.PPHitBufferRTV = Heaps.RTV->Alloc(1);
	Device->CreateRenderTargetView(SceneBuffers.PPHitBuffer, nullptr, SceneBuffers.PPHitBufferRTV.CPUHandle());

	for (int i = 0; i < PostProcessImageCount; i++)
	{
		SceneBuffers.PPImageRTV[i] = Heaps.RTV->Alloc(1);
		SceneBuffers.PPImageSRV[i] = Heaps.Common->Alloc(1);
		Device->CreateRenderTargetView(SceneBuffers.PPImage[i], nullptr, SceneBuffers.PPImageRTV[i].CPUHandle());
		Device->CreateShaderResourceView(SceneBuffers.PPImage[i], nullptr, SceneBuffers.PPImageSRV[i].CPUHandle());
	}

	SceneBuffers.PresentSRVs = Heaps.Common->Alloc(5);
	Device->CreateShaderResourceView(SceneBuffers.PPImage[PPI_FinalFrame], nullptr, SceneBuffers.PresentSRVs.CPUHandle(0));
	Device->CreateShaderResourceView(PresentPass.DitherTexture, nullptr, SceneBuffers.PresentSRVs.CPUHandle(1));
	Device->CreateShaderResourceView(SceneBuffers.PPImage[PPI_WorldScene], nullptr, SceneBuffers.PresentSRVs.CPUHandle(2));
	Device->CreateShaderResourceView(SceneBuffers.ResolvedUICompositionMask, nullptr, SceneBuffers.PresentSRVs.CPUHandle(3));
	// Keep the root signature valid in desktop mode without allocating VR
	// textures. UseVRUI is zero there, so this fallback descriptor is not sampled.
	Device->CreateShaderResourceView(SceneBuffers.PPImage[NeedsVRUIBuffers() ? PPI_VRUI : PPI_FinalFrame], nullptr, SceneBuffers.PresentSRVs.CPUHandle(4));

	if (NeedsVRUIBuffers())
	{
		SceneBuffers.OpenXRUISRVs = Heaps.Common->Alloc(5);
		Device->CreateShaderResourceView(SceneBuffers.PPImage[PPI_VRUI], nullptr, SceneBuffers.OpenXRUISRVs.CPUHandle(0));
		Device->CreateShaderResourceView(PresentPass.DitherTexture, nullptr, SceneBuffers.OpenXRUISRVs.CPUHandle(1));
		Device->CreateShaderResourceView(SceneBuffers.PPImage[PPI_WorldScene], nullptr, SceneBuffers.OpenXRUISRVs.CPUHandle(2));
		Device->CreateShaderResourceView(SceneBuffers.ResolvedUICompositionMask, nullptr, SceneBuffers.OpenXRUISRVs.CPUHandle(3));
		Device->CreateShaderResourceView(SceneBuffers.PPImage[PPI_VRUI], nullptr, SceneBuffers.OpenXRUISRVs.CPUHandle(4));
	}

	int bloomWidth = width;
	int bloomHeight = height;
	for (PPBlurLevel& level : SceneBuffers.BlurLevels)
	{
		bloomWidth = (bloomWidth + 1) / 2;
		bloomHeight = (bloomHeight + 1) / 2;

		texDesc.Width = bloomWidth;
		texDesc.Height = bloomHeight;

		result = Device->CreateCommittedResource(
			&defaultHeapProps,
			D3D12_HEAP_FLAG_NONE,
			&texDesc,
			D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE,
			nullptr,
			level.VTexture.GetIID(),
			level.VTexture.InitPtr());
		ThrowIfFailed(result, "CreateCommittedResource(SceneBuffers.BlurLevels.VTexture) failed");
		level.VTexture->SetName(TEXT("SceneBuffers.BlurLevels.VTexture"));

		result = Device->CreateCommittedResource(
			&defaultHeapProps,
			D3D12_HEAP_FLAG_NONE,
			&texDesc,
			D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE,
			nullptr,
			level.HTexture.GetIID(),
			level.HTexture.InitPtr());
		ThrowIfFailed(result, "CreateCommittedResource(SceneBuffers.BlurLevels.HTexture) failed");
		level.HTexture->SetName(TEXT("SceneBuffers.BlurLevels.HTexture"));

		level.VTextureRTV = Heaps.RTV->Alloc(1);
		level.HTextureRTV = Heaps.RTV->Alloc(1);
		level.VTextureSRV = Heaps.Common->Alloc(1);
		level.HTextureSRV = Heaps.Common->Alloc(1);

		Device->CreateRenderTargetView(level.VTexture, nullptr, level.VTextureRTV.CPUHandle());
		Device->CreateRenderTargetView(level.HTexture, nullptr, level.HTextureRTV.CPUHandle());
		Device->CreateShaderResourceView(level.VTexture, nullptr, level.VTextureSRV.CPUHandle());
		Device->CreateShaderResourceView(level.HTexture, nullptr, level.HTextureSRV.CPUHandle());

		level.Width = bloomWidth;
		level.Height = bloomHeight;
	}

	D3D12_HEAP_PROPERTIES readbackHeapProps = {};
	readbackHeapProps.Type = D3D12_HEAP_TYPE_READBACK;

	D3D12_RESOURCE_DESC desc = SceneBuffers.PPHitBuffer->GetDesc();
	UINT64 totalSize = 0, rowSizeInBytes = 0;
	D3D12_PLACED_SUBRESOURCE_FOOTPRINT footprint = {};
	UINT numRows = 0;
	Device->GetCopyableFootprints(&desc, 0, 1, 0, &footprint, &numRows, &rowSizeInBytes, &totalSize);

	D3D12_RESOURCE_DESC bufDesc = {};
	bufDesc.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
	bufDesc.Width = totalSize;
	bufDesc.Height = 1;
	bufDesc.DepthOrArraySize = 1;
	bufDesc.MipLevels = 1;
	bufDesc.SampleDesc.Count = 1;
	bufDesc.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
	bufDesc.Flags = D3D12_RESOURCE_FLAG_NONE;
	result = Device->CreateCommittedResource(
		&readbackHeapProps,
		D3D12_HEAP_FLAG_NONE,
		&bufDesc,
		D3D12_RESOURCE_STATE_COPY_DEST,
		nullptr,
		SceneBuffers.StagingHitBuffer.GetIID(),
		SceneBuffers.StagingHitBuffer.InitPtr());
	ThrowIfFailed(result, "CreateCommittedResource(SceneBuffers.StagingHitBuffer) failed");
	SceneBuffers.StagingHitBuffer->SetName(TEXT("SceneBuffers.StagingHitBuffer"));
}

bool UD3D12RenderDevice::NeedsVRUIBuffers() const
{
#if defined(UNREAL_227)
	return OpenXRRenderingReady != 0;
#else
	return false;
#endif
}

bool UD3D12RenderDevice::AreSceneBuffersReady() const
{
	if (!SceneBuffers.ColorBuffer || !SceneBuffers.HitBuffer || !SceneBuffers.UICompositionMaskBuffer ||
		!SceneBuffers.DepthBuffer || !SceneBuffers.PPHitBuffer || !SceneBuffers.ResolvedUICompositionMask ||
		!SceneBuffers.StagingHitBuffer)
		return false;

	// Foundation setup follows initial SetRes. Rebuild once if VR becomes ready
	// afterwards (or is torn down), even when resolution/MSAA did not change.
	if (!!SceneBuffers.PPImage[PPI_VRUI] != NeedsVRUIBuffers())
		return false;
	const int PostProcessImageCount = NeedsVRUIBuffers() ? PPI_Count : PPI_VRUIBase;
	for (int i = 0; i < PostProcessImageCount; i++)
	{
		if (!SceneBuffers.PPImage[i])
			return false;
	}
	const auto Screenshot = SceneBuffers.PPImage[PPI_Screenshot]->GetDesc();
	if (Screenshot.Width != static_cast<UINT64>(CurrentSizeX) || Screenshot.Height != static_cast<UINT>(CurrentSizeY))
		return false;
	return true;
}

void UD3D12RenderDevice::CreateUploadBuffer()
{
	D3D12_HEAP_PROPERTIES uploadHeapProps = { D3D12_HEAP_TYPE_UPLOAD };

	D3D12_RESOURCE_DESC bufDesc = {};
	bufDesc.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
	bufDesc.Width = Upload.Size * 2;
	bufDesc.Height = 1;
	bufDesc.DepthOrArraySize = 1;
	bufDesc.MipLevels = 1;
	bufDesc.SampleDesc.Count = 1;
	bufDesc.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
	bufDesc.Flags = D3D12_RESOURCE_FLAG_NONE;

	HRESULT result = Device->CreateCommittedResource(
		&uploadHeapProps,
		D3D12_HEAP_FLAG_NONE,
		&bufDesc,
		D3D12_RESOURCE_STATE_GENERIC_READ,
		nullptr,
		Upload.Buffer.GetIID(),
		Upload.Buffer.InitPtr());
	ThrowIfFailed(result, "CreateCommittedResource(Upload.Buffer) failed");
	Upload.Buffer->SetName(TEXT("Upload.Buffer"));

	D3D12_RANGE readRange = {};
	result = Upload.Buffer->Map(0, &readRange, (void**)&Upload.Data);
	ThrowIfFailed(result, "Map(Upload.Buffer) failed");
}

void UD3D12RenderDevice::ReleaseUploadBuffer()
{
	if (Upload.Data)
	{
		Upload.Buffer->Unmap(0, nullptr);
		Upload.Data = nullptr;
	}

	Upload.Buffer.reset();
}

void UD3D12RenderDevice::CreateScenePass()
{
	std::vector<D3D12_INPUT_ELEMENT_DESC> elements =
	{
		{ "AttrFlags", 0, DXGI_FORMAT_R32_UINT, 0, offsetof(SceneVertex, Flags), D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA, 0 },
		{ "AttrPos", 0, DXGI_FORMAT_R32G32B32_FLOAT, 0, offsetof(SceneVertex, Position), D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA, 0 },
		{ "AttrTexCoordOne", 0, DXGI_FORMAT_R32G32_FLOAT, 0, offsetof(SceneVertex, TexCoord), D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA, 0 },
		{ "AttrTexCoordTwo", 0, DXGI_FORMAT_R32G32_FLOAT, 0, offsetof(SceneVertex, TexCoord2), D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA, 0 },
		{ "AttrTexCoordThree", 0, DXGI_FORMAT_R32G32_FLOAT, 0, offsetof(SceneVertex, TexCoord3), D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA, 0 },
		{ "AttrTexCoordFour", 0, DXGI_FORMAT_R32G32_FLOAT, 0, offsetof(SceneVertex, TexCoord4), D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA, 0 },
		{ "AttrColor", 0, DXGI_FORMAT_R32G32B32A32_FLOAT, 0, offsetof(SceneVertex, Color), D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA, 0 }
	};

	auto vertexShader = CompileHlsl("shaders/Scene.vert", "vs");
	auto pixelShader = CompileHlsl("shaders/Scene.frag", "ps");
	auto pixelShaderAlphaTest = CompileHlsl("shaders/Scene.frag", "ps", { "ALPHATEST" });

	CreateSceneSamplers();

	std::vector<std::vector<D3D12_DESCRIPTOR_RANGE>> descriptorTables(2);

	D3D12_DESCRIPTOR_RANGE texRange = {};
	texRange.RangeType = D3D12_DESCRIPTOR_RANGE_TYPE_SRV;
	texRange.BaseShaderRegister = 0;
	texRange.NumDescriptors = 4;
	descriptorTables[0].push_back(texRange);

	D3D12_DESCRIPTOR_RANGE samplerRange = {};
	samplerRange.RangeType = D3D12_DESCRIPTOR_RANGE_TYPE_SAMPLER;
	samplerRange.BaseShaderRegister = 0;
	samplerRange.NumDescriptors = 4;
	descriptorTables[1].push_back(samplerRange);

	D3D12_ROOT_CONSTANTS pushConstants = {};
	pushConstants.ShaderRegister = 0;
	pushConstants.Num32BitValues = sizeof(ScenePushConstants) / sizeof(int32_t);

	ScenePass.RootSignature = CreateRootSignature("ScenePass.RootSignature", descriptorTables, pushConstants);

	D3D12_RASTERIZER_DESC rasterizerState = {};
	rasterizerState.FillMode = D3D12_FILL_MODE_SOLID;
	rasterizerState.CullMode = D3D12_CULL_MODE_NONE;
	rasterizerState.FrontCounterClockwise = FALSE;
	rasterizerState.DepthClipEnable = FALSE; // Avoid clipping the weapon. The UE1 engine clips the geometry anyway.
	rasterizerState.MultisampleEnable = SceneBuffers.Multisample > 1 ? TRUE : FALSE;

	auto ConfigureSceneAttachments = [](D3D12_GRAPHICS_PIPELINE_STATE_DESC& psoDesc)
	{
		psoDesc.NumRenderTargets = 3;
		psoDesc.RTVFormats[0] = DXGI_FORMAT_R16G16B16A16_FLOAT;
		psoDesc.RTVFormats[1] = DXGI_FORMAT_R32_UINT;
		psoDesc.RTVFormats[2] = DXGI_FORMAT_R8G8_UNORM;
		psoDesc.BlendState.IndependentBlendEnable = TRUE;
		psoDesc.BlendState.RenderTarget[1].BlendEnable = FALSE;
		psoDesc.BlendState.RenderTarget[1].RenderTargetWriteMask = D3D12_COLOR_WRITE_ENABLE_ALL;
		psoDesc.BlendState.RenderTarget[2].BlendEnable = TRUE;
		psoDesc.BlendState.RenderTarget[2].SrcBlend = D3D12_BLEND_ONE;
		psoDesc.BlendState.RenderTarget[2].DestBlend = D3D12_BLEND_ONE;
		psoDesc.BlendState.RenderTarget[2].BlendOp = D3D12_BLEND_OP_MAX;
		psoDesc.BlendState.RenderTarget[2].SrcBlendAlpha = D3D12_BLEND_ONE;
		psoDesc.BlendState.RenderTarget[2].DestBlendAlpha = D3D12_BLEND_ONE;
		psoDesc.BlendState.RenderTarget[2].BlendOpAlpha = D3D12_BLEND_OP_MAX;
		psoDesc.BlendState.RenderTarget[2].RenderTargetWriteMask = D3D12_COLOR_WRITE_ENABLE_RED | D3D12_COLOR_WRITE_ENABLE_GREEN;
	};

	for (int i = 0; i < 64; i++)
	{
		D3D12_GRAPHICS_PIPELINE_STATE_DESC psoDesc = {};
		psoDesc.pRootSignature = ScenePass.RootSignature;
		psoDesc.InputLayout.NumElements = elements.size();
		psoDesc.InputLayout.pInputElementDescs = elements.data();
		psoDesc.VS.pShaderBytecode = vertexShader.data();
		psoDesc.VS.BytecodeLength = vertexShader.size();

		if (i & 32) // PF_Masked
		{
			psoDesc.PS.pShaderBytecode = pixelShaderAlphaTest.data();
			psoDesc.PS.BytecodeLength = pixelShaderAlphaTest.size();
		}
		else
		{
			psoDesc.PS.pShaderBytecode = pixelShader.data();
			psoDesc.PS.BytecodeLength = pixelShader.size();
		}

		psoDesc.PrimitiveTopologyType = D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE;
		psoDesc.RasterizerState = rasterizerState;
		psoDesc.SampleDesc.Count = SceneBuffers.Multisample;
		psoDesc.SampleMask = UINT_MAX;
		ConfigureSceneAttachments(psoDesc);
		psoDesc.DSVFormat = DXGI_FORMAT_D32_FLOAT;

		psoDesc.BlendState.RenderTarget[0].BlendEnable = TRUE;
		switch (i & 7)
		{
		case 0: // PF_Translucent
			psoDesc.BlendState.RenderTarget[0].BlendOp = D3D12_BLEND_OP_ADD;
			psoDesc.BlendState.RenderTarget[0].BlendOpAlpha = D3D12_BLEND_OP_ADD;
			psoDesc.BlendState.RenderTarget[0].SrcBlend = D3D12_BLEND_ONE;
			psoDesc.BlendState.RenderTarget[0].SrcBlendAlpha = D3D12_BLEND_ONE;
			psoDesc.BlendState.RenderTarget[0].DestBlend = D3D12_BLEND_INV_SRC_COLOR;
			psoDesc.BlendState.RenderTarget[0].DestBlendAlpha = D3D12_BLEND_INV_SRC_ALPHA;
			break;
		case 1: // PF_Modulated
			psoDesc.BlendState.RenderTarget[0].BlendOp = D3D12_BLEND_OP_ADD;
			psoDesc.BlendState.RenderTarget[0].BlendOpAlpha = D3D12_BLEND_OP_ADD;
			psoDesc.BlendState.RenderTarget[0].SrcBlend = D3D12_BLEND_DEST_COLOR;
			psoDesc.BlendState.RenderTarget[0].SrcBlendAlpha = D3D12_BLEND_DEST_ALPHA;
			psoDesc.BlendState.RenderTarget[0].DestBlend = D3D12_BLEND_SRC_COLOR;
			psoDesc.BlendState.RenderTarget[0].DestBlendAlpha = D3D12_BLEND_SRC_ALPHA;
			break;
		case 2: // PF_Highlighted
			psoDesc.BlendState.RenderTarget[0].BlendOp = D3D12_BLEND_OP_ADD;
			psoDesc.BlendState.RenderTarget[0].BlendOpAlpha = D3D12_BLEND_OP_ADD;
			psoDesc.BlendState.RenderTarget[0].SrcBlend = D3D12_BLEND_ONE;
			psoDesc.BlendState.RenderTarget[0].SrcBlendAlpha = D3D12_BLEND_ONE;
			psoDesc.BlendState.RenderTarget[0].DestBlend = D3D12_BLEND_INV_SRC_ALPHA;
			psoDesc.BlendState.RenderTarget[0].DestBlendAlpha = D3D12_BLEND_INV_SRC_ALPHA;
			break;
		case 4: // PF_AlphaBlend
			psoDesc.BlendState.RenderTarget[0].BlendOp = D3D12_BLEND_OP_ADD;
			psoDesc.BlendState.RenderTarget[0].BlendOpAlpha = D3D12_BLEND_OP_ADD;
			psoDesc.BlendState.RenderTarget[0].SrcBlend = D3D12_BLEND_SRC_ALPHA;
			psoDesc.BlendState.RenderTarget[0].SrcBlendAlpha = D3D12_BLEND_SRC_ALPHA;
			psoDesc.BlendState.RenderTarget[0].DestBlend = D3D12_BLEND_INV_SRC_ALPHA;
			psoDesc.BlendState.RenderTarget[0].DestBlendAlpha = D3D12_BLEND_INV_SRC_ALPHA;
			break;
		default: // Hmm, is it faster to keep the blend mode enabled or to toggle it?
			psoDesc.BlendState.RenderTarget[0].BlendOp = D3D12_BLEND_OP_ADD;
			psoDesc.BlendState.RenderTarget[0].BlendOpAlpha = D3D12_BLEND_OP_ADD;
			psoDesc.BlendState.RenderTarget[0].SrcBlend = D3D12_BLEND_ONE;
			psoDesc.BlendState.RenderTarget[0].SrcBlendAlpha = D3D12_BLEND_ONE;
			psoDesc.BlendState.RenderTarget[0].DestBlend = D3D12_BLEND_ZERO;
			psoDesc.BlendState.RenderTarget[0].DestBlendAlpha = D3D12_BLEND_ZERO;
			break;
		}
		if (i & 8) // PF_Invisible
			psoDesc.BlendState.RenderTarget[0].RenderTargetWriteMask = 0;
		else
			psoDesc.BlendState.RenderTarget[0].RenderTargetWriteMask = D3D12_COLOR_WRITE_ENABLE_ALL;
		psoDesc.DepthStencilState.DepthEnable = TRUE;
		psoDesc.DepthStencilState.DepthFunc = D3D12_COMPARISON_FUNC_LESS_EQUAL;
		if (i & 16) // PF_Occlude
			psoDesc.DepthStencilState.DepthWriteMask = D3D12_DEPTH_WRITE_MASK_ALL;
		else
			psoDesc.DepthStencilState.DepthWriteMask = D3D12_DEPTH_WRITE_MASK_ZERO;

		HRESULT result = Device->CreateGraphicsPipelineState(&psoDesc, ScenePass.Pipelines[i].Pipeline.GetIID(), ScenePass.Pipelines[i].Pipeline.InitPtr());
		ThrowIfFailed(result, "CreateGraphicsPipelineState failed");
	}

	// Line pipeline
	for (int i = 0; i < 2; i++)
	{
		D3D12_GRAPHICS_PIPELINE_STATE_DESC psoDesc = {};
		psoDesc.pRootSignature = ScenePass.RootSignature;
		psoDesc.InputLayout.NumElements = elements.size();
		psoDesc.InputLayout.pInputElementDescs = elements.data();
		psoDesc.VS.pShaderBytecode = vertexShader.data();
		psoDesc.VS.BytecodeLength = vertexShader.size();
		psoDesc.PS.pShaderBytecode = pixelShader.data();
		psoDesc.PS.BytecodeLength = pixelShader.size();
		psoDesc.PrimitiveTopologyType = D3D12_PRIMITIVE_TOPOLOGY_TYPE_LINE;
		psoDesc.RasterizerState = rasterizerState;
		psoDesc.SampleDesc.Count = SceneBuffers.Multisample;
		psoDesc.SampleMask = UINT_MAX;
		ConfigureSceneAttachments(psoDesc);
		psoDesc.DSVFormat = DXGI_FORMAT_D32_FLOAT;

		psoDesc.BlendState.RenderTarget[0].BlendEnable = TRUE;
		psoDesc.BlendState.RenderTarget[0].BlendOp = D3D12_BLEND_OP_ADD;
		psoDesc.BlendState.RenderTarget[0].BlendOpAlpha = D3D12_BLEND_OP_ADD;
		psoDesc.BlendState.RenderTarget[0].SrcBlend = D3D12_BLEND_ONE;
		psoDesc.BlendState.RenderTarget[0].SrcBlendAlpha = D3D12_BLEND_ONE;
		psoDesc.BlendState.RenderTarget[0].DestBlend = D3D12_BLEND_INV_SRC_ALPHA;
		psoDesc.BlendState.RenderTarget[0].DestBlendAlpha = D3D12_BLEND_INV_SRC_ALPHA;
		psoDesc.BlendState.RenderTarget[0].RenderTargetWriteMask = D3D12_COLOR_WRITE_ENABLE_ALL;
		psoDesc.DepthStencilState.DepthEnable = TRUE;
		psoDesc.DepthStencilState.DepthFunc = D3D12_COMPARISON_FUNC_LESS_EQUAL;
		psoDesc.DepthStencilState.DepthWriteMask = D3D12_DEPTH_WRITE_MASK_ALL;

		HRESULT result = Device->CreateGraphicsPipelineState(&psoDesc, ScenePass.LinePipeline[i].Pipeline.GetIID(), ScenePass.LinePipeline[i].Pipeline.InitPtr());
		ThrowIfFailed(result, "CreateGraphicsPipelineState failed");

		if (i == 0)
		{
			ScenePass.LinePipeline[i].MinDepth = 0.0f;
			ScenePass.LinePipeline[i].MaxDepth = 0.1f;
		}
	}

	// Point pipeline
	for (int i = 0; i < 2; i++)
	{
		D3D12_GRAPHICS_PIPELINE_STATE_DESC psoDesc = {};
		psoDesc.pRootSignature = ScenePass.RootSignature;
		psoDesc.InputLayout.NumElements = elements.size();
		psoDesc.InputLayout.pInputElementDescs = elements.data();
		psoDesc.VS.pShaderBytecode = vertexShader.data();
		psoDesc.VS.BytecodeLength = vertexShader.size();
		psoDesc.PS.pShaderBytecode = pixelShader.data();
		psoDesc.PS.BytecodeLength = pixelShader.size();
		psoDesc.PrimitiveTopologyType = D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE;
		psoDesc.RasterizerState = rasterizerState;
		psoDesc.SampleDesc.Count = SceneBuffers.Multisample;
		psoDesc.SampleMask = UINT_MAX;
		ConfigureSceneAttachments(psoDesc);
		psoDesc.DSVFormat = DXGI_FORMAT_D32_FLOAT;

		psoDesc.BlendState.RenderTarget[0].BlendEnable = TRUE;
		psoDesc.BlendState.RenderTarget[0].BlendOp = D3D12_BLEND_OP_ADD;
		psoDesc.BlendState.RenderTarget[0].BlendOpAlpha = D3D12_BLEND_OP_ADD;
		psoDesc.BlendState.RenderTarget[0].SrcBlend = D3D12_BLEND_ONE;
		psoDesc.BlendState.RenderTarget[0].SrcBlendAlpha = D3D12_BLEND_ONE;
		psoDesc.BlendState.RenderTarget[0].DestBlend = D3D12_BLEND_INV_SRC_ALPHA;
		psoDesc.BlendState.RenderTarget[0].DestBlendAlpha = D3D12_BLEND_INV_SRC_ALPHA;
		psoDesc.BlendState.RenderTarget[0].RenderTargetWriteMask = D3D12_COLOR_WRITE_ENABLE_ALL;
		psoDesc.DepthStencilState.DepthEnable = TRUE;
		psoDesc.DepthStencilState.DepthFunc = D3D12_COMPARISON_FUNC_LESS_EQUAL;
		psoDesc.DepthStencilState.DepthWriteMask = D3D12_DEPTH_WRITE_MASK_ALL;

		HRESULT result = Device->CreateGraphicsPipelineState(&psoDesc, ScenePass.PointPipeline[i].Pipeline.GetIID(), ScenePass.PointPipeline[i].Pipeline.InitPtr());
		ThrowIfFailed(result, "CreateGraphicsPipelineState failed");

		if (i == 0)
		{
			ScenePass.PointPipeline[i].MinDepth = 0.0f;
			ScenePass.PointPipeline[i].MaxDepth = 0.1f;
		}
	}

	D3D12_HEAP_PROPERTIES uploadHeapProps = { D3D12_HEAP_TYPE_UPLOAD };
	D3D12_HEAP_PROPERTIES defaultHeapProps = { D3D12_HEAP_TYPE_DEFAULT };

	D3D12_RESOURCE_DESC bufDesc = {};
	bufDesc.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
	bufDesc.Width = ScenePass.VertexBufferSize * 2 * sizeof(SceneVertex);
	bufDesc.Height = 1;
	bufDesc.DepthOrArraySize = 1;
	bufDesc.MipLevels = 1;
	bufDesc.SampleDesc.Count = 1;
	bufDesc.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
	bufDesc.Flags = D3D12_RESOURCE_FLAG_NONE;

	HRESULT result = Device->CreateCommittedResource(
		&uploadHeapProps,
		D3D12_HEAP_FLAG_NONE,
		&bufDesc,
		D3D12_RESOURCE_STATE_GENERIC_READ,
		nullptr,
		ScenePass.VertexBuffer.GetIID(),
		ScenePass.VertexBuffer.InitPtr());
	ThrowIfFailed(result, "CreateCommittedResource(ScenePass.VertexBuffer) failed");
	ScenePass.VertexBuffer->SetName(TEXT("ScenePass.VertexBuffer"));

	bufDesc.Width = ScenePass.IndexBufferSize * 2 * sizeof(uint32_t);
	result = Device->CreateCommittedResource(
		&uploadHeapProps,
		D3D12_HEAP_FLAG_NONE,
		&bufDesc,
		D3D12_RESOURCE_STATE_GENERIC_READ,
		nullptr,
		ScenePass.IndexBuffer.GetIID(),
		ScenePass.IndexBuffer.InitPtr());
	ThrowIfFailed(result, "CreateCommittedResource(ScenePass.IndexBuffer) failed");
	ScenePass.IndexBuffer->SetName(TEXT("ScenePass.IndexBuffer"));

	ScenePass.VertexBufferView.StrideInBytes = sizeof(SceneVertex);
	ScenePass.VertexBufferView.BufferLocation = ScenePass.VertexBuffer->GetGPUVirtualAddress();
	ScenePass.VertexBufferView.SizeInBytes = ScenePass.VertexBufferSize * 2 * sizeof(SceneVertex);

	ScenePass.IndexBufferView.Format = DXGI_FORMAT_R32_UINT;
	ScenePass.IndexBufferView.BufferLocation = ScenePass.IndexBuffer->GetGPUVirtualAddress();
	ScenePass.IndexBufferView.SizeInBytes = ScenePass.IndexBufferSize * 2 * sizeof(uint32_t);

	D3D12_RANGE readRange = {};
	result = ScenePass.VertexBuffer->Map(0, &readRange, (void**)&ScenePass.VertexData);
	ThrowIfFailed(result, "Map(ScenePass.VertexBuffer) failed");

	result = ScenePass.IndexBuffer->Map(0, &readRange, (void**)&ScenePass.IndexData);
	ThrowIfFailed(result, "Map(ScenePass.IndexBuffer) failed");

	ScenePass.Multisample = SceneBuffers.Multisample;
}

void UD3D12RenderDevice::CreateSceneSamplers()
{
	const INT activeMaxAnisotropy = Clamp<INT>(MaxAnisotropy, 0, 16);
	debugf(TEXT("D3D12Drv: requested anisotropy %d, effective anisotropy %d"), MaxAnisotropy, activeMaxAnisotropy);

	for (int i = 0; i < 16; i++)
	{
		int dummyMipmapCount = (i >> 2) & 3;
		D3D12_FILTER filter = (i & 1) ? D3D12_FILTER_MIN_MAG_MIP_POINT
			: (activeMaxAnisotropy > 1 ? D3D12_FILTER_ANISOTROPIC : D3D12_FILTER_MIN_MAG_MIP_LINEAR);
		D3D12_TEXTURE_ADDRESS_MODE addressmode = (i & 2) ? D3D12_TEXTURE_ADDRESS_MODE_MIRROR_ONCE : D3D12_TEXTURE_ADDRESS_MODE_WRAP;
		D3D12_SAMPLER_DESC samplerDesc = {};
		samplerDesc.MinLOD = dummyMipmapCount;
		samplerDesc.MaxLOD = D3D12_FLOAT32_MAX;
		samplerDesc.ComparisonFunc = D3D12_COMPARISON_FUNC_NEVER;
		samplerDesc.BorderColor[0] = 1.0f;
		samplerDesc.BorderColor[1] = 1.0f;
		samplerDesc.BorderColor[2] = 1.0f;
		samplerDesc.BorderColor[3] = 1.0f;
		samplerDesc.MaxAnisotropy = Max<INT>(activeMaxAnisotropy, 1);
		samplerDesc.MipLODBias = (float)dummyMipmapCount + LODBias;
		samplerDesc.Filter = filter;
		samplerDesc.AddressU = addressmode;
		samplerDesc.AddressV = addressmode;
		samplerDesc.AddressW = addressmode;
		ScenePass.Samplers[i] = samplerDesc;
	}

	ScenePass.LODBias = LODBias;
	ScenePass.MaxAnisotropy = activeMaxAnisotropy;
}

void UD3D12RenderDevice::ReleaseSceneSamplers()
{
	for (auto& it : Descriptors.Sampler)
		it.second.reset();
	Descriptors.Sampler.clear();
	ScenePass.LODBias = 0.0f;
}

void UD3D12RenderDevice::UpdateScenePass()
{
	if (!ScenePass.RootSignature || ScenePass.Multisample != SceneBuffers.Multisample)
	{
		ReleaseScenePass();
		CreateScenePass();
	}

	if (ScenePass.LODBias != LODBias || ScenePass.MaxAnisotropy != Clamp<INT>(MaxAnisotropy, 0, 16))
	{
		ReleaseSceneSamplers();
		CreateSceneSamplers();
	}
}

void UD3D12RenderDevice::ReleaseScenePass()
{
	if (ScenePass.VertexData)
	{
		ScenePass.VertexBuffer->Unmap(0, nullptr);
		ScenePass.VertexData = nullptr;
	}

	if (ScenePass.IndexData)
	{
		ScenePass.IndexBuffer->Unmap(0, nullptr);
		ScenePass.IndexData = nullptr;
	}

	ScenePass.VertexBuffer.reset();
	ScenePass.IndexBuffer.reset();
	ReleaseSceneSamplers();
	for (auto& pipeline : ScenePass.Pipelines)
	{
		pipeline.Pipeline.reset();
	}
	for (int i = 0; i < 2; i++)
	{
		ScenePass.LinePipeline[i].Pipeline.reset();
		ScenePass.PointPipeline[i].Pipeline.reset();
	}
	ScenePass.RootSignature.reset();
}

void UD3D12RenderDevice::ReleaseBloomPass()
{
	BloomPass.Extract.reset();
	BloomPass.Combine.reset();
	BloomPass.CombineAdditive.reset();
	BloomPass.BlurVertical.reset();
	BloomPass.BlurHorizontal.reset();
	BloomPass.RootSignature.reset();
}

void UD3D12RenderDevice::ReleasePresentPass()
{
	PresentPass.HitResolve.reset();
	for (auto& shader : PresentPass.Present) shader.reset();
	PresentPass.PPStepVertexBuffer.reset();
	PresentPass.DitherTexture.reset();
	PresentPass.RootSignature.reset();
}

void UD3D12RenderDevice::ReleaseSceneBuffers()
{
	SceneBuffers.PresentSRVs.reset();
	SceneBuffers.OpenXRUISRVs.reset();
	SceneBuffers.SceneRTVs.reset();
	SceneBuffers.SceneDSV.reset();
	SceneBuffers.PPHitBufferRTV.reset();
	SceneBuffers.HitBufferSRV.reset();
	for (int i = 0; i < PPI_Count; i++)
	{
		SceneBuffers.PPImageRTV[i].reset();
		SceneBuffers.PPImageSRV[i].reset();
		SceneBuffers.PPImage[i].reset();
	}
	SceneBuffers.ColorBuffer.reset();
	SceneBuffers.StagingHitBuffer.reset();
	SceneBuffers.PPHitBuffer.reset();
	SceneBuffers.ResolvedUICompositionMask.reset();
	SceneBuffers.HitBuffer.reset();
	SceneBuffers.UICompositionMaskBuffer.reset();
	SceneBuffers.DepthBuffer.reset();
	for (PPBlurLevel& level : SceneBuffers.BlurLevels)
	{
		level.VTextureRTV.reset();
		level.VTextureSRV.reset();
		level.VTexture.reset();
		level.HTextureRTV.reset();
		level.HTextureSRV.reset();
		level.HTexture.reset();
	}
}

UD3D12RenderDevice::ScenePipelineState* UD3D12RenderDevice::GetPipeline(DWORD PolyFlags)
{
	int index;
	if (PolyFlags & PF_Translucent)
	{
		index = 0;
	}
	else if (PolyFlags & PF_Modulated)
	{
		index = 1;
	}
	else if (PolyFlags & PF_AlphaBlend)
	{
		index = 4;
	}
	else if (PolyFlags & PF_Highlighted)
	{
		index = 2;
	}
	else
	{
		index = 3;
	}

	if (PolyFlags & PF_Invisible)
	{
		index |= 8;
	}
	if (PolyFlags & PF_Occlude)
	{
		index |= 16;
	}
	if (PolyFlags & PF_Masked)
	{
		index |= 32;
	}

	return &ScenePass.Pipelines[index];
}

void UD3D12RenderDevice::CopySceneToPostProcess(PostProcessImageIndex imageIndex)
{
	if (SceneBuffers.Multisample > 1)
	{
		TransitionResourceBarrier(
			Commands.Current->Draw,
			SceneBuffers.PPImage[imageIndex], D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE, D3D12_RESOURCE_STATE_RESOLVE_DEST,
			SceneBuffers.ColorBuffer, D3D12_RESOURCE_STATE_RENDER_TARGET, D3D12_RESOURCE_STATE_RESOLVE_SOURCE);

		Commands.Current->Draw->ResolveSubresource(SceneBuffers.PPImage[imageIndex], 0, SceneBuffers.ColorBuffer, 0, DXGI_FORMAT_R16G16B16A16_FLOAT);

		TransitionResourceBarrier(
			Commands.Current->Draw,
			SceneBuffers.PPImage[imageIndex], D3D12_RESOURCE_STATE_RESOLVE_DEST, D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE,
			SceneBuffers.ColorBuffer, D3D12_RESOURCE_STATE_RESOLVE_SOURCE, D3D12_RESOURCE_STATE_RENDER_TARGET);
	}
	else
	{
		TransitionResourceBarrier(
			Commands.Current->Draw,
			SceneBuffers.PPImage[imageIndex], D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE, D3D12_RESOURCE_STATE_COPY_DEST,
			SceneBuffers.ColorBuffer, D3D12_RESOURCE_STATE_RENDER_TARGET, D3D12_RESOURCE_STATE_COPY_SOURCE);

		Commands.Current->Draw->CopyResource(SceneBuffers.PPImage[imageIndex], SceneBuffers.ColorBuffer);

		TransitionResourceBarrier(
			Commands.Current->Draw,
			SceneBuffers.PPImage[imageIndex], D3D12_RESOURCE_STATE_COPY_DEST, D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE,
			SceneBuffers.ColorBuffer, D3D12_RESOURCE_STATE_COPY_SOURCE, D3D12_RESOURCE_STATE_RENDER_TARGET);
	}
}

bool UD3D12RenderDevice::IsWorldPostProcessEnabled() const
{
	return (Bloom && BloomAmount > 0) || ChromaticAberration > 0 ||
		VignetteIntensity > 0 || FilmGrainAmount > 0 || ScanlineStrength > 0;
}

void UD3D12RenderDevice::BeginUIPass()
{
	if (IsWorldPostProcessEnabled() && !WorldSceneCaptured)
	{
		DrawBatches();
		CopySceneToPostProcess(PPI_WorldScene);
		WorldSceneCaptured = true;
	}
	UIPassActive = true;
}

void UD3D12RenderDevice::CopyPostProcessImage(PostProcessImageIndex source, PostProcessImageIndex destination)
{
	TransitionResourceBarrier(Commands.Current->Draw,
		SceneBuffers.PPImage[source], D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE, D3D12_RESOURCE_STATE_COPY_SOURCE,
		SceneBuffers.PPImage[destination], D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE, D3D12_RESOURCE_STATE_COPY_DEST);
	Commands.Current->Draw->CopyResource(SceneBuffers.PPImage[destination], SceneBuffers.PPImage[source]);
	TransitionResourceBarrier(Commands.Current->Draw,
		SceneBuffers.PPImage[source], D3D12_RESOURCE_STATE_COPY_SOURCE, D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE,
		SceneBuffers.PPImage[destination], D3D12_RESOURCE_STATE_COPY_DEST, D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE);
}

void UD3D12RenderDevice::BeginVRUIPass()
{
	if (!IsLocked || OpenXRStereoDrawEye < 0)
		return;
	if (!VRUISeparatedThisFrame)
	{
		DrawBatches();
		CopySceneToPostProcess(PPI_VRUIBase);
		const FLOAT transparent[4] = { 0.0f, 0.0f, 0.0f, 0.0f };
		Commands.Current->Draw->ClearRenderTargetView(SceneBuffers.SceneRTVs.CPUHandle(0), transparent, 0, nullptr);
		VRUISeparatedThisFrame = true;
		UIPassActive = false;
	}
	if (!VRUIPassActive)
	{
		// Canvas vertices use the symmetric game projection. The compositor
		// projects the finished panel into each eye later; applying an eye
		// frustum here shifts/scales the UI inside its texture a second time.
		VRUIPassActive = true;
		if (CurrentFrame)
			SetSceneNode(CurrentFrame);
	}
}

uint32_t UD3D12RenderDevice::GetUICompositionFlags(DWORD polyFlags) const
{
	if (!UIPassActive && !VRWeaponPassActive)
		return 0;

	uint32_t flags = UIPassActive ? SVF_UIComposition : 0;
	if (VRWeaponPassActive && !(polyFlags & PF_Invisible))
	{
		flags |= SVF_VRWeapon;
		if (!(polyFlags & (PF_Translucent | PF_Modulated | PF_Highlighted | PF_AlphaBlend)))
			flags |= SVF_VRWeaponOpaque;
	}
	if (polyFlags & PF_Translucent)
		flags |= SVF_UICompositionTranslucent;
	else if (polyFlags & PF_Modulated)
		flags |= SVF_UICompositionModulated;
	return flags;
}

void UD3D12RenderDevice::ResolveUICompositionMask()
{
	if (SceneBuffers.Multisample > 1)
	{
		TransitionResourceBarrier(
			Commands.Current->Draw,
			SceneBuffers.UICompositionMaskBuffer, D3D12_RESOURCE_STATE_RENDER_TARGET, D3D12_RESOURCE_STATE_RESOLVE_SOURCE,
			SceneBuffers.ResolvedUICompositionMask, D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE, D3D12_RESOURCE_STATE_RESOLVE_DEST);
		Commands.Current->Draw->ResolveSubresource(
			SceneBuffers.ResolvedUICompositionMask, 0, SceneBuffers.UICompositionMaskBuffer, 0, DXGI_FORMAT_R8G8_UNORM);

		TransitionResourceBarrier(
			Commands.Current->Draw,
			SceneBuffers.UICompositionMaskBuffer, D3D12_RESOURCE_STATE_RESOLVE_SOURCE, D3D12_RESOURCE_STATE_RENDER_TARGET,
			SceneBuffers.ResolvedUICompositionMask, D3D12_RESOURCE_STATE_RESOLVE_DEST, D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE);
	}
	else
	{
		TransitionResourceBarrier(
			Commands.Current->Draw,
			SceneBuffers.UICompositionMaskBuffer, D3D12_RESOURCE_STATE_RENDER_TARGET, D3D12_RESOURCE_STATE_COPY_SOURCE,
			SceneBuffers.ResolvedUICompositionMask, D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE, D3D12_RESOURCE_STATE_COPY_DEST);
		Commands.Current->Draw->CopyResource(SceneBuffers.ResolvedUICompositionMask, SceneBuffers.UICompositionMaskBuffer);
		TransitionResourceBarrier(
			Commands.Current->Draw,
			SceneBuffers.UICompositionMaskBuffer, D3D12_RESOURCE_STATE_COPY_SOURCE, D3D12_RESOURCE_STATE_RENDER_TARGET,
			SceneBuffers.ResolvedUICompositionMask, D3D12_RESOURCE_STATE_COPY_DEST, D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE);
	}
}

void UD3D12RenderDevice::RunBloomPass(const DescriptorSet& source, PostProcessImageIndex targetImageIndex)
{
	// The preceding VR UI pass leaves a 1024x1024 scissor. Bloom owns its
	// raster bounds; every downsample level fits inside the full scene extent.
	const D3D12_RECT BloomScissor = { 0, 0, SceneBuffers.Width, SceneBuffers.Height };
	Commands.Current->Draw->RSSetScissorRects(1, &BloomScissor);
	float blurAmount = 0.6f + BloomAmount * (1.9f / 255.0f);
	float bloomLevel = BloomAmount / 255.0f;
	BloomPushConstants pushconstants;
	ComputeBlurSamples(7, blurAmount, pushconstants.SampleWeights);
	pushconstants.Intensity = 8.0f * bloomLevel * (1.0f + bloomLevel);
	pushconstants.Threshold = 1.0f - BloomAmount * (0.5f / 255.0f);

	Commands.Current->Draw->IASetPrimitiveTopology(D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
	Commands.Current->Draw->IASetVertexBuffers(0, 1, &PresentPass.PPStepVertexBufferView);
	Commands.Current->Draw->SetGraphicsRootSignature(BloomPass.RootSignature);
	Commands.Current->Draw->SetGraphicsRoot32BitConstants(1, sizeof(BloomPushConstants) / sizeof(uint32_t), &pushconstants, 0);

	D3D12_VIEWPORT viewport = {};
	viewport.MaxDepth = 1.0f;

	// Extract overbright pixels that we want to bloom:
	viewport.Width = SceneBuffers.BlurLevels[0].Width;
	viewport.Height = SceneBuffers.BlurLevels[0].Height;
	TransitionResourceBarrier(Commands.Current->Draw, SceneBuffers.BlurLevels[0].VTexture, D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE, D3D12_RESOURCE_STATE_RENDER_TARGET);
	D3D12_CPU_DESCRIPTOR_HANDLE rtv = SceneBuffers.BlurLevels[0].VTextureRTV.CPUHandle();
	Commands.Current->Draw->OMSetRenderTargets(1, &rtv, FALSE, nullptr);
	Commands.Current->Draw->RSSetViewports(1, &viewport);
	Commands.Current->Draw->SetPipelineState(BloomPass.Extract);
	Commands.Current->Draw->SetGraphicsRootDescriptorTable(0, source.GPUHandle());
	Commands.Current->Draw->DrawInstanced(6, 1, 0, 0);
	TransitionResourceBarrier(Commands.Current->Draw, SceneBuffers.BlurLevels[0].VTexture, D3D12_RESOURCE_STATE_RENDER_TARGET, D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE);

	// Blur and downscale:
	for (int i = 0; i < SceneBuffers.NumBloomLevels - 1; i++)
	{
		auto& blevel = SceneBuffers.BlurLevels[i];
		auto& next = SceneBuffers.BlurLevels[i + 1];

		viewport.Width = blevel.Width;
		viewport.Height = blevel.Height;
		Commands.Current->Draw->RSSetViewports(1, &viewport);
		BlurStep(blevel.VTextureSRV, blevel.HTextureRTV, blevel.HTexture, false);
		BlurStep(blevel.HTextureSRV, blevel.VTextureRTV, blevel.VTexture, true);

		// Linear downscale:
		TransitionResourceBarrier(Commands.Current->Draw, next.VTexture, D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE, D3D12_RESOURCE_STATE_RENDER_TARGET);
		viewport.Width = next.Width;
		viewport.Height = next.Height;
		rtv = next.VTextureRTV.CPUHandle();
		Commands.Current->Draw->OMSetRenderTargets(1, &rtv, FALSE, nullptr);
		Commands.Current->Draw->RSSetViewports(1, &viewport);
		Commands.Current->Draw->SetPipelineState(BloomPass.Combine);
		Commands.Current->Draw->SetGraphicsRootDescriptorTable(0, blevel.VTextureSRV.GPUHandle());
		Commands.Current->Draw->DrawInstanced(6, 1, 0, 0);
		TransitionResourceBarrier(Commands.Current->Draw, next.VTexture, D3D12_RESOURCE_STATE_RENDER_TARGET, D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE);
	}

	// Blur and upscale:
	for (int i = SceneBuffers.NumBloomLevels - 1; i > 0; i--)
	{
		auto& blevel = SceneBuffers.BlurLevels[i];
		auto& next = SceneBuffers.BlurLevels[i - 1];

		viewport.Width = blevel.Width;
		viewport.Height = blevel.Height;
		Commands.Current->Draw->RSSetViewports(1, &viewport);
		BlurStep(blevel.VTextureSRV, blevel.HTextureRTV, blevel.HTexture, false);
		BlurStep(blevel.HTextureSRV, blevel.VTextureRTV, blevel.VTexture, true);

		// Linear upscale:
		TransitionResourceBarrier(Commands.Current->Draw, next.VTexture, D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE, D3D12_RESOURCE_STATE_RENDER_TARGET);
		viewport.Width = next.Width;
		viewport.Height = next.Height;
		rtv = next.VTextureRTV.CPUHandle();
		Commands.Current->Draw->OMSetRenderTargets(1, &rtv, FALSE, nullptr);
		Commands.Current->Draw->RSSetViewports(1, &viewport);
		Commands.Current->Draw->SetPipelineState(BloomPass.Combine);
		Commands.Current->Draw->SetGraphicsRootDescriptorTable(0, blevel.VTextureSRV.GPUHandle());
		Commands.Current->Draw->DrawInstanced(6, 1, 0, 0);
		TransitionResourceBarrier(Commands.Current->Draw, next.VTexture, D3D12_RESOURCE_STATE_RENDER_TARGET, D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE);
	}

	viewport.Width = SceneBuffers.BlurLevels[0].Width;
	viewport.Height = SceneBuffers.BlurLevels[0].Height;
	Commands.Current->Draw->RSSetViewports(1, &viewport);
	BlurStep(SceneBuffers.BlurLevels[0].VTextureSRV, SceneBuffers.BlurLevels[0].HTextureRTV, SceneBuffers.BlurLevels[0].HTexture, false);
	BlurStep(SceneBuffers.BlurLevels[0].HTextureSRV, SceneBuffers.BlurLevels[0].VTextureRTV, SceneBuffers.BlurLevels[0].VTexture, true);

	// Add bloom back to scene post process texture:

	TransitionResourceBarrier(Commands.Current->Draw, SceneBuffers.PPImage[targetImageIndex], D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE, D3D12_RESOURCE_STATE_RENDER_TARGET);

	viewport.Width = SceneBuffers.Width;
	viewport.Height = SceneBuffers.Height;
	rtv = SceneBuffers.PPImageRTV[targetImageIndex].CPUHandle();
	Commands.Current->Draw->OMSetRenderTargets(1, &rtv, FALSE, nullptr);
	Commands.Current->Draw->RSSetViewports(1, &viewport);
	Commands.Current->Draw->SetPipelineState(BloomPass.CombineAdditive);
	Commands.Current->Draw->SetGraphicsRootDescriptorTable(0, SceneBuffers.BlurLevels[0].VTextureSRV.GPUHandle());
	Commands.Current->Draw->DrawInstanced(6, 1, 0, 0);

	TransitionResourceBarrier(Commands.Current->Draw, SceneBuffers.PPImage[targetImageIndex], D3D12_RESOURCE_STATE_RENDER_TARGET, D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE);
}

void UD3D12RenderDevice::BlurStep(const DescriptorSet& input, const DescriptorSet& output, ID3D12Resource* outputResource, bool vertical)
{
	TransitionResourceBarrier(Commands.Current->Draw, outputResource, D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE, D3D12_RESOURCE_STATE_RENDER_TARGET);

	D3D12_CPU_DESCRIPTOR_HANDLE rtv = output.CPUHandle();
	Commands.Current->Draw->OMSetRenderTargets(1, &rtv, FALSE, nullptr);
	Commands.Current->Draw->SetPipelineState(vertical ? BloomPass.BlurVertical : BloomPass.BlurHorizontal);
	Commands.Current->Draw->SetGraphicsRootDescriptorTable(0, input.GPUHandle());
	Commands.Current->Draw->DrawInstanced(6, 1, 0, 0);

	TransitionResourceBarrier(Commands.Current->Draw, outputResource, D3D12_RESOURCE_STATE_RENDER_TARGET, D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE);
}

float UD3D12RenderDevice::ComputeBlurGaussian(float n, float theta) // theta = Blur Amount
{
	return (float)((1.0f / std::sqrtf(2 * 3.14159265359f * theta)) * std::expf(-(n * n) / (2.0f * theta * theta)));
}

void UD3D12RenderDevice::ComputeBlurSamples(int sampleCount, float blurAmount, float* sampleWeights)
{
	sampleWeights[0] = ComputeBlurGaussian(0, blurAmount);

	float totalWeights = sampleWeights[0];

	for (int i = 0; i < sampleCount / 2; i++)
	{
		float weight = ComputeBlurGaussian(i + 1.0f, blurAmount);

		sampleWeights[i * 2 + 1] = weight;
		sampleWeights[i * 2 + 2] = weight;

		totalWeights += weight * 2;
	}

	for (int i = 0; i < sampleCount; i++)
	{
		sampleWeights[i] /= totalWeights;
	}
}

void UD3D12RenderDevice::CreateBloomPass()
{
	auto vertexShader = CompileHlsl("shaders/PPStep.vert", "vs");
	auto extractPixelShader = CompileHlsl("shaders/BloomExtract.frag", "ps");
	auto combinePixelShader = CompileHlsl("shaders/BloomCombine.frag", "ps");
	auto combineAdditivePixelShader = CompileHlsl("shaders/BloomCombine.frag", "ps", {"BLOOM_ADDITIVE"});
	auto blurVertPixelShader = CompileHlsl("shaders/Blur.frag", "ps", {"BLUR_VERTICAL"});
	auto blurHorizontalPixelShader = CompileHlsl("shaders/Blur.frag", "ps", {"BLUR_HORIZONTAL"});

	std::vector<D3D12_INPUT_ELEMENT_DESC> elements =
	{
		{ "AttrPos", 0, DXGI_FORMAT_R32G32_FLOAT, 0, 0, D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA, 0 }
	};

	std::vector<std::vector<D3D12_DESCRIPTOR_RANGE>> descriptorTables(1);

	D3D12_DESCRIPTOR_RANGE texRange = {};
	texRange.RangeType = D3D12_DESCRIPTOR_RANGE_TYPE_SRV;
	texRange.BaseShaderRegister = 0;
	texRange.NumDescriptors = 1;
	descriptorTables[0].push_back(texRange);

	D3D12_ROOT_CONSTANTS pushConstants = {};
	pushConstants.ShaderRegister = 0;
	pushConstants.Num32BitValues = sizeof(BloomPushConstants) / sizeof(int32_t);

	std::vector<D3D12_STATIC_SAMPLER_DESC> staticSamplers;
	D3D12_STATIC_SAMPLER_DESC staticSampler = {};
	staticSampler.ShaderRegister = 0;
	staticSampler.ShaderVisibility = D3D12_SHADER_VISIBILITY_ALL;
	staticSampler.MaxLOD = D3D12_FLOAT32_MAX;
	staticSampler.ComparisonFunc = D3D12_COMPARISON_FUNC_NEVER;
	staticSampler.Filter = D3D12_FILTER_MIN_MAG_MIP_LINEAR;
	staticSampler.AddressU = D3D12_TEXTURE_ADDRESS_MODE_CLAMP;
	staticSampler.AddressV = D3D12_TEXTURE_ADDRESS_MODE_CLAMP;
	staticSampler.AddressW = D3D12_TEXTURE_ADDRESS_MODE_CLAMP;
	staticSamplers.push_back(staticSampler);

	BloomPass.RootSignature = CreateRootSignature("BloomPass.RootSignature", descriptorTables, pushConstants, staticSamplers);

	D3D12_GRAPHICS_PIPELINE_STATE_DESC psoDesc = {};
	psoDesc.pRootSignature = BloomPass.RootSignature;
	psoDesc.InputLayout.NumElements = elements.size();
	psoDesc.InputLayout.pInputElementDescs = elements.data();
	psoDesc.VS.pShaderBytecode = vertexShader.data();
	psoDesc.VS.BytecodeLength = vertexShader.size();
	psoDesc.PrimitiveTopologyType = D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE;
	psoDesc.RasterizerState.FillMode = D3D12_FILL_MODE_SOLID;
	psoDesc.RasterizerState.CullMode = D3D12_CULL_MODE_NONE;
	psoDesc.DepthStencilState.DepthFunc = D3D12_COMPARISON_FUNC_ALWAYS;
	psoDesc.SampleDesc.Count = 1;
	psoDesc.SampleMask = UINT_MAX;
	psoDesc.NumRenderTargets = 1;
	psoDesc.RTVFormats[0] = DXGI_FORMAT_R16G16B16A16_FLOAT;
	psoDesc.BlendState.RenderTarget[0].BlendEnable = FALSE;
	psoDesc.BlendState.RenderTarget[0].RenderTargetWriteMask = D3D12_COLOR_WRITE_ENABLE_ALL;

	psoDesc.PS.pShaderBytecode = extractPixelShader.data();
	psoDesc.PS.BytecodeLength = extractPixelShader.size();
	HRESULT result = Device->CreateGraphicsPipelineState(&psoDesc, BloomPass.Extract.GetIID(), BloomPass.Extract.InitPtr());
	ThrowIfFailed(result, "CreateGraphicsPipelineState(BloomPass.Extract) failed");

	psoDesc.PS.pShaderBytecode = blurVertPixelShader.data();
	psoDesc.PS.BytecodeLength = blurVertPixelShader.size();
	result = Device->CreateGraphicsPipelineState(&psoDesc, BloomPass.BlurVertical.GetIID(), BloomPass.BlurVertical.InitPtr());
	ThrowIfFailed(result, "CreateGraphicsPipelineState(BloomPass.Extract) failed");

	psoDesc.PS.pShaderBytecode = blurHorizontalPixelShader.data();
	psoDesc.PS.BytecodeLength = blurHorizontalPixelShader.size();
	result = Device->CreateGraphicsPipelineState(&psoDesc, BloomPass.BlurHorizontal.GetIID(), BloomPass.BlurHorizontal.InitPtr());
	ThrowIfFailed(result, "CreateGraphicsPipelineState(BloomPass.BlurHorizontal) failed");

	psoDesc.PS.pShaderBytecode = combinePixelShader.data();
	psoDesc.PS.BytecodeLength = combinePixelShader.size();
	result = Device->CreateGraphicsPipelineState(&psoDesc, BloomPass.Combine.GetIID(), BloomPass.Combine.InitPtr());
	ThrowIfFailed(result, "CreateGraphicsPipelineState(BloomPass.Combine) failed");

	D3D12_BLEND_DESC blendDesc = {};
	blendDesc.RenderTarget[0].RenderTargetWriteMask = D3D12_COLOR_WRITE_ENABLE_ALL;
	blendDesc.RenderTarget[0].BlendEnable = TRUE;
	blendDesc.RenderTarget[0].BlendOp = D3D12_BLEND_OP_ADD;
	blendDesc.RenderTarget[0].BlendOpAlpha = D3D12_BLEND_OP_ADD;
	blendDesc.RenderTarget[0].SrcBlend = D3D12_BLEND_ONE;
	blendDesc.RenderTarget[0].SrcBlendAlpha = D3D12_BLEND_ONE;
	blendDesc.RenderTarget[0].DestBlend = D3D12_BLEND_ONE;
	blendDesc.RenderTarget[0].DestBlendAlpha = D3D12_BLEND_ONE;

	psoDesc.BlendState = blendDesc;
	psoDesc.PS.pShaderBytecode = combineAdditivePixelShader.data();
	psoDesc.PS.BytecodeLength = combineAdditivePixelShader.size();
	result = Device->CreateGraphicsPipelineState(&psoDesc, BloomPass.CombineAdditive.GetIID(), BloomPass.CombineAdditive.InitPtr());
	ThrowIfFailed(result, "CreateGraphicsPipelineState(BloomPass.Combine) failed");
}

void UD3D12RenderDevice::CreatePresentPass()
{
	std::vector<vec2> positions =
	{
		vec2(-1.0, -1.0),
		vec2( 1.0, -1.0),
		vec2(-1.0,  1.0),
		vec2(-1.0,  1.0),
		vec2( 1.0, -1.0),
		vec2( 1.0,  1.0)
	};

	D3D12_HEAP_PROPERTIES uploadHeapProps = { D3D12_HEAP_TYPE_UPLOAD };

	D3D12_RESOURCE_DESC bufDesc = {};
	bufDesc.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
	bufDesc.Width = positions.size() * sizeof(vec2);
	bufDesc.Height = 1;
	bufDesc.DepthOrArraySize = 1;
	bufDesc.MipLevels = 1;
	bufDesc.SampleDesc.Count = 1;
	bufDesc.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
	bufDesc.Flags = D3D12_RESOURCE_FLAG_NONE;

	HRESULT result = Device->CreateCommittedResource(
		&uploadHeapProps,
		D3D12_HEAP_FLAG_NONE,
		&bufDesc,
		D3D12_RESOURCE_STATE_GENERIC_READ,
		nullptr,
		PresentPass.PPStepVertexBuffer.GetIID(),
		PresentPass.PPStepVertexBuffer.InitPtr());
	ThrowIfFailed(result, "CreateCommittedResource(PresentPass.PPStepVertexBuffer) failed");
	PresentPass.PPStepVertexBuffer->SetName(TEXT("PresentPass.PPStepVertexBuffer"));

	D3D12_RANGE readRange = {};
	void* dest = nullptr;
	result = PresentPass.PPStepVertexBuffer->Map(0, &readRange, &dest);
	ThrowIfFailed(result, "Map(PresentPass.PPStepVertexBuffer) failed");
	memcpy(dest, positions.data(), positions.size() * sizeof(vec2));
	PresentPass.PPStepVertexBuffer->Unmap(0, nullptr);

	PresentPass.PPStepVertexBufferView.BufferLocation = PresentPass.PPStepVertexBuffer->GetGPUVirtualAddress();
	PresentPass.PPStepVertexBufferView.SizeInBytes = positions.size() * sizeof(vec2);
	PresentPass.PPStepVertexBufferView.StrideInBytes = sizeof(vec2);

	std::vector<D3D12_INPUT_ELEMENT_DESC> elements =
	{
		{ "AttrPos", 0, DXGI_FORMAT_R32G32_FLOAT, 0, 0, D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA, 0 }
	};

	std::vector<std::vector<D3D12_DESCRIPTOR_RANGE>> descriptorTables(1);

	D3D12_DESCRIPTOR_RANGE texRange = {};
	texRange.RangeType = D3D12_DESCRIPTOR_RANGE_TYPE_SRV;
	texRange.BaseShaderRegister = 0;
	texRange.NumDescriptors = 5;
	descriptorTables[0].push_back(texRange);

	D3D12_ROOT_CONSTANTS pushConstants = {};
	pushConstants.ShaderRegister = 0;
	pushConstants.Num32BitValues = sizeof(PresentPushConstants) / sizeof(int32_t);

	std::vector<D3D12_STATIC_SAMPLER_DESC> staticSamplers;
	D3D12_STATIC_SAMPLER_DESC staticSampler = {};
	staticSampler.ShaderRegister = 0;
	staticSampler.ShaderVisibility = D3D12_SHADER_VISIBILITY_ALL;
	staticSampler.MaxLOD = D3D12_FLOAT32_MAX;
	staticSampler.ComparisonFunc = D3D12_COMPARISON_FUNC_NEVER;
	staticSampler.Filter = D3D12_FILTER_MIN_MAG_MIP_LINEAR;
	staticSampler.AddressU = D3D12_TEXTURE_ADDRESS_MODE_CLAMP;
	staticSampler.AddressV = D3D12_TEXTURE_ADDRESS_MODE_CLAMP;
	staticSampler.AddressW = D3D12_TEXTURE_ADDRESS_MODE_CLAMP;
	staticSamplers.push_back(staticSampler);
	staticSampler.ShaderRegister = 1;
	staticSampler.ShaderVisibility = D3D12_SHADER_VISIBILITY_ALL;
	staticSampler.Filter = D3D12_FILTER_MIN_MAG_MIP_POINT;
	staticSampler.AddressU = D3D12_TEXTURE_ADDRESS_MODE_WRAP;
	staticSampler.AddressV = D3D12_TEXTURE_ADDRESS_MODE_WRAP;
	staticSampler.AddressW = D3D12_TEXTURE_ADDRESS_MODE_WRAP;
	staticSamplers.push_back(staticSampler);

	PresentPass.RootSignature = CreateRootSignature("PresentPass.RootSignature", descriptorTables, pushConstants, staticSamplers);

	auto vertexShader = CompileHlsl("shaders/PPStep.vert", "vs");

	static const char* transferFunctions[2] = { nullptr, "HDR_MODE" };
	static const char* gammaModes[2] = { "GAMMA_MODE_D3D9", "GAMMA_MODE_XOPENGL" };
	static const char* colorModes[4] = { nullptr, "COLOR_CORRECT_MODE0", "COLOR_CORRECT_MODE1", "COLOR_CORRECT_MODE2" };
	for (int i = 0; i < 32; i++)
	{
		std::vector<std::string> defines;
		if (transferFunctions[i & 1]) defines.push_back(transferFunctions[i & 1]);
		if (gammaModes[(i >> 1) & 1]) defines.push_back(gammaModes[(i >> 1) & 1]);
		if (colorModes[(i >> 2) & 3]) defines.push_back(colorModes[(i >> 2) & 3]);
		auto pixelShader = CompileHlsl("shaders/Present.frag", "ps", defines);

		D3D12_GRAPHICS_PIPELINE_STATE_DESC psoDesc = {};
		psoDesc.pRootSignature = PresentPass.RootSignature;
		psoDesc.InputLayout.NumElements = elements.size();
		psoDesc.InputLayout.pInputElementDescs = elements.data();
		psoDesc.VS.pShaderBytecode = vertexShader.data();
		psoDesc.VS.BytecodeLength = vertexShader.size();
		psoDesc.PS.pShaderBytecode = pixelShader.data();
		psoDesc.PS.BytecodeLength = pixelShader.size();
		psoDesc.PrimitiveTopologyType = D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE;
		psoDesc.RasterizerState.FillMode = D3D12_FILL_MODE_SOLID;
		psoDesc.RasterizerState.CullMode = D3D12_CULL_MODE_NONE;
		psoDesc.BlendState.RenderTarget[0].RenderTargetWriteMask = D3D12_COLOR_WRITE_ENABLE_ALL;
		psoDesc.DepthStencilState.DepthFunc = D3D12_COMPARISON_FUNC_ALWAYS;
		psoDesc.SampleDesc.Count = 1;
		psoDesc.SampleMask = UINT_MAX;
		psoDesc.NumRenderTargets = 1;
		psoDesc.RTVFormats[0] = (i & 16) ? DXGI_FORMAT_R16G16B16A16_FLOAT : DXGI_FORMAT_R8G8B8A8_UNORM;

		HRESULT result = Device->CreateGraphicsPipelineState(&psoDesc, PresentPass.Present[i].GetIID(), PresentPass.Present[i].InitPtr());
		ThrowIfFailed(result, "CreateGraphicsPipelineState(Present) failed");
	}

	auto pixelShader = CompileHlsl("shaders/HitResolve.frag", "ps");

	D3D12_GRAPHICS_PIPELINE_STATE_DESC psoDesc = {};
	psoDesc.pRootSignature = PresentPass.RootSignature;
	psoDesc.InputLayout.NumElements = elements.size();
	psoDesc.InputLayout.pInputElementDescs = elements.data();
	psoDesc.VS.pShaderBytecode = vertexShader.data();
	psoDesc.VS.BytecodeLength = vertexShader.size();
	psoDesc.PS.pShaderBytecode = pixelShader.data();
	psoDesc.PS.BytecodeLength = pixelShader.size();
	psoDesc.PrimitiveTopologyType = D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE;
	psoDesc.RasterizerState.FillMode = D3D12_FILL_MODE_SOLID;
	psoDesc.RasterizerState.CullMode = D3D12_CULL_MODE_NONE;
	psoDesc.BlendState.RenderTarget[0].RenderTargetWriteMask = D3D12_COLOR_WRITE_ENABLE_ALL;
	psoDesc.DepthStencilState.DepthFunc = D3D12_COMPARISON_FUNC_ALWAYS;
	psoDesc.SampleDesc.Count = 1;
	psoDesc.SampleMask = UINT_MAX;
	psoDesc.NumRenderTargets = 1;
	psoDesc.RTVFormats[0] = DXGI_FORMAT_R32_UINT;
	result = Device->CreateGraphicsPipelineState(&psoDesc, PresentPass.HitResolve.GetIID(), PresentPass.HitResolve.InitPtr());
	ThrowIfFailed(result, "CreateGraphicsPipelineState(HitResolve) failed");

	D3D12_HEAP_PROPERTIES defaultHeapProps = {};
	defaultHeapProps.Type = D3D12_HEAP_TYPE_DEFAULT;

	D3D12_RESOURCE_DESC texDesc = {};
	texDesc.Dimension = D3D12_RESOURCE_DIMENSION_TEXTURE2D;
	texDesc.Layout = D3D12_TEXTURE_LAYOUT_UNKNOWN;
	texDesc.Format = DXGI_FORMAT_R32_FLOAT;
	texDesc.Width = 8;
	texDesc.Height = 8;
	texDesc.DepthOrArraySize = 1;
	texDesc.MipLevels = 1;
	texDesc.SampleDesc.Count = 1;

	result = Device->CreateCommittedResource(
		&defaultHeapProps,
		D3D12_HEAP_FLAG_NONE,
		&texDesc,
		D3D12_RESOURCE_STATE_COPY_DEST,
		nullptr,
		PresentPass.DitherTexture.GetIID(),
		PresentPass.DitherTexture.InitPtr());
	ThrowIfFailed(result, "CreateCommittedResource(PresentPass.DitherTexture) failed");
	PresentPass.DitherTexture->SetName(TEXT("PresentPass.DitherTexture"));

	static const float ditherdata[64] =
	{
		.0078125, .2578125, .1328125, .3828125, .0234375, .2734375, .1484375, .3984375,
		.7578125, .5078125, .8828125, .6328125, .7734375, .5234375, .8984375, .6484375,
		.0703125, .3203125, .1953125, .4453125, .0859375, .3359375, .2109375, .4609375,
		.8203125, .5703125, .9453125, .6953125, .8359375, .5859375, .9609375, .7109375,
		.0390625, .2890625, .1640625, .4140625, .0546875, .3046875, .1796875, .4296875,
		.7890625, .5390625, .9140625, .6640625, .8046875, .5546875, .9296875, .6796875,
		.1015625, .3515625, .2265625, .4765625, .1171875, .3671875, .2421875, .4921875,
		.8515625, .6015625, .9765625, .7265625, .8671875, .6171875, .9921875, .7421875
	};

	auto onWriteSubresource = [](uint8_t* dest, int subresource, const D3D12_SUBRESOURCE_FOOTPRINT& footprint)
		{
			const float* src = ditherdata;
			for (int y = 0; y < 8; y++)
			{
				memcpy(dest, src, 8 * sizeof(float));
				src += 8;
				dest += footprint.RowPitch;
			}
		};

	UploadTexture(PresentPass.DitherTexture, D3D12_RESOURCE_STATE_COPY_DEST, D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE, 0, 0, 8, 8, 0, 1, onWriteSubresource);
}

void UD3D12RenderDevice::UploadTexture(ID3D12Resource* resource, D3D12_RESOURCE_STATES stateBefore, D3D12_RESOURCE_STATES stateAfter, int x, int y, int width, int height, int firstSubresource, int numSubresources, const std::function<void(uint8_t* dest, int subresource, const D3D12_SUBRESOURCE_FOOTPRINT& footprint)>& onWriteSubresource)
{
	if (stateBefore != D3D12_RESOURCE_STATE_COPY_DEST)
	{
		TransitionResourceBarrier(Commands.Current->Transfer, resource, stateBefore, D3D12_RESOURCE_STATE_COPY_DEST);
	}

	Upload.Transfer.Footprints.resize(numSubresources);
	Upload.Transfer.NumRows.resize(numSubresources);
	Upload.Transfer.RowSizeInBytes.resize(numSubresources);

	D3D12_RESOURCE_DESC desc = resource->GetDesc();
	desc.Width = width;
	desc.Height = height;

	// GetCopyableFootprints in Windows 10 needs the BaseOffset to be aligned already.
	Upload.Pos = (Upload.Base + Upload.Pos + (D3D12_TEXTURE_DATA_PLACEMENT_ALIGNMENT - 1)) / D3D12_TEXTURE_DATA_PLACEMENT_ALIGNMENT * D3D12_TEXTURE_DATA_PLACEMENT_ALIGNMENT - Upload.Base;

	UINT64 totalSize = 0;
	Device->GetCopyableFootprints(&desc, firstSubresource, numSubresources, Upload.Base + Upload.Pos, Upload.Transfer.Footprints.data(), Upload.Transfer.NumRows.data(), Upload.Transfer.RowSizeInBytes.data(), &totalSize);

	if (Upload.Pos + totalSize > Upload.Size)
	{
		SubmitCommands(false);
		Upload.Pos = (Upload.Base + Upload.Pos + (D3D12_TEXTURE_DATA_PLACEMENT_ALIGNMENT - 1)) / D3D12_TEXTURE_DATA_PLACEMENT_ALIGNMENT * D3D12_TEXTURE_DATA_PLACEMENT_ALIGNMENT - Upload.Base;
		Device->GetCopyableFootprints(&desc, firstSubresource, numSubresources, Upload.Base + Upload.Pos, Upload.Transfer.Footprints.data(), Upload.Transfer.NumRows.data(), Upload.Transfer.RowSizeInBytes.data(), &totalSize);
		if (Upload.Pos + totalSize > Upload.Size)
		{
			debugf(TEXT("Could not upload texture. Total memory requirements are bigger than the entire upload buffer!"));
			if (stateAfter != D3D12_RESOURCE_STATE_COPY_DEST)
			{
				TransitionResourceBarrier(Commands.Current->Transfer, resource, D3D12_RESOURCE_STATE_COPY_DEST, stateAfter);
			}
			return;
		}
	}

	for (int i = 0; i < numSubresources; i++)
	{
		onWriteSubresource(Upload.Data + Upload.Transfer.Footprints[i].Offset, i, Upload.Transfer.Footprints[i].Footprint);

		D3D12_TEXTURE_COPY_LOCATION src = {};
		src.pResource = Upload.Buffer;
		src.Type = D3D12_TEXTURE_COPY_TYPE_PLACED_FOOTPRINT;
		src.PlacedFootprint = Upload.Transfer.Footprints[i];

		D3D12_TEXTURE_COPY_LOCATION dest = {};
		dest.pResource = resource;
		dest.Type = D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX;
		dest.SubresourceIndex = firstSubresource + i;

		D3D12_BOX srcBox = {};
		srcBox.right = Max(width >> i, 1);
		srcBox.bottom = Max(height >> i, 1);
		srcBox.back = 1;

		// Block compressed requires the box to be 4x4 aligned
		switch (desc.Format)
		{
		case DXGI_FORMAT_BC1_TYPELESS:
		case DXGI_FORMAT_BC1_UNORM:
		case DXGI_FORMAT_BC1_UNORM_SRGB:
		case DXGI_FORMAT_BC2_TYPELESS:
		case DXGI_FORMAT_BC2_UNORM:
		case DXGI_FORMAT_BC2_UNORM_SRGB:
		case DXGI_FORMAT_BC3_TYPELESS:
		case DXGI_FORMAT_BC3_UNORM:
		case DXGI_FORMAT_BC3_UNORM_SRGB:
		case DXGI_FORMAT_BC4_TYPELESS:
		case DXGI_FORMAT_BC4_UNORM:
		case DXGI_FORMAT_BC5_TYPELESS:
		case DXGI_FORMAT_BC5_UNORM:
			srcBox.right = (srcBox.right + 3) / 4 * 4;
			srcBox.bottom = (srcBox.bottom + 3) / 4 * 4;
			break;
		}

		Commands.Current->Transfer->CopyTextureRegion(&dest, x, y, 0, &src, &srcBox);
	}

	Upload.Pos += totalSize;

	if (stateAfter != D3D12_RESOURCE_STATE_COPY_DEST)
	{
		TransitionResourceBarrier(Commands.Current->Transfer, resource, D3D12_RESOURCE_STATE_COPY_DEST, stateAfter);
	}
}

#if defined(UNREALGOLD)

void UD3D12RenderDevice::Flush()
{
	guard(UD3D12RenderDevice::Flush);

	try
	{
		DrawBatches();
		ClearTextureCache();

		if (UsePrecache && !GIsEditor)
			PrecacheOnFlip = 1;
	}
	catch (const std::exception& e)
	{
		debugf(TEXT("Could not flush d3d12 renderer: %s"), to_utf16(e.what()).c_str());
		Exit();
	}

	unguard;
}

#else

void UD3D12RenderDevice::Flush(UBOOL AllowPrecache)
{
	guard(UD3D12RenderDevice::Flush);

	try
	{
		DrawBatches();
		ClearTextureCache();

		if (AllowPrecache && UsePrecache && !GIsEditor)
			PrecacheOnFlip = 1;
	}
	catch (const std::exception& e)
	{
		debugf(TEXT("Could not flush d3d12 renderer: %s"), to_utf16(e.what()).c_str());
		Exit();
	}

	unguard;
}

#endif

UBOOL UD3D12RenderDevice::Exec(const TCHAR* Cmd, FOutputDevice& Ar)
{
	guard(UD3D12RenderDevice::Exec);

	if (ParseCommand(&Cmd, TEXT("D3D12")))
	{
		#if defined(UNREAL_227)
		if (ParseCommand(&Cmd, TEXT("BEGINVRWEAPONPASS")))
		{
			VRWeaponPassActive = IsLocked && OpenXRStereoDrawEye >= 0 && !VRUIPassActive;
			return 1;
		}
		if (ParseCommand(&Cmd, TEXT("ENDVRWEAPONPASS")))
		{
			VRWeaponPassActive = false;
			return 1;
		}
		if (ParseCommand(&Cmd, TEXT("RELOADVRWEAPONS")))
		{
			const TCHAR* Filename = TEXT("ModernVRWeapons.ini");
			FString Contents;
			UClass* TuningClass = FindObject<UClass>(NULL, TEXT("ModernMenu.ModernVRWeaponTuning"));
			if (GConfig && TuningClass && appLoadFileToString(Contents, Filename) &&
				Contents.Caps().InStr(TEXT("[MODERNMENU.MODERNVRWEAPONTUNING]")) >= 0)
			{
				// Discard only this cached file without writing stale values over
				// the user's edits. Script clears old profiles before loading.
				GConfig->UnloadFile(Filename);
				TuningClass->GetDefaultObject()->LoadConfig(0, TuningClass, Filename, 1);
				debugf(TEXT("VR weapon tuning reloaded from ModernVRWeapons.ini"));
				Ar.Logf(TEXT("1"));
			}
			else Ar.Logf(TEXT("0"));
			return 1;
		}
		if (ParseCommand(&Cmd, TEXT("VRWEAPONFUNCTION")) || ParseCommand(&Cmd, TEXT("VRSTATEFUNCTION")))
		{
			FString ClassName, StateName, FunctionName;
			if (ParseToken(Cmd, ClassName, 0) && ParseToken(Cmd, StateName, 0) && ParseToken(Cmd, FunctionName, 0))
			{
				UClass* WeaponClass = FindObject<UClass>(NULL, *ClassName);
				if (WeaponClass && (WeaponClass->IsChildOf(AWeapon::StaticClass()) || WeaponClass->IsChildOf(APlayerPawn::StaticClass())))
				{
					for (TFieldIterator<UState> State(WeaponClass); State; ++State)
					{
						if (State->GetFName() != FName(*StateName)) continue;
						for (TFieldIterator<UFunction> Function(*State); Function; ++Function)
						{
							if (Function->GetFName() != FName(*FunctionName)) continue;
							Ar.Logf(TEXT("%d"), Function->GetIndex());
							return 1;
						}
						break;
					}
				}
			}
			Ar.Logf(TEXT("-1"));
			return 1;
		}
		if (ParseCommand(&Cmd, TEXT("VRWEAPONFIRE")))
		{
			// ScriptHook re-entry must preserve Global.Fire/Global.AltFire. A
			// virtual script call would instead hit the current state's no-op.
			FString Alternate;
			if (Viewport && Viewport->Actor && Viewport->Actor->Weapon &&
				Viewport->Actor->Weapon->Owner == Viewport->Actor && ParseToken(Cmd, Alternate, 0))
			{
				AWeapon* Weapon = Viewport->Actor->Weapon;
				UFunction* Function = Weapon->FindFunction(Alternate == TEXT("1") ? FName(TEXT("AltFire")) : FName(TEXT("Fire")), 1);
				if (Function)
				{
					FLOAT Value = appAtof(Cmd);
					Weapon->ProcessEvent(Function, &Value);
					Ar.Logf(TEXT("1"));
					return 1;
				}
			}
			Ar.Logf(TEXT("0"));
			return 1;
		}
		if (ParseCommand(&Cmd, TEXT("VRAIMMODE")))
		{
			FString Value;
			if (ParseToken(Cmd, Value, 0))
			{
				VRAimMode = appAtoi(*Value) == 1 ? 1 : 0;
				MotionControllers.Clear();
				SaveConfig();
			}
			Ar.Logf(TEXT("%d"), VRAimMode == 1 ? 1 : 0);
			return 1;
		}
		if (ParseCommand(&Cmd, TEXT("OPENXRPROFILES")))
		{
			const auto LeftProfile = to_utf16(MotionControllers.ProfileName(0));
			const auto RightProfile = to_utf16(MotionControllers.ProfileName(1));
			Ar.Logf(TEXT("Left: %ls | Right: %ls"), LeftProfile.c_str(), RightProfile.c_str());
			return 1;
		}
		if (ParseCommand(&Cmd, TEXT("OPENXRMOTIONACTIVE")))
		{
			// Mode checks do not need quaternion conversion or pose formatting.
			Ar.Logf(TEXT("%d"), VRAimMode == 1 && OpenXRSessionRunning && OpenXRRenderingReady ? 1 : 0);
			return 1;
		}
		if (ParseCommand(&Cmd, TEXT("OPENXRCONTROLLER")))
		{
			if (VRAimMode != 1 || !OpenXRSessionRunning || !OpenXRRenderingReady)
				Ar.Logf(TEXT("0"));
			else
			{
				const int Hand = Viewport && Viewport->Actor && Viewport->Actor->Handedness == 1 ? 0 : 1;
				const auto& State = MotionControllers.Hands[Hand];
				if (!State.Valid || !OpenXRBaseOrientationValid || !OpenXRHeadPoseValid ||
					OpenXRSessionState != XR_SESSION_STATE_FOCUSED || appSeconds() - MotionSampleTime > 0.25)
					Ar.Logf(TEXT("1 0"));
				else
				{
					const FLOAT Units = 50.0f / Clamp(VRWorldScale, 0.4f, 2.5f);
					const XrQuaternionf Inverse = {-OpenXRBaseOrientation.x, -OpenXRBaseOrientation.y,
						-OpenXRBaseOrientation.z, OpenXRBaseOrientation.w};
					const auto& P = State.Grip.position;
					const FVector Offset = OpenXRVectorToUnreal(RotateOpenXRVector(Inverse,
						FVector(P.x - OpenXRBaseHeadPosition.x, P.y - OpenXRBaseHeadPosition.y,
							P.z - OpenXRBaseHeadPosition.z))) * Units;
					const FRotator Rotation = RelativeOpenXRRotation(OpenXRBaseOrientation, State.Aim.orientation);
					Ar.Logf(TEXT("1 1 %d %d %d %.6f %.6f %.6f %.6f %.6f "),
						Rotation.Pitch, Rotation.Yaw, Rotation.Roll, Offset.X, Offset.Y, Offset.Z,
						Clamp(VRPlayerHeightOffset, -0.75f, 1.5f) * Units, Units / 50.0f);
				}
			}
			return 1;
		}
		if (ParseCommand(&Cmd, TEXT("OPENXRINPUT")))
		{
			if (!OpenXRSessionRunning || !OpenXRRenderingReady)
				Ar.Logf(TEXT("0"));
			else
			{
				auto Left = MotionControllers.Hands[0];
				auto Right = MotionControllers.Hands[1];
				if (OpenXRSessionState != XR_SESSION_STATE_FOCUSED || appSeconds() - MotionSampleTime > 0.25)
					Left = Right = {};
				if (!Left.Connected && !Right.Connected)
				{
					Ar.Logf(TEXT("0"));
					return 1;
				}
				// Xbox-compatible buttons: ABXY, grips as shoulders, left menu as Start.
				const INT Buttons = (Right.Primary ? 0x1000 : 0) | (Right.Secondary ? 0x2000 : 0) |
					(Left.Primary ? 0x4000 : 0) | (Left.Secondary ? 0x8000 : 0) |
					(Left.Squeeze > 0.5f ? 0x100 : 0) | (Right.Squeeze > 0.5f ? 0x200 : 0) |
					(Left.Click ? 0x40 : 0) | (Right.Click ? 0x80 : 0) | ((Left.Menu || Right.Menu) ? 0x10 : 0) | ((Left.View || Right.View) ? 0x20 : 0);
				const bool CanAim = OpenXRHeadPoseValid && (VRAimMode != 1 ||
					(Viewport && Viewport->Actor && Viewport->Actor->Handedness == 1 ? Left.Valid : Right.Valid));
				Ar.Logf(TEXT("1 %d %d %d %d %d %d %d %d %d"), CanAim ? 1 : 0, Buttons,
					(INT)(Clamp(Left.Stick.x, -1.f, 1.f) * 32767), (INT)(Clamp(Left.Stick.y, -1.f, 1.f) * 32767),
					(INT)(Clamp(Right.Stick.x, -1.f, 1.f) * 32767), (INT)(Clamp(Right.Stick.y, -1.f, 1.f) * 32767),
					CanAim ? (INT)(Clamp(Left.Trigger, 0.f, 1.f) * 255) : 0,
					CanAim ? (INT)(Clamp(Right.Trigger, 0.f, 1.f) * 255) : 0, VRAimMode == 1 ? 1 : 0);
			}
			return 1;
		}
		if (ParseCommand(&Cmd, TEXT("OPENXRPOSE")))
		{
			const bool HeadCenterRotation = ParseCommand(&Cmd, TEXT("CENTER")) != 0;
			if (OpenXRSessionRunning && OpenXRHeadPoseValid && OpenXRBaseOrientationValid)
			{
				FRotator EyeRotation = OpenXRRelativeHeadRotation;
				FVector EyeOffset(0.0f, 0.0f, 0.0f);
				FVector HeadOffset(0.0f, 0.0f, 0.0f);
				// Larger perceived worlds require fewer game units per tracked meter.
				const FLOAT UnitsPerMeter = 50.0f / Clamp(VRWorldScale, 0.4f, 2.5f);
				if ((OpenXRStereoDrawEye >= 0 || HeadCenterRotation) && OpenXRViewsValid && OpenXRViews.size() == 2)
				{
					if (!HeadCenterRotation && OpenXRStereoDrawEye >= 0)
						EyeRotation = RelativeOpenXRRotation(OpenXRBaseOrientation,
							OpenXRViews[OpenXRStereoDrawEye].pose.orientation);
					const XrVector3f& Position = OpenXRViews[OpenXRStereoDrawEye >= 0 ? OpenXRStereoDrawEye : 0].pose.position;
					const XrQuaternionf BaseInverse = {
						-OpenXRBaseOrientation.x, -OpenXRBaseOrientation.y,
						-OpenXRBaseOrientation.z, OpenXRBaseOrientation.w
					};
					const FVector LocalDelta = RotateOpenXRVector(BaseInverse,
						FVector(Position.x - OpenXRBaseHeadPosition.x,
							Position.y - OpenXRBaseHeadPosition.y,
							Position.z - OpenXRBaseHeadPosition.z));
					EyeOffset = OpenXRVectorToUnreal(LocalDelta) * UnitsPerMeter;
					const FVector CurrentHeadPosition(
						(OpenXRViews[0].pose.position.x + OpenXRViews[1].pose.position.x) * 0.5f,
						(OpenXRViews[0].pose.position.y + OpenXRViews[1].pose.position.y) * 0.5f,
						(OpenXRViews[0].pose.position.z + OpenXRViews[1].pose.position.z) * 0.5f);
					const FVector LocalHeadDelta = RotateOpenXRVector(BaseInverse,
						CurrentHeadPosition - FVector(OpenXRBaseHeadPosition.x,
							OpenXRBaseHeadPosition.y, OpenXRBaseHeadPosition.z));
					HeadOffset = OpenXRVectorToUnreal(LocalHeadDelta) * UnitsPerMeter;
					if (OpenXRStereoDrawEye < 0)
						EyeOffset = HeadOffset;
				}
				Ar.Logf(TEXT("1 %d %d %d %.6f %.6f %.6f %.6f %.6f %.6f %.6f %.6f"), EyeRotation.Pitch,
					EyeRotation.Yaw, EyeRotation.Roll,
					EyeOffset.X, EyeOffset.Y, EyeOffset.Z,
					HeadOffset.X, HeadOffset.Y, HeadOffset.Z,
					Clamp(VRPlayerHeightOffset, -0.75f, 1.5f) * UnitsPerMeter,
					UnitsPerMeter / 50.0f);
			}
			else
				Ar.Logf(TEXT("0"));
			return 1;
		}
		else
		#endif
		if (ParseCommand(&Cmd, TEXT("BEGINUIPASS")))
		{
			BeginUIPass();
			return 1;
		}
		else if (ParseCommand(&Cmd, TEXT("BEGINVRUIPASS")))
		{
			// Existing HUD/MENU/INTRO suffixes remain accepted. All UI now
			// shares one panel pose and physical size.
			BeginVRUIPass();
			return 1;
		}
		else if (ParseCommand(&Cmd, TEXT("ENDVRUIPASS")))
		{
			if (VRUIPassActive)
			{
				// SetSceneNode flushes pending UI with its existing projection
				// before restoring the eye projection for subsequent draws.
				VRUIPassActive = false;
				if (CurrentFrame)
					SetSceneNode(CurrentFrame);
			}
			return 1;
		}
		else if (ParseCommand(&Cmd, TEXT("RESETVRUIANCHOR")))
		{
			OpenXRUIAnchorValid = 0;
			return 1;
		}
		else if (ParseCommand(&Cmd, TEXT("RECENTERVR")))
		{
			VRTurn.Reset();
			if (OpenXRSessionRunning)
				OpenXRViewRecenterRequested = 1;
			return 1;
		}
		else if (ParseCommand(&Cmd, TEXT("VRLAUNCHMODE")))
		{
			const bool Requested = !ParseParam(appCmdLine(), TEXT("novr")) &&
				(ParseParam(appCmdLine(), TEXT("vr")) || EnableVR);
			Ar.Log(Requested ? TEXT("-vr") : TEXT("-novr"));
			return 1;
		}
		else if (ParseCommand(&Cmd, TEXT("VRTURNMODE")))
		{
			VRTurnMode = VRTurning::Mode(appAtoi(Cmd));
			VRTurn.Reset();
			SaveConfig();
			Ar.Logf(TEXT("%d"), VRTurnMode);
			return 1;
		}
		else if (ParseCommand(&Cmd, TEXT("VRSNAPANGLE")))
		{
			VRSnapAngle = VRTurning::Angle(appAtoi(Cmd));
			VRTurn.Reset();
			SaveConfig();
			Ar.Logf(TEXT("%d"), VRSnapAngle);
			return 1;
		}
		else if (ParseCommand(&Cmd, TEXT("VRTURNINPUT")))
		{
			FLOAT Axis = 0, Seconds = 0;
			INT Enabled = 0, Reset = 0;
			Parse(Cmd, TEXT("AXIS="), Axis);
			Parse(Cmd, TEXT("DT="), Seconds);
			Parse(Cmd, TEXT("ENABLED="), Enabled);
			Parse(Cmd, TEXT("RESET="), Reset);
			APlayerPawn* Player = Viewport ? Viewport->Actor : nullptr;
			const INT PlayerIndex = Player ? Player->GetIndex() : -1;
			if (PlayerIndex != VRTurnPlayerIndex) VRTurn.Reset();
			VRTurnPlayerIndex = PlayerIndex;
			const bool Menu = Viewport && Viewport->Console &&
				(Viewport->Console->GetbTyping() || (Viewport->Console->GetStateFrame() &&
				Viewport->Console->GetStateFrame()->StateNode &&
				Viewport->Console->GetStateFrame()->StateNode->GetFName() == FName(TEXT("Menuing"))));
			const bool Active = Enabled && Player && Player->Health > 0 &&
				!Player->bBehindView && !Player->ViewTarget && !Player->bShowMenu && !Player->bFreeLook && !Menu &&
				Player->Level && Player->Level->Pauser.Len() == 0 &&
				OpenXRSessionRunning && OpenXRHeadPoseValid && VRShouldRender &&
				OpenXRSessionState == XR_SESSION_STATE_FOCUSED && !OpenXRViewRecenterRequested;
			const INT Delta = VRTurn.Step(Axis, Seconds, VRTurnMode, VRSnapAngle, Active && !Reset);
			if (Delta)
				Player->ViewRotation.Yaw = static_cast<INT>((static_cast<DWORD>(Player->ViewRotation.Yaw) + static_cast<DWORD>(Delta)) & 65535);
			Ar.Log(Active && VRTurning::Mode(VRTurnMode) != 0 ? TEXT("1") : TEXT("0"));
			return 1;
		}
		else if (ParseCommand(&Cmd, TEXT("VRHEADCOLLISION")))
		{
			VRHeadCollisionFade = Clamp(appAtof(Cmd), 0.0f, 1.0f);
			return 1;
		}
		else if (ParseCommand(&Cmd, TEXT("VRPLAYERHEIGHT")))
		{
			VRPlayerHeightOffset = Clamp(appAtof(Cmd), -0.75f, 1.5f);
			SaveConfig();
			Ar.Logf(TEXT("%.2f"), VRPlayerHeightOffset);
			return 1;
		}
		else if (ParseCommand(&Cmd, TEXT("VRWORLDSCALE")))
		{
			VRWorldScale = Clamp(appAtof(Cmd), 0.4f, 2.5f);
			SaveConfig();
			Ar.Logf(TEXT("%.2f"), VRWorldScale);
			return 1;
		}
		else if (ParseCommand(&Cmd, TEXT("VRHUDDISTANCE")))
		{
			VRHUDDistance = Clamp(appAtof(Cmd), 0.5f, 5.0f);
			SaveConfig();
			Ar.Logf(TEXT("%.2f"), VRHUDDistance);
			return 1;
		}
		else if (ParseCommand(&Cmd, TEXT("VRHUDSCALE")))
		{
			VRHUDScale = Clamp(appAtof(Cmd), 0.5f, 2.0f);
			SaveConfig();
			Ar.Logf(TEXT("%.2f"), VRHUDScale);
			return 1;
		}
		else if (ParseCommand(&Cmd, TEXT("VRRENDERQUALITY")))
		{
			VRRenderQuality = VRRenderSizing::NormalizeQuality(appAtoi(Cmd));
			VRQualityPending = true;
			VRQualityChangeFailed = false;
			SaveConfig();
			Ar.Logf(TEXT("%d"), VRRenderQuality);
			debugf(TEXT("Unreal Revived OpenXR: render quality %d queued for next frame"), VRRenderQuality);
			return 1;
		}
		else if (ParseCommand(&Cmd, TEXT("VRQUALITYSTATUS")))
		{
			if (VRQualityChangeFailed)
				Ar.Log(TEXT("failed"));
			else if (VRQualityBuffersFailed)
				Ar.Log(TEXT("fallback"));
			else if (OpenXRSession != XR_NULL_HANDLE && VRRenderSizing::NormalizeQuality(VRRenderQuality) != ActiveVRRenderQuality)
				Ar.Log(TEXT("pending"));
			else
				Ar.Log(TEXT("ready"));
			return 1;
		}
		else if (ParseCommand(&Cmd, TEXT("VRSTATSACTIVE")))
		{
			Ar.Log(OpenXRSessionRunning && VRShouldRender && OpenXRSessionState == XR_SESSION_STATE_FOCUSED
				? TEXT("1") : TEXT("0"));
			return 1;
		}
		else if (ParseCommand(&Cmd, TEXT("VRFPSRESET")))
		{
			VRStatistics = {};
			return 1;
		}
		else if (ParseCommand(&Cmd, TEXT("VRFPS")))
		{
			const INT Index = appAtoi(Cmd);
			const bool Active = OpenXRSessionRunning && VRShouldRender && OpenXRSessionState == XR_SESSION_STATE_FOCUSED;
			Ar.Logf(TEXT("%.1f"), Index == 0 && !Active ? 0.0 : VRStatistics.Value(Index, VRFrameStatistics::Now()));
			return 1;
		}
		else if (ParseCommand(&Cmd, TEXT("VRRENDERSIZE")))
		{
			const INT Eye = Clamp<INT>(appAtoi(Cmd), 0, 1);
			if (!OpenXRRenderingReady || OpenXRSwapchains.size() != 2)
				return 1;
			INT Width = CurrentSizeX, Height = CurrentSizeY;
			if (ActiveVRRenderQuality && !VRQualityBuffersFailed)
			{
				const INT Buffer = VREyeBuffers[1].Width > 0 ? Eye : 0;
				const auto& Buffers = ActiveVREyeBuffer == Buffer ? SceneBuffers : VREyeBuffers[Buffer];
				// Before the first render (headset unworn), buffers are lazy.
				// Their configured size is already fixed by the eye swapchain.
				Width = Buffers.Width > 0 ? Buffers.Width : OpenXRSwapchains[Eye].Width;
				Height = Buffers.Height > 0 ? Buffers.Height : OpenXRSwapchains[Eye].Height;
			}
			Ar.Logf(TEXT("%dx%d -> %dx%d"), Width, Height,
				OpenXRSwapchains[Eye].Width, OpenXRSwapchains[Eye].Height);
			return 1;
		}
		else if (ParseCommand(&Cmd, TEXT("BLOOM")))
		{
			BloomAmount = Clamp<INT>(appAtoi(Cmd), 0, 255);
			Bloom = BloomAmount > 0;
			debugf(TEXT("D3D12Drv: live bloom amount %d"), (INT)BloomAmount);
			Ar.Logf(TEXT("%d"), (INT)BloomAmount);
			return 1;
		}
		else if (ParseCommand(&Cmd, TEXT("CHROMATICABERRATION")))
		{
			ChromaticAberration = Clamp<INT>(appAtoi(Cmd), 0, 255);
			debugf(TEXT("D3D12Drv: live chromatic aberration amount %d"), (INT)ChromaticAberration);
			Ar.Logf(TEXT("%d"), (INT)ChromaticAberration);
			return 1;
		}
		else if (ParseCommand(&Cmd, TEXT("VIGNETTE")))
		{
			VignetteIntensity = Clamp<INT>(appAtoi(Cmd), 0, 255);
			debugf(TEXT("D3D12Drv: live vignette intensity %d"), (INT)VignetteIntensity);
			Ar.Logf(TEXT("%d"), (INT)VignetteIntensity);
			return 1;
		}
		else if (ParseCommand(&Cmd, TEXT("FILMGRAIN")))
		{
			FilmGrainAmount = Clamp<INT>(appAtoi(Cmd), 0, 255);
			debugf(TEXT("D3D12Drv: live film grain amount %d"), (INT)FilmGrainAmount);
			Ar.Logf(TEXT("%d"), (INT)FilmGrainAmount);
			return 1;
		}
		else if (ParseCommand(&Cmd, TEXT("SCANLINES")))
		{
			ScanlineStrength = Clamp<INT>(appAtoi(Cmd), 0, 255);
			debugf(TEXT("D3D12Drv: live scanline strength %d"), (INT)ScanlineStrength);
			Ar.Logf(TEXT("%d"), (INT)ScanlineStrength);
			return 1;
		}
		else if (ParseCommand(&Cmd, TEXT("CONTRAST")))
		{
			Contrast = Clamp<INT>(appAtoi(Cmd), 64, 170);
			debugf(TEXT("D3D12Drv: live contrast %d"), (INT)Contrast);
			Ar.Logf(TEXT("%d"), (INT)Contrast);
			return 1;
		}
		else if (ParseCommand(&Cmd, TEXT("SATURATION")))
		{
			Saturation = Clamp<INT>(appAtoi(Cmd), 128, 383);
			debugf(TEXT("D3D12Drv: live saturation %d"), (INT)Saturation);
			Ar.Logf(TEXT("%d"), (INT)Saturation);
			return 1;
		}
		return 0;
	}
	else if (ParseCommand(&Cmd, TEXT("DGL")))
	{
		if (ParseCommand(&Cmd, TEXT("BUFFERTRIS")))
		{
			return 1;
		}
		else if (ParseCommand(&Cmd, TEXT("BUILD")))
		{
			return 1;
		}
		else if (ParseCommand(&Cmd, TEXT("AA")))
		{
			return 1;
		}
		return 0;
	}
	else if (ParseCommand(&Cmd, TEXT("GetRes")))
	{
		if (!ParseParam(appCmdLine(), TEXT("novr")) &&
			(ParseParam(appCmdLine(), TEXT("vr")) || EnableVR))
		{
			Ar.Log(TEXT("1280x1024"));
			return 1;
		}
		struct Resolution
		{
			int X;
			int Y;

			// For sorting highest resolution first
			bool operator<(const Resolution& other) const { if (X != other.X) return X > other.X; else return Y > other.Y; }
		};

		std::set<Resolution> resolutions;

		// Always include what the monitor is currently using
		GetOutputRect();
		resolutions.insert({ DesktopResolution.Width, DesktopResolution.Height });
		// D3D12 fullscreen already letterboxes a logical render size into a
		// desktop-sized window; these do not need to be physical monitor modes.
		const Resolution Presets[] = { {1024,768}, {1280,720}, {1280,1024},
			{1600,900}, {1600,1200}, {1600,1280}, {1920,1080}, {1920,1536},
			{2560,1440}, {3840,2160} };
		resolutions.insert(std::begin(Presets), std::end(Presets));

		IDXGIOutput* output = nullptr;
		HRESULT result = SwapChain3->GetContainingOutput(&output);
		if (SUCCEEDED(result))
		{
			UINT numModes = 0;
			result = output->GetDisplayModeList(ActiveHdr ? DXGI_FORMAT_R16G16B16A16_FLOAT : DXGI_FORMAT_R8G8B8A8_UNORM, 0, &numModes, nullptr);
			if (SUCCEEDED(result))
			{
				std::vector<DXGI_MODE_DESC> descs(numModes);
				result = output->GetDisplayModeList(ActiveHdr ? DXGI_FORMAT_R16G16B16A16_FLOAT : DXGI_FORMAT_R8G8B8A8_UNORM, 0, &numModes, descs.data());
				if (SUCCEEDED(result))
				{
					for (const DXGI_MODE_DESC& desc : descs)
					{
						resolutions.insert({ (int)desc.Width, (int)desc.Height });
					}
				}
			}
			output->Release();
		}

		FString Str;
		for (const Resolution& resolution : resolutions)
		{
			Str += FString::Printf(TEXT("%ix%i "), (INT)resolution.X, (INT)resolution.Y);
		}
		Ar.Log(*Str.LeftChop(1));
		return 1;
	}
	else
	{
#if !defined(UNREALGOLD)
		return URenderDevice::Exec(Cmd, Ar);
#else
		return 0;
#endif
	}

	unguard;
}

void UD3D12RenderDevice::Lock(FPlane InFlashScale, FPlane InFlashFog, FPlane ScreenClear, DWORD RenderLockFlags, BYTE* InHitData, INT* InHitSize)
{
	guard(UD3D12RenderDevice::Lock);

	// This crashes currently for some reason
#if 0
	int wantedBufferCount = GetWantedSwapChainBufferCount();
	if (BufferCount != wantedBufferCount)
	{
		SubmitCommands(false);
		WaitDeviceIdle();
		ReleaseSwapChainResources();
		BufferCount = wantedBufferCount;
		UpdateSwapChain();
	}
#endif

	if (CurrentSizeX && CurrentSizeY && ActiveVREyeBuffer < 0)
	{
		try
		{
			ResizeSceneBuffers(CurrentSizeX, CurrentSizeY, GetSettingsMultisample());
		}
		catch (const std::exception& e)
		{
			debugf(TEXT("Could not resize scene buffers: %s"), to_utf16(e.what()).c_str());
			return;
		}
	}

	try
	{
		UpdateScenePass();

		HitData = InHitData;
		HitSize = InHitSize;
		WorldSceneCaptured = false;
		UIPassActive = false;
		VRUIPassActive = false;
		VRWeaponPassActive = false;
		VRUISeparatedThisFrame = false;

		FlashScale = InFlashScale;
		FlashFog = InFlashFog;

		Commands.PrimitiveTopology = D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST;

		FLOAT color[4] = { ScreenClear.X, ScreenClear.Y, ScreenClear.Z, ScreenClear.W };
		FLOAT zero[4] = { 0.0f, 0.0f, 0.0f, 0.0f };
		D3D12_CPU_DESCRIPTOR_HANDLE views[3] = { SceneBuffers.SceneRTVs.CPUHandle(0), SceneBuffers.SceneRTVs.CPUHandle(1), SceneBuffers.SceneRTVs.CPUHandle(2) };
		D3D12_CPU_DESCRIPTOR_HANDLE depthview = SceneBuffers.SceneDSV.CPUHandle();
		Commands.Current->Draw->ClearRenderTargetView(views[0], color, 0, nullptr);
		Commands.Current->Draw->ClearRenderTargetView(views[1], zero, 0, nullptr);
		Commands.Current->Draw->ClearRenderTargetView(views[2], zero, 0, nullptr);
		Commands.Current->Draw->ClearDepthStencilView(depthview, D3D12_CLEAR_FLAG_DEPTH, 1.0f, 0, 0, nullptr);

		D3D12_RECT box = {};
		box.right = SceneBuffers.Width;
		box.bottom = SceneBuffers.Height;
		Commands.Current->Draw->RSSetScissorRects(1, &box);

		SceneConstants.HitIndex = 0;
		ForceHitIndex = -1;

		IsLocked = true;
	}
	catch (const std::exception& e)
	{
		debugf(TEXT("Could not lock d3d12 renderer: %s"), to_utf16(e.what()).c_str());
		Exit();
	}

	unguard;
}

void UD3D12RenderDevice::DrawStats(FSceneNode* Frame)
{
	Super::DrawStats(Frame);

#if defined(OLDUNREAL469SDK)
	GRender->ShowStat(CurrentFrame, TEXT("D3D12: Draw calls: %d, Complex surfaces: %d, Gouraud polygons: %d, Tiles: %d; Uploads: %d, Rect Uploads: %d, Buffers Used: %d, Textures Cached: %d, Descriptors Used: %d\r\n"), Stats.DrawCalls, Stats.ComplexSurfaces, Stats.GouraudPolygons, Stats.Tiles, Stats.Uploads, Stats.RectUploads, Stats.BuffersUsed, Textures->GetTexturesInCache(), Heaps.Common->GetUsedCount());
#endif

	Stats.DrawCalls = 0;
	Stats.ComplexSurfaces = 0;
	Stats.GouraudPolygons = 0;
	Stats.Tiles = 0;
	Stats.Uploads = 0;
	Stats.RectUploads = 0;
	Stats.BuffersUsed = 1;
}

PresentPushConstants UD3D12RenderDevice::GetPresentPushConstants()
{
	PresentPushConstants pushconstants = {};
	pushconstants.HdrScale = 0.8f + HdrScale * (3.0f / 255.0f);
	pushconstants.ChromaticAberration = ChromaticAberration / 255.0f;
	pushconstants.VignetteIntensity = VignetteIntensity / 255.0f;
	pushconstants.FilmGrainAmount = FilmGrainAmount / 255.0f;
	pushconstants.ScanlineStrength = ScanlineStrength / 255.0f;
	LARGE_INTEGER grainTime;
	QueryPerformanceCounter(&grainTime);
	// Film grain is photographic motion, not a per-rendered-frame flicker. Keep
	// it at 24 updates per second so uncapped 1000+ FPS presentation cannot
	// perceptually average the particles into a flat tonal shift.
	pushconstants.FilmGrainSeed = (float)std::fmod(
		std::floor(grainTime.QuadPart * 24.0 / Performance.Frequency.QuadPart), 4096.0);
	pushconstants.UseWorldPostProcess =
		IsWorldPostProcessEnabled() && WorldSceneCaptured ? 1.0f : 0.0f;
	pushconstants.UseVRUI = 0.0f;
	// Only the headset world-eye pass fades; the recovery menu stays visible.
	pushconstants.VRHeadCollisionFade = 0.0f;
	if (Viewport->IsOrtho())
	{
		pushconstants.GammaCorrection = { 1.0f };
		pushconstants.Contrast = 1.0f;
		pushconstants.Saturation = 1.0f;
		pushconstants.Brightness = 0.0f;
	}
	else
	{
		float brightness = Clamp(Viewport->GetOuterUClient()->Brightness * 2.0, 0.05, 2.99);

		if (GammaMode == 0)
		{
			float invGammaRed = 1.0f / Max(brightness + GammaOffset + GammaOffsetRed, 0.001f);
			float invGammaGreen = 1.0f / Max(brightness + GammaOffset + GammaOffsetGreen, 0.001f);
			float invGammaBlue = 1.0f / Max(brightness + GammaOffset + GammaOffsetBlue, 0.001f);
			pushconstants.GammaCorrection = vec4(invGammaRed, invGammaGreen, invGammaBlue, 0.0f);
		}
		else
		{
			float invGammaRed = (GammaOffset + GammaOffsetRed + 2.0f) > 0.0f ? 1.0f / (GammaOffset + GammaOffsetRed + 1.0f) : 1.0f;
			float invGammaGreen = (GammaOffset + GammaOffsetGreen + 2.0f) > 0.0f ? 1.0f / (GammaOffset + GammaOffsetGreen + 1.0f) : 1.0f;
			float invGammaBlue = (GammaOffset + GammaOffsetBlue + 2.0f) > 0.0f ? 1.0f / (GammaOffset + GammaOffsetBlue + 1.0f) : 1.0f;
			pushconstants.GammaCorrection = vec4(invGammaRed, invGammaGreen, invGammaBlue, brightness);
		}

		// pushconstants.Contrast = clamp(Contrast, 0.1f, 3.f);
		const INT clampedContrast = Clamp<INT>(Contrast, 64, 170);
		if (clampedContrast >= 128)
		{
			pushconstants.Contrast = 1.0f + (clampedContrast - 128) / 127.0f * 3.0f;
		}
		else
		{
			pushconstants.Contrast = clampedContrast / 128.0f;
		}

		// pushconstants.Saturation = clamp(Saturation, -1.0f, 1.0f);
		pushconstants.Saturation = 1.0f - 2.0f * (255 - Clamp<INT>(Saturation, 128, 383)) / 255.0f;

		// pushconstants.Brightness = clamp(LinearBrightness, -1.8f, 1.8f);
		if (LinearBrightness >= 128)
		{
			pushconstants.Brightness = (LinearBrightness - 128) / 127.0f * 1.8f;
		}
		else
		{
			pushconstants.Brightness = (128 - LinearBrightness) / 128.0f * -1.8f;
		}
	}
	return pushconstants;
}

void UD3D12RenderDevice::Unlock(UBOOL Blit)
{
	guard(UD3D12RenderDevice::Unlock);

	if (!IsLocked) // Don't trust the engine.
		return;

	try
	{
		if (Blit || HitData)
			DrawBatches();

		if (Blit)
		{
			if ((VRUISeparatedThisFrame && OpenXRStereoDrawEye >= 0) ||
				(WorldSceneCaptured && IsWorldPostProcessEnabled()))
				ResolveUICompositionMask();
			if (VRUISeparatedThisFrame && OpenXRStereoDrawEye >= 0)
			{
				CopySceneToPostProcess(PPI_VRUI);
				PresentOpenXRUI(static_cast<uint32_t>(OpenXRStereoDrawEye));
				CopyPostProcessImage(PPI_VRUIBase, PPI_FinalFrame);
			}
			else
				CopySceneToPostProcess(PPI_FinalFrame);

			if (WorldSceneCaptured && Bloom && BloomAmount > 0)
			{
				RunBloomPass(SceneBuffers.PPImageSRV[PPI_WorldScene], PPI_WorldScene);
			}
			TransitionResourceBarrier(Commands.Current->Draw, FrameBuffers[BackBufferIndex], D3D12_RESOURCE_STATE_PRESENT, D3D12_RESOURCE_STATE_RENDER_TARGET);

			D3D12_CPU_DESCRIPTOR_HANDLE rtv = FrameBufferRTVs.CPUHandle(BackBufferIndex);
			Commands.Current->Draw->SetGraphicsRootSignature(PresentPass.RootSignature);
			Commands.Current->Draw->OMSetRenderTargets(1, &rtv, FALSE, nullptr);

			RECT box = {};
			GetClientRect((HWND)Viewport->GetWindow(), &box);
			int width = box.right;
			int height = box.bottom;
			float scale = std::min(width / (float)CurrentSizeX, height / (float)CurrentSizeY);
			int letterboxWidth = (int)std::round(CurrentSizeX * scale);
			int letterboxHeight = (int)std::round(CurrentSizeY * scale);
			int letterboxX = (width - letterboxWidth) / 2;
			int letterboxY = (height - letterboxHeight) / 2;

			D3D12_VIEWPORT viewport = {};
			viewport.TopLeftX = letterboxX;
			viewport.TopLeftY = letterboxY;
			viewport.Width = letterboxWidth;
			viewport.Height = letterboxHeight;
			viewport.MaxDepth = 1.0f;
			Commands.Current->Draw->RSSetViewports(1, &viewport);

			D3D12_RECT scissorbox = {};
			scissorbox.left = box.left;
			scissorbox.top = box.top;
			scissorbox.right = box.right;
			scissorbox.bottom = box.bottom;
			Commands.Current->Draw->RSSetScissorRects(1, &scissorbox);

			PresentPushConstants pushconstants = GetPresentPushConstants();
			pushconstants.UseVRUI = VRUISeparatedThisFrame ? 1.0f : 0.0f;

			// Select present shader based on what the user is actually using
			int presentShader = 0;
			if (ActiveHdr) presentShader |= (1 | 16); // 1 = HDR in shader, 16 = output is rgba16f
			if (GammaMode == 1) presentShader |= 2;
			if (pushconstants.Brightness != 0.0f || pushconstants.Contrast != 1.0f || pushconstants.Saturation != 1.0f) presentShader |= (Clamp(GrayFormula, 0, 2) + 1) << 2;

			Commands.Current->Draw->SetPipelineState(PresentPass.Present[presentShader]);
			Commands.Current->Draw->IASetPrimitiveTopology(D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
			Commands.Current->Draw->IASetVertexBuffers(0, 1, &PresentPass.PPStepVertexBufferView);
			Commands.Current->Draw->SetGraphicsRootDescriptorTable(0, SceneBuffers.PresentSRVs.GPUHandle());
			Commands.Current->Draw->SetGraphicsRoot32BitConstants(1, sizeof(PresentPushConstants) / sizeof(uint32_t), &pushconstants, 0);
			Commands.Current->Draw->DrawInstanced(6, 1, 0, 0);
			TransitionResourceBarrier(Commands.Current->Draw, FrameBuffers[BackBufferIndex], D3D12_RESOURCE_STATE_RENDER_TARGET, D3D12_RESOURCE_STATE_PRESENT);

			Batch.Pipeline = nullptr;
			Batch.PrimitiveTopology = D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST;
			Batch.Tex = nullptr;
			Batch.Lightmap = nullptr;
			Batch.Detailtex = nullptr;
			Batch.Macrotex = nullptr;
			Batch.SceneIndexStart = 0;

#if defined(UNREAL_227)
			if (OpenXRStereoDrawEye >= 0)
				PresentOpenXREye(static_cast<uint32_t>(OpenXRStereoDrawEye));
			SubmitCommands(OpenXRStereoDrawEye != 0);
#else
			SubmitCommands(true);
#endif

			if (Performance.Enabled
#if defined(UNREAL_227)
				&& OpenXRStereoDrawEye != 0
#endif
			)
			{
				LARGE_INTEGER PresentTime;
				QueryPerformanceCounter(&PresentTime);
				if (Performance.LastPresent.QuadPart != 0)
				{
					if (Performance.WarmupFrames > 0)
						Performance.WarmupFrames--;
					else
					{
						Performance.FrameTimesMs.push_back((PresentTime.QuadPart - Performance.LastPresent.QuadPart) * 1000.0 / Performance.Frequency.QuadPart);
						if (Performance.FrameTimesMs.size() == 1)
							debugf(TEXT("D3D12Drv performance sampling started"));
						if (Performance.FrameTimesMs.size() % 120 == 0)
							LogPerformanceSummary();
					}
				}
				Performance.LastPresent = PresentTime;
			}

			// Flush the descriptors if we are running out
			if (Heaps.Common->GetUsedCount() * 100 / Heaps.Common->GetHeapSize() > 75)
			{
				WaitDeviceIdle();
				for (auto& it : Descriptors.Tex)
					it.second.reset();
				Descriptors.Tex.clear();
			}
		}

		if (HitData)
		{
			D3D12_BOX box = {};
			box.left = Viewport->HitX;
			box.right = Viewport->HitX + Viewport->HitXL;
			box.top = SceneBuffers.Height - Viewport->HitY - Viewport->HitYL;
			box.bottom = SceneBuffers.Height - Viewport->HitY;
			box.front = 0;
			box.back = 1;

			// Resolve multisampling and place the result in PPHitBuffer
			if (SceneBuffers.Multisample > 1)
			{
				TransitionResourceBarrier(
					Commands.Current->Draw,
					SceneBuffers.HitBuffer, D3D12_RESOURCE_STATE_RENDER_TARGET, D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE,
					SceneBuffers.PPHitBuffer, D3D12_RESOURCE_STATE_COPY_SOURCE, D3D12_RESOURCE_STATE_RENDER_TARGET);

				D3D12_CPU_DESCRIPTOR_HANDLE rtv = SceneBuffers.PPHitBufferRTV.CPUHandle();
				Commands.Current->Draw->SetGraphicsRootSignature(PresentPass.RootSignature);
				Commands.Current->Draw->OMSetRenderTargets(1, &rtv, FALSE, nullptr);

				D3D12_VIEWPORT viewport = {};
				viewport.TopLeftX = box.left;
				viewport.TopLeftY = box.top;
				viewport.Width = box.right - box.left;
				viewport.Height = box.bottom - box.top;
				viewport.MaxDepth = 1.0f;
				Commands.Current->Draw->RSSetViewports(1, &viewport);

				D3D12_RECT scissorbox = {};
				scissorbox.left = box.left;
				scissorbox.top = box.top;
				scissorbox.right = box.right;
				scissorbox.bottom = box.bottom;
				Commands.Current->Draw->RSSetScissorRects(1, &scissorbox);

				Commands.Current->Draw->SetPipelineState(PresentPass.HitResolve);
				Commands.Current->Draw->IASetPrimitiveTopology(D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
				Commands.Current->Draw->IASetVertexBuffers(0, 1, &PresentPass.PPStepVertexBufferView);
				Commands.Current->Draw->SetGraphicsRootDescriptorTable(0, SceneBuffers.HitBufferSRV.GPUHandle());
				Commands.Current->Draw->DrawInstanced(6, 1, 0, 0);

				TransitionResourceBarrier(
					Commands.Current->Draw,
					SceneBuffers.HitBuffer, D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE, D3D12_RESOURCE_STATE_RENDER_TARGET,
					SceneBuffers.PPHitBuffer, D3D12_RESOURCE_STATE_RENDER_TARGET, D3D12_RESOURCE_STATE_COPY_SOURCE);
			}
			else
			{
				TransitionResourceBarrier(
					Commands.Current->Draw,
					SceneBuffers.HitBuffer, D3D12_RESOURCE_STATE_RENDER_TARGET, D3D12_RESOURCE_STATE_COPY_SOURCE,
					SceneBuffers.PPHitBuffer, D3D12_RESOURCE_STATE_COPY_SOURCE, D3D12_RESOURCE_STATE_COPY_DEST);

				D3D12_TEXTURE_COPY_LOCATION src = {}, dest = {};
				src.pResource = SceneBuffers.HitBuffer;
				src.Type = D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX;
				dest.pResource = SceneBuffers.PPHitBuffer;
				dest.Type = D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX;
				Commands.Current->Draw->CopyTextureRegion(&dest, box.left, box.top, 0, &src, &box);

				TransitionResourceBarrier(
					Commands.Current->Draw,
					SceneBuffers.HitBuffer, D3D12_RESOURCE_STATE_COPY_SOURCE, D3D12_RESOURCE_STATE_RENDER_TARGET,
					SceneBuffers.PPHitBuffer, D3D12_RESOURCE_STATE_COPY_DEST, D3D12_RESOURCE_STATE_COPY_SOURCE);
			}

			// Copy PPHitBuffer to StagingHitbuffer, but only the part we want to examine
			D3D12_RESOURCE_DESC desc = SceneBuffers.PPHitBuffer->GetDesc();
			desc.Width = box.right - box.left;
			desc.Height = box.bottom - box.top;
			UINT64 totalSize = 0, rowSizeInBytes = 0;
			D3D12_PLACED_SUBRESOURCE_FOOTPRINT footprint = {};
			UINT numRows = 0;
			Device->GetCopyableFootprints(&desc, 0, 1, 0, &footprint, &numRows, &rowSizeInBytes, &totalSize);
			D3D12_TEXTURE_COPY_LOCATION src = {}, dest = {};
			src.pResource = SceneBuffers.PPHitBuffer;
			src.Type = D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX;
			dest.pResource = SceneBuffers.StagingHitBuffer;
			dest.Type = D3D12_TEXTURE_COPY_TYPE_PLACED_FOOTPRINT;
			dest.PlacedFootprint = footprint;
			Commands.Current->Draw->CopyTextureRegion(&dest, 0, 0, 0, &src, &box);

			SubmitCommands(false);
			WaitDeviceIdle();

			// Lock the buffer and look for the last hit
			int hit = 0;
			void* data = nullptr;
			D3D12_RANGE readRange = {};
			readRange.End = totalSize;
			HRESULT result = SceneBuffers.StagingHitBuffer->Map(0, &readRange, &data);
			if (SUCCEEDED(result))
			{
				int width = Viewport->HitXL;
				int height = Viewport->HitYL;
				for (int y = 0; y < height; y++)
				{
					const INT* line = (const INT*)(((const char*)data) + y * footprint.Footprint.RowPitch);
					for (int x = 0; x < width; x++)
					{
						hit = std::max(hit, line[x]);
					}
				}
				D3D12_RANGE writtenRange = {};
				SceneBuffers.StagingHitBuffer->Unmap(0, &writtenRange);
			}
			hit--;

			hit = std::max(hit, ForceHitIndex);

			if (hit >= 0 && hit < (int)HitQueries.size())
			{
				const HitQuery& query = HitQueries[hit];
				memcpy(HitData, HitBuffer.data() + query.Start, query.Count);
				*HitSize = query.Count;
			}
			else
			{
				*HitSize = 0;
			}
		}

		HitQueryStack.clear();
		HitQueries.clear();
		HitBuffer.clear();
		HitData = nullptr;
		HitSize = nullptr;

		IsLocked = false;
	}
	catch (const std::exception& e)
	{
		debugf(TEXT("Could not unlock d3d12 renderer: %s"), to_utf16(e.what()).c_str());
		Exit();
	}

	unguard;
}

void UD3D12RenderDevice::PushHit(const BYTE* Data, INT Count)
{
	guard(UD3D12RenderDevice::PushHit);

	if (Count <= 0) return;
	HitQueryStack.insert(HitQueryStack.end(), Data, Data + Count);

	SetHitLocation();

	unguard;
}

void UD3D12RenderDevice::PopHit(INT Count, UBOOL bForce)
{
	guard(UD3D12RenderDevice::PopHit);

	if (bForce) // Force hit what we are popping
		ForceHitIndex = HitQueries.size() - 1;

	HitQueryStack.resize(HitQueryStack.size() - Count);

	SetHitLocation();

	unguard;
}

void UD3D12RenderDevice::SetHitLocation()
{
	DrawBatches();

	if (!HitQueryStack.empty())
	{
		INT index = HitQueries.size();

		HitQuery query;
		query.Start = HitBuffer.size();
		query.Count = HitQueryStack.size();
		HitQueries.push_back(query);

		HitBuffer.insert(HitBuffer.end(), HitQueryStack.begin(), HitQueryStack.end());

		SceneConstants.HitIndex = index + 1;
	}
	else
	{
		SceneConstants.HitIndex = 0;
	}
}

#if defined(OLDUNREAL469SDK)

UBOOL UD3D12RenderDevice::SupportsTextureFormat(ETextureFormat Format)
{
	guard(UD3D12RenderDevice::SupportsTextureFormat);

	return Uploads->SupportsTextureFormat(Format) ? TRUE : FALSE;

	unguard;
}

void UD3D12RenderDevice::UpdateTextureRect(FTextureInfo& Info, INT U, INT V, INT UL, INT VL)
{
	guardSlow(UD3D12RenderDevice::UpdateTextureRect);

	Textures->UpdateTextureRect(&Info, U, V, UL, VL);

	unguardSlow;
}

#endif

void UD3D12RenderDevice::DrawComplexSurface(FSceneNode* Frame, FSurfaceInfo& Surface, FSurfaceFacet& Facet)
{
	guardSlow(UD3D12RenderDevice::DrawComplexSurface);

	DWORD PolyFlags = ApplyPrecedenceRules(Surface.PolyFlags);

	CachedTexture* tex = Textures->GetTexture(Surface.Texture, !!(PolyFlags & PF_Masked));
	CachedTexture* lightmap = Textures->GetTexture(Surface.LightMap, false);
	CachedTexture* macrotex = Textures->GetTexture(Surface.MacroTexture, false);
	CachedTexture* fogmap = (Surface.FogMap && Surface.FogMap->Mips[0] && Surface.FogMap->Mips[0]->DataPtr) ? Textures->GetTexture(Surface.FogMap, false) : nullptr;

#if defined(UNREALGOLD)
	CachedTexture* detailtex = Surface.FogMap ? nullptr : Textures->GetTexture(Surface.DetailTexture, false);
#else
	CachedTexture* detailtex = (Surface.FogMap || !DetailTextures) ? nullptr : Textures->GetTexture(Surface.DetailTexture, false);
#endif

	float UDot = Facet.MapCoords.XAxis | Facet.MapCoords.Origin;
	float VDot = Facet.MapCoords.YAxis | Facet.MapCoords.Origin;

	float UPan = tex ? UDot + Surface.Texture->Pan.X : 0.0f;
	float VPan = tex ? VDot + Surface.Texture->Pan.Y : 0.0f;
	float UMult = tex ? GetUMult(*Surface.Texture) : 0.0f;
	float VMult = tex ? GetVMult(*Surface.Texture) : 0.0f;
	float LMUPan = lightmap ? UDot + Surface.LightMap->Pan.X - 0.5f * Surface.LightMap->UScale : 0.0f;
	float LMVPan = lightmap ? VDot + Surface.LightMap->Pan.Y - 0.5f * Surface.LightMap->VScale : 0.0f;
	float LMUMult = lightmap ? GetUMult(*Surface.LightMap) : 0.0f;
	float LMVMult = lightmap ? GetVMult(*Surface.LightMap) : 0.0f;
	float MacroUPan = macrotex ? UDot + Surface.MacroTexture->Pan.X : 0.0f;
	float MacroVPan = macrotex ? VDot + Surface.MacroTexture->Pan.Y : 0.0f;
	float MacroUMult = macrotex ? GetUMult(*Surface.MacroTexture) : 0.0f;
	float MacroVMult = macrotex ? GetVMult(*Surface.MacroTexture) : 0.0f;
	float DetailUPan = detailtex ? UDot + Surface.DetailTexture->Pan.X : 0.0f;
	float DetailVPan = detailtex ? VDot + Surface.DetailTexture->Pan.Y : 0.0f;
	float DetailUMult = detailtex ? GetUMult(*Surface.DetailTexture) : 0.0f;
	float DetailVMult = detailtex ? GetVMult(*Surface.DetailTexture) : 0.0f;

	uint32_t flags = 0;
	if (lightmap) flags |= 1;
	if (macrotex) flags |= 2;
	if (detailtex && !fogmap) flags |= 4;
	if (fogmap) flags |= 8;

	if (LightMode == 1) flags |= 64;

	if (fogmap) // if Surface.FogMap exists, use instead of detail texture
	{
		detailtex = fogmap;
		DetailUPan = UDot + Surface.FogMap->Pan.X - 0.5f * Surface.FogMap->UScale;
		DetailVPan = VDot + Surface.FogMap->Pan.Y - 0.5f * Surface.FogMap->VScale;
		DetailUMult = GetUMult(*Surface.FogMap);
		DetailVMult = GetVMult(*Surface.FogMap);
	}

	SetPipeline(PolyFlags);
	SetDescriptorSet(PolyFlags, tex, lightmap, macrotex, detailtex);

	vec4 color(1.0f);

	for (FSavedPoly* Poly = Facet.Polys; Poly; Poly = Poly->Next)
	{
		auto pts = Poly->Pts;
		uint32_t vcount = Poly->NumPts;
		if (vcount < 3) continue;

		uint32_t icount = (vcount - 2) * 3;
		auto alloc = ReserveVertices(vcount, icount);
		if (alloc.vptr)
		{
			SceneVertex* vptr = alloc.vptr;
			uint32_t* iptr = alloc.iptr;
			uint32_t vpos = alloc.vpos;

			for (uint32_t i = 0; i < vcount; i++)
			{
				FVector point = pts[i]->Point;
				FLOAT u = Facet.MapCoords.XAxis | point;
				FLOAT v = Facet.MapCoords.YAxis | point;

				vptr->Flags = flags;
				vptr->Position.x = point.X;
				vptr->Position.y = point.Y;
				vptr->Position.z = point.Z;
				vptr->TexCoord.s = (u - UPan) * UMult;
				vptr->TexCoord.t = (v - VPan) * VMult;
				vptr->TexCoord2.s = (u - LMUPan) * LMUMult;
				vptr->TexCoord2.t = (v - LMVPan) * LMVMult;
				vptr->TexCoord3.s = (u - MacroUPan) * MacroUMult;
				vptr->TexCoord3.t = (v - MacroVPan) * MacroVMult;
				vptr->TexCoord4.s = (u - DetailUPan) * DetailUMult;
				vptr->TexCoord4.t = (v - DetailVPan) * DetailVMult;
				vptr->Color = color;
				vptr++;
			}

			for (uint32_t i = vpos + 2; i < vpos + vcount; i++)
			{
				*(iptr++) = vpos;
				*(iptr++) = i - 1;
				*(iptr++) = i;
			}

			UseVertices(vcount, icount);
		}
	}

	Stats.ComplexSurfaces++;

	if (!GIsEditor || (PolyFlags & (PF_Selected | PF_FlatShaded)) == 0)
		return;

	// Editor highlight surface (so stupid this is delegated to the renderdev as the engine could just issue a second call):

	SetPipeline(PF_Highlighted);
	SetDescriptorSet(PF_Highlighted);

	if (PolyFlags & PF_FlatShaded)
	{
		color.x = Surface.FlatColor.R / 255.0f;
		color.y = Surface.FlatColor.G / 255.0f;
		color.z = Surface.FlatColor.B / 255.0f;
		color.w = 0.85f;
		if (PolyFlags & PF_Selected)
		{
			color.x *= 1.5f;
			color.y *= 1.5f;
			color.z *= 1.5f;
			color.w = 1.0f;
		}
	}
	else
	{
		color = vec4(0.0f, 0.0f, 0.05f, 0.20f);
	}

	for (FSavedPoly* Poly = Facet.Polys; Poly; Poly = Poly->Next)
	{
		auto pts = Poly->Pts;
		uint32_t vcount = Poly->NumPts;
		if (vcount < 3) continue;

		uint32_t icount = (vcount - 2) * 3;
		auto alloc = ReserveVertices(vcount, icount);
		if (alloc.vptr)
		{
			SceneVertex* vptr = alloc.vptr;
			uint32_t* iptr = alloc.iptr;
			uint32_t vpos = alloc.vpos;

			for (uint32_t i = 0; i < vcount; i++)
			{
				FVector point = pts[i]->Point;
				FLOAT u = Facet.MapCoords.XAxis | point;
				FLOAT v = Facet.MapCoords.YAxis | point;

				vptr->Flags = flags;
				vptr->Position.x = point.X;
				vptr->Position.y = point.Y;
				vptr->Position.z = point.Z;
				vptr->TexCoord.s = (u - UPan) * UMult;
				vptr->TexCoord.t = (v - VPan) * VMult;
				vptr->TexCoord2.s = (u - LMUPan) * LMUMult;
				vptr->TexCoord2.t = (v - LMVPan) * LMVMult;
				vptr->TexCoord3.s = (u - MacroUPan) * MacroUMult;
				vptr->TexCoord3.t = (v - MacroVPan) * MacroVMult;
				vptr->TexCoord4.s = (u - DetailUPan) * DetailUMult;
				vptr->TexCoord4.t = (v - DetailVPan) * DetailVMult;
				vptr->Color = color;
				vptr++;
			}

			for (uint32_t i = vpos + 2; i < vpos + vcount; i++)
			{
				*(iptr++) = vpos;
				*(iptr++) = i - 1;
				*(iptr++) = i;
			}

			UseVertices(vcount, icount);
		}
	}

	unguardSlow;
}

void UD3D12RenderDevice::DrawGouraudPolygon(FSceneNode* Frame, FTextureInfo& Info, FTransTexture** Pts, int NumPts, DWORD PolyFlags, FSpanBuffer* Span)
{
	guardSlow(UD3D12RenderDevice::DrawGouraudPolygon);

	if (NumPts < 3) return; // This can apparently happen!!

	PolyFlags = ApplyPrecedenceRules(PolyFlags);

	CachedTexture* tex = Textures->GetTexture(&Info, !!(PolyFlags & PF_Masked));

	SetPipeline(PolyFlags);
	SetDescriptorSet(PolyFlags, tex);

	float UMult = GetUMult(Info);
	float VMult = GetVMult(Info);
	int flags = (PolyFlags & (PF_RenderFog | PF_Translucent | PF_Modulated | PF_AlphaBlend)) == PF_RenderFog ? 16 : 0;
	if (VRWeaponPassActive)
		flags |= GetUICompositionFlags(PolyFlags);

	if ((PolyFlags & (PF_Translucent | PF_Modulated | PF_AlphaBlend)) == 0 && LightMode == 2) flags |= 32;

	auto alloc = ReserveVertices(NumPts, (NumPts - 2) * 3);
	if (alloc.vptr)
	{
		SceneVertex* vptr = alloc.vptr;
		uint32_t* iptr = alloc.iptr;
		uint32_t vpos = alloc.vpos;

		if (PolyFlags & PF_Modulated)
		{
			SceneVertex* vertex = vptr;
			for (INT i = 0; i < NumPts; i++)
			{
				FTransTexture* P = Pts[i];
				vertex->Flags = flags;
				vertex->Position.x = P->Point.X;
				vertex->Position.y = P->Point.Y;
				vertex->Position.z = P->Point.Z;
				vertex->TexCoord.s = P->U * UMult;
				vertex->TexCoord.t = P->V * VMult;
				vertex->TexCoord2.s = P->Fog.X;
				vertex->TexCoord2.t = P->Fog.Y;
				vertex->TexCoord3.s = P->Fog.Z;
				vertex->TexCoord3.t = P->Fog.W;
				vertex->TexCoord4.s = 0.0f;
				vertex->TexCoord4.t = 0.0f;
				vertex->Color.r = 1.0f;
				vertex->Color.g = 1.0f;
				vertex->Color.b = 1.0f;
				vertex->Color.a = (PolyFlags & PF_AlphaBlend) ? P->Light.W : 1.0f;
				vertex++;
			}
		}
		else
		{
			SceneVertex* vertex = vptr;
			for (INT i = 0; i < NumPts; i++)
			{
				FTransTexture* P = Pts[i];
				vertex->Flags = flags;
				vertex->Position.x = P->Point.X;
				vertex->Position.y = P->Point.Y;
				vertex->Position.z = P->Point.Z;
				vertex->TexCoord.s = P->U * UMult;
				vertex->TexCoord.t = P->V * VMult;
				vertex->TexCoord2.s = P->Fog.X;
				vertex->TexCoord2.t = P->Fog.Y;
				vertex->TexCoord3.s = P->Fog.Z;
				vertex->TexCoord3.t = P->Fog.W;
				vertex->TexCoord4.s = 0.0f;
				vertex->TexCoord4.t = 0.0f;
				vertex->Color.r = P->Light.X;
				vertex->Color.g = P->Light.Y;
				vertex->Color.b = P->Light.Z;
				vertex->Color.a = 1.0f;
				vertex++;
			}
		}

		uint32_t vstart = vpos;
		uint32_t vcount = NumPts;
		for (uint32_t i = vstart + 2; i < vstart + vcount; i++)
		{
			*(iptr++) = vstart;
			*(iptr++) = i - 1;
			*(iptr++) = i;
		}

		UseVertices(NumPts, (NumPts - 2) * 3);
	}

	Stats.GouraudPolygons++;

	unguardSlow;
}

#if defined(UNREAL_227)

void UD3D12RenderDevice::DrawGouraudPolyList(FSceneNode* Frame, FTextureInfo& Info, FTransTexture* Pts, int NumPts, DWORD PolyFlags, FSpanBuffer* Span)
{
	guardSlow(UD3D12RenderDevice::DrawGouraudPolyList);

	for (INT index = 0; index + 2 < NumPts; index += 3)
	{
		FTransTexture* triangle[] = { &Pts[index], &Pts[index + 1], &Pts[index + 2] };
		DrawGouraudPolygon(Frame, Info, triangle, 3, PolyFlags, Span);
	}

	unguardSlow;
}

#endif

#if defined(OLDUNREAL469SDK)

static void EnviroMap(const FSceneNode* Frame, FTransTexture& P, FLOAT UScale, FLOAT VScale)
{
	FVector T = P.Point.UnsafeNormal().MirrorByVector(P.Normal).TransformVectorBy(Frame->Uncoords);
	P.U = (T.X + 1.0f) * 0.5f * 256.0f * UScale;
	P.V = (T.Y + 1.0f) * 0.5f * 256.0f * VScale;
}

void UD3D12RenderDevice::DrawGouraudTriangles(const FSceneNode* Frame, const FTextureInfo& Info, FTransTexture* const Pts, INT NumPts, DWORD PolyFlags, DWORD DataFlags, FSpanBuffer* Span)
{
	guardSlow(UD3D12RenderDevice::DrawGouraudTriangles);

	if (NumPts < 3) return; // This can apparently happen!!

	PolyFlags = ApplyPrecedenceRules(PolyFlags);

	CachedTexture* tex = Textures->GetTexture(const_cast<FTextureInfo*>(&Info), !!(PolyFlags & PF_Masked));

	SetPipeline(PolyFlags);
	SetDescriptorSet(PolyFlags, tex);

	if (!ScenePass.VertexData || !ScenePass.IndexData) return;

	float UMult = GetUMult(Info);
	float VMult = GetVMult(Info);
	int flags = (PolyFlags & (PF_RenderFog | PF_Translucent | PF_Modulated | PF_AlphaBlend)) == PF_RenderFog ? 16 : 0;

	if ((PolyFlags & (PF_Translucent | PF_Modulated | PF_AlphaBlend)) == 0 && LightMode == 2) flags |= 32;

	if (PolyFlags & PF_Environment)
	{
		FLOAT UScale = Info.UScale * Info.USize * (1.0f / 256.0f);
		FLOAT VScale = Info.VScale * Info.VSize * (1.0f / 256.0f);

		for (INT i = 0; i < NumPts; i++)
			::EnviroMap(Frame, Pts[i], UScale, VScale);
	}

	auto alloc = ReserveVertices(NumPts, (NumPts - 2) * 3);
	if (alloc.vptr)
	{
		SceneVertex* vptr = alloc.vptr;
		uint32_t* iptr = alloc.iptr;
		uint32_t vpos = alloc.vpos;

		if (PolyFlags & PF_Modulated)
		{
			SceneVertex* vertex = vptr;
			for (INT i = 0; i < NumPts; i++)
			{
				FTransTexture* P = &Pts[i];
				vertex->Flags = flags;
				vertex->Position.x = P->Point.X;
				vertex->Position.y = P->Point.Y;
				vertex->Position.z = P->Point.Z;
				vertex->TexCoord.s = P->U * UMult;
				vertex->TexCoord.t = P->V * VMult;
				vertex->TexCoord2.s = P->Fog.X;
				vertex->TexCoord2.t = P->Fog.Y;
				vertex->TexCoord3.s = P->Fog.Z;
				vertex->TexCoord3.t = P->Fog.W;
				vertex->TexCoord4.s = 0.0f;
				vertex->TexCoord4.t = 0.0f;
				vertex->Color.r = 1.0f;
				vertex->Color.g = 1.0f;
				vertex->Color.b = 1.0f;
				vertex->Color.a = (PolyFlags & PF_AlphaBlend) ? P->Light.W : 1.0f;
				vertex++;
			}
		}
		else
		{
			SceneVertex* vertex = vptr;
			for (INT i = 0; i < NumPts; i++)
			{
				FTransTexture* P = &Pts[i];
				vertex->Flags = flags;
				vertex->Position.x = P->Point.X;
				vertex->Position.y = P->Point.Y;
				vertex->Position.z = P->Point.Z;
				vertex->TexCoord.s = P->U * UMult;
				vertex->TexCoord.t = P->V * VMult;
				vertex->TexCoord2.s = P->Fog.X;
				vertex->TexCoord2.t = P->Fog.Y;
				vertex->TexCoord3.s = P->Fog.Z;
				vertex->TexCoord3.t = P->Fog.W;
				vertex->TexCoord4.s = 0.0f;
				vertex->TexCoord4.t = 0.0f;
				vertex->Color.r = P->Light.X;
				vertex->Color.g = P->Light.Y;
				vertex->Color.b = P->Light.Z;
				vertex->Color.a = 1.0f;
				vertex++;
			}
		}

		bool mirror = (Frame->Mirror == -1.0);

		size_t vstart = vpos;
		size_t vcount = NumPts;
		size_t icount = 0;

		if (PolyFlags & PF_TwoSided)
		{
			for (uint32_t i = 2; i < vcount; i += 3)
			{
				// If outcoded, skip it.
				if (Pts[i - 2].Flags & Pts[i - 1].Flags & Pts[i].Flags)
					continue;

				*(iptr++) = vstart + i;
				*(iptr++) = vstart + i - 1;
				*(iptr++) = vstart + i - 2;
				icount += 3;
			}
		}
		else
		{
			for (uint32_t i = 2; i < vcount; i += 3)
			{
				// If outcoded, skip it.
				if (Pts[i - 2].Flags & Pts[i - 1].Flags & Pts[i].Flags)
					continue;

				bool backface = FTriple(Pts[i - 2].Point, Pts[i - 1].Point, Pts[i].Point) <= 0.0;
				if (mirror == backface)
				{
					*(iptr++) = vstart + i - 2;
					*(iptr++) = vstart + i - 1;
					*(iptr++) = vstart + i;
					icount += 3;
				}
			}
		}

		UseVertices(vcount, icount);
	}

	Stats.GouraudPolygons++;

	unguardSlow;
}

#endif

void UD3D12RenderDevice::DrawTile(FSceneNode* Frame, FTextureInfo& Info, FLOAT X, FLOAT Y, FLOAT XL, FLOAT YL, FLOAT U, FLOAT V, FLOAT UL, FLOAT VL, class FSpanBuffer* Span, FLOAT Z, FPlane Color, FPlane Fog, DWORD PolyFlags)
{
	guardSlow(UD3D12RenderDevice::DrawTile);

	// stijn: fix for invisible actor icons in ortho viewports
	if (GIsEditor && Frame->Viewport->Actor && (Frame->Viewport->IsOrtho() || Abs(Z) <= SMALL_NUMBER))
	{
		Z = 1.f;
	}

	PolyFlags = ApplyPrecedenceRules(PolyFlags);
	uint32_t uiFlags = GetUICompositionFlags(PolyFlags);

	CachedTexture* tex = Textures->GetTexture(&Info, !!(PolyFlags & PF_Masked));

	float UMult = tex ? GetUMult(Info) : 0.0f;
	float VMult = tex ? GetVMult(Info) : 0.0f;
	float u0 = U * UMult;
	float v0 = V * VMult;
	float u1 = (U + UL) * UMult;
	float v1 = (V + VL) * VMult;
	bool clamp = (u0 >= 0.0f && u1 <= 1.00001f && v0 >= 0.0f && v1 <= 1.00001f);

	SetPipeline(PolyFlags);
	SetDescriptorSet(PolyFlags, tex, nullptr, nullptr, nullptr, clamp);

	float r, g, b, a;
	if (PolyFlags & PF_Modulated)
	{
		r = 1.0f;
		g = 1.0f;
		b = 1.0f;
	}
	else
	{
		r = Color.X;
		g = Color.Y;
		b = Color.Z;
	}
	a = 1.0f;

	if (SceneBuffers.Multisample > 1)
	{
		XL = std::floor(X + XL + 0.5f);
		YL = std::floor(Y + YL + 0.5f);
		X = std::floor(X + 0.5f);
		Y = std::floor(Y + 0.5f);
		XL = XL - X;
		YL = YL - Y;
	}

	auto alloc = ReserveVertices(4, 6);
	if (alloc.vptr)
	{
		SceneVertex* vptr = alloc.vptr;
		uint32_t* iptr = alloc.iptr;
		uint32_t vpos = alloc.vpos;

		vptr[0] = { uiFlags, vec3(RFX2 * Z * (X - Frame->FX2),      RFY2 * Z * (Y - Frame->FY2),      Z), vec2(U * UMult,        V * VMult),        vec2(0.0f, 0.0f), vec2(0.0f, 0.0f), vec2(0.0f, 0.0f), vec4(r, g, b, a), };
		vptr[1] = { uiFlags, vec3(RFX2 * Z * (X + XL - Frame->FX2), RFY2 * Z * (Y - Frame->FY2),      Z), vec2((U + UL) * UMult, V * VMult),        vec2(0.0f, 0.0f), vec2(0.0f, 0.0f), vec2(0.0f, 0.0f), vec4(r, g, b, a), };
		vptr[2] = { uiFlags, vec3(RFX2 * Z * (X + XL - Frame->FX2), RFY2 * Z * (Y + YL - Frame->FY2), Z), vec2((U + UL) * UMult, (V + VL) * VMult), vec2(0.0f, 0.0f), vec2(0.0f, 0.0f), vec2(0.0f, 0.0f), vec4(r, g, b, a), };
		vptr[3] = { uiFlags, vec3(RFX2 * Z * (X - Frame->FX2),      RFY2 * Z * (Y + YL - Frame->FY2), Z), vec2(U * UMult,        (V + VL) * VMult), vec2(0.0f, 0.0f), vec2(0.0f, 0.0f), vec2(0.0f, 0.0f), vec4(r, g, b, a), };

		iptr[0] = vpos;
		iptr[1] = vpos + 1;
		iptr[2] = vpos + 2;
		iptr[3] = vpos;
		iptr[4] = vpos + 2;
		iptr[5] = vpos + 3;

		UseVertices(4, 6);
	}

	Stats.Tiles++;

	unguardSlow;
}

vec4 UD3D12RenderDevice::ApplyInverseGamma(vec4 color)
{
	if (Viewport->IsOrtho())
		return color;
	float brightness = Clamp(Viewport->GetOuterUClient()->Brightness * 2.0, 0.05, 2.99);
	float gammaRed = Max(brightness + GammaOffset + GammaOffsetRed, 0.001f);
	float gammaGreen = Max(brightness + GammaOffset + GammaOffsetGreen, 0.001f);
	float gammaBlue = Max(brightness + GammaOffset + GammaOffsetBlue, 0.001f);
	return vec4(pow(color.r, gammaRed), pow(color.g, gammaGreen), pow(color.b, gammaBlue), color.a);
}

void UD3D12RenderDevice::Draw3DLine(FSceneNode* Frame, FPlane Color, DWORD LineFlags, FVector P1, FVector P2)
{
	guard(UD3D12RenderDevice::Draw3DLine);

	P1 = P1.TransformPointBy(Frame->Coords);
	P2 = P2.TransformPointBy(Frame->Coords);
	if (Frame->Viewport->IsOrtho())
	{
		P1.X = (P1.X) / Frame->Zoom + Frame->FX2;
		P1.Y = (P1.Y) / Frame->Zoom + Frame->FY2;
		P1.Z = 1;
		P2.X = (P2.X) / Frame->Zoom + Frame->FX2;
		P2.Y = (P2.Y) / Frame->Zoom + Frame->FY2;
		P2.Z = 1;

		if (Abs(P2.X - P1.X) + Abs(P2.Y - P1.Y) >= 0.2)
		{
			Draw2DLine(Frame, Color, LineFlags, P1, P2);
		}
		else if (Frame->Viewport->Actor->OrthoZoom < ORTHO_LOW_DETAIL)
		{
			Draw2DPoint(Frame, Color, LINE_None, P1.X - 1, P1.Y - 1, P1.X + 1, P1.Y + 1, P1.Z);
		}
	}
	else
	{
#if defined(OLDUNREAL469SDK)
		bool occlude = !!(LineFlags & LINE_DepthCued);
#else
		bool occlude = OccludeLines;
#endif
		SetPipeline(&ScenePass.LinePipeline[occlude], D3D_PRIMITIVE_TOPOLOGY_LINELIST);
		SetDescriptorSet(PF_Highlighted);
		vec4 color = ApplyInverseGamma(vec4(Color.X, Color.Y, Color.Z, 1.0f));

		auto alloc = ReserveVertices(2, 2);
		if (alloc.vptr)
		{
			SceneVertex* vptr = alloc.vptr;
			uint32_t* iptr = alloc.iptr;
			uint32_t vpos = alloc.vpos;

			vptr[0] = { 0, vec3(P1.X, P1.Y, P1.Z), vec2(0.0f), vec2(0.0f), vec2(0.0f), vec2(0.0f), color };
			vptr[1] = { 0, vec3(P2.X, P2.Y, P2.Z), vec2(0.0f), vec2(0.0f), vec2(0.0f), vec2(0.0f), color };

			iptr[0] = vpos;
			iptr[1] = vpos + 1;

			UseVertices(2, 2);
		}
	}

	unguard;
}

void UD3D12RenderDevice::Draw2DClippedLine(FSceneNode* Frame, FPlane Color, DWORD LineFlags, FVector P1, FVector P2)
{
	guard(UD3D12RenderDevice::Draw2DClippedLine);
	URenderDevice::Draw2DClippedLine(Frame, Color, LineFlags, P1, P2);
	unguard;
}

void UD3D12RenderDevice::Draw2DLine(FSceneNode* Frame, FPlane Color, DWORD LineFlags, FVector P1, FVector P2)
{
	guard(UD3D12RenderDevice::Draw2DLine);

#if defined(OLDUNREAL469SDK)
	bool occlude = !!(LineFlags & LINE_DepthCued);
#else
	bool occlude = OccludeLines;
#endif
	SetPipeline(&ScenePass.LinePipeline[occlude], D3D_PRIMITIVE_TOPOLOGY_LINELIST);
	SetDescriptorSet(PF_Highlighted);
	vec4 color = ApplyInverseGamma(vec4(Color.X, Color.Y, Color.Z, 1.0f));
	uint32_t uiFlags = GetUICompositionFlags(PF_Highlighted);

	auto alloc = ReserveVertices(2, 2);
	if (alloc.vptr)
	{
		SceneVertex* vptr = alloc.vptr;
		uint32_t* iptr = alloc.iptr;
		uint32_t vpos = alloc.vpos;

		vptr[0] = { uiFlags, vec3(RFX2 * P1.Z * (P1.X - Frame->FX2), RFY2 * P1.Z * (P1.Y - Frame->FY2), P1.Z), vec2(0.0f), vec2(0.0f), vec2(0.0f), vec2(0.0f), color };
		vptr[1] = { uiFlags, vec3(RFX2 * P2.Z * (P2.X - Frame->FX2), RFY2 * P2.Z * (P2.Y - Frame->FY2), P2.Z), vec2(0.0f), vec2(0.0f), vec2(0.0f), vec2(0.0f), color };

		iptr[0] = vpos;
		iptr[1] = vpos + 1;

		UseVertices(2, 2);
	}

	unguard;
}

void UD3D12RenderDevice::Draw2DPoint(FSceneNode* Frame, FPlane Color, DWORD LineFlags, FLOAT X1, FLOAT Y1, FLOAT X2, FLOAT Y2, FLOAT Z)
{
	guard(UD3D12RenderDevice::Draw2DPoint);

	// Hack to fix UED selection problem with selection brush
	if (GIsEditor) Z = 1.0f;

#if defined(OLDUNREAL469SDK)
	bool occlude = !!(LineFlags & LINE_DepthCued);
#else
	bool occlude = OccludeLines;
#endif
	SetPipeline(&ScenePass.PointPipeline[occlude], D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
	SetDescriptorSet(PF_Highlighted);
	vec4 color = ApplyInverseGamma(vec4(Color.X, Color.Y, Color.Z, 1.0f));
	uint32_t uiFlags = GetUICompositionFlags(PF_Highlighted);

	auto alloc = ReserveVertices(4, 6);
	if (alloc.vptr)
	{
		SceneVertex* vptr = alloc.vptr;
		uint32_t* iptr = alloc.iptr;
		uint32_t vpos = alloc.vpos;

		vptr[0] = { uiFlags, vec3(RFX2 * Z * (X1 - Frame->FX2 - 0.5f), RFY2 * Z * (Y1 - Frame->FY2 - 0.5f), Z), vec2(0.0f), vec2(0.0f), vec2(0.0f), vec2(0.0f), color };
		vptr[1] = { uiFlags, vec3(RFX2 * Z * (X2 - Frame->FX2 + 0.5f), RFY2 * Z * (Y1 - Frame->FY2 - 0.5f), Z), vec2(0.0f), vec2(0.0f), vec2(0.0f), vec2(0.0f), color };
		vptr[2] = { uiFlags, vec3(RFX2 * Z * (X2 - Frame->FX2 + 0.5f), RFY2 * Z * (Y2 - Frame->FY2 + 0.5f), Z), vec2(0.0f), vec2(0.0f), vec2(0.0f), vec2(0.0f), color };
		vptr[3] = { uiFlags, vec3(RFX2 * Z * (X1 - Frame->FX2 - 0.5f), RFY2 * Z * (Y2 - Frame->FY2 + 0.5f), Z), vec2(0.0f), vec2(0.0f), vec2(0.0f), vec2(0.0f), color };

		iptr[0] = vpos;
		iptr[1] = vpos + 1;
		iptr[2] = vpos + 2;
		iptr[3] = vpos;
		iptr[4] = vpos + 2;
		iptr[5] = vpos + 3;

		UseVertices(4, 6);
	}

	unguard;
}

void UD3D12RenderDevice::ClearZ(FSceneNode* Frame)
{
	guard(UD3D12RenderDevice::ClearZ);

	DrawBatches();

	Commands.Current->Draw->ClearDepthStencilView(SceneBuffers.SceneDSV.CPUHandle(), D3D12_CLEAR_FLAG_DEPTH, 1.0f, 0, 0, nullptr);

	unguard;
}

void UD3D12RenderDevice::GetStats(TCHAR* Result)
{
	guard(UD3D12RenderDevice::GetStats);
	Result[0] = 0;
	unguard;
}

void UD3D12RenderDevice::ReadPixels(FColor* Pixels, UBOOL bGammaCorrectOutput)
{
	guard(UD3D12RenderDevice::ReadPixels);

	auto& ReadBuffers = ActiveVREyeBuffer < 0 && LastVREyeBuffer >= 0 ? VREyeBuffers[LastVREyeBuffer] : SceneBuffers;
	ID3D12Resource* imageResource = nullptr;

	if (GammaCorrectScreenshots)
	{
		TransitionResourceBarrier(Commands.Current->Draw, ReadBuffers.PPImage[PPI_Screenshot], D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE, D3D12_RESOURCE_STATE_RENDER_TARGET);

		D3D12_CPU_DESCRIPTOR_HANDLE rtv = ReadBuffers.PPImageRTV[PPI_Screenshot].CPUHandle();
		Commands.Current->Draw->SetGraphicsRootSignature(PresentPass.RootSignature);
		Commands.Current->Draw->OMSetRenderTargets(1, &rtv, FALSE, nullptr);

		D3D12_VIEWPORT viewport = {};
		viewport.Width = CurrentSizeX;
		viewport.Height = CurrentSizeY;
		viewport.MaxDepth = 1.0f;
		Commands.Current->Draw->RSSetViewports(1, &viewport);

		D3D12_RECT box = {};
		box.right = CurrentSizeX;
		box.bottom = CurrentSizeY;
		Commands.Current->Draw->RSSetScissorRects(1, &box);

		PresentPushConstants pushconstants = GetPresentPushConstants();

		// Select present shader based on what the user is actually using
		int presentShader = 16; // ScreenshotImage always uses rgba16f output.
		if (ActiveHdr) presentShader |= (1 | 16); // 1 = HDR in shader, 16 = output is rgba16f
		if (GammaMode == 1) presentShader |= 2;
		if (pushconstants.Brightness != 0.0f || pushconstants.Contrast != 1.0f || pushconstants.Saturation != 1.0f) presentShader |= (Clamp(GrayFormula, 0, 2) + 1) << 2;

		Commands.Current->Draw->SetPipelineState(PresentPass.Present[presentShader]);
		Commands.Current->Draw->IASetPrimitiveTopology(D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
		Commands.Current->Draw->IASetVertexBuffers(0, 1, &PresentPass.PPStepVertexBufferView);
		Commands.Current->Draw->SetGraphicsRootDescriptorTable(0, ReadBuffers.PresentSRVs.GPUHandle());
		Commands.Current->Draw->SetGraphicsRoot32BitConstants(1, sizeof(PresentPushConstants) / sizeof(uint32_t), &pushconstants, 0);
		Commands.Current->Draw->DrawInstanced(6, 1, 0, 0);

		TransitionResourceBarrier(Commands.Current->Draw, ReadBuffers.PPImage[PPI_Screenshot], D3D12_RESOURCE_STATE_RENDER_TARGET, D3D12_RESOURCE_STATE_COPY_SOURCE);
		imageResource = ReadBuffers.PPImage[PPI_Screenshot];
	}
	else
	{
		TransitionResourceBarrier(Commands.Current->Draw, ReadBuffers.PPImage[PPI_FinalFrame], D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE, D3D12_RESOURCE_STATE_COPY_SOURCE);
		imageResource = ReadBuffers.PPImage[PPI_FinalFrame];
	}

	D3D12_RESOURCE_DESC desc = imageResource->GetDesc();
	UINT64 totalSize = 0, rowSizeInBytes = 0;
	D3D12_PLACED_SUBRESOURCE_FOOTPRINT footprint = {};
	UINT numRows = 0;
	Device->GetCopyableFootprints(&desc, 0, 1, 0, &footprint, &numRows, &rowSizeInBytes, &totalSize);

	D3D12_HEAP_PROPERTIES readbackHeapProps = { D3D12_HEAP_TYPE_READBACK };

	D3D12_RESOURCE_DESC bufDesc = {};
	bufDesc.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
	bufDesc.Width = totalSize;
	bufDesc.Height = 1;
	bufDesc.DepthOrArraySize = 1;
	bufDesc.MipLevels = 1;
	bufDesc.SampleDesc.Count = 1;
	bufDesc.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
	bufDesc.Flags = D3D12_RESOURCE_FLAG_NONE;

	ComPtr<ID3D12Resource> buffer;
	HRESULT result = Device->CreateCommittedResource(
		&readbackHeapProps,
		D3D12_HEAP_FLAG_NONE,
		&bufDesc,
		D3D12_RESOURCE_STATE_COPY_DEST,
		nullptr,
		buffer.GetIID(),
		buffer.InitPtr());
	ThrowIfFailed(result, "CreateCommittedResource(ReadPixelsBuffer) failed");
	buffer->SetName(TEXT("ReadPixelsBuffer"));

	D3D12_TEXTURE_COPY_LOCATION src = {};
	src.pResource = imageResource;
	src.Type = D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX;

	D3D12_TEXTURE_COPY_LOCATION dest = {};
	dest.pResource = buffer;
	dest.Type = D3D12_TEXTURE_COPY_TYPE_PLACED_FOOTPRINT;
	dest.PlacedFootprint = footprint;

	Commands.Current->Draw->CopyTextureRegion(&dest, 0, 0, 0, &src, nullptr);

	TransitionResourceBarrier(Commands.Current->Draw, imageResource, D3D12_RESOURCE_STATE_COPY_SOURCE, D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE);
	SubmitCommands(false);
	WaitDeviceIdle();

	void* data = nullptr;
	D3D12_RANGE readRange = { 0, (SIZE_T)totalSize };
	result = buffer->Map(0, &readRange, &data);
	ThrowIfFailed(result, "Map(ReadPixelsBuffer) failed");
	uint8_t* srcpixels = (uint8_t*)data;
	int w = CurrentSizeX;
	int h = CurrentSizeY;
	void* pixelData = Pixels;

	for (int y = 0; y < h; y++)
	{
		int desty = GammaCorrectScreenshots ? y : (h - y - 1);
		uint8_t* dest = (uint8_t*)pixelData + desty * w * 4;
		const int SourceY = GammaCorrectScreenshots ? y :
			static_cast<int>(static_cast<int64_t>(y) * desc.Height / h);
		uint16_t* srcrow = (uint16_t*)(srcpixels + SourceY * footprint.Footprint.RowPitch);
		for (int x = 0; x < w; x++)
		{
			const int SourceX = GammaCorrectScreenshots ? x :
				static_cast<int>(static_cast<int64_t>(x) * desc.Width / w);
			uint16_t* src = srcrow + SourceX * 4;
			float red = halfToFloatSimple(*(src++));
			float green = halfToFloatSimple(*(src++));
			float blue = halfToFloatSimple(*(src++));
			float alpha = halfToFloatSimple(*(src++));

			dest[0] = (int)clamp(std::round(blue * 255.0f), 0.0f, 255.0f);
			dest[1] = (int)clamp(std::round(green * 255.0f), 0.0f, 255.0f);
			dest[2] = (int)clamp(std::round(red * 255.0f), 0.0f, 255.0f);
			dest[3] = (int)clamp(std::round(alpha * 255.0f), 0.0f, 255.0f);
			dest += 4;
		}
	}

	D3D12_RANGE writtenRange = {};
	buffer->Unmap(0, &writtenRange);

	unguard;
}

void UD3D12RenderDevice::EndFlash()
{
	guard(UD3D12RenderDevice::EndFlash);
	if (FlashScale != FPlane(0.5f, 0.5f, 0.5f, 0.0f) || FlashFog != FPlane(0.0f, 0.0f, 0.0f, 0.0f))
	{
		DrawBatches();

		vec4 color(FlashFog.X, FlashFog.Y, FlashFog.Z, 1.0f - Min(FlashScale.X * 2.0f, 1.0f));
		vec2 zero2(0.0f);

		SceneConstants.ObjectToProjection = mat4::identity();
		SceneConstants.NearClip = vec4(0.0f, 0.0f, 0.0f, 1.0f);

		SetPipeline(PF_Highlighted);
		SetDescriptorSet(0);

		auto alloc = ReserveVertices(4, 6);
		if (alloc.vptr)
		{
			SceneVertex* vptr = alloc.vptr;
			uint32_t* iptr = alloc.iptr;
			uint32_t vpos = alloc.vpos;

			vptr[0] = { 0, vec3(-1.0f, -1.0f, 0.0f), zero2, zero2, zero2, zero2, color };
			vptr[1] = { 0, vec3(1.0f, -1.0f, 0.0f), zero2, zero2, zero2, zero2, color };
			vptr[2] = { 0, vec3(1.0f,  1.0f, 0.0f), zero2, zero2, zero2, zero2, color };
			vptr[3] = { 0, vec3(-1.0f,  1.0f, 0.0f), zero2, zero2, zero2, zero2, color };

			iptr[0] = vpos;
			iptr[1] = vpos + 1;
			iptr[2] = vpos + 2;
			iptr[3] = vpos;
			iptr[4] = vpos + 2;
			iptr[5] = vpos + 3;

			UseVertices(4, 6);
		}

		DrawBatches();
		if (CurrentFrame)
			SetSceneNode(CurrentFrame);
	}
	unguard;
}

void UD3D12RenderDevice::SetSceneNode(FSceneNode* Frame)
{
	guardSlow(UD3D12RenderDevice::SetSceneNode);

	DrawBatches();
	CurrentFrame = Frame;
	Aspect = Frame->FY / Frame->FX;
	RProjZ = (float)appTan(radians(Viewport->Actor->FovAngle) * 0.5);
	RFX2 = 2.0f * RProjZ / Frame->FX;
	RFY2 = 2.0f * RProjZ * Aspect / Frame->FY;

	SceneViewport = {};
	SceneViewport.TopLeftX = Frame->XB;
	SceneViewport.TopLeftY = SceneBuffers.Height - Frame->YB - Frame->Y;
	SceneViewport.Width = Frame->X;
	SceneViewport.Height = Frame->Y;
	if (ActiveVREyeBuffer >= 0)
	{
		const auto Raster = VRRenderSizing::RasterViewport({ CurrentSizeX, CurrentSizeY },
			{ SceneBuffers.Width, SceneBuffers.Height },
			{ static_cast<float>(Frame->XB), static_cast<float>(Frame->YB),
			  static_cast<float>(Frame->X), static_cast<float>(Frame->Y) });
		SceneViewport.TopLeftX = Raster.X;
		SceneViewport.TopLeftY = Raster.Y;
		SceneViewport.Width = Raster.Width;
		SceneViewport.Height = Raster.Height;
	}
	SceneViewport.MinDepth = 0.1f;
	SceneViewport.MaxDepth = 1.0f;
	Commands.Current->Draw->RSSetViewports(1, &SceneViewport);

	if (!VRUIPassActive && OpenXRStereoDrawEye >= 0 && OpenXRViewsValid &&
		static_cast<uint32_t>(OpenXRStereoDrawEye) < OpenXRViews.size())
	{
		const XrFovf& EyeFov = OpenXRViews[OpenXRStereoDrawEye].fov;
		const FLOAT Left = appTan(EyeFov.angleLeft);
		const FLOAT Right = appTan(EyeFov.angleRight);
		// UE1 camera-space Y is positive down, and the renderer's final present
		// pass flips the scene vertically. Convert OpenXR's positive-up FOV into
		// those bounds while preserving the runtime's asymmetric optical center.
		const FLOAT Bottom = -appTan(EyeFov.angleUp);
		const FLOAT Top = -appTan(EyeFov.angleDown);
		SceneConstants.ObjectToProjection = mat4::frustum(Left, Right, Bottom, Top,
			1.0f, 32768.0f, handedness::left, clipzrange::zero_positive_w);
		if (!OpenXRFovLogged && OpenXRStereoDrawEye == 1)
		{
			OpenXRFovLogged = 1;
			debugf(TEXT("Unreal Revived OpenXR: asymmetric eye projection applied left=(%.3f %.3f %.3f %.3f) right=(%.3f %.3f %.3f %.3f)"),
				OpenXRViews[0].fov.angleLeft, OpenXRViews[0].fov.angleRight,
				OpenXRViews[0].fov.angleUp, OpenXRViews[0].fov.angleDown,
				OpenXRViews[1].fov.angleLeft, OpenXRViews[1].fov.angleRight,
				OpenXRViews[1].fov.angleUp, OpenXRViews[1].fov.angleDown);
		}
	}
	else
	{
		SceneConstants.ObjectToProjection = mat4::frustum(-RProjZ, RProjZ, -Aspect * RProjZ, Aspect * RProjZ, 1.0f, 32768.0f, handedness::left, clipzrange::zero_positive_w);
	}
	SceneConstants.NearClip = vec4(Frame->NearClip.X, Frame->NearClip.Y, Frame->NearClip.Z, Frame->NearClip.W);

	unguardSlow;
}

void UD3D12RenderDevice::PrecacheTexture(FTextureInfo& Info, DWORD PolyFlags)
{
	guard(UD3D12RenderDevice::PrecacheTexture);
	PolyFlags = ApplyPrecedenceRules(PolyFlags);
	Textures->GetTexture(&Info, !!(PolyFlags & PF_Masked));
	unguard;
}

void UD3D12RenderDevice::ClearTextureCache()
{
	DrawBatches(true);
	WaitDeviceIdle();
	Textures->ClearCache();
	for (auto& it : Descriptors.Tex)
		it.second.reset();
	Descriptors.Tex.clear();
}

void UD3D12RenderDevice::AddDrawBatch()
{
	if (Batch.SceneIndexStart != ScenePass.IndexPos)
	{
		Batch.SceneIndexEnd = ScenePass.IndexPos;
		QueuedBatches.push_back(Batch);
		Batch.SceneIndexStart = ScenePass.IndexPos;
	}
}

void UD3D12RenderDevice::DrawBatches(bool nextBuffer)
{
	AddDrawBatch();

	if (!QueuedBatches.empty())
	{
		D3D12_CPU_DESCRIPTOR_HANDLE views[3] = { SceneBuffers.SceneRTVs.CPUHandle(0), SceneBuffers.SceneRTVs.CPUHandle(1), SceneBuffers.SceneRTVs.CPUHandle(2) };
		D3D12_CPU_DESCRIPTOR_HANDLE depthview = SceneBuffers.SceneDSV.CPUHandle();

		Commands.Current->Draw->SetGraphicsRootSignature(ScenePass.RootSignature);
		Commands.Current->Draw->SetGraphicsRoot32BitConstants(2, sizeof(ScenePushConstants) / sizeof(uint32_t), &SceneConstants, 0);
		Commands.Current->Draw->OMSetRenderTargets(3, views, FALSE, &depthview);
		Commands.Current->Draw->IASetPrimitiveTopology(Commands.PrimitiveTopology);
		Commands.Current->Draw->IASetVertexBuffers(0, 1, &ScenePass.VertexBufferView);
		Commands.Current->Draw->IASetIndexBuffer(&ScenePass.IndexBufferView);

		for (const DrawBatchEntry& entry : QueuedBatches)
			DrawEntry(entry);
		QueuedBatches.clear();

		if (nextBuffer)
		{
			SubmitCommands(false);
		}
	}

	Batch.SceneIndexStart = ScenePass.IndexPos;
}

void UD3D12RenderDevice::DrawEntry(const DrawBatchEntry& entry)
{
	size_t icount = entry.SceneIndexEnd - entry.SceneIndexStart;

	if (SceneViewport.MinDepth != entry.Pipeline->MinDepth || SceneViewport.MaxDepth != entry.Pipeline->MaxDepth)
	{
		SceneViewport.MinDepth = entry.Pipeline->MinDepth;
		SceneViewport.MaxDepth = entry.Pipeline->MaxDepth;
		Commands.Current->Draw->RSSetViewports(1, &SceneViewport);
	}

	DescriptorSet& common = Descriptors.Tex[{ entry.Tex, entry.Lightmap, entry.Detailtex, entry.Macrotex }];
	if (!common)
	{
		common = Heaps.Common->Alloc(4);
		Device->CreateShaderResourceView(entry.Tex ? entry.Tex->Texture : Textures->GetNullTexture()->Texture, nullptr, common.CPUHandle(0));
		Device->CreateShaderResourceView(entry.Lightmap ? entry.Lightmap->Texture : Textures->GetNullTexture()->Texture, nullptr, common.CPUHandle(1));
		Device->CreateShaderResourceView(entry.Macrotex ? entry.Macrotex->Texture : Textures->GetNullTexture()->Texture, nullptr, common.CPUHandle(2));
		Device->CreateShaderResourceView(entry.Detailtex ? entry.Detailtex->Texture : Textures->GetNullTexture()->Texture, nullptr, common.CPUHandle(3));
	}

	DescriptorSet& sampler = Descriptors.Sampler[(entry.TexSamplerMode << 16) | (entry.DetailtexSamplerMode << 8) | entry.MacrotexSamplerMode];
	if (!sampler)
	{
		sampler = Heaps.Sampler->Alloc(4);
		Device->CreateSampler(&ScenePass.Samplers[entry.TexSamplerMode], sampler.CPUHandle(0));
		Device->CreateSampler(&ScenePass.Samplers[0], sampler.CPUHandle(1));
		Device->CreateSampler(&ScenePass.Samplers[entry.MacrotexSamplerMode], sampler.CPUHandle(2));
		Device->CreateSampler(&ScenePass.Samplers[entry.DetailtexSamplerMode], sampler.CPUHandle(3));
	}

	if (entry.PrimitiveTopology != Commands.PrimitiveTopology)
	{
		Commands.PrimitiveTopology = entry.PrimitiveTopology;
		Commands.Current->Draw->IASetPrimitiveTopology(Commands.PrimitiveTopology);
	}

	Commands.Current->Draw->SetPipelineState(entry.Pipeline->Pipeline);
	Commands.Current->Draw->SetGraphicsRootDescriptorTable(0, common.GPUHandle());
	Commands.Current->Draw->SetGraphicsRootDescriptorTable(1, sampler.GPUHandle());
	Commands.Current->Draw->DrawIndexedInstanced(icount, 1, ScenePass.IndexBase + entry.SceneIndexStart, 0, 0);

	Stats.DrawCalls++;
}

ComPtr<ID3D12RootSignature> UD3D12RenderDevice::CreateRootSignature(const char* name, const std::vector<std::vector<D3D12_DESCRIPTOR_RANGE>>& descriptorTables, const D3D12_ROOT_CONSTANTS& pushConstants, const std::vector<D3D12_STATIC_SAMPLER_DESC>& staticSamplers)
{
	std::vector<D3D12_ROOT_PARAMETER> parameters;

	for (const std::vector<D3D12_DESCRIPTOR_RANGE>& table : descriptorTables)
	{
		D3D12_ROOT_PARAMETER param = {};
		param.ShaderVisibility = D3D12_SHADER_VISIBILITY_ALL;
		param.ParameterType = D3D12_ROOT_PARAMETER_TYPE_DESCRIPTOR_TABLE;
		param.DescriptorTable.NumDescriptorRanges = table.size();
		param.DescriptorTable.pDescriptorRanges = table.data();
		parameters.push_back(param);
	}

	if (pushConstants.Num32BitValues > 0)
	{
		D3D12_ROOT_PARAMETER param = {};
		param.ShaderVisibility = D3D12_SHADER_VISIBILITY_ALL;
		param.ParameterType = D3D12_ROOT_PARAMETER_TYPE_32BIT_CONSTANTS;
		param.Constants = pushConstants;
		parameters.push_back(param);
	}

	D3D12_ROOT_SIGNATURE_DESC desc = {};
	desc.NumParameters = parameters.size();
	desc.pParameters = parameters.data();
	desc.NumStaticSamplers = staticSamplers.size();
	desc.pStaticSamplers = staticSamplers.data();
	desc.Flags = D3D12_ROOT_SIGNATURE_FLAG_ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT;

	ComPtr<ID3DBlob> signatureblob, error;
	HRESULT result = D3D12SerializeRootSignature(&desc, D3D_ROOT_SIGNATURE_VERSION_1, signatureblob.TypedInitPtr(), error.TypedInitPtr());
	if (FAILED(result))
	{
		std::string text = "Could not serialize ";
		text += name;
		if (error)
		{
			text += ": ";
			text.append((const char*)error->GetBufferPointer(), error->GetBufferSize());
		}
		throw std::runtime_error(text);
	}

	ComPtr<ID3D12RootSignature> signature;
	result = Device->CreateRootSignature(0, signatureblob->GetBufferPointer(), signatureblob->GetBufferSize(), signature.GetIID(), signature.InitPtr());
	if (FAILED(result))
	{
		std::string text = "Could not create ";
		text += name;
		throw std::runtime_error(text);
	}

	return signature;
}

std::vector<uint8_t> UD3D12RenderDevice::CompileHlsl(const std::string& filename, const std::string& shadertype, const std::vector<std::string> defines)
{
	std::string code = FileResource::readAllText(filename);

	std::string target;
	switch (FeatureLevel)
	{
	default:
	// case D3D_FEATURE_LEVEL_12_2: target = shadertype + "_6_5"; break;
	case D3D_FEATURE_LEVEL_12_1: target = shadertype + "_5_0"; break;
	case D3D_FEATURE_LEVEL_12_0: target = shadertype + "_5_0"; break;
	case D3D_FEATURE_LEVEL_11_1: target = shadertype + "_5_0"; break;
	case D3D_FEATURE_LEVEL_11_0: target = shadertype + "_5_0"; break;
	}

	std::vector<D3D_SHADER_MACRO> macros;
	for (const std::string& define : defines)
	{
		D3D_SHADER_MACRO macro = {};
		macro.Name = define.c_str();
		macro.Definition = "1";
		macros.push_back(macro);
	}
	macros.push_back({});

	ComPtr<ID3DBlob> blob, errors;
	HRESULT result = D3DCompile(code.data(), code.size(), filename.c_str(), macros.data(), nullptr, "main", target.c_str(), D3DCOMPILE_ENABLE_STRICTNESS | D3DCOMPILE_OPTIMIZATION_LEVEL3, 0, blob.TypedInitPtr(), errors.TypedInitPtr());
	if (FAILED(result))
	{
		std::string msg((const char*)errors->GetBufferPointer(), errors->GetBufferSize());
		if (!msg.empty() && msg.back() == 0) msg.pop_back();
		throw std::runtime_error("Could not compile shader '" + filename + "':" + msg);
	}
	ThrowIfFailed(result, "D3DCompile failed");

	std::vector<uint8_t> bytecode;
	bytecode.resize(blob->GetBufferSize());
	memcpy(bytecode.data(), blob->GetBufferPointer(), bytecode.size());
	return bytecode;
}

void UD3D12RenderDevice::OnDebugMessage(D3D12_MESSAGE_CATEGORY category, D3D12_MESSAGE_SEVERITY severity, D3D12_MESSAGE_ID id, LPCSTR description, void* context)
{
	UD3D12RenderDevice* self = (UD3D12RenderDevice*)context;

	const char* severitystr = "unknown";
	switch (severity)
	{
	case D3D12_MESSAGE_SEVERITY_CORRUPTION: severitystr = "corruption"; break;
	case D3D12_MESSAGE_SEVERITY_ERROR: severitystr = "error"; break;
	case D3D12_MESSAGE_SEVERITY_WARNING: severitystr = "warning"; break;
	case D3D12_MESSAGE_SEVERITY_INFO: severitystr = "info"; break;
	case D3D12_MESSAGE_SEVERITY_MESSAGE: severitystr = "message"; break;
	}

	debugf(TEXT("[%s] %s"), to_utf16(severitystr).c_str(), to_utf16(description).c_str());
}

void ThrowError(HRESULT result, const char* msg)
{
	std::string message = msg;

	switch (result)
	{
	case D3D12_ERROR_ADAPTER_NOT_FOUND: message += " (D3D12_ERROR_ADAPTER_NOT_FOUND)"; break;
	case D3D12_ERROR_DRIVER_VERSION_MISMATCH: message += " (D3D12_ERROR_DRIVER_VERSION_MISMATCH)"; break;
	case DXGI_ERROR_INVALID_CALL: message += " (DXGI_ERROR_INVALID_CALL)"; break;
	case DXGI_ERROR_WAS_STILL_DRAWING: message += " (DXGI_ERROR_WAS_STILL_DRAWING)"; break;
	case DXGI_ERROR_ACCESS_DENIED: message += " (DXGI_ERROR_ACCESS_DENIED)"; break;
	case DXGI_ERROR_ACCESS_LOST: message += " (DXGI_ERROR_ACCESS_LOST)"; break;
	case DXGI_ERROR_ALREADY_EXISTS: message += " (DXGI_ERROR_ALREADY_EXISTS)"; break;
	case DXGI_ERROR_CANNOT_PROTECT_CONTENT: message += " (DXGI_ERROR_CANNOT_PROTECT_CONTENT)"; break;
	case DXGI_ERROR_DEVICE_HUNG: message += " (DXGI_ERROR_DEVICE_HUNG)"; break;
	case DXGI_ERROR_DEVICE_REMOVED: message += " (DXGI_ERROR_DEVICE_REMOVED)"; break;
	case DXGI_ERROR_DEVICE_RESET: message += " (DXGI_ERROR_DEVICE_RESET)"; break;
	case DXGI_ERROR_DRIVER_INTERNAL_ERROR: message += " (DXGI_ERROR_DRIVER_INTERNAL_ERROR)"; break;
	case DXGI_ERROR_FRAME_STATISTICS_DISJOINT: message += " (DXGI_ERROR_FRAME_STATISTICS_DISJOINT)"; break;
	case DXGI_ERROR_GRAPHICS_VIDPN_SOURCE_IN_USE: message += " (DXGI_ERROR_GRAPHICS_VIDPN_SOURCE_IN_USE)"; break;
	case DXGI_ERROR_MORE_DATA: message += " (DXGI_ERROR_MORE_DATA)"; break;
	case DXGI_ERROR_NAME_ALREADY_EXISTS: message += " (DXGI_ERROR_NAME_ALREADY_EXISTS)"; break;
	case DXGI_ERROR_NONEXCLUSIVE: message += " (DXGI_ERROR_NONEXCLUSIVE)"; break;
	case DXGI_ERROR_NOT_CURRENTLY_AVAILABLE: message += " (DXGI_ERROR_NOT_CURRENTLY_AVAILABLE)"; break;
	case DXGI_ERROR_NOT_FOUND: message += " (DXGI_ERROR_NOT_FOUND)"; break;
	case DXGI_ERROR_RESTRICT_TO_OUTPUT_STALE: message += " (DXGI_ERROR_RESTRICT_TO_OUTPUT_STALE)"; break;
	case DXGI_ERROR_SDK_COMPONENT_MISSING: message += " (DXGI_ERROR_SDK_COMPONENT_MISSING)"; break;
	case DXGI_ERROR_SESSION_DISCONNECTED: message += " (DXGI_ERROR_SESSION_DISCONNECTED)"; break;
	case DXGI_ERROR_UNSUPPORTED: message += " (DXGI_ERROR_UNSUPPORTED)"; break;
	case DXGI_ERROR_WAIT_TIMEOUT: message += " (DXGI_ERROR_WAIT_TIMEOUT)"; break;
	case E_FAIL: message += " (E_FAIL)"; break;
	case E_INVALIDARG: message += " (E_INVALIDARG)"; break;
	case E_OUTOFMEMORY: message += " (E_OUTOFMEMORY)"; break;
	case E_NOTIMPL: message += " (E_NOTIMPL)"; break;
	default: message += " (HRESULT " + std::to_string(result) + ")"; break;
	}

	throw std::runtime_error(message);
}
