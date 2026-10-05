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
9. Race + Finish System — TODO
10. Android Optimization + APK Export — TODO

## Track

- Multiple connected 3D road segments
- Curved road sections
- Raised road sections
- Driveable ramps
- Ramp warning stripes
- Collision barriers
- Barrel obstacles
- Physical collision on road and obstacles

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
