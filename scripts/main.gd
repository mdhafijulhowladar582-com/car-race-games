extends Node3D

var health_bar: ProgressBar
var health_label: Label
var mobile_controls: CanvasLayer
var game_over_overlay: ColorRect
var game_over_title: Label
var restart_button: Button
var race_label: Label
var race_bar: ProgressBar
var finish_overlay: ColorRect
var finish_button: Button
var countdown_label: Label
var timer_label: Label
var position_label: Label
var checkpoint_label: Label
var result_time_label: Label
var mode_overlay: ColorRect
var mode_label: Label
var selected_mode := "quick_race"
var mode_name := "QUICK RACE"
var selected_car := "SPORTS"
var car_label: Label
var customization_label: Label
var selected_color := Color(0.82, 0.025, 0.02)
var selected_wheels := "SPORT"
var upgrade_level := 0
var garage_overlay: ColorRect
var garage_info_label: Label
var ai_opponents: Array[Node3D] = []
var ai_count := 3
var ambience_player: AudioStreamPlayer3D
var race_finished := false
var race_started := false
var race_elapsed := 0.0
var countdown_time := 3.0
var career_lap_complete := false
var current_checkpoint := 0
var total_checkpoints := 3
var lap := 1
var total_laps := 1
var coins := 0
var xp := 0
var selected_weather := "DAY"
var weather_overlay: ColorRect
var rain_particles: GPUParticles3D
var fog_environment: Environment
var reward_label: Label
var coins_label: Label
var speed_label: Label
var speed_bar: ProgressBar
var mini_progress: ProgressBar
var race_start_z := 15.0
var finish_z := -66.0


func _ready() -> void:
    _build_environment()
    _build_road()
    _build_environment_scenery()
    _build_scenery()
    _build_ambience_audio()
    _build_mobile_controls()
    _build_health_hud()
    _build_race_system()
    _build_ai_opponents()
    _build_game_over_ui()
    _build_mode_select()
    _apply_weather(selected_weather)
    _build_rewards_hud()
    _build_professional_mobile_hud()
    _build_weather_select()

    var car := get_node_or_null("PlayerCar")
    if car:
        car.health_changed.connect(_on_health_changed)
        car.game_over.connect(_on_game_over)
        _on_health_changed(car.health, car.max_health)

func _build_ambience_audio() -> void:
    ambience_player = AudioStreamPlayer3D.new()
    ambience_player.name = "TrackAmbience"
    var stream := _create_ambience()
    ambience_player.stream = stream
    ambience_player.volume_db = -24.0
    ambience_player.max_distance = 80.0
    add_child(ambience_player)
    ambience_player.play()

func _create_ambience() -> AudioStreamWAV:
    var sample_rate := 22050
    var duration := 1.8
    var samples := int(sample_rate * duration)
    var data := PackedByteArray()
    data.resize(samples * 2)
    var rng := RandomNumberGenerator.new()
    rng.seed = 19427

    for i in samples:
        var t := float(i) / sample_rate
        var low := sin(TAU * 95.0 * t) * 0.06
        var mid := sin(TAU * 260.0 * t) * 0.025
        var noise := rng.randf_range(-1.0, 1.0) * 0.018
        data.encode_s16(i * 2, int(clamp(low + mid + noise, -1.0, 1.0) * 8000.0))

    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = sample_rate
    stream.stereo = false
    stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
    stream.loop_begin = 0
    stream.loop_end = samples
    stream.data = data
    return stream

func _build_environment() -> void:
    var world := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.08, 0.1, 0.14)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.55, 0.6, 0.7)
    environment.ambient_light_energy = 0.8
    world.environment = environment
    add_child(world)

    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-55.0, -25.0, 0.0)
    light.light_energy = 1.2
    add_child(light)

func _build_scenery() -> void:
    var grass_material := _make_material(Color(0.08, 0.2, 0.08), 0.0, 0.95)
    var mountain_material := _make_material(Color(0.16, 0.2, 0.24), 0.0, 1.0)

    _add_scenery_ground(Vector3(0.0, -0.25, -25.0), Vector3(70.0, 0.25, 100.0), grass_material)
    _add_mountain(Vector3(-27.0, 5.0, -32.0), Vector3(22.0, 10.0, 28.0), mountain_material)
    _add_mountain(Vector3(31.0, 7.0, -50.0), Vector3(28.0, 14.0, 34.0), mountain_material)

    var tree_positions := [
        Vector3(-10.0, 0.0, 5.0), Vector3(11.0, 0.0, 2.0),
        Vector3(-11.0, 0.0, -10.0), Vector3(10.0, 0.0, -13.0),
        Vector3(-12.0, 0.0, -27.0), Vector3(17.0, 0.5, -29.0),
        Vector3(-11.0, 0.0, -42.0), Vector3(18.0, 0.8, -45.0),
        Vector3(-10.0, 0.0, -58.0), Vector3(17.0, 1.0, -62.0),
        Vector3(-19.0, 0.0, -72.0), Vector3(23.0, 1.0, -73.0)
    ]
    for p in tree_positions:
        _add_tree(p)

    var lamp_positions := [
        Vector3(-7.5, 0.0, 2.0), Vector3(7.5, 0.0, -6.0),
        Vector3(-8.0, 0.0, -19.0), Vector3(12.0, 0.45, -34.0),
        Vector3(-7.5, 0.0, -43.0), Vector3(14.0, 0.9, -58.0)
    ]
    for p in lamp_positions:
        _add_lamp_post(p)

    _add_building(Vector3(-18.0, 0.0, -18.0), Vector3(7.0, 11.0, 8.0), Color(0.3, 0.34, 0.4))
    _add_building(Vector3(20.0, 0.0, -22.0), Vector3(8.0, 14.0, 9.0), Color(0.38, 0.32, 0.27))
    _add_building(Vector3(-20.0, 0.0, -48.0), Vector3(9.0, 9.0, 10.0), Color(0.28, 0.38, 0.44))
    _add_building(Vector3(22.0, 1.0, -56.0), Vector3(8.0, 12.0, 8.0), Color(0.42, 0.34, 0.3))

    _add_road_sign(Vector3(-7.0, 0.0, -8.0), 0.0, "TURN")
    _add_road_sign(Vector3(12.0, 0.5, -31.0), -18.0, "CURVE")
    _add_road_sign(Vector3(-8.0, 0.0, -51.0), 0.0, "RAMP")
    _add_road_sign(Vector3(14.0, 0.8, -61.0), 0.0, "FINISH")

func _add_scenery_ground(position: Vector3, size: Vector3, material: StandardMaterial3D) -> void:
    var ground := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    ground.mesh = mesh
    ground.position = position
    ground.material_override = material
    add_child(ground)

func _add_tree(position: Vector3) -> void:
    var tree := Node3D.new()
    tree.position = position
    add_child(tree)

    var trunk := MeshInstance3D.new()
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.28
    trunk_mesh.bottom_radius = 0.4
    trunk_mesh.height = 2.8
    trunk.mesh = trunk_mesh
    trunk.position.y = 1.4
    trunk.material_override = _make_material(Color(0.25, 0.12, 0.05), 0.0, 0.95)
    tree.add_child(trunk)

    for data in [
        {"y": 3.0, "radius": 1.5},
        {"y": 4.1, "radius": 1.15},
        {"y": 5.0, "radius": 0.8}
    ]:
        var crown := MeshInstance3D.new()
        var crown_mesh := SphereMesh.new()
        crown_mesh.radius = data.radius
        crown_mesh.height = data.radius * 1.7
        crown.mesh = crown_mesh
        crown.position.y = data.y
        crown.material_override = _make_material(Color(0.05, 0.32, 0.09), 0.0, 0.9)
        tree.add_child(crown)

func _add_lamp_post(position: Vector3) -> void:
    var post := Node3D.new()
    post.position = position
    add_child(post)

    var metal := _make_material(Color(0.12, 0.14, 0.17), 0.75, 0.35)
    var pole := MeshInstance3D.new()
    var pole_mesh := CylinderMesh.new()
    pole_mesh.top_radius = 0.09
    pole_mesh.bottom_radius = 0.14
    pole_mesh.height = 4.2
    pole.mesh = pole_mesh
    pole.position.y = 2.1
    pole.material_override = metal
    post.add_child(pole)

    var arm := MeshInstance3D.new()
    var arm_mesh := BoxMesh.new()
    arm_mesh.size = Vector3(1.0, 0.12, 0.12)
    arm.mesh = arm_mesh
    arm.position = Vector3(0.45, 4.0, 0.0)
    arm.material_override = metal
    post.add_child(arm)

    var lamp := MeshInstance3D.new()
    var lamp_mesh := SphereMesh.new()
    lamp_mesh.radius = 0.18
    lamp_mesh.height = 0.25
    lamp.mesh = lamp_mesh
    lamp.position = Vector3(0.88, 3.9, 0.0)
    lamp.material_override = _make_emission_material(Color(1.0, 0.82, 0.45), 1.8)
    post.add_child(lamp)

    var light := OmniLight3D.new()
    light.position = Vector3(0.88, 3.8, 0.0)
    light.omni_range = 7.0
    light.light_energy = 0.65
    light.light_color = Color(1.0, 0.78, 0.45)
    post.add_child(light)

func _add_building(position: Vector3, size: Vector3, color: Color) -> void:
    var building := Node3D.new()
    building.position = position
    add_child(building)

    var body := MeshInstance3D.new()
    var body_mesh := BoxMesh.new()
    body_mesh.size = size
    body.mesh = body_mesh
    body.position.y = size.y * 0.5
    body.material_override = _make_material(color, 0.05, 0.85)
    building.add_child(body)

    var window_material := _make_emission_material(Color(0.65, 0.82, 1.0), 0.45)
    for floor in range(2, max(3, int(size.y / 2.2))):
        for side in [-1.0, 1.0]:
            for x in [-size.x * 0.28, 0.0, size.x * 0.28]:
                var window := MeshInstance3D.new()
                var window_mesh := BoxMesh.new()
                window_mesh.size = Vector3(0.65, 0.85, 0.04)
                window.mesh = window_mesh
                window.position = Vector3(x, floor * 2.0, side * (size.z * 0.5 + 0.025))
                window.material_override = window_material
                building.add_child(window)

func _add_road_sign(position: Vector3, rotation_y: float, text_value: String) -> void:
    var sign := Node3D.new()
    sign.position = position
    sign.rotation_degrees.y = rotation_y
    add_child(sign)

    var pole := MeshInstance3D.new()
    var pole_mesh := CylinderMesh.new()
    pole_mesh.top_radius = 0.06
    pole_mesh.bottom_radius = 0.08
    pole_mesh.height = 2.0
    pole.mesh = pole_mesh
    pole.position.y = 1.0
    pole.material_override = _make_material(Color(0.18, 0.19, 0.21), 0.6, 0.4)
    sign.add_child(pole)

    var board := MeshInstance3D.new()
    var board_mesh := BoxMesh.new()
    board_mesh.size = Vector3(1.8, 0.8, 0.08)
    board.mesh = board_mesh
    board.position = Vector3(0.0, 2.05, 0.0)
    board.material_override = _make_material(Color(0.95, 0.55, 0.04), 0.05, 0.55)
    sign.add_child(board)

    var label := Label3D.new()
    label.text = text_value
    label.position = Vector3(0.0, 2.05, -0.06)
    label.font_size = 48
    label.outline_size = 8
    label.modulate = Color(0.05, 0.05, 0.05)
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    sign.add_child(label)

func _build_environment_scenery() -> void:
    var grass := _make_material(Color(0.07, 0.22, 0.09), 0.0, 0.95)
    var mountain := _make_material(Color(0.12, 0.16, 0.2), 0.0, 1.0)
    var building := _make_material(Color(0.22, 0.25, 0.3), 0.15, 0.82)
    var glass := _make_emission_material(Color(0.12, 0.28, 0.48), 0.45)
    var lamp := _make_material(Color(0.08, 0.09, 0.1), 0.75, 0.35)
    var sign := _make_emission_material(Color(0.95, 0.7, 0.12), 0.2)

    _add_ground(grass)
    _add_mountain_range(mountain)
    _add_tree_line(grass)
    _add_city_blocks(building, glass)
    _add_lamp_posts(lamp)
    _add_track_signs(sign)

func _add_ground(material: StandardMaterial3D) -> void:
    var ground := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(70.0, 0.5, 115.0)
    ground.mesh = mesh
    ground.position = Vector3(4.0, -0.45, -25.0)
    ground.material_override = material
    add_child(ground)

func _add_mountain_range(material: StandardMaterial3D) -> void:
    for i in range(8):
        var m := MeshInstance3D.new()
        var mesh := PrismMesh.new()
        mesh.size = Vector3(12.0, 10.0 + float(i % 3) * 3.0, 8.0)
        m.mesh = mesh
        m.position = Vector3(-28.0 + i * 8.0, 4.5, -72.0)
        m.rotation_degrees.y = float(i * 17)
        m.material_override = material
        add_child(m)

func _add_tree_line(material: StandardMaterial3D) -> void:
    for i in range(10):
        var z := 8.0 - i * 8.0
        _add_tree(Vector3(-11.0, 0.0, z), material, 0.9 + float(i % 3) * 0.12)
        if i > 2:
            _add_tree(Vector3(18.0, 0.2 + float(i) * 0.08, z - 4.0), material, 1.0 + float((i + 1) % 3) * 0.1)

func _add_tree(position: Vector3, material: StandardMaterial3D, scale_value: float) -> void:
    var tree := Node3D.new()
    tree.position = position
    tree.scale = Vector3.ONE * scale_value
    add_child(tree)

    var trunk := MeshInstance3D.new()
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.18
    trunk_mesh.bottom_radius = 0.3
    trunk_mesh.height = 2.4
    trunk.mesh = trunk_mesh
    trunk.position.y = 1.2
    trunk.material_override = _make_material(Color(0.25, 0.12, 0.05), 0.0, 1.0)
    tree.add_child(trunk)

    var crown := MeshInstance3D.new()
    var crown_mesh := SphereMesh.new()
    crown_mesh.radius = 1.45
    crown_mesh.height = 2.8
    crown.mesh = crown_mesh
    crown.position.y = 3.0
    crown.material_override = material
    tree.add_child(crown)

func _add_city_blocks(building_material: StandardMaterial3D, glass_material: StandardMaterial3D) -> void:
    var data := [
        [Vector3(-16.0, 2.5, -8.0), Vector3(6.0, 5.0, 6.0)],
        [Vector3(18.0, 3.5, -18.0), Vector3(7.0, 7.0, 7.0)],
        [Vector3(-18.0, 4.5, -36.0), Vector3(8.0, 9.0, 8.0)],
        [Vector3(20.0, 3.0, -47.0), Vector3(6.0, 6.0, 6.0)]
    ]
    for item in data:
        _add_building(item[0], item[1], building_material, glass_material)

func _add_building(position: Vector3, size: Vector3, building_material: StandardMaterial3D, glass_material: StandardMaterial3D) -> void:
    var building := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    building.mesh = mesh
    building.position = position
    building.material_override = building_material
    add_child(building)

    for y in range(1, maxi(2, int(size.y / 2.0))):
        var window := MeshInstance3D.new()
        var window_mesh := BoxMesh.new()
        window_mesh.size = Vector3(size.x * 0.6, 0.45, 0.06)
        window.mesh = window_mesh
        window.position = position + Vector3(0.0, -size.y * 0.5 + y * 1.5, size.z * 0.51)
        window.material_override = glass_material
        add_child(window)

func _add_lamp_posts(material: StandardMaterial3D) -> void:
    for i in range(7):
        var z := 6.0 - i * 9.0
        _add_lamp_post(Vector3(-8.0, 0.0, z), material, -1.0)
        if i % 2 == 0:
            _add_lamp_post(Vector3(15.0, 0.45 + float(i) * 0.06, z - 3.0), material, 1.0)

func _add_lamp_post(position: Vector3, material: StandardMaterial3D, side: float) -> void:
    var post := Node3D.new()
    post.position = position
    add_child(post)

    var pole := MeshInstance3D.new()
    var pole_mesh := CylinderMesh.new()
    pole_mesh.top_radius = 0.08
    pole_mesh.bottom_radius = 0.12
    pole_mesh.height = 4.0
    pole.mesh = pole_mesh
    pole.position.y = 2.0
    pole.material_override = material
    post.add_child(pole)

    var arm := MeshInstance3D.new()
    var arm_mesh := BoxMesh.new()
    arm_mesh.size = Vector3(1.1, 0.12, 0.12)
    arm.mesh = arm_mesh
    arm.position = Vector3(side * 0.45, 4.0, 0.0)
    arm.material_override = material
    post.add_child(arm)

    var light := OmniLight3D.new()
    light.position = Vector3(side * 0.85, 3.85, 0.0)
    light.omni_range = 8.0
    light.light_energy = 1.0
    light.light_color = Color(1.0, 0.82, 0.55)
    post.add_child(light)

    var bulb := MeshInstance3D.new()
    var bulb_mesh := SphereMesh.new()
    bulb_mesh.radius = 0.16
    bulb_mesh.height = 0.32
    bulb.mesh = bulb_mesh
    bulb.position = light.position
    bulb.material_override = _make_emission_material(Color(1.0, 0.75, 0.35), 2.0)
    post.add_child(bulb)

func _add_track_signs(material: StandardMaterial3D) -> void:
    _add_sign(Vector3(-7.2, 1.2, -12.0), 8.0, "CURVE")
    _add_sign(Vector3(15.0, 1.3, -34.0), -18.0, "RAMP")
    _add_sign(Vector3(14.5, 1.3, -57.0), -10.0, "FINISH")

func _add_sign(position: Vector3, rotation_y: float, text_value: String) -> void:
    var sign_root := Node3D.new()
    sign_root.position = position
    sign_root.rotation_degrees.y = rotation_y
    add_child(sign_root)

    var pole := MeshInstance3D.new()
    var pole_mesh := CylinderMesh.new()
    pole_mesh.top_radius = 0.06
    pole_mesh.bottom_radius = 0.09
    pole_mesh.height = 2.2
    pole.mesh = pole_mesh
    pole.position.y = 1.1
    pole.material_override = _make_material(Color(0.16, 0.17, 0.19), 0.55, 0.5)
    sign_root.add_child(pole)

    var board := MeshInstance3D.new()
    var board_mesh := BoxMesh.new()
    board_mesh.size = Vector3(2.8, 1.0, 0.12)
    board.mesh = board_mesh
    board.position.y = 2.35
    board.material_override = material
    sign_root.add_child(board)

func _build_road() -> void:
    var road_material := _make_material(Color(0.075, 0.08, 0.095), 0.0, 0.9)
    var curb_material := _make_material(Color(0.75, 0.78, 0.82), 0.15, 0.7)
    var red_curb_material := _make_material(Color(0.72, 0.08, 0.05), 0.05, 0.72)
    var marking_material := _make_emission_material(Color(0.95, 0.95, 0.82), 0.25)

    var segment_data := [
        {"position": Vector3(0.0, -0.1, 10.0), "size": Vector3(12.0, 0.2, 20.0), "rotation": 0.0},
        {"position": Vector3(0.0, -0.1, -8.0), "size": Vector3(12.0, 0.2, 18.0), "rotation": 0.0},
        {"position": Vector3(2.0, 0.0, -24.0), "size": Vector3(12.0, 0.2, 16.0), "rotation": -8.0},
        {"position": Vector3(6.0, 0.22, -39.0), "size": Vector3(12.0, 0.2, 15.0), "rotation": -18.0},
        {"position": Vector3(9.0, 0.48, -52.0), "size": Vector3(12.0, 0.2, 13.0), "rotation": -10.0},
        {"position": Vector3(10.0, 0.78, -64.0), "size": Vector3(12.0, 0.2, 12.0), "rotation": 0.0}
    ]

    for data in segment_data:
        _add_road_segment(data.position, data.size, data.rotation, road_material, curb_material, red_curb_material, marking_material)

    _add_ramp(Vector3(-1.5, 0.0, -16.5), 0.0)
    _add_ramp(Vector3(6.8, 0.34, -47.5), -18.0)

    _add_guardrail(Vector3(-6.35, 0.1, -20.0), 0.0, 14.0)
    _add_guardrail(Vector3(10.7, 0.65, -40.0), -18.0, 12.0)
    _add_guardrail(Vector3(15.0, 0.85, -53.0), -10.0, 9.0)
    _add_tunnel(Vector3(9.0, 0.48, -53.0), -10.0, 10.0)

    _add_barrier(Vector3(-4.0, 0.65, -5.0), 0.0)
    _add_barrier(Vector3(3.5, 0.62, -30.0), -8.0)
    _add_barrier(Vector3(11.0, 1.15, -43.0), -18.0)
    _add_barrel(Vector3(1.8, 0.7, -34.0))
    _add_barrel(Vector3(8.0, 1.0, -57.0))

func _make_material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = metallic
    material.roughness = roughness
    return material

func _make_emission_material(color: Color, energy: float) -> StandardMaterial3D:
    var material := _make_material(color, 0.0, 0.5)
    material.emission_enabled = true
    material.emission = color
    material.emission_energy_multiplier = energy
    return material

func _add_road_segment(position: Vector3, size: Vector3, rotation_y: float, material: StandardMaterial3D, curb_material: StandardMaterial3D, red_curb_material: StandardMaterial3D, marking_material: StandardMaterial3D) -> void:
    var road_body := StaticBody3D.new()
    road_body.position = position
    road_body.rotation_degrees.y = rotation_y
    add_child(road_body)

    var road_mesh := MeshInstance3D.new()
    var road_box := BoxMesh.new()
    road_box.size = size
    road_mesh.mesh = road_box
    road_mesh.material_override = material
    road_body.add_child(road_mesh)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    road_body.add_child(collision)

    var curb_height := 0.12
    var curb_width := 0.3
    for side in [-1.0, 1.0]:
        var curb := MeshInstance3D.new()
        var curb_mesh := BoxMesh.new()
        curb_mesh.size = Vector3(curb_width, curb_height, size.z)
        curb.mesh = curb_mesh
        curb.position = Vector3(side * (size.x * 0.5 + curb_width * 0.5), size.y * 0.5 + curb_height * 0.5, 0.0)
        curb.material_override = curb_material
        road_body.add_child(curb)

        var red_curb := MeshInstance3D.new()
        var red_mesh := BoxMesh.new()
        red_mesh.size = Vector3(curb_width, curb_height + 0.01, minf(1.5, size.z * 0.12))
        red_curb.mesh = red_mesh
        red_curb.position = Vector3(side * (size.x * 0.5 + curb_width * 0.5), size.y * 0.5 + curb_height * 0.5, -size.z * 0.36)
        red_curb.material_override = red_curb_material
        road_body.add_child(red_curb)

    var dash_count := maxi(2, int(size.z / 3.0))
    for i in range(dash_count):
        var dash := MeshInstance3D.new()
        var dash_mesh := BoxMesh.new()
        dash_mesh.size = Vector3(0.16, 0.025, 1.35)
        dash.mesh = dash_mesh
        dash.position = Vector3(0.0, size.y * 0.5 + 0.025, -size.z * 0.5 + 1.8 + i * 3.0)
        dash.material_override = marking_material
        road_body.add_child(dash)

func _add_guardrail(position: Vector3, rotation_y: float, length: float) -> void:
    var rail := StaticBody3D.new()
    rail.position = position
    rail.rotation_degrees.y = rotation_y
    add_child(rail)

    var rail_material := _make_material(Color(0.35, 0.38, 0.42), 0.75, 0.35)
    var post_material := _make_material(Color(0.16, 0.18, 0.2), 0.7, 0.4)

    var beam := MeshInstance3D.new()
    var beam_mesh := BoxMesh.new()
    beam_mesh.size = Vector3(0.18, 0.5, length)
    beam.mesh = beam_mesh
    beam.position.y = 0.85
    beam.material_override = rail_material
    rail.add_child(beam)

    var post_count := maxi(2, int(length / 2.5))
    for i in range(post_count):
        var post := MeshInstance3D.new()
        var post_mesh := BoxMesh.new()
        post_mesh.size = Vector3(0.16, 0.85, 0.16)
        post.mesh = post_mesh
        post.position = Vector3(0.0, 0.45, -length * 0.5 + 0.8 + i * (length - 1.6) / float(post_count - 1))
        post.material_override = post_material
        rail.add_child(post)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(0.35, 1.0, length)
    collision.shape = shape
    collision.position.y = 0.7
    rail.add_child(collision)

func _add_ramp(position: Vector3, rotation_y: float) -> void:
    var ramp := StaticBody3D.new()
    ramp.position = position
    ramp.rotation_degrees.y = rotation_y
    add_child(ramp)

    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(5.0, 0.7, 6.0)
    mesh_instance.mesh = mesh
    mesh_instance.position = Vector3(0.0, 0.25, 0.0)
    mesh_instance.rotation_degrees.x = -10.0
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.2, 0.24, 0.3)
    material.metallic = 0.25
    mesh_instance.material_override = material
    ramp.add_child(mesh_instance)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(5.0, 0.7, 6.0)
    collision.shape = shape
    collision.position = Vector3(0.0, 0.25, 0.0)
    collision.rotation_degrees.x = -10.0
    ramp.add_child(collision)

    var stripe := MeshInstance3D.new()
    var stripe_mesh := BoxMesh.new()
    stripe_mesh.size = Vector3(4.2, 0.05, 0.7)
    stripe.mesh = stripe_mesh
    stripe.position = Vector3(0.0, 0.65, -1.2)
    var stripe_material := StandardMaterial3D.new()
    stripe_material.albedo_color = Color(1.0, 0.72, 0.05)
    stripe_material.emission_enabled = true
    stripe_material.emission = Color(0.8, 0.35, 0.02)
    stripe.material_override = stripe_material
    ramp.add_child(stripe)

func _add_tunnel(position: Vector3, rotation_y: float, length: float) -> void:
    var tunnel := Node3D.new()
    tunnel.position = position
    tunnel.rotation_degrees.y = rotation_y
    add_child(tunnel)

    var concrete := _make_material(Color(0.18, 0.2, 0.23), 0.2, 0.82)

    var roof := MeshInstance3D.new()
    var roof_mesh := BoxMesh.new()
    roof_mesh.size = Vector3(12.8, 0.45, length)
    roof.mesh = roof_mesh
    roof.position = Vector3(0.0, 4.4, 0.0)
    roof.material_override = concrete
    tunnel.add_child(roof)

    for side in [-1.0, 1.0]:
        var wall := MeshInstance3D.new()
        var wall_mesh := BoxMesh.new()
        wall_mesh.size = Vector3(0.45, 4.4, length)
        wall.mesh = wall_mesh
        wall.position = Vector3(side * 6.15, 2.2, 0.0)
        wall.material_override = concrete
        tunnel.add_child(wall)

    for side in [-1.0, 1.0]:
        for z in [-length * 0.5, length * 0.5]:
            var light := OmniLight3D.new()
            light.position = Vector3(side * 4.6, 3.5, z)
            light.omni_range = 7.0
            light.light_energy = 1.3
            light.light_color = Color(0.8, 0.88, 1.0)
            tunnel.add_child(light)

func _add_barrier(position: Vector3, rotation_y: float) -> void:
    var obstacle := StaticBody3D.new()
    obstacle.position = position
    obstacle.rotation_degrees.y = rotation_y
    add_child(obstacle)

    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(3.0, 1.0, 0.55)
    mesh_instance.mesh = mesh
    mesh_instance.position.y = 0.5
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.9, 0.12, 0.04)
    mesh_instance.material_override = material
    obstacle.add_child(mesh_instance)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(3.0, 1.0, 0.55)
    collision.shape = shape
    collision.position.y = 0.5
    obstacle.add_child(collision)

func _add_barrel(position: Vector3) -> void:
    var obstacle := StaticBody3D.new()
    obstacle.position = position
    add_child(obstacle)

    var mesh_instance := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.45
    mesh.bottom_radius = 0.45
    mesh.height = 1.1
    mesh_instance.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.95, 0.45, 0.03)
    mesh_instance.material_override = material
    obstacle.add_child(mesh_instance)

    var collision := CollisionShape3D.new()
    var shape := CylinderShape3D.new()
    shape.radius = 0.45
    shape.height = 1.1
    collision.shape = shape
    obstacle.add_child(collision)

func _build_car_select(parent: Control) -> void:
    car_label = Label.new()
    car_label.text = "CAR: SPORTS\nSpeed 34 | Acceleration 18 | Handling 2.2"
    car_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    car_label.set_anchors_preset(Control.PRESET_CENTER)
    car_label.position = Vector2(-360.0, -130.0)
    car_label.size = Vector2(720.0, 80.0)
    car_label.add_theme_font_size_override("font_size", 22)
    parent.add_child(car_label)

    _add_car_button(parent, "SPORTS", Vector2(-310.0, -45.0))
    _add_car_button(parent, "MUSCLE", Vector2(-105.0, -45.0))
    _add_car_button(parent, "GT", Vector2(100.0, -45.0))

    customization_label = Label.new()
    customization_label.text = "COLOR: RED   WHEELS: SPORT   UPGRADE: 0/3"
    customization_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    customization_label.set_anchors_preset(Control.PRESET_CENTER)
    customization_label.position = Vector2(-360.0, -55.0)
    customization_label.size = Vector2(720.0, 55.0)
    customization_label.add_theme_font_size_override("font_size", 19)
    parent.add_child(customization_label)

    _add_custom_button(parent, "RED", Vector2(-310.0, 115.0), "color_red")
    _add_custom_button(parent, "BLUE", Vector2(-105.0, 115.0), "color_blue")
    _add_custom_button(parent, "GREEN", Vector2(100.0, 115.0), "color_green")
    _add_custom_button(parent, "SPORT WHEELS", Vector2(-310.0, 180.0), "wheel_sport")
    _add_custom_button(parent, "BLACK WHEELS", Vector2(-105.0, 180.0), "wheel_black")
    _add_custom_button(parent, "GOLD WHEELS", Vector2(100.0, 180.0), "wheel_gold")
    _add_custom_button(parent, "UPGRADE +", Vector2(-95.0, 245.0), "upgrade")
    _build_garage(parent)

func _add_car_button(parent: Control, car_name: String, button_position: Vector2) -> void:
    var button := Button.new()
    button.text = car_name
    button.set_anchors_preset(Control.PRESET_CENTER)
    button.position = button_position
    button.size = Vector2(190.0, 64.0)
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 20)
    button.pressed.connect(_select_car.bind(car_name))
    parent.add_child(button)

func _add_custom_button(parent: Control, button_text: String, button_position: Vector2, action_name: String) -> void:
    var button := Button.new()
    button.text = button_text
    button.set_anchors_preset(Control.PRESET_CENTER)
    button.position = button_position
    button.size = Vector2(190.0, 54.0)
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 17)
    button.pressed.connect(_apply_customization.bind(action_name))
    parent.add_child(button)

func _apply_customization(action_name: String) -> void:
    if action_name == "color_red":
        selected_color = Color(0.82, 0.025, 0.02)
    elif action_name == "color_blue":
        selected_color = Color(0.04, 0.08, 0.72)
    elif action_name == "color_green":
        selected_color = Color(0.04, 0.55, 0.18)
    elif action_name == "wheel_black":
        selected_wheels = "BLACK"
    elif action_name == "wheel_gold":
        selected_wheels = "GOLD"
    elif action_name == "wheel_sport":
        selected_wheels = "SPORT"
    elif action_name == "upgrade":
        upgrade_level = mini(upgrade_level + 1, 3)
    _refresh_customization_label()
    if is_instance_valid(garage_info_label):
        garage_info_label.text = "CAR: %s\\nCOLOR: %s\\nWHEELS: %s\\nUPGRADE: %d/3\\n\\nSPEED: %d   ACCEL: %d   HANDLING: %.1f" % [_garage_car_name(), _garage_color_name(), selected_wheels, upgrade_level, _garage_speed(), _garage_accel(), _garage_handling()]

func _refresh_customization_label() -> void:
    var color_name := "RED"
    if selected_color == Color(0.04, 0.08, 0.72):
        color_name = "BLUE"
    elif selected_color == Color(0.04, 0.55, 0.18):
        color_name = "GREEN"
    customization_label.text = "COLOR: %s   WHEELS: %s   UPGRADE: %d/3" % [color_name, selected_wheels, upgrade_level]

func _select_car(car_name: String) -> void:
    selected_car = car_name
    if car_name == "MUSCLE":
        car_label.text = "CAR: MUSCLE\nSpeed 30 | Acceleration 20 | Handling 1.8"
    elif car_name == "GT":
        car_label.text = "CAR: GT\nSpeed 38 | Acceleration 16 | Handling 2.4"
    else:
        car_label.text = "CAR: SPORTS\nSpeed 34 | Acceleration 18 | Handling 2.2"

func _build_weather_select() -> void:
    var panel := Panel.new()
    panel.position = Vector2(30.0, 300.0)
    panel.size = Vector2(320.0, 220.0)
    panel.z_index = 5
    mode_overlay.add_child(panel)

    var title := Label.new()
    title.text = "WEATHER"
    title.position = Vector2(20.0, 12.0)
    title.size = Vector2(280.0, 35.0)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 22)
    panel.add_child(title)

    _add_weather_button(panel, "DAY", Vector2(20.0, 55.0), "DAY")
    _add_weather_button(panel, "NIGHT", Vector2(20.0, 110.0), "NIGHT")
    _add_weather_button(panel, "RAIN + FOG", Vector2(20.0, 165.0), "RAIN")

func _add_weather_button(parent: Control, text_value: String, button_position: Vector2, weather_value: String) -> void:
    var button := Button.new()
    button.text = text_value
    button.position = button_position
    button.size = Vector2(280.0, 45.0)
    button.focus_mode = Control.FOCUS_NONE
    button.pressed.connect(_select_weather.bind(weather_value))
    parent.add_child(button)

func _select_weather(weather_value: String) -> void:
    selected_weather = weather_value
    _apply_weather(selected_weather)

func _apply_weather(weather_value: String) -> void:
    var world := get_node_or_null("WorldEnvironment") as WorldEnvironment
    if not world:
        return
    var environment := world.environment
    if weather_value == "NIGHT":
        environment.background_color = Color(0.015, 0.025, 0.07)
        environment.ambient_light_color = Color(0.2, 0.25, 0.45)
        environment.ambient_light_energy = 0.42
    elif weather_value == "RAIN":
        environment.background_color = Color(0.06, 0.075, 0.1)
        environment.ambient_light_color = Color(0.38, 0.42, 0.5)
        environment.ambient_light_energy = 0.58
        environment.fog_enabled = true
        environment.fog_light_color = Color(0.3, 0.34, 0.4)
        environment.fog_density = 0.012
        _ensure_rain()
    else:
        environment.background_color = Color(0.08, 0.1, 0.14)
        environment.ambient_light_color = Color(0.55, 0.6, 0.7)
        environment.ambient_light_energy = 0.8
        environment.fog_enabled = false
        if is_instance_valid(rain_particles):
            rain_particles.emitting = false

func _ensure_rain() -> void:
    if is_instance_valid(rain_particles):
        rain_particles.emitting = true
        return
    rain_particles = GPUParticles3D.new()
    rain_particles.name = "RainParticles"
    rain_particles.amount = 260
    rain_particles.lifetime = 0.8
    rain_particles.visibility_aabb = AABB(Vector3(-35.0, -1.0, -80.0), Vector3(70.0, 28.0, 100.0))
    var material := ParticleProcessMaterial.new()
    material.direction = Vector3(0.0, -1.0, 0.0)
    material.initial_velocity_min = 22.0
    material.initial_velocity_max = 30.0
    material.gravity = Vector3(0.0, -5.0, 0.0)
    material.scale_min = 0.025
    material.scale_max = 0.05
    rain_particles.process_material = material
    var mesh := BoxMesh.new()
    mesh.size = Vector3(0.025, 0.35, 0.025)
    rain_particles.draw_pass_1 = mesh
    rain_particles.position = Vector3(4.0, 13.0, -25.0)
    add_child(rain_particles)
    rain_particles.emitting = true

func _build_garage(parent: Control) -> void:
    var garage_button := Button.new()
    garage_button.text = "GARAGE"
    garage_button.set_anchors_preset(Control.PRESET_CENTER)
    garage_button.position = Vector2(-360.0, 315.0)
    garage_button.size = Vector2(180.0, 58.0)
    garage_button.focus_mode = Control.FOCUS_NONE
    garage_button.add_theme_font_size_override("font_size", 20)
    garage_button.pressed.connect(_open_garage)
    parent.add_child(garage_button)

func _open_garage() -> void:
    if is_instance_valid(garage_overlay):
        garage_overlay.queue_free()

    garage_overlay = ColorRect.new()
    garage_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    garage_overlay.color = Color(0.015, 0.02, 0.03, 0.96)
    garage_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    garage_overlay.z_index = 50
    mode_overlay.add_child(garage_overlay)

    var title := Label.new()
    title.text = "🏪 GARAGE"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.set_anchors_preset(Control.PRESET_CENTER)
    title.position = Vector2(-360.0, -300.0)
    title.size = Vector2(720.0, 65.0)
    title.add_theme_font_size_override("font_size", 42)
    garage_overlay.add_child(title)

    garage_info_label = Label.new()
    garage_info_label.text = "CAR: %s\nCOLOR: %s\nWHEELS: %s\nUPGRADE: %d/3\n\nSPEED: %d   ACCEL: %d   HANDLING: %.1f" % [_garage_car_name(), _garage_color_name(), selected_wheels, upgrade_level, _garage_speed(), _garage_accel(), _garage_handling()]
    garage_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    garage_info_label.set_anchors_preset(Control.PRESET_CENTER)
    garage_info_label.position = Vector2(-300.0, -180.0)
    garage_info_label.size = Vector2(600.0, 190.0)
    garage_info_label.add_theme_font_size_override("font_size", 25)
    garage_overlay.add_child(garage_info_label)

    var close_button := Button.new()
    close_button.text = "BACK TO RACE SETUP"
    close_button.set_anchors_preset(Control.PRESET_CENTER)
    close_button.position = Vector2(-180.0, 190.0)
    close_button.size = Vector2(360.0, 70.0)
    close_button.focus_mode = Control.FOCUS_NONE
    close_button.add_theme_font_size_override("font_size", 22)
    close_button.pressed.connect(_close_garage)
    garage_overlay.add_child(close_button)

func _close_garage() -> void:
    if is_instance_valid(garage_overlay):
        garage_overlay.queue_free()
        garage_overlay = null

func _garage_car_name() -> String:
    return selected_car

func _garage_color_name() -> String:
    if selected_color == Color(0.04, 0.08, 0.72):
        return "BLUE"
    if selected_color == Color(0.04, 0.55, 0.18):
        return "GREEN"
    return "RED"

func _garage_speed() -> int:
    var speed := 34
    if selected_car == "MUSCLE":
        speed = 30
    elif selected_car == "GT":
        speed = 38
    return speed + upgrade_level * 1.5

func _garage_accel() -> int:
    var accel := 18
    if selected_car == "MUSCLE":
        accel = 20
    elif selected_car == "GT":
        accel = 16
    return accel + upgrade_level * 0.8

func _garage_handling() -> float:
    if selected_car == "MUSCLE":
        return 1.8
    if selected_car == "GT":
        return 2.4
    return 2.2

func _build_mode_select() -> void:
    var canvas := CanvasLayer.new()
    canvas.name = "ModeSelectUI"
    canvas.layer = 40
    add_child(canvas)

    mode_overlay = ColorRect.new()
    mode_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mode_overlay.color = Color(0.015, 0.02, 0.035, 0.94)
    mode_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    canvas.add_child(mode_overlay)

    var title := Label.new()
    title.text = "🏆 SELECT GAME MODE"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.set_anchors_preset(Control.PRESET_CENTER)
    title.position = Vector2(-360.0, -250.0)
    title.size = Vector2(720.0, 80.0)
    title.add_theme_font_size_override("font_size", 46)
    mode_overlay.add_child(title)

    mode_label = Label.new()
    mode_label.text = "QUICK RACE\nRace against 3 AI opponents"
    mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    mode_label.set_anchors_preset(Control.PRESET_CENTER)
    mode_label.position = Vector2(-360.0, -150.0)
    mode_label.size = Vector2(720.0, 90.0)
    mode_label.add_theme_font_size_override("font_size", 24)
    mode_overlay.add_child(mode_label)

    _build_car_select(mode_overlay)

    _add_mode_button(mode_overlay, "QUICK RACE", Vector2(-310.0, 45.0), "quick_race")
    _add_mode_button(mode_overlay, "TIME TRIAL", Vector2(-105.0, 45.0), "time_trial")
    _add_mode_button(mode_overlay, "CAREER", Vector2(100.0, 45.0), "career")

    var start := Button.new()
    start.text = "START RACE"
    start.set_anchors_preset(Control.PRESET_CENTER)
    start.position = Vector2(-170.0, 315.0)
    start.size = Vector2(340.0, 78.0)
    start.focus_mode = Control.FOCUS_NONE
    start.add_theme_font_size_override("font_size", 28)
    start.pressed.connect(_start_selected_mode)
    mode_overlay.add_child(start)

func _add_mode_button(parent: Control, text_value: String, button_position: Vector2, mode_value: String) -> void:
    var button := Button.new()
    button.text = text_value
    button.set_anchors_preset(Control.PRESET_CENTER)
    button.position = button_position
    button.size = Vector2(190.0, 72.0)
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 20)
    button.pressed.connect(_select_mode.bind(mode_value))
    parent.add_child(button)

func _select_mode(mode_value: String) -> void:
    selected_mode = mode_value
    if mode_value == "time_trial":
        mode_name = "TIME TRIAL"
        mode_label.text = "TIME TRIAL\nRace alone and beat your best time"
    elif mode_value == "career":
        mode_name = "CAREER"
        mode_label.text = "CAREER\nComplete a 3-lap championship race"
    else:
        mode_name = "QUICK RACE"
        mode_label.text = "QUICK RACE\nRace against 3 AI opponents"

func _start_selected_mode() -> void:
    if is_instance_valid(mode_overlay):
        mode_overlay.queue_free()
    if selected_mode == "time_trial":
        for ai in ai_opponents:
            if is_instance_valid(ai):
                ai.queue_free()
        ai_opponents.clear()
        total_laps = 1
    elif selected_mode == "career":
        total_laps = 3
    else:
        total_laps = 1
    race_label.text = mode_name + " | " + selected_car + " 0%"
    var car := get_node_or_null("PlayerCar")
    if car and car.has_method("configure_car"):
        car.configure_car(selected_car)
        if car.has_method("customize_car"):
            car.customize_car(selected_color, selected_wheels, upgrade_level)
    _start_race_countdown()

func _start_race_countdown() -> void:
    countdown_label = Label.new()
    countdown_label.name = "Countdown"
    countdown_label.set_anchors_preset(Control.PRESET_CENTER)
    countdown_label.position = Vector2(-180.0, -120.0)
    countdown_label.size = Vector2(360.0, 120.0)
    countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    countdown_label.add_theme_font_size_override("font_size", 72)
    countdown_label.text = "3"
    var canvas := get_node_or_null("RaceHUD") as CanvasLayer
    if canvas:
        canvas.add_child(countdown_label)
    _countdown_step()

func _countdown_step() -> void:
    if not is_instance_valid(countdown_label):
        return
    var value := int(ceil(countdown_time))
    if value > 0:
        countdown_label.text = str(value)
        countdown_time -= 1.0
        get_tree().create_timer(1.0).timeout.connect(_countdown_step)
    else:
        countdown_label.text = "GO!"
        race_started = true
        for ai in ai_opponents:
            if is_instance_valid(ai) and ai.has_method("start_race"):
                ai.start_race()
        var tween := create_tween()
        tween.tween_property(countdown_label, "modulate:a", 0.0, 0.6)
        tween.finished.connect(countdown_label.queue_free)

func _build_ai_opponents() -> void:
    var route: Array[Vector3] = [
        Vector3(0.0, 0.95, 6.0),
        Vector3(0.0, 0.95, -8.0),
        Vector3(2.0, 1.05, -24.0),
        Vector3(6.0, 1.25, -39.0),
        Vector3(9.0, 1.5, -52.0),
        Vector3(10.0, 1.8, -65.0)
    ]
    var ai_script := load("res://scripts/ai_car.gd")
    for i in range(ai_count):
        var ai := CharacterBody3D.new()
        ai.name = "AIOpponent%d" % (i + 1)
        ai.position = Vector3(-3.0 + i * 3.0, 1.0, 19.0 + i * 2.0)
        ai.set_script(ai_script)
        add_child(ai)
        ai.call("setup", route)
        ai_opponents.append(ai)

func _get_player_position_rank() -> int:
    var player := get_node_or_null("PlayerCar")
    if not player:
        return 1
    var player_progress := _race_progress_for_z(player.global_position.z)
    var rank := 1
    for ai in ai_opponents:
        if is_instance_valid(ai):
            if _race_progress_for_z(ai.global_position.z) > player_progress:
                rank += 1
    return rank

func _race_progress_for_z(z_value: float) -> float:
    return clamp((race_start_z - z_value) / max(abs(finish_z - race_start_z), 0.01), 0.0, 1.0)

func _build_race_system() -> void:
    _add_finish_line()
    _add_race_checkpoints()

    var canvas := CanvasLayer.new()
    canvas.name = "RaceHUD"
    add_child(canvas)

    race_label = Label.new()
    race_label.position = Vector2(28.0, 122.0)
    race_label.size = Vector2(330.0, 34.0)
    race_label.text = "RACE 0%"
    race_label.add_theme_font_size_override("font_size", 22)
    canvas.add_child(race_label)

    race_bar = ProgressBar.new()
    race_bar.position = Vector2(28.0, 160.0)
    race_bar.size = Vector2(330.0, 18.0)
    race_bar.min_value = 0.0
    race_bar.max_value = 100.0
    race_bar.value = 0.0
    race_bar.show_percentage = false
    canvas.add_child(race_bar)

    checkpoint_label = Label.new()
    checkpoint_label.name = "CheckpointInfo"
    checkpoint_label.position = Vector2(28.0, 184.0)
    checkpoint_label.size = Vector2(330.0, 30.0)
    checkpoint_label.text = "FINISH: 81m"
    checkpoint_label.add_theme_font_size_override("font_size", 16)
    canvas.add_child(checkpoint_label)

    timer_label = Label.new()
    timer_label.position = Vector2(28.0, 218.0)
    timer_label.size = Vector2(330.0, 30.0)
    timer_label.text = "TIME 00:00.00"
    timer_label.add_theme_font_size_override("font_size", 18)
    canvas.add_child(timer_label)

    position_label = Label.new()
    position_label.position = Vector2(28.0, 250.0)
    position_label.size = Vector2(330.0, 30.0)
    position_label.text = "POSITION 1 / 1"
    position_label.add_theme_font_size_override("font_size", 18)
    canvas.add_child(position_label)

    var lap_label := Label.new()
    lap_label.name = "LapInfo"
    lap_label.position = Vector2(28.0, 282.0)
    lap_label.size = Vector2(330.0, 30.0)
    lap_label.text = "LAP 1 / 1"
    lap_label.add_theme_font_size_override("font_size", 18)
    canvas.add_child(lap_label)

func _add_race_checkpoints() -> void:
    var checkpoint_positions := [Vector3(0.0, 1.0, -8.0), Vector3(5.0, 1.0, -30.0), Vector3(9.5, 1.4, -51.0)]
    for i in range(checkpoint_positions.size()):
        var checkpoint := Area3D.new()
        checkpoint.name = "Checkpoint%d" % (i + 1)
        checkpoint.position = checkpoint_positions[i]
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = Vector3(11.5, 2.2, 1.2)
        collision.shape = shape
        checkpoint.add_child(collision)
        checkpoint.body_entered.connect(_on_checkpoint_body_entered.bind(i))
        add_child(checkpoint)

func _on_checkpoint_body_entered(body: Node3D, index: int) -> void:
    if not race_started or race_finished or body.name != "PlayerCar" or index != current_checkpoint:
        return
    current_checkpoint += 1
    if is_instance_valid(checkpoint_label):
        checkpoint_label.text = "CHECKPOINT %d / %d" % [current_checkpoint, total_checkpoints] if current_checkpoint < total_checkpoints else "CHECKPOINTS COMPLETE"

func _format_race_time(value: float) -> String:
    var minutes := int(value / 60.0)
    var seconds := fmod(value, 60.0)
    return "%02d:%05.2f" % [minutes, seconds]

func _add_finish_line() -> void:
    var finish := Area3D.new()
    finish.name = "FinishLine"
    finish.position = Vector3(10.0, 1.05, -66.0)
    add_child(finish)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(12.0, 2.2, 1.0)
    collision.shape = shape
    finish.add_child(collision)

    var stripe := MeshInstance3D.new()
    var stripe_mesh := BoxMesh.new()
    stripe_mesh.size = Vector3(12.0, 0.06, 1.0)
    stripe.mesh = stripe_mesh
    stripe.position.y = -0.98
    var stripe_material := StandardMaterial3D.new()
    stripe_material.albedo_color = Color(1.0, 1.0, 1.0)
    stripe_material.emission_enabled = true
    stripe_material.emission = Color(0.5, 0.5, 0.5)
    stripe.material_override = stripe_material
    finish.add_child(stripe)

    for x in [-4.5, -3.0, -1.5, 0.0, 1.5, 3.0, 4.5]:
        var tile := MeshInstance3D.new()
        var tile_mesh := BoxMesh.new()
        tile_mesh.size = Vector3(1.5, 0.07, 1.02)
        tile.mesh = tile_mesh
        tile.position = Vector3(x, -0.93, 0.0)
        var tile_material := StandardMaterial3D.new()
        tile_material.albedo_color = Color(0.04 if int((x + 4.5) / 1.5) % 2 == 0 else 0.9, 0.04, 0.04)
        tile.material_override = tile_material
        finish.add_child(tile)

    var arch_left := MeshInstance3D.new()
    var arch_mesh := BoxMesh.new()
    arch_mesh.size = Vector3(0.35, 3.0, 0.35)
    arch_left.mesh = arch_mesh
    arch_left.position = Vector3(-5.3, 1.5, 0.0)
    finish.add_child(arch_left)

    var arch_right := arch_left.duplicate()
    arch_right.position.x = 5.3
    finish.add_child(arch_right)

    var banner := MeshInstance3D.new()
    var banner_mesh := BoxMesh.new()
    banner_mesh.size = Vector3(10.6, 0.65, 0.28)
    banner.mesh = banner_mesh
    banner.position = Vector3(0.0, 3.0, 0.0)
    var banner_material := StandardMaterial3D.new()
    banner_material.albedo_color = Color(0.08, 0.08, 0.1)
    banner.material_override = banner_material
    finish.add_child(banner)

    finish.body_entered.connect(_on_finish_body_entered)

func _process(delta: float) -> void:
    if race_finished:
        return

    var car := get_node_or_null("PlayerCar")
    if not car:
        return

    if race_started:
        race_elapsed += delta
    _update_professional_mobile_hud()
    if is_instance_valid(timer_label):
        timer_label.text = "TIME " + _format_race_time(race_elapsed)
    if is_instance_valid(position_label):
        position_label.text = "POSITION %d / %d" % [_get_player_position_rank(), ai_opponents.size() + 1] if selected_mode != "time_trial" else "TIME TRIAL 1 / 1"
    var lap_label := get_node_or_null("RaceHUD/LapInfo") as Label
    if is_instance_valid(lap_label):
        lap_label.text = "LAP %d / %d" % [lap, total_laps]

    for ai in ai_opponents:
        if is_instance_valid(ai) and not bool(ai.get("finished")) and ai.global_position.z <= finish_z:
            ai.set("finished", true)
            ai.set("race_active", false)
            ai.set("velocity", Vector3.ZERO)

    var distance_total := abs(finish_z - race_start_z)
    var distance_done := clamp(abs(race_start_z - car.global_position.z), 0.0, distance_total)
    var progress := clamp((distance_done / distance_total) * 100.0, 0.0, 100.0)
    race_bar.value = progress
    race_label.text = "RACE %d%%" % roundi(progress)

    var remaining := max(0.0, distance_total - distance_done)
    var checkpoint := get_node_or_null("RaceHUD/CheckpointInfo")
    if checkpoint:
        checkpoint.text = "FINISH: %dm" % roundi(remaining)

func _on_finish_body_entered(body: Node3D) -> void:
    if race_finished or body.name != "PlayerCar":
        return
    if not race_started or current_checkpoint < total_checkpoints:
        if is_instance_valid(checkpoint_label):
            checkpoint_label.text = "PASS CHECKPOINTS FIRST"
        return

    if selected_mode == "career" and lap < total_laps:
        lap += 1
        current_checkpoint = 0
        var car := get_node_or_null("PlayerCar")
        if car:
            car.global_position = Vector3(0.0, 1.0, race_start_z)
            car.velocity = Vector3.ZERO
            car.rotation_degrees = Vector3.ZERO
        if is_instance_valid(checkpoint_label):
            checkpoint_label.text = "LAP %d / %d" % [lap, total_laps]
        return

    race_finished = true
    _grant_race_rewards()
    var car := get_node_or_null("PlayerCar")
    if car and car.has_method("set_finish_cinematic"):
        car.set_finish_cinematic(true)
    _show_finish_overlay()

func _show_finish_overlay() -> void:
    if is_instance_valid(mobile_controls):
        mobile_controls.visible = false

    finish_overlay = ColorRect.new()
    finish_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    finish_overlay.color = Color(0.0, 0.0, 0.0, 0.72)
    finish_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

    var canvas := CanvasLayer.new()
    canvas.name = "FinishUI"
    canvas.layer = 30
    add_child(canvas)
    canvas.add_child(finish_overlay)

    var title := Label.new()
    title.text = "🏁 RACE FINISHED!"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.set_anchors_preset(Control.PRESET_CENTER)
    title.position = Vector2(-320.0, -140.0)
    title.size = Vector2(640.0, 100.0)
    title.add_theme_font_size_override("font_size", 54)
    finish_overlay.add_child(title)

    var message := Label.new()
    message.text = "MODE: %s" % mode_name

    result_time_label = Label.new()
    result_time_label.text = "TIME  " + _format_race_time(race_elapsed) + "\nPOSITION  " + str(_get_player_position_rank()) + " / " + str(ai_opponents.size() + 1) + "\nREWARD  +" + str(_calculate_race_reward()[0]) + " COINS   +" + str(_calculate_race_reward()[1]) + " XP"
    result_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    result_time_label.set_anchors_preset(Control.PRESET_CENTER)
    result_time_label.position = Vector2(-320.0, 5.0)
    result_time_label.size = Vector2(640.0, 45.0)
    result_time_label.add_theme_font_size_override("font_size", 28)
    finish_overlay.add_child(result_time_label)
    message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    message.set_anchors_preset(Control.PRESET_CENTER)
    message.position = Vector2(-320.0, -48.0)
    message.size = Vector2(640.0, 50.0)
    message.add_theme_font_size_override("font_size", 24)
    finish_overlay.add_child(message)

    finish_button = Button.new()
    finish_button.text = "RACE AGAIN"
    finish_button.set_anchors_preset(Control.PRESET_CENTER)
    finish_button.position = Vector2(-140.0, 55.0)
    finish_button.size = Vector2(280.0, 80.0)
    finish_button.focus_mode = Control.FOCUS_NONE
    finish_button.add_theme_font_size_override("font_size", 28)
    finish_button.pressed.connect(_restart_game)
    finish_overlay.add_child(finish_button)

func _build_professional_mobile_hud() -> void:
    var canvas := CanvasLayer.new()
    canvas.name = "ProfessionalMobileHUD"
    canvas.layer = 9
    add_child(canvas)

    var speed_panel := Panel.new()
    speed_panel.position = Vector2(500.0, 575.0)
    speed_panel.size = Vector2(280.0, 125.0)
    var panel_style := StyleBoxFlat.new()
    panel_style.bg_color = Color(0.015, 0.02, 0.03, 0.82)
    panel_style.corner_radius_top_left = 22
    panel_style.corner_radius_top_right = 22
    panel_style.corner_radius_bottom_left = 22
    panel_style.corner_radius_bottom_right = 22
    panel_style.border_width_left = 2
    panel_style.border_width_top = 2
    panel_style.border_width_right = 2
    panel_style.border_width_bottom = 2
    panel_style.border_color = Color(1.0, 1.0, 1.0, 0.22)
    speed_panel.add_theme_stylebox_override("panel", panel_style)
    canvas.add_child(speed_panel)

    speed_label = Label.new()
    speed_label.text = "0 KM/H"
    speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    speed_label.position = Vector2(10.0, 8.0)
    speed_label.size = Vector2(260.0, 48.0)
    speed_label.add_theme_font_size_override("font_size", 34)
    speed_panel.add_child(speed_label)

    speed_bar = ProgressBar.new()
    speed_bar.position = Vector2(20.0, 68.0)
    speed_bar.size = Vector2(240.0, 18.0)
    speed_bar.min_value = 0.0
    speed_bar.max_value = 100.0
    speed_bar.show_percentage = false
    speed_panel.add_child(speed_bar)

    var mini_panel := Panel.new()
    mini_panel.position = Vector2(1100.0, 35.0)
    mini_panel.size = Vector2(145.0, 220.0)
    mini_panel.add_theme_stylebox_override("panel", panel_style)
    canvas.add_child(mini_panel)

    var mini_title := Label.new()
    mini_title.text = "TRACK"
    mini_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    mini_title.position = Vector2(5.0, 8.0)
    mini_title.size = Vector2(135.0, 30.0)
    mini_title.add_theme_font_size_override("font_size", 17)
    mini_panel.add_child(mini_title)

    mini_progress = ProgressBar.new()
    mini_progress.position = Vector2(53.0, 48.0)
    mini_progress.size = Vector2(38.0, 150.0)
    mini_progress.min_value = 0.0
    mini_progress.max_value = 100.0
    mini_progress.value = 0.0
    mini_progress.show_percentage = false
    mini_panel.add_child(mini_progress)

func _update_professional_mobile_hud() -> void:
    var car := get_node_or_null("PlayerCar")
    if not car:
        return
    var speed := abs(car.velocity.length()) * 3.6
    if is_instance_valid(speed_label):
        speed_label.text = "%d KM/H" % roundi(speed)
    if is_instance_valid(speed_bar):
        speed_bar.value = clamp(speed / 1.8, 0.0, 100.0)
    if is_instance_valid(mini_progress):
        mini_progress.value = race_bar.value if is_instance_valid(race_bar) else 0.0

func _build_rewards_hud() -> void:
    var canvas := CanvasLayer.new()
    canvas.name = "RewardsHUD"
    canvas.layer = 8
    add_child(canvas)

    coins_label = Label.new()
    coins_label.text = "COINS 0   XP 0"
    coins_label.position = Vector2(28.0, 118.0)
    coins_label.size = Vector2(330.0, 38.0)
    coins_label.add_theme_font_size_override("font_size", 22)
    canvas.add_child(coins_label)

func _update_rewards_hud() -> void:
    if is_instance_valid(coins_label):
        coins_label.text = "COINS %d   XP %d" % [coins, xp]

func _calculate_race_reward() -> Array[int]:
    var base_coins := 50
    var base_xp := 100
    if selected_mode == "time_trial":
        base_coins = 75
        base_xp = 125
    elif selected_mode == "career":
        base_coins = 100
        base_xp = 180
    var rank_bonus := 0
    if selected_mode != "time_trial":
        var rank := _get_player_position_rank()
        rank_bonus = max(0, (ai_opponents.size() + 1 - rank) * 25)
    return [base_coins + rank_bonus, base_xp + rank_bonus * 2]

func _grant_race_rewards() -> void:
    var reward := _calculate_race_reward()
    coins += reward[0]
    xp += reward[1]
    _update_rewards_hud()

func _build_health_hud() -> void:
    var canvas := CanvasLayer.new()
    canvas.name = "GameHUD"
    add_child(canvas)

    var panel := Panel.new()
    panel.position = Vector2(28.0, 28.0)
    panel.size = Vector2(330.0, 82.0)

    var panel_style := StyleBoxFlat.new()
    panel_style.bg_color = Color(0.02, 0.02, 0.03, 0.78)
    panel_style.corner_radius_top_left = 14
    panel_style.corner_radius_top_right = 14
    panel_style.corner_radius_bottom_left = 14
    panel_style.corner_radius_bottom_right = 14
    panel.add_theme_stylebox_override("panel", panel_style)
    canvas.add_child(panel)

    health_label = Label.new()
    health_label.position = Vector2(18.0, 10.0)
    health_label.size = Vector2(290.0, 28.0)
    health_label.text = "HP 100 / 100"
    health_label.add_theme_font_size_override("font_size", 22)
    panel.add_child(health_label)

    health_bar = ProgressBar.new()
    health_bar.position = Vector2(18.0, 46.0)
    health_bar.size = Vector2(294.0, 22.0)
    health_bar.min_value = 0.0
    health_bar.max_value = 100.0
    health_bar.value = 100.0
    health_bar.show_percentage = false
    panel.add_child(health_bar)

func _build_game_over_ui() -> void:
    var canvas := CanvasLayer.new()
    canvas.name = "GameOverUI"
    canvas.layer = 20
    add_child(canvas)

    game_over_overlay = ColorRect.new()
    game_over_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    game_over_overlay.color = Color(0.0, 0.0, 0.0, 0.72)
    game_over_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    game_over_overlay.visible = false
    canvas.add_child(game_over_overlay)

    game_over_title = Label.new()
    game_over_title.text = "GAME OVER"
    game_over_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    game_over_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    game_over_title.set_anchors_preset(Control.PRESET_CENTER)
    game_over_title.position = Vector2(-300.0, -120.0)
    game_over_title.size = Vector2(600.0, 100.0)
    game_over_title.add_theme_font_size_override("font_size", 64)
    game_over_overlay.add_child(game_over_title)

    var message := Label.new()
    message.text = "Your car has been destroyed"
    message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    message.set_anchors_preset(Control.PRESET_CENTER)
    message.position = Vector2(-300.0, -20.0)
    message.size = Vector2(600.0, 50.0)
    message.add_theme_font_size_override("font_size", 24)
    game_over_overlay.add_child(message)

    restart_button = Button.new()
    restart_button.text = "RESTART"
    restart_button.set_anchors_preset(Control.PRESET_CENTER)
    restart_button.position = Vector2(-140.0, 55.0)
    restart_button.size = Vector2(280.0, 80.0)
    restart_button.focus_mode = Control.FOCUS_NONE
    restart_button.add_theme_font_size_override("font_size", 28)
    restart_button.pressed.connect(_restart_game)
    game_over_overlay.add_child(restart_button)

func _on_game_over() -> void:
    if is_instance_valid(mobile_controls):
        mobile_controls.visible = false
    if is_instance_valid(game_over_overlay):
        game_over_overlay.visible = true

func _restart_game() -> void:
    var car := get_node_or_null("PlayerCar")
    if car and car.has_method("restart_game"):
        car.restart_game()

func _on_health_changed(current_health: float, maximum_health: float) -> void:
    if not is_instance_valid(health_bar):
        return

    health_bar.max_value = maximum_health
    health_bar.value = current_health
    health_label.text = "HP %d / %d" % [roundi(current_health), roundi(maximum_health)]

func _build_mobile_controls() -> void:
    mobile_controls = CanvasLayer.new()
    mobile_controls.name = "MobileControls"
    mobile_controls.layer = 10
    add_child(mobile_controls)

    var title := Label.new()
    title.text = "DRIVE"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 18)
    title.modulate = Color(1.0, 1.0, 1.0, 0.65)
    title.set_anchors_preset(Control.PRESET_TOP_WIDE)
    title.position = Vector2(0.0, 18.0)
    title.size = Vector2(1280.0, 30.0)
    mobile_controls.add_child(title)

    _add_touch_button(mobile_controls, "LEFT", "steer_left", Vector2(30.0, 585.0), Vector2(145.0, 100.0))
    _add_touch_button(mobile_controls, "RIGHT", "steer_right", Vector2(190.0, 585.0), Vector2(145.0, 100.0))
    _add_touch_button(mobile_controls, "BRAKE", "brake", Vector2(955.0, 585.0), Vector2(145.0, 100.0))
    _add_touch_button(mobile_controls, "GO", "accelerate", Vector2(1105.0, 585.0), Vector2(145.0, 100.0))

func _add_touch_button(parent: CanvasLayer, label_text: String, action: String, button_position: Vector2, button_size: Vector2) -> void:
    var button := Button.new()
    button.text = label_text
    button.position = button_position
    button.size = button_size
    button.focus_mode = Control.FOCUS_NONE
    button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    button.add_theme_font_size_override("font_size", 24)

    var normal := StyleBoxFlat.new()
    normal.bg_color = Color(0.05, 0.05, 0.08, 0.72)
    normal.corner_radius_top_left = 18
    normal.corner_radius_top_right = 18
    normal.corner_radius_bottom_left = 18
    normal.corner_radius_bottom_right = 18
    normal.border_width_left = 2
    normal.border_width_top = 2
    normal.border_width_right = 2
    normal.border_width_bottom = 2
    normal.border_color = Color(1.0, 1.0, 1.0, 0.45)

    var pressed := normal.duplicate()
    pressed.bg_color = Color(0.25, 0.55, 0.95, 0.9)

    button.add_theme_stylebox_override("normal", normal)
    button.add_theme_stylebox_override("hover", normal)
    button.add_theme_stylebox_override("pressed", pressed)

    button.button_down.connect(_on_control_down.bind(action))
    button.button_up.connect(_on_control_up.bind(action))
    parent.add_child(button)

func _on_control_down(action: String) -> void:
    Input.action_press(action)

func _on_control_up(action: String) -> void:
    Input.action_release(action)
