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

@export_category("Health")
@export var max_health := 100.0
@export var collision_damage := 20.0
@export var damage_cooldown := 0.5

@export_category("Stability")
@export var gravity := 22.0
@export var ground_stick := 0.2

var speed := 0.0
var steering := 0.0
var health := 100.0
var damage_timer := 0.0
var is_game_over := false
var engine_player: AudioStreamPlayer3D
var brake_player: AudioStreamPlayer3D
var crash_player: AudioStreamPlayer3D
var game_over_player: AudioStreamPlayer3D

signal health_changed(current_health: float, maximum_health: float)
signal game_over
signal crash_impact

func _ready() -> void:
    health = max_health
    _build_car()
    _build_audio()
    health_changed.emit(health, max_health)

func _physics_process(delta: float) -> void:
    damage_timer = max(0.0, damage_timer - delta)

    if is_game_over:
        speed = move_toward(speed, 0.0, braking * delta)
        steering = move_toward(steering, 0.0, steering_response * delta)
        _apply_movement(delta)
        _update_engine_audio(delta)
        return

    var throttle := Input.get_axis("brake", "accelerate")
    var steer_input := Input.get_axis("steer_left", "steer_right")

    _update_speed(throttle, delta)
    _update_steering(steer_input, delta)
    _apply_movement(delta)
    _update_engine_audio(delta)

    if Input.is_action_pressed("brake") and abs(speed) > 1.0:
        _play_brake_audio()

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

func _apply_movement(delta: float) -> void:
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

    if not is_game_over:
        for i in get_slide_collision_count():
            var collision := get_slide_collision(i)
            var impact_speed := collision.get_travel().length() / max(delta, 0.001)
            if impact_speed > 4.0:
                var damage := clamp(impact_speed * 0.9, collision_damage * 0.5, collision_damage * 2.0)
                take_damage(damage)
                crash_impact.emit()
                _play_crash_audio()

func _build_audio() -> void:
    engine_player = AudioStreamPlayer3D.new()
    engine_player.name = "EngineAudio"
    engine_player.stream = _create_tone(90.0, 0.35)
    engine_player.volume_db = -10.0
    engine_player.max_distance = 45.0
    add_child(engine_player)
    engine_player.play()

    brake_player = AudioStreamPlayer3D.new()
    brake_player.name = "BrakeAudio"
    brake_player.stream = _create_tone(180.0, 0.08)
    brake_player.volume_db = -14.0
    brake_player.max_distance = 30.0
    add_child(brake_player)

    crash_player = AudioStreamPlayer3D.new()
    crash_player.name = "CrashAudio"
    crash_player.stream = _create_noise(0.18)
    crash_player.volume_db = -3.0
    crash_player.max_distance = 50.0
    add_child(crash_player)

    game_over_player = AudioStreamPlayer3D.new()
    game_over_player.name = "GameOverAudio"
    game_over_player.stream = _create_tone(55.0, 0.55)
    game_over_player.volume_db = -5.0
    game_over_player.max_distance = 50.0
    add_child(game_over_player)

func _create_tone(frequency: float, duration: float) -> AudioStreamWAV:
    var sample_rate := 22050
    var samples := int(sample_rate * duration)
    var data := PackedByteArray()
    data.resize(samples * 2)

    for i in samples:
        var sample := sin(TAU * frequency * float(i) / sample_rate)
        var value := int(clamp(sample, -1.0, 1.0) * 16000.0)
        data.encode_s16(i * 2, value)

    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = sample_rate
    stream.stereo = false
    stream.data = data
    return stream

func _create_noise(duration: float) -> AudioStreamWAV:
    var sample_rate := 22050
    var samples := int(sample_rate * duration)
    var data := PackedByteArray()
    data.resize(samples * 2)

    var rng := RandomNumberGenerator.new()
    rng.seed = 74291

    for i in samples:
        var envelope := 1.0 - float(i) / samples
        var sample := (rng.randf_range(-1.0, 1.0) * envelope)
        data.encode_s16(i * 2, int(sample * 19000.0))

    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = sample_rate
    stream.stereo = false
    stream.data = data
    return stream

func _update_engine_audio(delta: float) -> void:
    if not is_instance_valid(engine_player):
        return

    var speed_ratio := clamp(abs(speed) / max_speed, 0.0, 1.0)
    engine_player.pitch_scale = lerp(0.85, 1.8, speed_ratio)
    engine_player.volume_db = lerp(-18.0, -7.0, speed_ratio)

func _play_brake_audio() -> void:
    if is_instance_valid(brake_player) and not brake_player.playing:
        brake_player.play()

func _play_crash_audio() -> void:
    if is_instance_valid(crash_player):
        crash_player.pitch_scale = randf_range(0.9, 1.1)
        crash_player.play()

func _play_game_over_audio() -> void:
    if is_instance_valid(game_over_player):
        game_over_player.play()

func take_damage(amount: float) -> void:
    if damage_timer > 0.0 or health <= 0.0 or is_game_over:
        return

    health = clamp(health - amount, 0.0, max_health)
    damage_timer = damage_cooldown
    health_changed.emit(health, max_health)

    if health <= 0.0:
        _trigger_game_over()

func _trigger_game_over() -> void:
    if is_game_over:
        return

    is_game_over = true
    speed = 0.0
    steering = 0.0
    _play_game_over_audio()
    game_over.emit()

func restart_game() -> void:
    get_tree().reload_current_scene()

func repair(amount: float) -> void:
    if is_game_over:
        return
    health = clamp(health + amount, 0.0, max_health)
    health_changed.emit(health, max_health)

func get_health_percent() -> float:
    if max_health <= 0.0:
        return 0.0
    return health / max_health

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
