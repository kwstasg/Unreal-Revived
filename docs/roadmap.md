# Roadmap

This roadmap records the intended order of the project's main future additions.
It is planning material only: none of the features below should be described as
implemented or supported until its acceptance criteria have been completed and
validated.

## 1. Seated PC VR through OpenXR

The first major addition is optional, seated-first PC VR through OpenXR. It
will preserve flat-screen play as the default and continue to use
`D3D12Drv.D3D12RenderDevice` rather than requiring players to select another
video driver.

The first milestone is defined in the
[seated PC VR plan](pc-vr-seated.md). Its intended scope includes true stereo,
seated 6DoF head tracking, head-gaze aiming, gamepad locomotion, smooth turning,
a delayed-following spatial HUD, spatial menus, and fade-based head collision.
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

