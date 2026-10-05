# Car Race Games

Godot 4.x 3D car racing game for Android and PC.

## Current Progress

1. 3D Car + Car Physics — DONE
2. Smooth Steering + Acceleration + Braking — DONE
3. Mobile Touch Controls — DONE
4. Health + Damage — TODO
5. Game Over — TODO
6. Audio — TODO
7. Better 3D Car — TODO
8. Bends, Ramps + Obstacles — TODO
9. Race + Finish System — TODO
10. Android Optimization + APK Export — TODO

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

Mobile buttons are created at runtime and feed the same input actions used by the car physics.

## Car Control Features

- Smooth acceleration
- Smooth braking
- Reverse speed
- Rolling resistance
- Smooth steering response
- Adjustable steering sensitivity
- Speed-based steering stability
- Ground stick and gravity

## Mobile Features

- Four touch controls
- Press-and-hold driving
- Visual pressed state
- Android-friendly canvas UI
- Scalable viewport
- No separate mobile physics code

## Project Structure

- `project.godot` — Godot project settings and input actions
- `scenes/main.tscn` — Main 3D scene
- `scripts/main.gd` — Environment, road and mobile controls
- `scripts/player_car.gd` — Player car physics and controls
