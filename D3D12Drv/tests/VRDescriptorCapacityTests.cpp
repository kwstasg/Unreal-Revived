#include <d3d12.h>
#include <dxgi1_4.h>
#include <vector>
#include <utility>
#include <stdexcept>
#include <iostream>
#include "../ComPtr.h"
#include "../Descriptors.h"

void Check(bool OK, const char* Message)
{
	if (!OK) throw std::runtime_error(Message);
}

// Production allocation shapes: three scene RTVs, hit target, five postprocess
// images, and two targets for each of the four bloom levels.
void Scene(DescriptorHeap& Heap, std::vector<DescriptorSet>& Sets)
{
	Sets.push_back(Heap.Alloc(3));
	for (int i = 0; i < 14; ++i) Sets.push_back(Heap.Alloc(1));
}
void Release(std::vector<DescriptorSet>& Sets)
{
	for (auto& Set : Sets) Set.reset();
	Sets.clear();
}
void Exercise(ID3D12Device* Device, int Capacity, int Eyes)
{
	DescriptorHeap Heap(Device, Capacity, D3D12_DESCRIPTOR_HEAP_TYPE_RTV, D3D12_DESCRIPTOR_HEAP_FLAG_NONE);
	std::vector<DescriptorSet> Fixed, Active;
	Scene(Heap, Fixed);
	Fixed.push_back(Heap.Alloc(3)); // Desktop back buffers.
	Fixed.push_back(Heap.Alloc(6)); // Stereo UI swapchain.
	for (int Eye = 0; Eye < Eyes; ++Eye) Scene(Heap, Active);
	Active.push_back(Heap.Alloc(3));
	Active.push_back(Heap.Alloc(3));
	const int Steady = Heap.GetUsedCount();
	for (int Switch = 0; Switch < 200; ++Switch)
	{
		std::vector<DescriptorSet> Replacement;
		Replacement.push_back(Heap.Alloc(3));
		Replacement.push_back(Heap.Alloc(3));
		for (int Eye = 0; Eye < Eyes; ++Eye) Scene(Heap, Replacement);
		if (Switch % 3 == 0) // Failed replacement must retain the active pair.
			Release(Replacement);
		else
		{
			Active.swap(Replacement);
			Release(Replacement);
		}
		Check(Heap.GetUsedCount() == Steady, "Live switch leaked RTV descriptors");
		// UI quality allocates both eye slices before releasing its old swapchain.
		auto ReplacementUI = Heap.Alloc(6);
		ReplacementUI.reset();
		Check(Heap.GetUsedCount() == Steady, "HUD replacement leaked RTV descriptors");
	}
	Release(Active);
	Release(Fixed);
	Check(Heap.GetUsedCount() == 0, "Teardown leaked RTV descriptors");
}
int main()
{
	try
	{
		ComPtr<IDXGIFactory4> Factory;
		Check(SUCCEEDED(CreateDXGIFactory1(Factory.GetIID(), Factory.InitPtr())), "DXGI factory failed");
		ComPtr<IDXGIAdapter> Warp;
		Check(SUCCEEDED(Factory->EnumWarpAdapter(Warp.GetIID(), Warp.InitPtr())), "WARP unavailable");
		ComPtr<ID3D12Device> Device;
		Check(SUCCEEDED(D3D12CreateDevice(Warp.get(), D3D_FEATURE_LEVEL_11_0, Device.GetIID(), Device.InitPtr())), "D3D12 WARP failed");
		bool Reproduced = false;
		try { Exercise(Device.get(), 64, 1); }
		catch (const std::runtime_error&) { Reproduced = true; }
		Check(Reproduced, "Old capacity should reproduce the reported failure");
		Exercise(Device.get(), RenderTargetDescriptorCapacity, 1);
		Exercise(Device.get(), RenderTargetDescriptorCapacity, 2);
	}
	catch (const std::exception& Error) { std::cerr << Error.what() << '\n'; return 1; }
}
