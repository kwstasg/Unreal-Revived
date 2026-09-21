# Per-weapon VR size and position

Edit `local/game/System64/ModernVRWeapons.ini` (or the installed game's
`System64/ModernVRWeapons.ini`), save it, then enter `ReloadVRWeapons` in the game
console. Both aiming modes update immediately; no map reload or restart is needed.
The command confirms success on screen. A missing/unreadable file or missing
settings section retains the current settings. Removing a profile restores
its inherited or neutral values. Reloading does not write to the INI.
Successful reloads reuse the existing tuning object and clear its lookup cache;
disk reads occur only when explicitly reloading, not periodically during play.

Optionally bind a spare key once, for example `set input F8 ReloadVRWeapons`.
This replaces any existing F8 binding. Then save the INI and press F8 to test.
An already running game needs one restart to load the build containing this command.
Each weapon's `Profiles=` line has one shared scale and separate gaze/motion offsets.
Builds and installer updates seed the file only if missing, preserving your edits.
The source template is `UnrealScript/ModernMenu/Config/ModernVRWeapons.ini`.

| Setting | Effect |
| --- | --- |
| `Scale` | Multiplies the physical weapon size in both aiming modes |
| `GazeOffsetCM` | Moves the gaze weapon in view-local axes |
| `MotionOffsetCM` | Moves the tracked weapon and muzzle in controller aim-local axes |

Scale `1.0` uses the shared physical baseline, `1.2` enlarges by 20%, and `0.8`
shrinks by 20%. Missing or non-positive scales use `1.0`. Both modes normalize
the same first-person mesh to the same weapon-family physical length and apply
the same `Scale`, producing equal model sizes at the same world scale.
Offsets remain independent; there is no automatic
averaging or matching option. Distance from the eyes can change apparent size
even when the physical model sizes are identical.

The runtime INI is the source of truth for personal tuning. The shipped seed
contains the 14 owner-accepted profiles from the 2026-09-21 milestone, including
Eightball gaze Y=20. Existing runtime files are preserved on build/install.
Neutral profiles still use the physical baseline with independent placement.

## Accepted milestone

On 2026-09-21 the owner confirmed that everything in the completed weapon work
looked correct in the headset, after checking the final Eightball correction.
The accepted scope is shared gaze/motion physical sizing, calibrated placement,
right/left/center gaze handling, primary/alternate muzzle and aiming alignment,
RazorJack's rotating alternate-fire muzzle and weapon/HUD overlap behavior.
This acceptance supersedes earlier pending-headset notes for these changes.
Preserve it as the known-good weapon baseline for future work.

- Annotated local Git tag: `vr-weapons-validated-2026-09-21`.
- Shipped calibration: `UnrealScript/ModernMenu/Config/ModernVRWeapons.ini`.

The repository is the milestone record. At the owner's request, the additional
runtime backup and source bundle were removed; the original tag annotation's
backup reference is historical, not an available recovery artifact.

To recover the source without disturbing ongoing work, create a separate
worktree with `git worktree add --detach ../Unreal-Revived-vr-baseline vr-weapons-validated-2026-09-21`.
Follow [the build instructions](building.md) to provision a disposable runtime
and rebuild from that source. Git retains source and shipped calibration, not
game assets, generated binaries, saves or private runtime profiles. Do not
overwrite the original installation or reset an active working tree.

This is a local milestone, not a published release or installer.
Remote-client VR firing, full campaign/mod compatibility,
other headset/controller combinations and the recurring F8/HMD stutter report
are not declared resolved by this weapon acceptance.

Older profiles used `GazeScale` and `MotionScale`. Replace these with `Scale`;
the old field names are no longer read. If they were equal, retain that value.
If different, choose the desired common size; using the old `MotionScale`
preserves the tracked weapon size, including profiles from before the shared
baseline. There is no automatic conversion of other installed/custom profiles.
The current disposable runtime and source template have been converted.
Restart once after deploying the updated package; later profile edits still
apply through `ReloadVRWeapons`.

## Weapon compatibility

The shared baseline covers stock weapons and Return to Na Pali's CARifle,
GrenadeLauncher and RocketLauncher. Existing physical lengths are retained.
Weapon subclasses inherit their family length; unrelated custom classes use
a generic 65 cm maximum mesh dimension until explicitly calibrated. A changed
first-person mesh or view scale selects a fresh cached geometry entry.

The regression verifies neutral and configured shared-scale equality for all
14 stock/UPak profile classes, Old DispersionPistol/Old AutoMag, and a custom
weapon fixture that swaps its mesh and view scale. This exercises replacement
weapons, not every mutator or a complete Return to Na Pali playthrough.
Mutators that use standard weapon meshes/rendering benefit from the shared
calculation; custom renderers, extra model attachments, unusual animations or
firing implementations may need adapters. Both aiming modes now use calibrated
stock muzzle references for all 14 profile families, including hitscan weapons.
Replacement meshes retain the bounds-based estimate; this is not universal
barrel/pivot calibration. Multiplayer remains unverified.

## Placement and inheritance

Offsets are **centimetres**, relative to the existing calibrated position:
X is forward, Y is right, Z is up. Negative values move backward, left, or down.
They follow the weapon/view orientation and the VR world-size setting.
`GazeOffsetCM.Y` is a right-hand calibration: right hand uses the saved value,
left hand negates it, and center uses zero added Y. Gaze X/Z and scale stay the
same. Drawing and gaze muzzle calculation use the same handed adjustment.
Center normally retains stock weapon placement and roll, including authored
lateral offsets or mesh asymmetry. Stock Eightball and UPak RocketLauncher are
exceptions: their lateral placement is compensated so center places the barrel on the
view center and left mirrors the unchanged right-hand barrel position. This
gaze-only correction follows scale and model roll; replacement meshes are excluded.
The owner accepted both launcher adjustments as part of the milestone above.
Motion offsets remain controller-local and are not auto-mirrored. Zero offsets
preserve the current placement; neutral profiles make no change to motion geometry.

For example, edit the existing Automag line to enlarge it by 10% in both modes
and move only its motion placement 2 cm down:

```ini
Profiles=(WeaponClass="UnrealShare.AutoMag",Scale=1.1,GazeOffsetCM=(X=0,Y=0,Z=0),MotionOffsetCM=(X=0,Y=0,Z=-2))
```

In motion mode, mesh, muzzle origin, flash position and aiming reticle use the
same adjustments. Gaze attacks for all listed stock/UPak families start at the
displayed model's calculated muzzle, including head-center translation, and
converge on the gaze target. Active VR shots retain that calculated direction
instead of legacy auto-aim pulling them away from the reticle. Projectile gravity,
weapon spread, homing and guided behavior remain weapon-specific; the reticle
is not a ballistic landing-point predictor.

RazorJack primary and UPak RocketLauncher have explicit adapters for their
omitted lateral fire offset. Eightball volleys and both GrenadeLauncher modes
replace hard-coded body-relative/random spawn positions with the muzzle reference.
Eightball retains its rocket count, angular spread, speed variation and seeking
logic; volleys share the barrel reference instead of the old spawn ring. Flak
retains its small fragment offsets around that reference. Reloading QuadShot,
zooming Rifle and detonating an existing remote grenade do not require muzzle
clearance. Actual firing still uses the existing obstruction checks.

ASMD's amplified visual beam offsets are compensated only inside VR firing;
stock hit processing, damage, combo behavior and effects still run through the
original functions. Other standard firing functions remain original except for
the narrowly scoped stock spawn adapters above.

Stock muzzle references use resting-mesh landmarks instead of the whole-mesh
centre. Each pair below is sampled at frame zero and averaged:

| Weapon | Vertices | Pose | Mesh vertex count |
| --- | --- | --- | --- |
| AutoMag, either hand | 78/181 | Still | 208 |
| Stinger | 113/158 | Still | 235 |
| ASMD | 0/6 | Still | 154 |
| Eightball | 149/151 | Idle | 219 |
| FlakCannon | 7/133 | Still | 192 |
| Rifle | 19/129 | Still | 177 |
| Minigun | 84/122 | Still | 248 |
| RazorJack | 103/115 | Idle | 136 |
| GESBioRifle | 59/60 | Still | 181 |
| QuadShot, either hand | Front-face bounds centre | Idle | 1056 |
| CARifle | 124/125 | Still | 175 |
| GrenadeLauncher | 34/37 | Still | 208 |
| RocketLauncher | 103/104 | Still | 164 |

QuadShot's handed meshes have different vertex ordering, so its common muzzle-face
reference uses the foremost resting vertices, not shared indices. Multi-barrel
weapons use a shared muzzle reference, not individual animated barrel sockets.
References use the existing model scale and one-unit forward clearance and are
cached with the geometry. Measurement restores the live mesh, rotation and
animation. Mesh identity and vertex-count guards retain the bounds-based fallback
for replacement meshes. Sizes, grip placement and profile offsets are unchanged.
The owner accepted stock visual barrel alignment at the milestone above;
replacement meshes and future changes still require headset inspection.

Stock RazorJack samples its two muzzle vertices at the current animation frame
during `AltFire1`, `AltFire2` and `AltFire3`, in both aiming modes. This follows
the rotating alternate-fire barrel without changing model placement, physical
size, the cached idle reference or the stock alternate projectile's roll.
Mesh and rotation are restored after sampling; replacement meshes are excluded.

Stock DispersionPistol uses its 195-vertex view mesh's power-level-specific idle
form (`Idle1` through `Idle5`, frame zero). Levels 0/1 use the centre of front
opening vertices 2/13/10/11; levels 2/3/4 use the extended barrel pair 29/156.
Upgrading refreshes only the cached muzzle, retaining model scale and placement.
Mesh, rotation and animation state are restored after sampling. This correction
feeds primary and charged shots in both VR aiming modes; replacement meshes
retain the bounds-based fallback.

Desktop rendering is unaffected. These settings translate the existing pivot;
they do not add a new rotation correction or change weapon animations.

Weapon matching uses the full script class name, independent of language.
Old Weapons and other subclasses inherit the nearest matching parent profile.
Add a line with `WeaponClass="OldWeapons.OldAutoMag"` to tune that variant
separately. An exact class overrides its parent regardless of line order. If a
class is listed twice, its first line wins. An absent profile uses neutral values.

Start with small changes to one weapon. Set its scale back
to `1.0` and offsets to zero to restore the built-in placement. Keep a copy of
your tuned file before experimenting.
