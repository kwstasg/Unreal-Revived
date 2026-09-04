# Supported controllers

Unreal Revived uses a pinned SDL3 Gamepad backend to translate modern gamepads
into Unreal's existing controller inputs. The table distinguishes controllers
tested directly with Unreal Revived from devices supported through SDL's
standard gamepad mappings.

## Compatibility overview

| Controller | Connection | Support status | Validation |
| --- | --- | --- | --- |
| Xbox Series controller | USB and Bluetooth | Manually validated | Gameplay, menus, both sticks, D-pad, face and shoulder buttons, stick clicks, independent triggers, disconnect and reconnect, transport switching, and held-input disconnect behavior were tested. |
| DualShock 4 v2 | USB and Bluetooth | Manually validated | Gameplay, menus, both sticks, D-pad, Cross, Circle, Square, Triangle, L1/R1, L2/R2, Share, Options, and stick clicks were tested without Steam or DS4Windows. |
| DualSense | SDL-mapped | Backend supported | SDL3 provides a standard gamepad mapping. Device-specific Unreal Revived validation has not yet been recorded. |
| Other SDL-mapped gamepads | Device dependent | Backend supported | Controllers recognized by SDL3 as standard gamepads use the same Unreal input mapping. Compatibility depends on the device and its SDL mapping. |

## Supported controls

| Input | In-game behavior |
| --- | --- |
| Left stick | Movement, strafing, and menu navigation. |
| Right stick | Looking, with independent sensitivity, dead-zone, and vertical-inversion settings. |
| D-pad | Menu navigation and configurable gameplay actions. |
| Face buttons | Menu activation and return plus configurable gameplay actions. |
| Shoulder buttons | Preferences tab switching and configurable gameplay actions. |
| Left and right triggers | Independent analog-to-button actions for gameplay bindings. |
| Stick clicks | Configurable gameplay actions; left-stick click is included in the shipped crouch defaults. |
| View or Share | Configurable through Unreal's existing joystick-key bindings. |
| Menu or Options | Opens and closes the in-game menu and remains reserved during binding capture. |

## Controller features

| Feature | Description |
| --- | --- |
| Automatic selection | Selects an available SDL-mapped controller automatically. |
| Adjustable dead zones | Provides independent 0-50% sliders for the left and right sticks, both with 25% defaults. |
| Adjustable sensitivity | Provides separate movement and look sensitivity controls with live percentage values and reset actions. |
| Frame-rate-independent gameplay | Keeps Xbox movement and look response consistent in validated tests at about 240 FPS and above 1000 FPS. |
| Menu navigation | Supports menu toggle, focus navigation, activation, return, tab switching, scrolling, combo boxes, slider reset, dialogs, and binding capture. |
| Flexible bindings | Allows up to three visible keyboard, mouse, or controller assignments per action. |
| Disconnect safety | Releases held buttons and neutralizes axes before fallback; Xbox disconnect tests showed no stuck movement or fire. |
| Mixed input | Keyboard and mouse remain usable alongside the active controller. |

## Fallback paths

| Path | Purpose |
| --- | --- |
| System XInput | Dynamically loaded fallback for compatible Xbox-style controllers. |
| WinMM | Legacy joystick fallback retained by the side-by-side input package. |
| Stock WinDrv | Original viewport and input package retained as a recovery choice. |

Controller support does not require Steam Input or DS4Windows for the manually
validated Xbox Series and DualShock 4 configurations. SDL controller mappings
can vary by operating system, connection type, firmware, and device revision.