extends CharacterBody3D

@export var max_speed := 22.0
@export var acceleration := 11.0
@export var steering_speed := 2.2
@export var waypoint_reach := 4.0
@export var corner_slowdown := 0.48
@export var steering_response := 4.5
@export var target_speed_variation := 0.08
@export var recovery_strength := 2.0
var speed := 0.0
var target_speed := 22.0
var race_time := 0.0
var waypoint_index := 0
var waypoints: Array[Vector3] = []
var race_active := false
var finished := false

func setup(route: Array[Vector3], start_index: int = 0) -> void:
    waypoints = route
    waypoint_index = start_index
    _build_car()

func start_race() -> void:
    race_active = true
    target_speed = max_speed * (1.0 + sin(get_instance_id() * 1.73) * target_speed_variation)

func _physics_process(delta: float) -> void:
    if not race_active or finished or waypoints.is_empty():
        velocity = Vector3.ZERO
        return
    var target := waypoints[waypoint_index]
    var offset := target - global_position
    offset.y = 0.0
    if offset.length() < waypoint_reach:
        waypoint_index = (waypoint_index + 1) % waypoints.size()
        target = waypoints[waypoint_index]
        offset = target - global_position
    race_time += delta
    var target_distance := offset.length()
    var desired := rotation.y
    if target_distance > 0.1:
        desired = atan2(-offset.x, -offset.z)
    var turn := wrapf(desired - rotation.y, -PI, PI)
    var turn_ratio := clamp(abs(turn) / PI, 0.0, 1.0)
    var adaptive_speed := target_speed * (1.0 - corner_slowdown * turn_ratio)
    adaptive_speed = max(adaptive_speed, target_speed * 0.52)
    speed = move_toward(speed, adaptive_speed, acceleration * (1.0 - turn_ratio * 0.35) * delta)
    var steering_limit := lerp(steering_speed, steering_speed * 0.58, clamp(speed / max_speed, 0.0, 1.0))
    rotation.y += clamp(turn, -steering_limit * delta, steering_limit * delta)

    var forward := -global_transform.basis.z
    var right := global_transform.basis.x
    var desired_velocity := forward * speed
    var lateral_velocity := right * velocity.dot(right)
    var grip := clamp((1.0 - turn_ratio * 0.35) * recovery_strength * delta, 0.0, 1.0)
    lateral_velocity = lateral_velocity.lerp(Vector3.ZERO, grip)
    velocity.x = (desired_velocity + lateral_velocity).x
    velocity.z = (desired_velocity + lateral_velocity).z
    velocity.y = -0.2
    move_and_slide()

func _build_car() -> void:
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(2.0, 0.8, 3.6)
    collision.shape = shape
    add_child(collision)

    var body := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(2.0, 0.65, 3.6)
    body.mesh = mesh
    body.position.y = 0.05
    body.material_override = _material(Color(0.06, 0.22, 0.82), 0.45, 0.22)
    add_child(body)

    var roof := MeshInstance3D.new()
    var roof_mesh := BoxMesh.new()
    roof_mesh.size = Vector3(1.35, 0.45, 1.45)
    roof.mesh = roof_mesh
    roof.position = Vector3(0.0, 0.48, 0.25)
    roof.material_override = _material(Color(0.03, 0.05, 0.08), 0.35, 0.12)
    add_child(roof)

    for x in [-0.64, 0.64]:
        var headlight := MeshInstance3D.new()
        var light_mesh := BoxMesh.new()
        light_mesh.size = Vector3(0.42, 0.11, 0.08)
        headlight.mesh = light_mesh
        headlight.position = Vector3(x, 0.18, -1.84)
        headlight.material_override = _emission_material(Color(0.75, 0.9, 1.0), 3.0)
        add_child(headlight)

    var nameplate := Label3D.new()
    nameplate.text = "AI"
    nameplate.position = Vector3(0.0, 1.55, 0.0)
    nameplate.font_size = 32
    nameplate.outline_size = 6
    nameplate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    add_child(nameplate)

func _material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = metallic
    material.roughness = roughness
    return material

func _emission_material(color: Color, energy: float) -> StandardMaterial3D:
    var material := _material(color, 0.1, 0.12)
    material.emission_enabled = true
    material.emission = color
    material.emission_energy_multiplier = energy
    return material
