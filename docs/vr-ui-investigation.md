# VR UI investigation archive

This is a historical failure record, not implementation instructions. The
[accepted milestone and maintenance contract](vr-ui-recovery-design.md) is the
current authority. The user accepted the final result on 2026-09-10.

## Recovery history

Commit `9dc4802` alone did not reproduce the previously visible menu. Recovered
Git tree `f767139c` contained a visible but stretched/clipped menu and stable
slider anchors. Later working files diverged again: slider commands recentered
and menu/HUD geometry differed. Neither old snapshot is the final baseline.
The accepted source/binaries were preserved at
`local/backups/vr-ui-accepted-milestone-20260910-212645/` before final cleanup.

## Failed approaches and lessons

| Approach | Outcome and lesson |
| --- | --- |
| Logo recomposition | At one point only a logo remained visible. Do not redesign artwork while fixing menu bounds. |
| Wider swapchain plus scaling, pose and painting rewrites | Menu disappeared or became a fragment; simultaneous coordinate changes prevented diagnosis. |
| Root Canvas shrink and guessed offsets | Created a 70%-width upper-left menu and incomplete input conversion. Use the existing desktop canvas consistently. |
| Per-layout panel size/position | Opening menus changed width, vertical position and anchor. Use one panel for all UI. |
| Recenter on slider changes | Every notification sampled the moving head again and made the menu jump. Keep the reference anchor fixed. |
| Width proportional to distance | Kept angular size constant and hid much of the visible distance effect. Physical size depends only on scale. |
| Flip/depth/alpha/checkerboard/per-eye guesses | Did not solve the original width problem. Removed; no evidence justified composition changes. |
| Forced Preferences and synthetic input | Focus and UWindow state made results ambiguous. Not headset acceptance evidence. |
| Ordinary desktop mirror as proof | It did not reliably show the submitted OpenXR layer. Require headset validation. |

## What actually fixed it

The renderer built UI vertices with symmetric game FOV but projected them with
asymmetric headset FOV. With the saved right-eye angles (-0.621, +0.768 radians)
and a 90-degree game FOV, source horizontal bounds [0,1] mapped to approximately
[-0.1693,1.0203], and the center mapped to 0.4255. These are calculated projection
coordinates, not measurements of the menu's child bounds.

Selecting matching canvas projection during the VR UI pass made the full menu
visible. Removing script-only scaling/offsets then restored desktop layout.
Sharing one upright panel, removing implicit recenter, and decoupling distance
from physical scale completed the accepted result. Projection, layout and pose
were corrected in separate builds with user feedback between them.

The old experiment code, per-layout state and partial input transforms have been
removed. Local recovery evidence stays ignored; it must never be packaged or
mistaken for current implementation.
