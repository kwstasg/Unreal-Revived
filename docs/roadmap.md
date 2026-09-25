# Roadmap

This roadmap records the intended order of the project's main future additions.
Seated and standing VR are implemented with CV1 acceptance; the other-headset acceptance
boundary and current unfinished work are listed in [pending tasks](pending-tasks.md).
RTX and Vulkan remain plans, not implemented features.

## 1. PC VR through OpenXR

The first major addition, optional PC VR through OpenXR, is implemented.
Version 0.9.0 extends the seated baseline with standing play and automatic HUD
recovery, and adds Smooth, Instant Snap and Smooth Snap turning. It
preserves flat-screen play as the default and continues to use
`D3D12Drv.D3D12RenderDevice` rather than requiring players to select another
video driver.

The first milestone is defined in the
[seated PC VR plan](pc-vr-seated.md). Its intended scope includes true stereo,
seated 6DoF head tracking, head-gaze aiming, gamepad locomotion, selectable
smooth/snap turning, the accepted upright shared HUD/menu panel with explicit
recenter and automatic recovery, and fade-based head collision. The automatic
HUD needs no seated/standing option; full room-scale pawn movement remains separate.
Flat-screen mode must remain isolated from OpenXR initialization and VR runtime
costs.

## 2. RTX support

RTX support is the second major addition, after the seated PC VR milestone.
Its exact renderer features, hardware boundary, fallback behavior, and
acceptance tests must be defined before implementation begins. Existing D3D12
behavior and support for non-RTX hardware must remain explicit in that design.

## 3. Vulkan driver

A native Vulkan driver is the third major addition, after RTX support. Its
architecture, supported platforms, feature-parity target, packaging, recovery
behavior, and test matrix must be planned before implementation begins. The
existing Direct3D 12 renderer remains the supported primary renderer today.
