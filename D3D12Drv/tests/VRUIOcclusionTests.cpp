#include "../FileResource.h"
#include <d3d11.h>
#include <d3dcompiler.h>
#include <wrl/client.h>
#include <array>
#include <cmath>
#include <cstdlib>
#include <iostream>

using Microsoft::WRL::ComPtr;

void Check(bool Passed, const char* Message)
{
	if (!Passed) { std::cerr << Message << '\n'; std::exit(1); }
}

ComPtr<ID3DBlob> Compile(const char* Name, const char* Profile, const D3D_SHADER_MACRO* Defines = nullptr)
{
	const auto Source = FileResource::readAllText(Name);
	ComPtr<ID3DBlob> Code, Errors;
	const HRESULT Result = D3DCompile(Source.data(), Source.size(), Name, Defines, nullptr,
		"main", Profile, D3DCOMPILE_ENABLE_STRICTNESS, 0, &Code, &Errors);
	if (Errors) std::cerr << static_cast<const char*>(Errors->GetBufferPointer());
	Check(SUCCEEDED(Result), "production shader compilation");
	return Code;
}

void TestSceneCoverage(ID3D11Device* Device, ID3D11DeviceContext* Context)
{
	const char* Source = R"(
		cbuffer Parameters { uint Flags; float3 Padding; };
		struct Output
		{
			float4 pos : SV_Position;
			nointerpolation uint flags : PixelFlags;
			float2 texCoord : PixelTexCoordOne;
			float2 texCoord2 : PixelTexCoordTwo;
			float2 texCoord3 : PixelTexCoordThree;
			float2 texCoord4 : PixelTexCoordFour;
			float4 color : PixelColor;
			nointerpolation uint hitIndex : PixelHitIndex;
		};
		Output main(uint VertexIndex : SV_VertexID)
		{
			Output Result = (Output)0;
			float2 Corner = float2((VertexIndex << 1) & 2, VertexIndex & 2);
			Result.pos = float4(Corner * 2 - 1, 0, 1);
			Result.flags = Flags;
			Result.color = 1;
			return Result;
		}
	)";
	ComPtr<ID3DBlob> VertexCode;
	Check(SUCCEEDED(D3DCompile(Source, std::char_traits<char>::length(Source), "CoverageFixture", nullptr, nullptr,
		"main", "vs_5_0", D3DCOMPILE_ENABLE_STRICTNESS, 0, &VertexCode, nullptr)), "coverage fixture shader");
	ComPtr<ID3D11VertexShader> VertexShader;
	Check(SUCCEEDED(Device->CreateVertexShader(VertexCode->GetBufferPointer(), VertexCode->GetBufferSize(), nullptr, &VertexShader)), "coverage vertex shader");
	const D3D_SHADER_MACRO Masked[] = { {"ALPHATEST", "1"}, {nullptr, nullptr} };
	const auto PixelCode = Compile("shaders/Scene.frag", "ps_5_0");
	const auto MaskedCode = Compile("shaders/Scene.frag", "ps_5_0", Masked);
	ComPtr<ID3D11PixelShader> PixelShader, MaskedShader;
	Check(SUCCEEDED(Device->CreatePixelShader(PixelCode->GetBufferPointer(), PixelCode->GetBufferSize(), nullptr, &PixelShader)), "coverage pixel shader");
	Check(SUCCEEDED(Device->CreatePixelShader(MaskedCode->GetBufferPointer(), MaskedCode->GetBufferSize(), nullptr, &MaskedShader)), "masked coverage shader");
	D3D11_BUFFER_DESC BufferDesc = {};
	BufferDesc.ByteWidth = 16;
	BufferDesc.BindFlags = D3D11_BIND_CONSTANT_BUFFER;
	ComPtr<ID3D11Buffer> Constants;
	Check(SUCCEEDED(Device->CreateBuffer(&BufferDesc, nullptr, &Constants)), "coverage constants");
	D3D11_TEXTURE2D_DESC TextureDesc = {};
	TextureDesc.Width = TextureDesc.Height = TextureDesc.MipLevels = TextureDesc.ArraySize = TextureDesc.SampleDesc.Count = 1;
	TextureDesc.Format = DXGI_FORMAT_R32G32B32A32_FLOAT;
	TextureDesc.BindFlags = D3D11_BIND_SHADER_RESOURCE;
	ComPtr<ID3D11Texture2D> Skin, Target, Readback;
	ComPtr<ID3D11ShaderResourceView> SkinView;
	ComPtr<ID3D11RenderTargetView> TargetView;
	Check(SUCCEEDED(Device->CreateTexture2D(&TextureDesc, nullptr, &Skin)), "coverage skin texture");
	Check(SUCCEEDED(Device->CreateShaderResourceView(Skin.Get(), nullptr, &SkinView)), "coverage skin view");
	TextureDesc.BindFlags = D3D11_BIND_RENDER_TARGET;
	Check(SUCCEEDED(Device->CreateTexture2D(&TextureDesc, nullptr, &Target)), "coverage target");
	Check(SUCCEEDED(Device->CreateRenderTargetView(Target.Get(), nullptr, &TargetView)), "coverage target view");
	TextureDesc.BindFlags = 0;
	TextureDesc.Usage = D3D11_USAGE_STAGING;
	TextureDesc.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
	Check(SUCCEEDED(Device->CreateTexture2D(&TextureDesc, nullptr, &Readback)), "coverage readback");
	Context->IASetInputLayout(nullptr);
	Context->VSSetShader(VertexShader.Get(), nullptr, 0);
	Context->VSSetConstantBuffers(0, 1, Constants.GetAddressOf());
	Context->PSSetShaderResources(0, 1, SkinView.GetAddressOf());
	ID3D11RenderTargetView* Targets[] = {nullptr, nullptr, TargetView.Get()};
	Context->OMSetRenderTargets(3, Targets, nullptr);
	auto Coverage = [&](UINT Flags, std::array<float, 4> Texel, bool AlphaTest)
	{
		const std::array<UINT, 4> Values = {Flags, 0, 0, 0};
		const float Clear[] = {0, 0, 0, 0};
		Context->UpdateSubresource(Constants.Get(), 0, nullptr, Values.data(), 0, 0);
		Context->UpdateSubresource(Skin.Get(), 0, nullptr, Texel.data(), sizeof(Texel), 0);
		Context->ClearRenderTargetView(TargetView.Get(), Clear);
		Context->PSSetShader(AlphaTest ? MaskedShader.Get() : PixelShader.Get(), nullptr, 0);
		Context->Draw(3, 0);
		Context->CopyResource(Readback.Get(), Target.Get());
		D3D11_MAPPED_SUBRESOURCE Mapped = {};
		Check(SUCCEEDED(Context->Map(Readback.Get(), 0, D3D11_MAP_READ, 0, &Mapped)), "coverage pixel readback");
		const float* Pixel = static_cast<const float*>(Mapped.pData);
		const std::array<float, 2> Result = {Pixel[0], Pixel[1]};
		Context->Unmap(Readback.Get(), 0);
		return Result;
	};
	constexpr UINT Weapon = 1u << 10, Opaque = 1u << 11, UI = 1u << 7;
	Check(Coverage(Weapon | Opaque, {0,0,0,0}, false)[1] == 1, "opaque black zero-alpha skin fully blocks HUD");
	Check(Coverage(Weapon | Opaque | UI, {1,1,1,0}, false)[0] == 0, "opaque weapon correction leaves ordinary UI alpha unchanged");
	Check(Coverage(Weapon | Opaque, {1,1,1,0}, true)[1] == 0, "masked texture holes remain discarded");
	Check(Coverage(Weapon | Opaque, {1,1,1,0.75f}, true)[1] == 1, "surviving masked texels fully block HUD");
	Check(std::fabs(Coverage(Weapon, {1,1,1,0.25f}, false)[1] - 0.25f) < 0.001f, "alpha-blended weapon retains fractional coverage");
	Check(Coverage(Weapon | (1u << 8), {0,0,0,1}, false)[1] == 0, "black translucent effect remains transparent");
	Check(Coverage(Weapon | (1u << 9), {0.5f,0.5f,0.5f,1}, false)[1] < 0.02f, "neutral modulated effect remains nearly transparent");
}

int main()
{
	const D3D_SHADER_MACRO Defines[] = { {"OPENXR_UI_LAYER", "1"}, {"GAMMA_MODE_D3D9", "1"}, {nullptr, nullptr} };
	const D3D_SHADER_MACRO Masked[] = { {"ALPHATEST", "1"}, {nullptr, nullptr} };
	Compile("shaders/Scene.frag", "ps_5_0");
	Compile("shaders/Scene.frag", "ps_5_0", Masked);
	const auto VertexCode = Compile("shaders/PPStep.vert", "vs_5_0");
	const auto PixelCode = Compile("shaders/Present.frag", "ps_5_0", Defines);
	ComPtr<ID3D11Device> Device;
	ComPtr<ID3D11DeviceContext> Context;
	Check(SUCCEEDED(D3D11CreateDevice(nullptr, D3D_DRIVER_TYPE_WARP, nullptr, 0, nullptr, 0,
		D3D11_SDK_VERSION, &Device, nullptr, &Context)), "WARP device creation");
	ComPtr<ID3D11VertexShader> VertexShader;
	ComPtr<ID3D11PixelShader> PixelShader;
	Check(SUCCEEDED(Device->CreateVertexShader(VertexCode->GetBufferPointer(), VertexCode->GetBufferSize(), nullptr, &VertexShader)), "vertex shader");
	Check(SUCCEEDED(Device->CreatePixelShader(PixelCode->GetBufferPointer(), PixelCode->GetBufferSize(), nullptr, &PixelShader)), "pixel shader");
	const D3D11_INPUT_ELEMENT_DESC Element = {"AttrPos", 0, DXGI_FORMAT_R32G32_FLOAT, 0, 0, D3D11_INPUT_PER_VERTEX_DATA, 0};
	ComPtr<ID3D11InputLayout> Layout;
	Check(SUCCEEDED(Device->CreateInputLayout(&Element, 1, VertexCode->GetBufferPointer(), VertexCode->GetBufferSize(), &Layout)), "input layout");
	const float Vertices[] = {-1,-1, -1,1, 1,1, -1,-1, 1,1, 1,-1};
	D3D11_BUFFER_DESC BufferDesc = {};
	BufferDesc.ByteWidth = sizeof(Vertices);
	BufferDesc.BindFlags = D3D11_BIND_VERTEX_BUFFER;
	D3D11_SUBRESOURCE_DATA VertexData = {Vertices, 0, 0};
	ComPtr<ID3D11Buffer> VertexBuffer, Constants;
	Check(SUCCEEDED(Device->CreateBuffer(&BufferDesc, &VertexData, &VertexBuffer)), "vertex buffer");
	BufferDesc.ByteWidth = 36 * sizeof(float);
	BufferDesc.BindFlags = D3D11_BIND_CONSTANT_BUFFER;
	Check(SUCCEEDED(Device->CreateBuffer(&BufferDesc, nullptr, &Constants)), "constant buffer");
	D3D11_TEXTURE2D_DESC TextureDesc = {};
	TextureDesc.Width = TextureDesc.Height = TextureDesc.MipLevels = TextureDesc.ArraySize = TextureDesc.SampleDesc.Count = 1;
	TextureDesc.Format = DXGI_FORMAT_R32G32B32A32_FLOAT;
	TextureDesc.BindFlags = D3D11_BIND_SHADER_RESOURCE;
	const float UI[] = {0.25f, 0.5f, 0.75f, 0.8f};
	D3D11_SUBRESOURCE_DATA UIData = {UI, sizeof(UI), 0};
	ComPtr<ID3D11Texture2D> UITexture, Target, Readback, MaskTexture;
	ComPtr<ID3D11ShaderResourceView> UIView, MaskView;
	Check(SUCCEEDED(Device->CreateTexture2D(&TextureDesc, &UIData, &UITexture)), "UI texture");
	Check(SUCCEEDED(Device->CreateShaderResourceView(UITexture.Get(), nullptr, &UIView)), "UI view");
	TextureDesc.BindFlags = D3D11_BIND_RENDER_TARGET;
	Check(SUCCEEDED(Device->CreateTexture2D(&TextureDesc, nullptr, &Target)), "render target");
	ComPtr<ID3D11RenderTargetView> TargetView;
	Check(SUCCEEDED(Device->CreateRenderTargetView(Target.Get(), nullptr, &TargetView)), "target view");
	TextureDesc.BindFlags = 0;
	TextureDesc.Usage = D3D11_USAGE_STAGING;
	TextureDesc.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
	Check(SUCCEEDED(Device->CreateTexture2D(&TextureDesc, nullptr, &Readback)), "readback texture");
	TextureDesc.Width = TextureDesc.Height = 8;
	TextureDesc.Format = DXGI_FORMAT_R8G8_UNORM;
	TextureDesc.BindFlags = D3D11_BIND_SHADER_RESOURCE;
	TextureDesc.Usage = D3D11_USAGE_DEFAULT;
	TextureDesc.CPUAccessFlags = 0;
	Check(SUCCEEDED(Device->CreateTexture2D(&TextureDesc, nullptr, &MaskTexture)), "mask texture");
	Check(SUCCEEDED(Device->CreateShaderResourceView(MaskTexture.Get(), nullptr, &MaskView)), "mask view");
	D3D11_SAMPLER_DESC SamplerDesc = {};
	SamplerDesc.Filter = D3D11_FILTER_MIN_MAG_MIP_LINEAR;
	SamplerDesc.AddressU = SamplerDesc.AddressV = SamplerDesc.AddressW = D3D11_TEXTURE_ADDRESS_CLAMP;
	SamplerDesc.MaxLOD = D3D11_FLOAT32_MAX;
	ComPtr<ID3D11SamplerState> Sampler;
	Check(SUCCEEDED(Device->CreateSamplerState(&SamplerDesc, &Sampler)), "sampler");
	D3D11_RASTERIZER_DESC RasterDesc = {};
	RasterDesc.FillMode = D3D11_FILL_SOLID;
	RasterDesc.CullMode = D3D11_CULL_NONE;
	ComPtr<ID3D11RasterizerState> Raster;
	Check(SUCCEEDED(Device->CreateRasterizerState(&RasterDesc, &Raster)), "rasterizer");
	Context->RSSetState(Raster.Get());
	D3D11_VIEWPORT Viewport = {0,0,1,1,0,1};
	Context->RSSetViewports(1, &Viewport);
	Context->OMSetRenderTargets(1, TargetView.GetAddressOf(), nullptr);
	Context->IASetInputLayout(Layout.Get());
	Context->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
	const UINT Stride = 2 * sizeof(float), Offset = 0;
	Context->IASetVertexBuffers(0, 1, VertexBuffer.GetAddressOf(), &Stride, &Offset);
	Context->VSSetShader(VertexShader.Get(), nullptr, 0);
	Context->PSSetShader(PixelShader.Get(), nullptr, 0);
	Context->PSSetConstantBuffers(0, 1, Constants.GetAddressOf());
	ID3D11ShaderResourceView* Views[] = {UIView.Get(), UIView.Get(), UIView.Get(), MaskView.Get(), UIView.Get()};
	Context->PSSetShaderResources(0, 5, Views);
	ID3D11SamplerState* Samplers[] = {Sampler.Get(), Sampler.Get()};
	Context->PSSetSamplers(0, 2, Samplers);
	std::array<float, 36> Parameters = {};
	Parameters[0] = Parameters[1] = 1;
	Parameters[4] = Parameters[5] = Parameters[6] = 1;
	Parameters[18] = -1;
	Parameters[19] = 1;
	Parameters[28] = Parameters[30] = -1;
	Parameters[29] = Parameters[31] = 1;
	std::array<unsigned char, 128> Mask = {};
	for (int Row = 0; Row < 8; Row++)
		for (int Column = 0; Column < 8; Column++)
		{
			Mask[(Row * 8 + Column) * 2] = 255;
			Mask[(Row * 8 + Column) * 2 + 1] = Row >= 4 && Column >= 4 ? 255 : 0;
		}
	Context->UpdateSubresource(MaskTexture.Get(), 0, nullptr, Mask.data(), 16, 0);
	auto Render = [&](float OriginX, float OriginY, float Depth)
	{
		Parameters[16] = OriginX;
		Parameters[17] = OriginY;
		Parameters[18] = Depth;
		Context->UpdateSubresource(Constants.Get(), 0, nullptr, Parameters.data(), 0, 0);
		Context->Draw(6, 0);
		Context->CopyResource(Readback.Get(), Target.Get());
		D3D11_MAPPED_SUBRESOURCE Mapped = {};
		Check(SUCCEEDED(Context->Map(Readback.Get(), 0, D3D11_MAP_READ, 0, &Mapped)), "read rendered pixel");
		const float* Pixel = static_cast<const float*>(Mapped.pData);
		const std::array<float, 4> Result = {Pixel[0], Pixel[1], Pixel[2], Pixel[3]};
		Context->Unmap(Readback.Get(), 0);
		return Result;
	};
	const auto Visible = Render(-0.5f, 0.5f, -1);
	Check(std::fabs(Visible[3] - 0.8f) < 0.001f, "ordinary UI coverage must not occlude the panel");
	const auto Hidden = Render(0.5f, 0.5f, -1);
	Check(Hidden[0] == 0 && Hidden[1] == 0 && Hidden[2] == 0 && Hidden[3] == 0, "weapon coverage removes premultiplied color and alpha");
	Check(Render(0.5f, -0.5f, -1) == Visible, "positive-up eye coordinates use the flipped scene mask");
	Check(Render(3, 0.5f, -1) == Visible, "out-of-frustum panel does not sample clamped mask edges");
	Check(Render(0.5f, 0.5f, 1) == Visible, "panel behind the eye is not projected into the mask");
	Parameters[28] = -3;
	Parameters[29] = 1;
	Check(Render(-0.5f, 0.5f, -1)[3] == 0, "asymmetric eye FOV changes mask lookup");
	for (size_t Index = 1; Index < Mask.size(); Index += 2) Mask[Index] = 128;
	Context->UpdateSubresource(MaskTexture.Get(), 0, nullptr, Mask.data(), 16, 0);
	const auto Partial = Render(0, 0, -1);
	for (size_t Channel = 0; Channel < 4; Channel++)
		Check(std::fabs(Partial[Channel] - Visible[Channel] * (127.0f / 255.0f)) < 0.001f, "partial coverage preserves premultiplied color");
	// Render the actual world presentation shader at chosen per-eye UVs. The
	// same head-relative ray must receive the same fade despite cant/asymmetry.
	const D3D_SHADER_MACRO WorldDefines[] = { {"GAMMA_MODE_D3D9", "1"}, {nullptr, nullptr} };
	const auto WorldCode = Compile("shaders/Present.frag", "ps_5_0", WorldDefines);
	ComPtr<ID3D11PixelShader> WorldShader;
	Check(SUCCEEDED(Device->CreatePixelShader(WorldCode->GetBufferPointer(), WorldCode->GetBufferSize(), nullptr, &WorldShader)), "world vignette shader");
	const char* RayVertexSource = R"(
		cbuffer SamplePoint : register(b1) { float2 UV; float2 Padding; };
		struct Output { float4 pos : SV_Position; float2 uv : PixelTexCoord; };
		Output main(float2 pos : AttrPos) {
			Output o; o.pos = float4(pos,0,1); o.uv = UV; return o;
		}
	)";
	ComPtr<ID3DBlob> RayVertexCode;
	Check(SUCCEEDED(D3DCompile(RayVertexSource, std::char_traits<char>::length(RayVertexSource), "RaySample", nullptr, nullptr,
		"main", "vs_5_0", D3DCOMPILE_ENABLE_STRICTNESS, 0, &RayVertexCode, nullptr)), "ray sample vertex code");
	ComPtr<ID3D11VertexShader> RayVertexShader;
	Check(SUCCEEDED(Device->CreateVertexShader(RayVertexCode->GetBufferPointer(), RayVertexCode->GetBufferSize(), nullptr, &RayVertexShader)), "ray sample vertex shader");
	BufferDesc.ByteWidth = 16;
	ComPtr<ID3D11Buffer> RayUV;
	Check(SUCCEEDED(Device->CreateBuffer(&BufferDesc, nullptr, &RayUV)), "ray UV constants");
	Context->VSSetConstantBuffers(1, 1, RayUV.GetAddressOf());
	Context->VSSetShader(RayVertexShader.Get(), nullptr, 0);
	Context->PSSetShader(WorldShader.Get(), nullptr, 0);
	Mask.fill(0);
	Context->UpdateSubresource(MaskTexture.Get(), 0, nullptr, Mask.data(), 16, 0);
	Parameters[13] = 1; // world-only effects, with UI excluded
	auto SampleUV = [&](float U, float V) {
		const float Point[] = {U,V,0,0};
		Context->UpdateSubresource(RayUV.Get(), 0, nullptr, Point, 0, 0);
		return Render(0,0,-1)[0];
	};
	auto SampleRay = [&](float X, float Y, float Z, float Cant, bool RightEye, bool PitchEye = false) {
		Parameters[28] = RightEye ? -2.2f : -2.6f;
		Parameters[29] = RightEye ? 2.6f : 2.2f;
		Parameters[30] = RightEye ? -1.4f : -1.8f;
		Parameters[31] = RightEye ? 1.8f : 1.4f;
		Parameters[32] = PitchEye ? std::sin(Cant/2) : 0;
		Parameters[34] = 0;
		Parameters[33] = PitchEye ? 0 : std::sin(Cant/2);
		Parameters[35] = std::cos(Cant/2);
		// Inverse eye rotation converts the shared head ray into this eye.
		const float EyeX = PitchEye ? X : std::cos(Cant)*X - std::sin(Cant)*Z;
		const float EyeY = PitchEye ? std::cos(Cant)*Y + std::sin(Cant)*Z : Y;
		const float EyeZ = PitchEye ? -std::sin(Cant)*Y + std::cos(Cant)*Z : std::sin(Cant)*X + std::cos(Cant)*Z;
		const float U = (EyeX/-EyeZ - Parameters[28])/(Parameters[29]-Parameters[28]);
		const float V = (EyeY/-EyeZ - Parameters[30])/(Parameters[31]-Parameters[30]);
		Check(U >= 0 && U <= 1 && V >= 0 && V <= 1, "sample ray lies in both eye frustums");
		return SampleUV(U,V);
	};
	Parameters[9] = 0;
	const float Unfiltered = SampleRay(0,0,-1,0,false);
	Parameters[9] = 1;
	Check(std::abs(SampleRay(0,0,-1,-0.2f,false)-Unfiltered) < 0.005f, "head-forward stays clear with asymmetric canted eyes");
	for (float Angle : {0.0f, 0.5235988f, 0.6108652f, 0.6981317f, 0.7853982f})
		for (float Sign : {-1.0f,1.0f})
			for (bool Vertical : {false,true}) {
				const float X = Vertical ? 0 : Sign*std::sin(Angle);
				const float Y = Vertical ? Sign*std::sin(Angle) : 0;
				const float Z = -std::cos(Angle);
				const float L = SampleRay(X,Y,Z,-0.2f,false);
				const float R = SampleRay(X,Y,Z,0.2f,true);
				Check(std::abs(L-R) < 0.005f, "same angular ray fades equally in both eyes");
				if (Angle > 0.7f) Check(L < Unfiltered*0.6f, "maximum vignette is visibly darker at 45 degrees");
			}
	Check(std::abs(SampleRay(0,0.5f,-0.8660254f,-0.15f,false,true) -
		SampleRay(0,0.5f,-0.8660254f,0.15f,true,true)) < 0.005f, "vertical cant respects presentation Y convention within the fade");
	Parameters[9] = 0.5f;
	const float FortyDegrees = 0.6981317f;
	const float MidFade = SampleRay(std::sin(FortyDegrees),0,-std::cos(FortyDegrees),0,false);
	Check(MidFade < Unfiltered*0.8f && MidFade > Unfiltered*0.7f, "half strength visibly dims the 40 degree periphery");
	const float Gentle = SampleRay(0.7071068f,0,-0.7071068f,0,true);
	Parameters[9] = 1;
	Check(std::abs(SampleRay(std::sin(0.34906585f),0,-std::cos(0.34906585f),0,false)-Unfiltered) < 0.005f, "maximum strength keeps the central 20 degrees clear");
	Check(SampleRay(std::sin(0.6108652f),0,-std::cos(0.6108652f),0,false) < Unfiltered*0.2f, "maximum strength is prominent at 35 degrees");
	Check(SampleRay(std::sin(FortyDegrees),0,-std::cos(FortyDegrees),0,false) < 0.005f, "maximum strength reaches black at 40 degrees");
	Check(SampleRay(0.7071068f,0,-0.7071068f,0,true) < Gentle, "one slider increases angular coverage and opacity");
	// Existing UI-mask exclusion must still win over the VR world fade.
	for (size_t Index = 0; Index < Mask.size(); Index += 2) Mask[Index] = 255;
	Context->UpdateSubresource(MaskTexture.Get(), 0, nullptr, Mask.data(), 16, 0);
	Check(std::abs(SampleRay(0.7071068f,0,-0.7071068f,0,true)-Unfiltered) < 0.005f, "vignette does not darken UI pixels");
	Mask.fill(0);
	Context->UpdateSubresource(MaskTexture.Get(), 0, nullptr, Mask.data(), 16, 0);
	Parameters[32] = Parameters[33] = Parameters[34] = Parameters[35] = 0;
	const float Desktop = SampleUV(0.85f,0.5f);
	const float T = (0.35f-0.30f)/(0.52f-0.30f);
	Check(std::abs(Desktop - 0.25f*(1-T*T*(3-2*T))) < 0.005f, "desktop vignette keeps accepted falloff");
	Context->VSSetShader(VertexShader.Get(), nullptr, 0);

	// Reproduce the VR UI scissor leaking into the production bloom shader.
	const auto BloomCode = Compile("shaders/BloomCombine.frag", "ps_5_0");
	ComPtr<ID3D11PixelShader> BloomShader;
	Check(SUCCEEDED(Device->CreatePixelShader(BloomCode->GetBufferPointer(), BloomCode->GetBufferSize(), nullptr, &BloomShader)), "bloom shader");
	Context->PSSetShader(BloomShader.Get(), nullptr, 0);
	Context->PSSetShaderResources(0, 1, UIView.GetAddressOf());
	RasterDesc.ScissorEnable = TRUE;
	Check(SUCCEEDED(Device->CreateRasterizerState(&RasterDesc, &Raster)), "bloom scissor rasterizer");
	Context->RSSetState(Raster.Get());
	const int Sizes[][2] = {{1280,1024},{1008,1200},{1344,1600},{1680,2000},{2016,2400},{2688,3200}};
	for (const auto& Size : Sizes)
	{
		TextureDesc.Width = Size[0]; TextureDesc.Height = Size[1];
		TextureDesc.Format = DXGI_FORMAT_R32G32B32A32_FLOAT;
		TextureDesc.BindFlags = D3D11_BIND_RENDER_TARGET;
		ComPtr<ID3D11Texture2D> BloomTarget;
		ComPtr<ID3D11RenderTargetView> BloomView;
		Check(SUCCEEDED(Device->CreateTexture2D(&TextureDesc, nullptr, &BloomTarget)), "bloom target");
		Check(SUCCEEDED(Device->CreateRenderTargetView(BloomTarget.Get(), nullptr, &BloomView)), "bloom RTV");
		Context->OMSetRenderTargets(1, BloomView.GetAddressOf(), nullptr);
		Viewport.Width = float(Size[0]); Viewport.Height = float(Size[1]);
		Context->RSSetViewports(1, &Viewport);
		for (int Fixed = 0; Fixed < 2; ++Fixed)
		{
			const float Clear[] = {0,0,0,0};
			Context->ClearRenderTargetView(BloomView.Get(), Clear);
			const D3D11_RECT Rect = {0,0,Fixed ? Size[0] : 1024,Fixed ? Size[1] : 1024};
			Context->RSSetScissorRects(1, &Rect);
			Context->Draw(6, 0);
			const D3D11_BOX Corner = {UINT(Size[0]-1),UINT(Size[1]-1),0,UINT(Size[0]),UINT(Size[1]),1};
			Context->CopySubresourceRegion(Readback.Get(), 0, 0, 0, 0, BloomTarget.Get(), 0, &Corner);
			D3D11_MAPPED_SUBRESOURCE Data = {};
			Check(SUCCEEDED(Context->Map(Readback.Get(), 0, D3D11_MAP_READ, 0, &Data)), "bloom readback");
			const float Red = *static_cast<const float*>(Data.pData);
			Context->Unmap(Readback.Get(), 0);
			Check(std::fabs(Red - (Fixed ? 0.25f : 0.0f)) < 0.001f,
				"full-resolution bloom reaches the eye edge; inherited UI bounds clip it");
		}
	}
	TestSceneCoverage(Device.Get(), Context.Get());
	std::cout << "Production VR UI shader occlusion, eye mapping, material coverage and alpha checks passed\n";
}
