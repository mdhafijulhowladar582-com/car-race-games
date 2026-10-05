extends CharacterBody3D

@export_category("Speed")
@export var max_speed := 28.0
@export var reverse_speed := 10.0
@export var acceleration := 18.0
@export var braking := 30.0
@export var rolling_resistance := 7.0

@export_category("Steering")
@export_range(0.1, 5.0, 0.1) var steering_sensitivity := 2.4
@export var steering_response := 7.0
@export var max_steering_angle := 30.0
@export var steering_at_speed := 0.65

@export_category("Stability")
@export var gravity := 22.0
@export var ground_stick := 0.2

var speed := 0.0
var steering := 0.0

func _ready() -> void:
    _build_car()

func _physics_process(delta: float) -> void:
    var throttle := Input.get_axis("brake", "accelerate")
    var steer_input := Input.get_axis("steer_left", "steer_right")

    _update_speed(throttle, delta)
    _update_steering(steer_input, delta)
    _move_car(delta)

func _update_speed(throttle: float, delta: float) -> void:
    if throttle > 0.0:
        speed = move_toward(speed, max_speed, acceleration * throttle * delta)
    elif throttle < 0.0:
        if speed > 0.5:
            speed = move_toward(speed, 0.0, braking * -throttle * delta)
        else:
            speed = move_toward(speed, -reverse_speed, acceleration * 0.55 * -throttle * delta)
    else:
        speed = move_toward(speed, 0.0, rolling_resistance * delta)

func _update_steering(steer_input: float, delta: float) -> void:
    var target_steering := steer_input * steering_sensitivity
    steering = move_toward(steering, target_steering, steering_response * delta)

func _move_car(delta: float) -> void:
    var speed_ratio := clamp(abs(speed) / max_speed, 0.0, 1.0)
    var turn_strength := steering * lerp(1.0, steering_at_speed, speed_ratio)

    if abs(speed) > 0.1:
        var direction := 1.0 if speed >= 0.0 else -1.0
        rotation.y -= direction * turn_strength * deg_to_rad(max_steering_angle) * delta

    var forward := -global_transform.basis.z
    velocity.x = forward.x * speed
    velocity.z = forward.z * speed

    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = -ground_stick

    move_and_slide()

func _build_car() -> void:
    var collision := get_node("CollisionShape3D") as CollisionShape3D
    var box := BoxShape3D.new()
    box.size = Vector3(2.2, 0.9, 4.0)
    collision.shape = box

    var body := get_node("Body") as MeshInstance3D
    var mesh := BoxMesh.new()
    mesh.size = Vector3(2.2, 0.9, 4.0)
    body.mesh = mesh

    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.8, 0.08, 0.05)
    body.material_override = material

    _add_wheel(Vector3(-1.0, -0.45, -1.25))
    _add_wheel(Vector3(1.0, -0.45, -1.25))
    _add_wheel(Vector3(-1.0, -0.45, 1.25))
    _add_wheel(Vector3(1.0, -0.45, 1.25))

func _add_wheel(pos: Vector3) -> void:
    var wheel := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.42
    mesh.bottom_radius = 0.42
    mesh.height = 0.28
    wheel.mesh = mesh
    wheel.position = pos
    wheel.rotation_degrees = Vector3(0, 0, 90)
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.02, 0.02, 0.02)
    wheel.material_override = material
    add_child(wheel)
