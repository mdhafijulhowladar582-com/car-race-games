# Car Race Games

Godot 4.x 3D car racing game for Android and PC.

## Current Progress

1. 3D Car + Car Physics — DONE
2. Smooth Steering + Acceleration + Braking — DONE
3. Mobile Touch Controls — DONE
4. Health + Damage — DONE
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

## Health System

- 100 HP by default
- Collision-based damage
- Impact-speed-based damage amount
- Damage cooldown to prevent rapid repeated damage
- Health cannot go below 0
- Repair function for future pickups
- Real-time HP HUD
- Health percentage helper
- Game Over is intentionally handled in task #5

## Project Structure

- `project.godot` — Godot project settings and input actions
- `scenes/main.tscn` — Main 3D scene
- `scripts/main.gd` — Environment, road, mobile controls and HUD
- `scripts/player_car.gd` — Player car physics, controls and health
