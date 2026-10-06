# Car Race Games

Godot 4.x 3D car racing game for Android and PC.

## Current Progress

1. 3D Car + Car Physics — DONE
2. Smooth Steering + Acceleration + Braking — DONE
3. Mobile Touch Controls — DONE
4. Health + Damage — DONE
5. Game Over — DONE
6. Audio — DONE
7. Better 3D Car — DONE
8. Bends, Ramps + Obstacles — DONE
9. Race + Finish System — DONE
10. Android Optimization + APK Export — DONE

## Android Optimization

- Godot Compatibility renderer for Android-friendly performance
- Mobile renderer explicitly uses Compatibility mode
- Lightweight procedural assets with no external 3D dependencies
- Procedural audio avoids external audio files
- Duplicate road-building code removed
- Physics uses GodotPhysics for predictable mobile compatibility
- Engine audio uses a looped procedural stream instead of repeatedly creating audio
- UI uses the existing 1280x720 canvas stretch setup

## APK Export

- Project is configured as an Android-ready Godot project
- Android APK/AAB export still requires a Godot installation with Android export templates and the Android SDK/JDK
- Release builds additionally require Android signing configuration

## Game Modes

- Quick Race: one-lap race against three AI opponents
- Time Trial: solo one-lap run focused on beating the clock
- Career: three-lap championship-style race against AI opponents
- Mode selection screen appears before every race
- Race HUD and finish results adapt to the selected mode
- Career mode resets the track at each lap while preserving the race timer

## AI Opponents

- Three computer-controlled opponent cars spawn on the starting grid
- Waypoint-based driving follows the full road route through bends and ramps
- Independent acceleration, steering and top speed create competitive movement
- AI starts with the 3-2-1-GO countdown and stops at the finish
- Live player position updates against all AI opponents
- Lightweight procedural AI cars require no external assets

## Advanced Race System

- 3-2-1-GO race countdown
- Sequential checkpoint gates that must be completed before finishing
- Live race timer with minute/second precision
- Lap and position HUD
- Finish-line validation and final race time result
- Race progress and remaining distance HUD

## Camera System

- Speed-based dynamic FOV for a stronger sense of acceleration
- Smooth follow offset that changes with vehicle speed
- Steering/drift camera lean for more responsive driving feedback
- Lightweight collision camera shake
- Finish-line cinematic camera pull-back and FOV transition
- Camera effects are procedural and use no external assets

## Professional Audio

- Layered low/high procedural engine audio with speed and throttle response
- Continuous tire/road surface sound that reacts to speed, braking and steering
- Speed wind layer increases naturally with vehicle velocity
- Controlled brake audio that starts and stops correctly
- Collision impact audio and game-over audio
- Track ambience layer for environmental atmosphere
- All audio is generated at runtime with lightweight WAV streams and no external audio assets

## Better Effects

- Lightweight procedural tire dust particles during hard braking and steering
- Dynamic skid-mark visuals for braking and aggressive steering
- Damage smoke activates automatically at low health
- Collision sparks burst on strong impacts
- Short collision flash effect for stronger impact feedback
- Effects are generated at runtime with no external texture or VFX asset dependency
- CPU-friendly particle counts are kept low for Android compatibility

## Race System

- Race progress percentage HUD
- Remaining distance to finish
- Physical finish-line trigger
- Checkered finish-line visuals
- Finish banner and arch
- Race Finished overlay
- Race Again restart button

## Track

- Multi-section connected racing route with progressive bends
- Raised road sections for elevation changes
- Alternating curb blocks for a professional race-track edge look
- Center lane markings across road sections
- Metallic roadside guardrails with physical collision
- Driveable ramps with warning stripes
- Tunnel structure with interior lights
- Trackside trees and vegetation
- Distant mountain silhouettes
- Multi-floor roadside buildings with illuminated windows
- Street lamp posts with working lights
- Directional roadside signs for turns, curves, ramps and finish
- Collision barriers and barrel obstacles
- Physical collision on road and track obstacles

## Environment

- Large roadside grass/terrain area
- Mountain range backdrop
- Repeating roadside trees
- City building blocks with illuminated windows
- Roadside lamp posts with working lights
- Track direction/sign boards
- Lightweight procedural scenery with no external asset dependencies

## Car Visual

- Detailed procedural sports-car body
- Hood and raised cabin
- Dark windshield and rear window
- Front and rear bumpers
- Emissive headlights
- Emissive taillights
- Rear spoiler
- Four detailed wheels
- Metallic/roughness materials
- No external 3D model asset required for the current prototype

## Controls

### PC
- W / Up Arrow: accelerate
- S / Down Arrow: brake and reverse
- A / Left Arrow: steer left
- D / Right Arrow: steer right

### Android
- LEFT: steer left
- RIGHT: steer right
- BRAKE: brake and reverse
- GO: accelerate

## Systems Completed

- Car physics and controls
- Mobile touch controls
- Health and collision damage
- Game Over and restart
- Procedural audio
- Detailed procedural car visuals
- Curved/raised track
- Ramps and obstacles

## Project Structure

- `project.godot` — Godot project settings and input actions
- `scenes/main.tscn` — Main 3D scene
- `scripts/main.gd` — Environment, track, obstacles, controls, HUD and game-over UI
- `scripts/player_car.gd` — Car physics, controls, health, game-over, audio and visual model
