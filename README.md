# Car Race Games

Godot 4.x 3D car racing game for Android and PC.

## Current Progress

1. 3D Car + Car Physics — DONE
2. Smooth Steering + Acceleration + Braking — DONE
3. Mobile Touch Controls — DONE
4. Health + Damage — DONE
5. Game Over — DONE
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

## Health and Game Over

- 100 HP by default
- Collision-based damage
- Impact-speed-based damage amount
- Damage cooldown
- Live HP HUD and health bar
- At 0 HP the car enters a permanent game-over state
- Driving controls stop affecting the car after game over
- Mobile controls are hidden after game over
- Full-screen Game Over overlay
- Restart button reloads the current scene
- Game Over signal keeps the system ready for future score/race results

## Project Structure

- `project.godot` — Godot project settings and input actions
- `scenes/main.tscn` — Main 3D scene
- `scripts/main.gd` — Environment, road, controls, HUD and game-over UI
- `scripts/player_car.gd` — Player car physics, controls, health and game-over state
