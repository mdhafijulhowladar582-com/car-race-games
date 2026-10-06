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
var engine_high_player: AudioStreamPlayer3D
var engine_load_player: AudioStreamPlayer3D
var gear_shift_player: AudioStreamPlayer3D
var previous_speed_ratio := 0.0
var tire_player: AudioStreamPlayer3D
var wind_player: AudioStreamPlayer3D
var brake_player: AudioStreamPlayer3D
var crash_player: AudioStreamPlayer3D
var game_over_player: AudioStreamPlayer3D
var dust_particles: Array[CPUParticles3D] = []
var smoke_particles: CPUParticles3D
var spark_particles: CPUParticles3D
var skid_marks: Array[MeshInstance3D] = []
var crash_light: OmniLight3D
var camera: Camera3D
var camera_base_position := Vector3(0.0, 4.5, 8.0)
var camera_base_rotation := Vector3(-15.0, 180.0, 0.0)
var camera_shake := 0.0
var camera_shake_strength := 0.0
var camera_cinematic := false
var boost_particles: GPUParticles3D
var impact_particles: GPUParticles3D
var car_model := "SPORTS"
var car_max_speed := 34.0
var car_acceleration := 18.0
var car_steering := 2.2
var customization_color := Color(0.82, 0.025, 0.02)
var wheel_style := "SPORT"
var performance_level := 0

signal health_changed(current_health: float, maximum_health: float)
signal game_over
signal crash_impact

func customize_car(color: Color, wheel_style_name: String, upgrade_level: int) -> void:
    customization_color = color
    wheel_style = wheel_style_name
    performance_level = clamp(upgrade_level, 0, 3)
    var speed_bonus := float(performance_level) * 1.5
    var acceleration_bonus := float(performance_level) * 0.8
    max_speed = car_max_speed + speed_bonus
    acceleration = car_acceleration + acceleration_bonus
    _apply_custom_color()
    _apply_wheel_style()

func _apply_custom_color() -> void:
    var body_root := get_node_or_null("CarVisual")
    if not body_root:
        return
    for node in body_root.get_children():
        var mesh := node as MeshInstance3D
        if mesh and (mesh.name == "Body" or mesh.name == "Hood"):
            mesh.material_override = _material(customization_color, 0.6, 0.18)

func _apply_wheel_style() -> void:
    var body_root := get_node_or_null("CarVisual")
    if not body_root:
        return
    var rim_color := Color(0.42, 0.44, 0.48)
    if wheel_style == "BLACK":
        rim_color = Color(0.03, 0.035, 0.045)
    elif wheel_style == "GOLD":
        rim_color = Color(0.85, 0.58, 0.08)
    for node in get_tree().get_nodes_in_group("car_rim"):
        var mesh := node as MeshInstance3D
        if mesh:
            mesh.material_override = _material(rim_color, 0.9, 0.18)

func configure_car(model_name: String) -> void:
    car_model = model_name
    if model_name == "MUSCLE":
        car_max_speed = 30.0
        car_acceleration = 20.0
        car_steering = 1.8
    elif model_name == "GT":
        car_max_speed = 38.0
        car_acceleration = 16.0
        car_steering = 2.4
    else:
        car_max_speed = 34.0
        car_acceleration = 18.0
        car_steering = 2.2
    max_speed = car_max_speed
    acceleration = car_acceleration
    steering_response = car_steering

func _ready() -> void:
    health = max_health
    _build_car()
    _build_audio()
    _build_professional_vfx()
    _build_effects()
    camera = get_node_or_null("Camera3D") as Camera3D
    if is_instance_valid(camera):
        camera_base_position = camera.position
        camera_base_rotation = camera.rotation_degrees
        camera.fov = 70.0
    health_changed.emit(health, max_health)

func _build_professional_vfx() -> void:
    boost_particles = GPUParticles3D.new()
    boost_particles.name = "BoostSmoke"
    boost_particles.amount = 45
    boost_particles.lifetime = 0.55
    boost_particles.emitting = false
    var boost_material := ParticleProcessMaterial.new()
    boost_material.direction = Vector3(0.0, 0.25, 1.0)
    boost_material.spread = 28.0
    boost_material.initial_velocity_min = 2.0
    boost_material.initial_velocity_max = 5.0
    boost_material.gravity = Vector3(0.0, 0.8, 0.0)
    boost_material.scale_min = 0.06
    boost_material.scale_max = 0.14
    boost_particles.process_material = boost_material
    var smoke_mesh := SphereMesh.new()
    smoke_mesh.radius = 0.12
    smoke_mesh.height = 0.24
    boost_particles.draw_pass_1 = smoke_mesh
    boost_particles.position = Vector3(0.0, 0.25, 1.65)
    add_child(boost_particles)

    impact_particles = GPUParticles3D.new()
    impact_particles.name = "ImpactDust"
    impact_particles.amount = 35
    impact_particles.lifetime = 0.45
    impact_particles.emitting = false
    var impact_material := ParticleProcessMaterial.new()
    impact_material.direction = Vector3(0.0, 1.0, 0.0)
    impact_material.spread = 55.0
    impact_material.initial_velocity_min = 3.0
    impact_material.initial_velocity_max = 8.0
    impact_material.gravity = Vector3(0.0, -7.0, 0.0)
    impact_material.scale_min = 0.04
    impact_material.scale_max = 0.11
    impact_particles.process_material = impact_material
    var dust_mesh := SphereMesh.new()
    dust_mesh.radius = 0.1
    dust_mesh.height = 0.2
    impact_particles.draw_pass_1 = dust_mesh
    impact_particles.position = Vector3(0.0, 0.25, -0.8)
    add_child(impact_particles)

func _update_professional_vfx() -> void:
    if not is_instance_valid(boost_particles):
        return
    var speed := velocity.length()
    var throttle_input := Input.get_axis("brake", "accelerate")
    boost_particles.emitting = speed > 18.0 and throttle_input > 0.25 and health > max_health * 0.25
    if is_instance_valid(impact_particles):
        impact_particles.position = Vector3(0.0, 0.25, -0.9)
    
func _physics_process(delta: float) -> void:
    damage_timer = max(0.0, damage_timer - delta)

    if is_game_over:
        speed = move_toward(speed, 0.0, braking * delta)
        steering = move_toward(steering, 0.0, steering_response * delta)
        _apply_movement(delta)
        _update_engine_audio(delta)
        _update_driving_audio(delta)
        _update_effects()
        return

    var throttle := Input.get_axis("brake", "accelerate")
    var steer_input := Input.get_axis("steer_left", "steer_right")

    _update_speed(throttle, delta)
    _update_steering(steer_input, delta)
    _apply_movement(delta)
    _update_engine_audio(delta)
    _update_driving_audio(delta)
    _update_effects()

    if Input.is_action_pressed("brake") and abs(speed) > 1.0:
        _play_brake_audio()

func _update_camera(delta: float) -> void:
    if not is_instance_valid(camera):
        return

    var speed_ratio := clamp(abs(speed) / max_speed, 0.0, 1.0)
    var steer_ratio := clamp(steering / max(steering_sensitivity, 0.01), -1.0, 1.0)
    var target_fov := lerp(68.0, 82.0, speed_ratio)
    camera.fov = lerp(camera.fov, target_fov, minf(delta * 5.0, 1.0))

    if camera_cinematic:
        camera.position = camera.position.lerp(Vector3(0.0, 5.8, 11.5), minf(delta * 2.5, 1.0))
        camera.rotation_degrees = camera.rotation_degrees.lerp(Vector3(-18.0, 180.0, 0.0), minf(delta * 2.5, 1.0))
        camera.fov = lerp(camera.fov, 62.0, minf(delta * 2.0, 1.0))
        return

    camera_shake = maxf(0.0, camera_shake - delta)
    var shake_ratio := clamp(camera_shake, 0.0, 1.0)
    var shake_x := sin(Time.get_ticks_msec() * 0.043) * camera_shake_strength * shake_ratio
    var shake_y := cos(Time.get_ticks_msec() * 0.057) * camera_shake_strength * shake_ratio

    var target_position := camera_base_position
    target_position.x += steer_ratio * 0.32
    target_position.y += speed_ratio * 0.22
    target_position.z -= speed_ratio * 0.65
    target_position.x += shake_x
    target_position.y += shake_y

    var target_rotation := camera_base_rotation
    target_rotation.x -= speed_ratio * 2.0
    target_rotation.z = -steer_ratio * 3.2 + shake_y * 1.8

    camera.position = camera.position.lerp(target_position, minf(delta * 7.0, 1.0))
    camera.rotation_degrees = camera.rotation_degrees.lerp(target_rotation, minf(delta * 7.0, 1.0))

func trigger_camera_shake(strength: float = 0.18, duration: float = 0.28) -> void:
    camera_shake = maxf(camera_shake, duration)
    camera_shake_strength = maxf(camera_shake_strength, strength)

func set_finish_cinematic(enabled: bool) -> void:
    camera_cinematic = enabled

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
                _trigger_crash_effect(impact_speed)
                trigger_camera_shake(clamp(impact_speed * 0.012, 0.12, 0.38), 0.32)
                _play_crash_audio()

func _build_effects() -> void:
    var dust_material := ParticleProcessMaterial.new()
    dust_material.direction = Vector3(0.0, 0.7, 0.15)
    dust_material.spread = 55.0
    dust_material.gravity = Vector3(0.0, 1.5, 0.0)
    dust_material.initial_velocity_min = 1.0
    dust_material.initial_velocity_max = 3.0
    dust_material.scale_min = 0.18
    dust_material.scale_max = 0.42
    dust_material.color = Color(0.34, 0.29, 0.22, 0.5)

    for pos in [Vector3(-0.82, -0.42, 1.25), Vector3(0.82, -0.42, 1.25)]:
        var dust := CPUParticles3D.new()
        dust.name = "Dust"
        dust.position = pos
        dust.amount = 12
        dust.lifetime = 0.55
        dust.randomness = 0.45
        dust.local_coords = false
        dust.emitting = false
        dust.process_material = dust_material
        dust.mesh = _particle_sphere(0.18)
        add_child(dust)
        dust_particles.append(dust)

    var smoke_material := ParticleProcessMaterial.new()
    smoke_material.direction = Vector3(0.0, 1.0, 0.0)
    smoke_material.spread = 30.0
    smoke_material.gravity = Vector3(0.0, 0.7, 0.0)
    smoke_material.initial_velocity_min = 0.3
    smoke_material.initial_velocity_max = 1.1
    smoke_material.scale_min = 0.28
    smoke_material.scale_max = 0.62
    smoke_material.color = Color(0.16, 0.16, 0.18, 0.42)

    smoke_particles = CPUParticles3D.new()
    smoke_particles.name = "DamageSmoke"
    smoke_particles.position = Vector3(0.0, 0.05, 1.7)
    smoke_particles.amount = 10
    smoke_particles.lifetime = 1.2
    smoke_particles.randomness = 0.6
    smoke_particles.emitting = false
    smoke_particles.process_material = smoke_material
    smoke_particles.mesh = _particle_sphere(0.22)
    add_child(smoke_particles)

    var spark_material := ParticleProcessMaterial.new()
    spark_material.direction = Vector3(0.0, 0.7, 0.0)
    spark_material.spread = 70.0
    spark_material.gravity = Vector3(0.0, -5.0, 0.0)
    spark_material.initial_velocity_min = 4.0
    spark_material.initial_velocity_max = 9.0
    spark_material.scale_min = 0.05
    spark_material.scale_max = 0.12
    spark_material.color = Color(1.0, 0.48, 0.06, 1.0)

    spark_particles = CPUParticles3D.new()
    spark_particles.name = "CollisionSparks"
    spark_particles.amount = 20
    spark_particles.lifetime = 0.35
    spark_particles.one_shot = true
    spark_particles.explosiveness = 0.9
    spark_particles.emitting = false
    spark_particles.process_material = spark_material
    spark_particles.mesh = _particle_sphere(0.08)
    add_child(spark_particles)

    crash_light = OmniLight3D.new()
    crash_light.name = "CrashFlash"
    crash_light.light_color = Color(1.0, 0.45, 0.12)
    crash_light.light_energy = 0.0
    crash_light.omni_range = 5.0
    add_child(crash_light)

    for pos in [Vector3(-0.82, -0.44, 0.95), Vector3(0.82, -0.44, 0.95)]:
        var mark := MeshInstance3D.new()
        var mark_mesh := BoxMesh.new()
        mark_mesh.size = Vector3(0.34, 0.015, 1.25)
        mark.mesh = mark_mesh
        mark.position = pos
        mark.material_override = _material(Color(0.025, 0.025, 0.025, 0.55), 0.0, 1.0)
        mark.visible = false
        add_child(mark)
        skid_marks.append(mark)

func _particle_sphere(radius: float) -> SphereMesh:
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    return mesh

func _update_effects() -> void:
    var moving := abs(speed) > 5.0
    var braking_now := Input.is_action_pressed("brake") and abs(speed) > 4.0
    var steering_now := abs(steering) > 0.55 and abs(speed) > 9.0
    var skid_active := braking_now or steering_now

    for dust in dust_particles:
        dust.emitting = moving and (braking_now or steering_now)

    for mark in skid_marks:
        mark.visible = skid_active

    if is_instance_valid(smoke_particles):
        smoke_particles.emitting = health <= max_health * 0.45 and not is_game_over

func _trigger_crash_effect(impact_speed: float) -> void:
    if not is_instance_valid(spark_particles):
        return

    spark_particles.position = Vector3(0.0, 0.1, -0.8)
    spark_particles.emitting = false
    spark_particles.restart()

    if is_instance_valid(crash_light):
        crash_light.light_energy = clamp(impact_speed * 0.18, 0.8, 3.0)
        var tween := create_tween()
        tween.tween_property(crash_light, "light_energy", 0.0, 0.16)

func _build_audio() -> void:
    engine_player = AudioStreamPlayer3D.new()
    engine_player.name = "EngineLow"
    engine_player.stream = _create_tone(75.0, 0.5)
    engine_player.volume_db = -13.0
    engine_player.max_distance = 55.0
    add_child(engine_player)
    engine_player.play()

    engine_high_player = AudioStreamPlayer3D.new()
    engine_high_player.name = "EngineHigh"
    engine_high_player.stream = _create_tone(155.0, 0.35)
    engine_high_player.volume_db = -18.0
    engine_high_player.max_distance = 50.0
    add_child(engine_high_player)
    engine_high_player.play()

    tire_player = AudioStreamPlayer3D.new()
    tire_player.name = "TireRoadAudio"
    tire_player.stream = _create_looped_noise(0.65)
    tire_player.volume_db = -34.0
    tire_player.max_distance = 42.0
    add_child(tire_player)
    tire_player.play()

    wind_player = AudioStreamPlayer3D.new()
    wind_player.name = "SpeedWindAudio"
    wind_player.stream = _create_looped_noise(0.9)
    wind_player.volume_db = -42.0
    wind_player.max_distance = 55.0
    add_child(wind_player)
    wind_player.play()

    brake_player = AudioStreamPlayer3D.new()
    brake_player.name = "BrakeAudio"
    brake_player.stream = _create_tone(210.0, 0.16)
    brake_player.volume_db = -22.0
    brake_player.max_distance = 34.0
    add_child(brake_player)

    crash_player = AudioStreamPlayer3D.new()
    crash_player.name = "CrashAudio"
    crash_player.stream = _create_noise(0.22)
    crash_player.volume_db = -2.0
    crash_player.max_distance = 50.0
    add_child(crash_player)

    game_over_player = AudioStreamPlayer3D.new()
    game_over_player.name = "GameOverAudio"
    game_over_player.stream = _create_tone(55.0, 0.7)
    game_over_player.volume_db = -5.0
    game_over_player.max_distance = 50.0
    add_child(game_over_player)

    engine_load_player = AudioStreamPlayer3D.new()
    engine_load_player.name = "EngineLoad"
    engine_load_player.stream = _create_tone(110.0, 0.4)
    engine_load_player.volume_db = -28.0
    engine_load_player.max_distance = 48.0
    add_child(engine_load_player)
    engine_load_player.play()

    gear_shift_player = AudioStreamPlayer3D.new()
    gear_shift_player.name = "GearShiftAudio"
    gear_shift_player.stream = _create_tone(420.0, 0.08)
    gear_shift_player.volume_db = -16.0
    gear_shift_player.max_distance = 42.0
    add_child(gear_shift_player)

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
    stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
    stream.loop_begin = 0
    stream.loop_end = samples
    stream.data = data
    return stream

func _create_looped_noise(duration: float) -> AudioStreamWAV:
    var stream := _create_noise(duration)
    stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
    stream.loop_begin = 0
    stream.loop_end = int(stream.data.size() / 2)
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

func _update_engine_audio(_delta: float) -> void:
    if not is_instance_valid(engine_player):
        return

    var speed_ratio := clamp(abs(speed) / max_speed, 0.0, 1.0)
    var throttle_ratio := 1.0 if Input.is_action_pressed("accelerate") else 0.35
    engine_player.pitch_scale = lerp(0.82, 1.75, speed_ratio)
    engine_player.volume_db = lerp(-20.0, -6.0, speed_ratio) + lerp(-2.0, 2.0, throttle_ratio)

    if is_instance_valid(engine_high_player):
        engine_high_player.pitch_scale = lerp(0.72, 2.2, speed_ratio)
        engine_high_player.volume_db = lerp(-29.0, -11.0, speed_ratio) + lerp(-2.0, 3.0, throttle_ratio)

    if is_instance_valid(engine_load_player):
        var load_ratio := clamp(throttle_ratio * speed_ratio, 0.0, 1.0)
        engine_load_player.pitch_scale = lerp(0.72, 1.9, speed_ratio)
        engine_load_player.volume_db = lerp(-34.0, -12.0, load_ratio)
        if Input.is_action_pressed("accelerate"):
            engine_load_player.volume_db += 3.0

    if is_instance_valid(gear_shift_player):
        if previous_speed_ratio < 0.72 and speed_ratio >= 0.72:
            gear_shift_player.pitch_scale = 1.0
            gear_shift_player.play()
        elif previous_speed_ratio >= 0.72 and speed_ratio < 0.68:
            gear_shift_player.pitch_scale = 0.82
            gear_shift_player.play()

    previous_speed_ratio = speed_ratio

func _play_brake_audio() -> void:
    if is_instance_valid(brake_player) and not brake_player.playing:
        brake_player.play()

func _update_driving_audio() -> void:
    var speed_ratio := clamp(abs(speed) / max_speed, 0.0, 1.0)
    var braking_now := Input.is_action_pressed("brake") and abs(speed) > 1.0
    var steering_now := abs(steering) > 0.55 and abs(speed) > 8.0

    if is_instance_valid(tire_player):
        tire_player.volume_db = lerp(-34.0, -12.0, speed_ratio)
        tire_player.pitch_scale = lerp(0.75, 1.55, speed_ratio)
        if braking_now or steering_now:
            tire_player.volume_db += 5.0

    if is_instance_valid(wind_player):
        wind_player.volume_db = lerp(-42.0, -10.0, speed_ratio)
        wind_player.pitch_scale = lerp(0.7, 1.25, speed_ratio)

    if braking_now:
        _play_brake_audio()
    elif is_instance_valid(brake_player) and brake_player.playing:
        brake_player.stop()

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

func _apply_car_style() -> void:
    var body_root := get_node_or_null("CarVisual")
    if not body_root:
        return
    var colors := {
        "SPORTS": Color(0.82, 0.025, 0.02),
        "MUSCLE": Color(0.04, 0.08, 0.72),
        "GT": Color(0.04, 0.55, 0.18)
    }
    var body := body_root.get_node_or_null("Body") as MeshInstance3D
    var hood := body_root.get_node_or_null("Hood") as MeshInstance3D
    if body:
        body.material_override = _material(colors.get(car_model, colors["SPORTS"]), 0.55, 0.2)
    if hood:
        hood.material_override = _material(colors.get(car_model, colors["SPORTS"]), 0.6, 0.18)

func _build_car() -> void:
    var collision := get_node("CollisionShape3D") as CollisionShape3D
    var box := BoxShape3D.new()
    box.size = Vector3(2.2, 0.9, 4.0)
    collision.shape = box

    var car_root := Node3D.new()
    car_root.name = "CarVisual"
    add_child(car_root)

    _add_body(car_root)
    var body := car_root.get_node_or_null("Body") as MeshInstance3D
    if body:
        body.name = "Body"
    _add_cabin(car_root)
    _add_details(car_root)
    _add_premium_body_details(car_root)
    _add_lights(car_root)
    _add_spoiler(car_root)
    _add_wheels()
    _apply_car_style()

func _add_body(parent: Node3D) -> void:
    var body := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(2.2, 0.72, 4.0)
    body.mesh = mesh
    body.material_override = _material(Color(0.82, 0.025, 0.02), 0.55, 0.2)
    parent.add_child(body)

    var lower_body := MeshInstance3D.new()
    var lower_mesh := BoxMesh.new()
    lower_mesh.size = Vector3(2.32, 0.34, 3.45)
    lower_body.mesh = lower_mesh
    lower_body.position = Vector3(0.0, -0.27, 0.05)
    lower_body.material_override = _material(Color(0.035, 0.035, 0.045), 0.35, 0.3)
    parent.add_child(lower_body)

    var hood := MeshInstance3D.new()
    var hood_mesh := BoxMesh.new()
    hood_mesh.size = Vector3(1.86, 0.14, 1.45)
    hood.mesh = hood_mesh
    hood.position = Vector3(0.0, 0.43, -1.02)
    hood.material_override = _material(Color(0.92, 0.035, 0.025), 0.6, 0.18)
    parent.add_child(hood)

    var front_lip := MeshInstance3D.new()
    var lip_mesh := BoxMesh.new()
    lip_mesh.size = Vector3(2.15, 0.16, 0.3)
    front_lip.mesh = lip_mesh
    front_lip.position = Vector3(0.0, -0.28, -2.02)
    front_lip.material_override = _material(Color(0.015, 0.015, 0.02), 0.7, 0.2)
    parent.add_child(front_lip)

func _add_cabin(parent: Node3D) -> void:
    var roof := MeshInstance3D.new()
    var roof_mesh := BoxMesh.new()
    roof_mesh.size = Vector3(1.55, 0.52, 1.72)
    roof.mesh = roof_mesh
    roof.position = Vector3(0.0, 0.62, 0.42)
    roof.rotation_degrees = Vector3(-2.0, 0.0, 0.0)
    roof.material_override = _material(Color(0.018, 0.025, 0.032), 0.25, 0.08)
    parent.add_child(roof)

    _add_window(parent, Vector3(0.0, 0.67, -0.42), Vector3(1.38, 0.38, 0.07), Vector3(-17.0, 0.0, 0.0))
    _add_window(parent, Vector3(0.0, 0.67, 1.25), Vector3(1.38, 0.34, 0.07), Vector3(17.0, 0.0, 0.0))
    _add_window(parent, Vector3(-0.79, 0.67, 0.43), Vector3(0.06, 0.38, 1.25), Vector3(0.0, 0.0, 0.0))
    _add_window(parent, Vector3(0.79, 0.67, 0.43), Vector3(0.06, 0.38, 1.25), Vector3(0.0, 0.0, 0.0))

func _add_window(parent: Node3D, pos: Vector3, size: Vector3, rotation: Vector3) -> void:
    var window := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    window.mesh = mesh
    window.position = pos
    window.rotation_degrees = rotation
    window.material_override = _material(Color(0.025, 0.09, 0.14), 0.45, 0.08)
    parent.add_child(window)

func _add_details(parent: Node3D) -> void:
    for x in [-0.72, 0.72]:
        var skirt := MeshInstance3D.new()
        var skirt_mesh := BoxMesh.new()
        skirt_mesh.size = Vector3(0.16, 0.2, 2.65)
        skirt.mesh = skirt_mesh
        skirt.position = Vector3(x, -0.28, 0.12)
        skirt.material_override = _material(Color(0.025, 0.025, 0.03), 0.6, 0.2)
        parent.add_child(skirt)

    var grille := MeshInstance3D.new()
    var grille_mesh := BoxMesh.new()
    grille_mesh.size = Vector3(1.05, 0.22, 0.08)
    grille.mesh = grille_mesh
    grille.position = Vector3(0.0, -0.05, -2.04)
    grille.material_override = _material(Color(0.008, 0.008, 0.01), 0.8, 0.2)
    parent.add_child(grille)

    for x in [-0.72, 0.72]:
        var mirror := MeshInstance3D.new()
        var mirror_mesh := SphereMesh.new()
        mirror_mesh.radius = 0.14
        mirror_mesh.height = 0.2
        mirror.mesh = mirror_mesh
        mirror.position = Vector3(x * 1.12, 0.62, -0.35)
        mirror.scale = Vector3(0.75, 0.55, 1.15)
        mirror.material_override = _material(Color(0.03, 0.035, 0.04), 0.65, 0.15)
        parent.add_child(mirror)

    var diffuser := MeshInstance3D.new()
    var diffuser_mesh := BoxMesh.new()
    diffuser_mesh.size = Vector3(2.05, 0.2, 0.34)
    diffuser.mesh = diffuser_mesh
    diffuser.position = Vector3(0.0, -0.3, 1.98)
    diffuser.material_override = _material(Color(0.01, 0.01, 0.015), 0.75, 0.18)
    parent.add_child(diffuser)


func _add_premium_body_details(parent: Node3D) -> void:
    var front_bumper := MeshInstance3D.new()
    var bumper_mesh := BoxMesh.new()
    bumper_mesh.size = Vector3(2.18, 0.32, 0.34)
    front_bumper.mesh = bumper_mesh
    front_bumper.position = Vector3(0.0, 0.02, -1.92)
    front_bumper.material_override = _material(customization_color, 0.65, 0.16)
    parent.add_child(front_bumper)

    for x in [-0.72, 0.72]:
        var intake := MeshInstance3D.new()
        var intake_mesh := BoxMesh.new()
        intake_mesh.size = Vector3(0.38, 0.22, 0.09)
        intake.mesh = intake_mesh
        intake.position = Vector3(x, 0.0, -2.095)
        intake.material_override = _material(Color(0.006, 0.008, 0.012), 0.2, 0.65)
        parent.add_child(intake)

    var hood_scoop := MeshInstance3D.new()
    var scoop_mesh := BoxMesh.new()
    scoop_mesh.size = Vector3(0.58, 0.12, 0.48)
    hood_scoop.mesh = scoop_mesh
    hood_scoop.position = Vector3(0.0, 0.53, -1.02)
    hood_scoop.rotation_degrees = Vector3(-5.0, 0.0, 0.0)
    hood_scoop.material_override = _material(Color(0.025, 0.025, 0.03), 0.72, 0.16)
    parent.add_child(hood_scoop)

    for x in [-0.92, 0.92]:
        var side_intake := MeshInstance3D.new()
        var intake_mesh := BoxMesh.new()
        intake_mesh.size = Vector3(0.10, 0.30, 0.62)
        side_intake.mesh = intake_mesh
        side_intake.position = Vector3(x, 0.05, 0.25)
        side_intake.material_override = _material(Color(0.008, 0.009, 0.012), 0.35, 0.58)
        parent.add_child(side_intake)

    for x in [-0.62, 0.62]:
        var exhaust := MeshInstance3D.new()
        var exhaust_mesh := CylinderMesh.new()
        exhaust_mesh.top_radius = 0.095
        exhaust_mesh.bottom_radius = 0.095
        exhaust_mesh.height = 0.16
        exhaust.mesh = exhaust_mesh
        exhaust.rotation_degrees = Vector3(90.0, 0.0, 0.0)
        exhaust.position = Vector3(x, -0.16, 2.14)
        exhaust.material_override = _material(Color(0.22, 0.23, 0.25), 0.88, 0.14)
        parent.add_child(exhaust)

    var roof_glass := MeshInstance3D.new()
    var glass_mesh := BoxMesh.new()
    glass_mesh.size = Vector3(1.25, 0.035, 1.22)
    roof_glass.mesh = glass_mesh
    roof_glass.position = Vector3(0.0, 0.91, 0.42)
    roof_glass.material_override = _material(Color(0.01, 0.035, 0.055), 0.3, 0.05)
    parent.add_child(roof_glass)

func _add_lights(parent: Node3D) -> void:
    for x in [-0.68, 0.68]:
        var headlight := MeshInstance3D.new()
        var mesh := BoxMesh.new()
        mesh.size = Vector3(0.52, 0.13, 0.12)
        headlight.mesh = mesh
        headlight.position = Vector3(x, 0.22, -2.05)
        headlight.material_override = _emission_material(Color(0.82, 0.94, 1.0), 5.0)
        parent.add_child(headlight)

        var tail := MeshInstance3D.new()
        var tail_mesh := BoxMesh.new()
        tail_mesh.size = Vector3(0.58, 0.14, 0.12)
        tail.mesh = tail_mesh
        tail.position = Vector3(x, 0.18, 2.05)
        tail.material_override = _emission_material(Color(1.0, 0.01, 0.005), 3.0)
        parent.add_child(tail)

func _add_spoiler(parent: Node3D) -> void:
    for x in [-0.52, 0.52]:
        var support := MeshInstance3D.new()
        var mesh := BoxMesh.new()
        mesh.size = Vector3(0.12, 0.58, 0.14)
        support.mesh = mesh
        support.position = Vector3(x, 0.68, 1.68)
        support.material_override = _material(Color(0.02, 0.02, 0.025), 0.7, 0.16)
        parent.add_child(support)

    var wing := MeshInstance3D.new()
    var wing_mesh := BoxMesh.new()
    wing_mesh.size = Vector3(2.05, 0.13, 0.4)
    wing.mesh = wing_mesh
    wing.position = Vector3(0.0, 0.96, 1.68)
    wing.rotation_degrees = Vector3(-7.0, 0.0, 0.0)
    wing.material_override = _material(Color(0.012, 0.012, 0.018), 0.75, 0.14)
    parent.add_child(wing)

func _add_wheels() -> void:
    for pos in [Vector3(-1.02, -0.46, -1.28), Vector3(1.02, -0.46, -1.28), Vector3(-1.02, -0.46, 1.28), Vector3(1.02, -0.46, 1.28)]:
        _add_wheel(pos)

func _add_wheel(pos: Vector3) -> void:
    var wheel_root := Node3D.new()
    wheel_root.position = pos
    add_child(wheel_root)

    var tire := MeshInstance3D.new()
    var tire_mesh := CylinderMesh.new()
    tire_mesh.top_radius = 0.44
    tire_mesh.bottom_radius = 0.44
    tire_mesh.height = 0.30
    tire.mesh = tire_mesh
    tire.rotation_degrees = Vector3(0.0, 0.0, 90.0)
    tire.material_override = _material(Color(0.008, 0.008, 0.01), 0.1, 0.42)
    wheel_root.add_child(tire)

    var rim := MeshInstance3D.new()
    var rim_mesh := CylinderMesh.new()
    rim_mesh.top_radius = 0.23
    rim_mesh.bottom_radius = 0.23
    rim_mesh.height = 0.32
    rim.mesh = rim_mesh
    rim.rotation_degrees = Vector3(0.0, 0.0, 90.0)
    rim.add_to_group("car_rim")
    rim.material_override = _material(Color(0.42, 0.44, 0.48), 0.9, 0.18)
    wheel_root.add_child(rim)

    var brake_disc := MeshInstance3D.new()
    var disc_mesh := CylinderMesh.new()
    disc_mesh.top_radius = 0.16
    disc_mesh.bottom_radius = 0.16
    disc_mesh.height = 0.035
    brake_disc.mesh = disc_mesh
    brake_disc.rotation_degrees = Vector3(0.0, 0.0, 90.0)
    brake_disc.material_override = _material(Color(0.16, 0.17, 0.18), 0.92, 0.2)
    wheel_root.add_child(brake_disc)

    var hub := MeshInstance3D.new()
    var hub_mesh := CylinderMesh.new()
    hub_mesh.top_radius = 0.09
    hub_mesh.bottom_radius = 0.09
    hub_mesh.height = 0.34
    hub.mesh = hub_mesh
    hub.rotation_degrees = Vector3(0.0, 0.0, 90.0)
    hub.material_override = _material(Color(0.08, 0.08, 0.09), 0.75, 0.2)
    wheel_root.add_child(hub)

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
