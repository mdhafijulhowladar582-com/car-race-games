extends CharacterBody3D

@export var max_speed := 28.0
@export var acceleration := 18.0
@export var braking := 28.0
@export var steering_speed := 2.2
@export var max_steering_angle := 28.0
@export var gravity := 22.0

var speed := 0.0
var steering := 0.0

func _ready() -> void:
    _build_car()

func _physics_process(delta: float) -> void:
    var throttle := Input.get_axis("brake", "accelerate")
    var steer_input := Input.get_axis("steer_left", "steer_right")

    if throttle > 0.0:
        speed = move_toward(speed, max_speed, acceleration * delta)
    elif throttle < 0.0:
        speed = move_toward(speed, 0.0, braking * delta)
    else:
        speed = move_toward(speed, 0.0, acceleration * 0.35 * delta)

    steering = move_toward(steering, steer_input, steering_speed * delta)

    var turn_strength := steering * clamp(speed / max_speed, 0.0, 1.0)
    rotation.y -= turn_strength * max_steering_angle * delta

    velocity.x = sin(rotation.y) * speed
    velocity.z = cos(rotation.y) * speed
    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = -0.2

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
