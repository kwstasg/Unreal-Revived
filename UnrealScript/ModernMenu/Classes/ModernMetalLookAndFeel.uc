// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived

class ModernMetalLookAndFeel extends UMenuMetalLookAndFeel;

const ResizeBorder = 4;
const ResizeCorner = 15;

function FrameHitTest FW_HitTest(UWindowFramedWindow W, float X, float Y)
{
	if ((X < ResizeCorner && Y < ResizeBorder)
		|| (X < ResizeBorder && Y < ResizeCorner))
		return HT_NW;
	if ((X > W.WinWidth - ResizeBorder && Y < ResizeCorner)
		|| (X > W.WinWidth - ResizeCorner && Y < ResizeBorder))
		return HT_NE;
	if ((X < ResizeCorner && Y > W.WinHeight - ResizeBorder)
		|| (X < ResizeBorder && Y > W.WinHeight - ResizeCorner))
		return HT_SW;
	if ((X > W.WinWidth - ResizeCorner && Y > W.WinHeight - ResizeBorder)
		|| (X > W.WinWidth - ResizeBorder && Y > W.WinHeight - ResizeCorner))
		return HT_SE;
	if (Y < ResizeBorder)
		return HT_N;
	if (Y > W.WinHeight - ResizeBorder)
		return HT_S;
	if (X < ResizeBorder)
		return HT_W;
	if (X > W.WinWidth - ResizeBorder)
		return HT_E;
	if (X >= ResizeBorder && X <= W.WinWidth - ResizeBorder && Y >= 3 && Y <= 14)
		return HT_TitleBar;
	return HT_None;
}
