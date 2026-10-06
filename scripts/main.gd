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
var ai_skill_profiles := [0.94, 1.0, 1.06]
var ai_racing_offsets := [-1.8, 0.0, 1.8]
var ai_race_progress: Array[float] = []
var ai_last_positions: Array[int] = []
var player_race_position := 1
var ai_lap_progress: Array[int] = []
var ambience_player: AudioStreamPlayer3D
var music_player: AudioStreamPlayer
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
var save_path := "user://car_race_save.json"
var total_races := 0
var best_time := 0.0
var achievements: Array[String] = []
var selected_weather := "DAY"
var selected_map := "CITY"
var map_label: Label
var weather_overlay: ColorRect
var rain_particles: GPUParticles3D
var fog_environment: Environment
var reward_label: Label
var coins_label: Label
var speed_label: Label
var speed_bar: ProgressBar
var mini_progress: ProgressBar
var settings_overlay: ColorRect
var settings_label: Label
var graphics_quality := "MEDIUM"
var master_volume := 1.0
var steering_sensitivity := 1.0
var vibration_enabled := true
var settings_path := "user://car_race_settings.json"
var target_fps := 60
var battery_saver := false
var leaderboard_overlay: ColorRect
var leaderboard_label: Label
var leaderboard_entries: Array = []
var online_leaderboard_url := ""
var leaderboard_http: HTTPRequest
var online_leaderboard_status := "OFFLINE"
var career_level := 1
var career_wins := 0
var career_races := 0
var career_stars := 0
var career_reward_multiplier := 1.0
var achievements_overlay: ColorRect
var loading_overlay: ColorRect
var results_canvas: CanvasLayer

var race_start_z := 15.0
var finish_z := -66.0
var track_path: Array[Vector3] = []
var sun_light: DirectionalLight3D
var sky_fill_light: DirectionalLight3D
var lighting_tuning := 1.0

func _load_progress() -> void:
    var file := FileAccess.open(save_path, FileAccess.READ)
    if file == null:
        return
    var json := JSON.new()
    var error := json.parse(file.get_as_text())
    if error != OK:
        return
    var data: Dictionary = json.data
    if data.has("coins"):
        coins = int(data["coins"])
    if data.has("xp"):
        xp = int(data["xp"])
    if data.has("total_races"):
        total_races = int(data["total_races"])
    if data.has("best_time"):
        best_time = float(data["best_time"])
    if data.has("achievements"):
        achievements = Array(data["achievements"])

func _load_settings() -> void:
    var file := FileAccess.open(settings_path, FileAccess.READ)
    if file == null:
        return
    var json := JSON.new()
    var error := json.parse(file.get_as_text())
    if error != OK:
        return
    var data: Dictionary = json.data
    if data.has("graphics_quality"):
        graphics_quality = str(data["graphics_quality"])
    if data.has("master_volume"):
        master_volume = float(data["master_volume"])
    if data.has("steering_sensitivity"):
        steering_sensitivity = float(data["steering_sensitivity"])
    if data.has("vibration_enabled"):
        vibration_enabled = bool(data["vibration_enabled"])

func _ready() -> void:
    _load_progress()
    _load_settings()
    _build_environment()
    _build_professional_track()
    _build_environment_scenery()
    _build_professional_environment()
    _build_premium_environment()
    _build_high_quality_environment()
    _build_ambience_audio()
    _build_music_system()
    _build_mobile_controls()
    _build_health_hud()
    _build_race_system()
    _build_ai_opponents()
    _build_game_over_ui()
    _build_mode_select()
    _apply_professional_lighting(selected_weather)
    _apply_weather(selected_weather)
    _apply_map(selected_map)
    _build_rewards_hud()
    _build_professional_mobile_hud()
    _build_weather_select()
    _build_map_select()
    _build_settings_button()
    _build_leaderboard_button()
    _setup_online_leaderboard()
    _update_map_label()
    _update_rewards_hud()
    _update_ai_racing(0.0)

    var car := get_node_or_null("PlayerCar")
    if car:
        car.health_changed.connect(_on_health_changed)
        car.game_over.connect(_on_game_over)
        _on_health_changed(car.health, car.max_health)

func _build_mobile_controls() -> void:
    mobile_controls = CanvasLayer.new()
    add_child(mobile_controls)
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    mobile_controls.add_child(root)
    var hint := Label.new()
    hint.text = "Steer: A/D or Left/Right\nAccelerate: W / Up\nBrake: S / Down"
    hint.position = Vector2(18.0, 18.0)
    hint.add_theme_font_size_override("font_size", 18)
    root.add_child(hint)

func _build_health_hud() -> void:
    var canvas := CanvasLayer.new()
    add_child(canvas)
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    canvas.add_child(root)
    health_bar = ProgressBar.new()
    health_bar.min_value = 0.0
    health_bar.max_value = 100.0
    health_bar.value = 100.0
    health_bar.position = Vector2(20.0, 20.0)
    health_bar.size = Vector2(220.0, 20.0)
    root.add_child(health_bar)
    health_label = Label.new()
    health_label.position = Vector2(20.0, 45.0)
    health_label.text = "Health 100%"
    root.add_child(health_label)

func _build_race_system() -> void:
    race_label = Label.new()
    race_label.text = "READY"
    race_label.position = Vector2(320.0, 20.0)
    race_label.add_theme_font_size_override("font_size", 30)
    add_child(race_label)

func _build_ai_opponents() -> void:
    if track_path.is_empty():
        return
    var ai_scene := preload("res://scripts/ai_car.gd")
    for i in range(ai_count):
        var ai := CharacterBody3D.new()
        ai.set_script(ai_scene)
        ai.position = Vector3(ai_racing_offsets[i], 1.0, 15.0)
        ai.name = "AiOpponent%s" % (i + 1)
        add_child(ai)
        ai_opponents.append(ai)
        ai.setup(track_path, i)
        ai.start_race()

func _build_game_over_ui() -> void:
    game_over_overlay = ColorRect.new()
    game_over_overlay.color = Color(0.0, 0.0, 0.0, 0.7)
    game_over_overlay.size = Vector2(1280.0, 720.0)
    game_over_overlay.visible = false
    add_child(game_over_overlay)
    game_over_title = Label.new()
    game_over_title.text = "RACE OVER"
    game_over_title.position = Vector2(520.0, 200.0)
    game_over_title.add_theme_font_size_override("font_size", 42)
    game_over_overlay.add_child(game_over_title)
    restart_button = Button.new()
    restart_button.text = "Restart"
    restart_button.position = Vector2(540.0, 350.0)
    restart_button.pressed.connect(func() -> void:
        get_tree().reload_current_scene()
    )
    game_over_overlay.add_child(restart_button)

func _build_mode_select() -> void:
    mode_overlay = ColorRect.new()
    mode_overlay.color = Color(0.0, 0.0, 0.0, 0.15)
    mode_overlay.size = Vector2(300.0, 120.0)
    mode_overlay.position = Vector2(480.0, 20.0)
    add_child(mode_overlay)
    mode_label = Label.new()
    mode_label.text = "QUICK RACE"
    mode_label.position = Vector2(20.0, 40.0)
    mode_label.add_theme_font_size_override("font_size", 26)
    mode_overlay.add_child(mode_label)

func _apply_weather(weather: String) -> void:
    selected_weather = weather

func _apply_map(map_name: String) -> void:
    selected_map = map_name
    if map_label:
        map_label.text = "MAP: %s" % selected_map

func _build_rewards_hud() -> void:
    reward_label = Label.new()
    reward_label.text = "Rewards"
    reward_label.position = Vector2(950.0, 20.0)
    add_child(reward_label)
    coins_label = Label.new()
    coins_label.text = "Coins: 0"
    coins_label.position = Vector2(950.0, 48.0)
    add_child(coins_label)

func _build_professional_mobile_hud() -> void:
    speed_label = Label.new()
    speed_label.text = "0 KM/H"
    speed_label.position = Vector2(1000.0, 600.0)
    add_child(speed_label)
    speed_bar = ProgressBar.new()
    speed_bar.min_value = 0.0
    speed_bar.max_value = 140.0
    speed_bar.value = 0.0
    speed_bar.position = Vector2(960.0, 640.0)
    speed_bar.size = Vector2(200.0, 15.0)
    add_child(speed_bar)

func _build_weather_select() -> void:
    weather_overlay = ColorRect.new()
    weather_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
    weather_overlay.size = Vector2(1.0, 1.0)
    add_child(weather_overlay)

func _build_map_select() -> void:
    map_label = Label.new()
    map_label.text = "MAP: CITY"
    map_label.position = Vector2(700.0, 15.0)
    add_child(map_label)

func _build_settings_button() -> void:
    var button := Button.new()
    button.text = "Settings"
    button.position = Vector2(1160.0, 20.0)
    add_child(button)

func _build_leaderboard_button() -> void:
    var button := Button.new()
    button.text = "Leaderboard"
    button.position = Vector2(1110.0, 70.0)
    add_child(button)

func _setup_online_leaderboard() -> void:
    online_leaderboard_status = "OFFLINE"

func _update_map_label() -> void:
    if map_label:
        map_label.text = "MAP: %s" % selected_map

func _update_rewards_hud() -> void:
    if coins_label:
        coins_label.text = "Coins: %d" % coins
    if reward_label:
        reward_label.text = "Rewards | XP: %d | Coins: %d" % [xp, coins]

func _update_ai_racing(_delta: float) -> void:
    for i in range(ai_opponents.size()):
        var ai := ai_opponents[i] as Node3D
        if ai:
            ai.position.z = clamp(ai.position.z - 0.1, -120.0, 50.0)

func _on_health_changed(current_health: float, maximum_health: float) -> void:
    if health_bar:
        health_bar.max_value = maximum_health
        health_bar.value = current_health
    if health_label:
        health_label.text = "Health %.0f%%" % (current_health / max(maximum_health, 0.0001) * 100.0)

func _on_game_over() -> void:
    if game_over_overlay:
        game_over_overlay.visible = true

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

func _build_music_system() -> void:
    music_player = AudioStreamPlayer.new()
    music_player.name = "RaceMusic"
    music_player.stream = _create_race_music()
    music_player.volume_db = -16.0
    music_player.bus = "Master"
    add_child(music_player)
    music_player.play()

func _create_race_music() -> AudioStreamWAV:
    var sample_rate := 22050
    var beat := 0.32
    var note_count := 32
    var samples_per_note := int(sample_rate * beat)
    var data := PackedByteArray()
    data.resize(samples_per_note * note_count * 2)
    var melody := [220.0, 261.63, 329.63, 392.0, 329.63, 261.63, 293.66, 349.23, 440.0, 349.23, 293.66, 261.63, 220.0, 293.66, 329.63, 392.0]
    for i in range(note_count):
        var frequency: float = melody[i % melody.size()]
        for sample in range(samples_per_note):
            var index := i * samples_per_note + sample
            var t := float(sample) / sample_rate
            var envelope := minf(1.0, t * 18.0) * minf(1.0, (beat - t) * 12.0)
            var tone := sin(TAU * frequency * t) * 0.11
            tone += sin(TAU * frequency * 2.0 * t) * 0.035
            tone += sin(TAU * frequency * 0.5 * t) * 0.025
            data.encode_s16(index * 2, int(clamp(tone * envelope, -1.0, 1.0) * 32767.0))
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = sample_rate
    stream.stereo = false
    stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
    stream.loop_begin = 0
    stream.loop_end = samples_per_note * note_count
    stream.data = data
    return stream

func _build_environment() -> void:
    var world := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_material := ProceduralSkyMaterial.new()
    sky_material.sky_top_color = Color(0.025, 0.07, 0.18)
    sky_material.sky_horizon_color = Color(0.62, 0.72, 0.82)
    sky_material.ground_bottom_color = Color(0.025, 0.035, 0.045)
    sky_material.ground_horizon_color = Color(0.24, 0.28, 0.3)
    sky_material.sun_angle_max = 12.0
    sky_material.sun_curve = 0.08
    sky.sky_material = sky_material
    environment.sky = sky
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    environment.ambient_light_energy = 0.72
    environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.glow_enabled = true
    environment.glow_intensity = 0.7
    environment.glow_strength = 1.0
    environment.glow_bloom = 0.12
    environment.volumetric_fog_enabled = true
    environment.volumetric_fog_density = 0.008
    environment.volumetric_fog_albedo = Color(0.55, 0.62, 0.7)
    world.environment = environment
    add_child(world)

    var sun := DirectionalLight3D.new()
    sun.name = "SunLight"
    sun.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
    sun.light_color = Color(1.0, 0.92, 0.78)
    sun.light_energy = 1.45
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 90.0
    sun.directional_shadow_fade_start = 55.0
    sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
    add_child(sun)

    var fill := DirectionalLight3D.new()
    fill.name = "SkyFillLight"
    fill.rotation_degrees = Vector3(-25.0, 145.0, 0.0)
    fill.light_color = Color(0.55, 0.68, 1.0)
    fill.light_energy = 0.28
    fill.shadow_enabled = false
    add_child(fill)

    for position in [Vector3(-6.8, 3.0, 2.0), Vector3(12.0, 3.2, -26.0), Vector3(-7.5, 3.4, -48.0)]:
        var lamp := OmniLight3D.new()
        lamp.name = "TrackLight"
        lamp.position = position
        lamp.light_color = Color(1.0, 0.72, 0.38)
        lamp.light_energy = 1.8
        lamp.omni_range = 10.0
        lamp.shadow_enabled = true
        add_child(lamp)

func _apply_professional_lighting(weather: String) -> void:
    if not sun_light:
        sun_light = get_node_or_null("SunLight") as DirectionalLight3D
    if not sky_fill_light:
        sky_fill_light = get_node_or_null("SkyFillLight") as DirectionalLight3D
    if not sun_light:
        return
    if weather == "NIGHT":
        sun_light.light_color = Color(0.34, 0.43, 0.68)
        sun_light.light_energy = 0.32 * lighting_tuning
        sun_light.rotation_degrees = Vector3(-18.0, 35.0, 0.0)
        if sky_fill_light:
            sky_fill_light.light_energy = 0.18
    elif weather == "RAIN + FOG":
        sun_light.light_color = Color(0.72, 0.78, 0.86)
        sun_light.light_energy = 0.82 * lighting_tuning
        sun_light.rotation_degrees = Vector3(-38.0, -28.0, 0.0)
        if sky_fill_light:
            sky_fill_light.light_energy = 0.24
    else:
        sun_light.light_color = Color(1.0, 0.92, 0.78)
        sun_light.light_energy = 1.45 * lighting_tuning
        sun_light.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
        if sky_fill_light:
            sky_fill_light.light_energy = 0.28

func _build_professional_environment() -> void:
    var road_side := _make_material(Color(0.16, 0.19, 0.17), 0.0, 0.9)
    var rock := _make_material(Color(0.18, 0.2, 0.22), 0.0, 1.0)
    var tree_leaf := _make_material(Color(0.05, 0.2, 0.08), 0.0, 0.95)
    var tree_trunk := _make_material(Color(0.24, 0.12, 0.05), 0.0, 1.0)
    var sign_material := _make_emission_material(Color(0.95, 0.72, 0.12), 0.25)
    for i in range(9):
        var z := 12.0 - float(i) * 8.5
        _add_environment_tree(Vector3(-10.5 - float(i % 2), 0.0, z), tree_trunk, tree_leaf, 0.9 + float(i % 3) * 0.12)
        _add_environment_tree(Vector3(17.0 + float(i % 3), 0.0, z - 3.5), tree_trunk, tree_leaf, 1.0 + float((i + 1) % 3) * 0.1)
    for i in range(6):
        var z := 4.0 - float(i) * 10.5
        _add_roadside_sign(Vector3(-7.0, 1.5, z), 0.0, sign_material)
    for i in range(5):
        var z := -3.0 - float(i) * 12.0
        _add_rock(Vector3(-14.0 - float(i % 2) * 2.0, 1.2, z), rock, 1.0 + float(i % 3) * 0.35)
        _add_rock(Vector3(20.0 + float(i % 2) * 2.0, 1.0, z - 4.0), rock, 0.8 + float((i + 1) % 3) * 0.3)
    _add_environment_banner(Vector3(0.0, 4.8, 2.0), "RACE ZONE")

func _add_environment_tree(position: Vector3, trunk_material: StandardMaterial3D, leaf_material: StandardMaterial3D, scale_value: float) -> void:
    var root := Node3D.new()
    root.position = position
    root.scale = Vector3.ONE * scale_value
    add_child(root)
    var trunk := MeshInstance3D.new()
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.14
    trunk_mesh.bottom_radius = 0.25
    trunk_mesh.height = 2.8
    trunk.mesh = trunk_mesh
    trunk.position.y = 1.4
    trunk.material_override = trunk_material
    root.add_child(trunk)
    for offset in [Vector3(0.0, 2.9, 0.0), Vector3(0.0, 3.6, 0.2)]:
        var crown := MeshInstance3D.new()
        var crown_mesh := SphereMesh.new()
        crown_mesh.radius = 1.25
        crown_mesh.height = 2.4
        crown.mesh = crown_mesh
        crown.position = offset
        crown.material_override = leaf_material
        root.add_child(crown)

func _add_rock(position: Vector3, material: StandardMaterial3D, scale_value: float) -> void:
    var rock := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 1.5
    mesh.height = 1.8
    rock.mesh = mesh
    rock.position = position
    rock.scale = Vector3(scale_value * 1.4, scale_value, scale_value)
    rock.rotation_degrees = Vector3(0.0, float(int(position.z * 7.0) % 35), 8.0)
    rock.material_override = material
    add_child(rock)

func _add_roadside_sign(position: Vector3, rotation_y: float, material: StandardMaterial3D) -> void:
    var root := Node3D.new()
    root.position = position
    root.rotation_degrees.y = rotation_y
    add_child(root)
    var pole := MeshInstance3D.new()
    var pole_mesh := CylinderMesh.new()
    pole_mesh.top_radius = 0.06
    pole_mesh.bottom_radius = 0.09
    pole_mesh.height = 2.6
    pole.mesh = pole_mesh
    pole.position.y = 1.3
    pole.material_override = _make_material(Color(0.12, 0.13, 0.14), 0.5, 0.45)
    root.add_child(pole)
    var board := MeshInstance3D.new()
    var board_mesh := BoxMesh.new()
    board_mesh.size = Vector3(1.8, 0.8, 0.1)
    board.mesh = board_mesh
    board.position.y = 2.7
    board.material_override = material
    root.add_child(board)

func _add_environment_banner(position: Vector3, text_value: String) -> void:
    var banner := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(9.0, 1.0, 0.25)
    banner.mesh = mesh
    banner.position = position
    banner.material_override = _make_emission_material(Color(0.06, 0.08, 0.12), 0.15)
    add_child(banner)

func _build_environment_scenery() -> void:
    var grass := _make_pbr_material(Color(0.07, 0.22, 0.09), 0.96, 0.0, 3.0, 301)
    var mountain := _make_pbr_material(Color(0.12, 0.16, 0.2), 0.92, 0.0, 2.0, 302)
    var building := _make_pbr_material(Color(0.22, 0.25, 0.3), 0.62, 0.22, 3.0, 303)
    var glass := _make_emission_material(Color(0.12, 0.28, 0.48), 0.45)
    var lamp := _make_pbr_material(Color(0.08, 0.09, 0.1), 0.3, 0.78, 2.0, 304)
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

func _build_premium_environment() -> void:
    var grass := _make_material(Color(0.055, 0.16, 0.065), 0.0, 0.98)
    var dark_grass := _make_material(Color(0.035, 0.095, 0.045), 0.0, 1.0)
    var glass := _make_emission_material(Color(0.08, 0.22, 0.42), 0.7)
    var concrete := _make_material(Color(0.2, 0.21, 0.23), 0.15, 0.78)
    var road_sign := _make_emission_material(Color(0.95, 0.62, 0.08), 0.35)

    for i in range(12):
        var z := 10.0 - float(i) * 6.5
        _add_premium_tree_cluster(Vector3(-12.0 - float(i % 3) * 1.5, 0.0, z), grass, dark_grass, 1.0 + float(i % 3) * 0.12)
        _add_premium_tree_cluster(Vector3(17.0 + float(i % 2) * 2.0, 0.0, z - 2.5), grass, dark_grass, 0.9 + float((i + 1) % 3) * 0.15)

    var buildings := [
        [Vector3(-17.0, 4.0, -4.0), Vector3(5.5, 8.0, 5.5)],
        [Vector3(18.0, 5.5, -15.0), Vector3(6.5, 11.0, 6.5)],
        [Vector3(-18.0, 6.0, -29.0), Vector3(7.0, 12.0, 7.0)],
        [Vector3(20.0, 4.5, -43.0), Vector3(6.0, 9.0, 6.0)],
        [Vector3(-16.0, 5.0, -55.0), Vector3(6.0, 10.0, 6.0)]
    ]
    for item in buildings:
        _add_premium_building(item[0], item[1], concrete, glass)

    _add_premium_bridge(Vector3(3.5, 4.5, -21.0), 18.0, concrete)
    _add_premium_sign(Vector3(-7.5, 2.0, -18.0), "RACE", road_sign)
    _add_premium_sign(Vector3(14.0, 2.0, -38.0), "SLOW", road_sign)

func _add_premium_tree_cluster(position: Vector3, leaf_material: StandardMaterial3D, dark_material: StandardMaterial3D, scale_value: float) -> void:
    var root := Node3D.new()
    root.position = position
    root.scale = Vector3.ONE * scale_value
    add_child(root)

    var trunk := MeshInstance3D.new()
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.16
    trunk_mesh.bottom_radius = 0.28
    trunk_mesh.height = 3.2
    trunk.mesh = trunk_mesh
    trunk.position.y = 1.6
    trunk.material_override = _make_material(Color(0.2, 0.09, 0.035), 0.0, 1.0)
    root.add_child(trunk)

    for offset in [Vector3(0.0, 3.1, 0.0), Vector3(-0.65, 2.8, 0.15), Vector3(0.65, 2.8, -0.1)]:
        var crown := MeshInstance3D.new()
        var crown_mesh := SphereMesh.new()
        crown_mesh.radius = 1.25
        crown_mesh.height = 2.4
        crown.mesh = crown_mesh
        crown.position = offset
        crown.material_override = leaf_material if offset.x == 0.0 else dark_material
        root.add_child(crown)

func _add_premium_building(position: Vector3, size: Vector3, concrete: StandardMaterial3D, glass: StandardMaterial3D) -> void:
    var root := Node3D.new()
    root.position = position
    add_child(root)

    var body := MeshInstance3D.new()
    var body_mesh := BoxMesh.new()
    body_mesh.size = size
    body.mesh = body_mesh
    body.material_override = concrete
    root.add_child(body)

    for y in range(1, max(2, int(size.y / 2.0))):
        for side in [-1.0, 1.0]:
            var window := MeshInstance3D.new()
            var window_mesh := BoxMesh.new()
            window_mesh.size = Vector3(size.x * 0.62, 0.5, 0.08)
            window.mesh = window_mesh
            window.position = Vector3(0.0, -size.y * 0.5 + y * 1.55, side * size.z * 0.505)
            window.material_override = glass
            root.add_child(window)

func _add_premium_bridge(position: Vector3, rotation_y: float, material: StandardMaterial3D) -> void:
    var bridge := Node3D.new()
    bridge.position = position
    bridge.rotation_degrees.y = rotation_y
    add_child(bridge)

    var deck := MeshInstance3D.new()
    var deck_mesh := BoxMesh.new()
    deck_mesh.size = Vector3(16.0, 0.45, 3.2)
    deck.mesh = deck_mesh
    deck.position.y = 4.0
    deck.material_override = material
    bridge.add_child(deck)

    for side in [-1.0, 1.0]:
        for x in [-6.0, 0.0, 6.0]:
            var pillar := MeshInstance3D.new()
            var pillar_mesh := BoxMesh.new()
            pillar_mesh.size = Vector3(0.45, 4.0, 0.45)
            pillar.mesh = pillar_mesh
            pillar.position = Vector3(x, 2.0, side * 1.1)
            pillar.material_override = material
            bridge.add_child(pillar)

func _add_premium_sign(position: Vector3, text_value: String, material: StandardMaterial3D) -> void:
    var sign := Node3D.new()
    sign.position = position
    add_child(sign)

    var pole := MeshInstance3D.new()
    var pole_mesh := CylinderMesh.new()
    pole_mesh.top_radius = 0.07
    pole_mesh.bottom_radius = 0.1
    pole_mesh.height = 3.2
    pole.mesh = pole_mesh
    pole.position.y = 1.6
    pole.material_override = _make_material(Color(0.12, 0.13, 0.15), 0.65, 0.4)
    sign.add_child(pole)

    var board := MeshInstance3D.new()
    var board_mesh := BoxMesh.new()
    board_mesh.size = Vector3(2.6, 0.85, 0.14)
    board.mesh = board_mesh
    board.position.y = 3.15
    board.material_override = material
    sign.add_child(board)

func _make_pbr_material(base_color: Color, roughness_value: float, metallic_value: float, texture_scale: float = 4.0, seed_value: int = 1) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = base_color
    material.metallic = clampf(metallic_value, 0.0, 1.0)
    material.roughness = clampf(roughness_value, 0.05, 1.0)
    material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
    material.uv1_triplanar = true
    material.uv1_world_triplanar = true
    material.uv1_scale = Vector3.ONE * texture_scale
    var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value
    for y in range(32):
        for x in range(32):
            var variation := rng.randf_range(0.82, 1.18)
            image.set_pixel(x, y, Color(base_color.r * variation, base_color.g * variation, base_color.b * variation, 1.0))
    material.albedo_texture = ImageTexture.create_from_image(image)
    return material

func _make_material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
    var material := _make_pbr_material(color, roughness, metallic, 2.5, 401)
    return material

func _make_emission_material(color: Color, energy: float) -> StandardMaterial3D:
    var material := _make_material(color, 0.1, 0.12)
    material.emission_enabled = true
    material.emission = color
    material.emission_energy_multiplier = energy
    return material

func _build_high_quality_environment() -> void:
    var terrain := _make_pbr_material(Color(0.035, 0.11, 0.045), 0.98, 0.0, 3.0, 101)
    var terrain_edge := _make_material(Color(0.07, 0.18, 0.08), 0.0, 0.92)
    var foliage := _make_pbr_material(Color(0.025, 0.14, 0.055), 0.95, 0.0, 2.0, 103)
    var foliage_light := _make_pbr_material(Color(0.08, 0.28, 0.11), 0.9, 0.0, 2.0, 104)
    var concrete := _make_pbr_material(Color(0.16, 0.18, 0.2), 0.72, 0.18, 3.0, 105)
    var glass := _make_emission_material(Color(0.08, 0.3, 0.58), 0.9)
    var metal := _make_pbr_material(Color(0.22, 0.24, 0.27), 0.32, 0.82, 2.0, 106)
    var accent := _make_emission_material(Color(0.95, 0.18, 0.035), 0.65)

    _add_environment_terrain_layer(Vector3(4.0, -0.18, -27.0), Vector3(92.0, 0.28, 122.0), terrain)
    _add_environment_terrain_layer(Vector3(4.0, 0.02, -27.0), Vector3(78.0, 0.12, 112.0), terrain_edge)

    for i in range(18):
        var z := 13.0 - float(i) * 5.1
        var side := -1.0 if i % 2 == 0 else 1.0
        _add_high_quality_tree(Vector3(-11.5 + side * 0.8, 0.0, z), foliage, foliage_light, 1.0 + float(i % 4) * 0.08)
        _add_high_quality_tree(Vector3(16.0 - side * 0.7, 0.0, z - 2.2), foliage, foliage_light, 0.9 + float((i + 1) % 4) * 0.09)

    for i in range(8):
        var z := 8.0 - float(i) * 9.0
        _add_roadside_barrier(Vector3(-7.1, 0.35, z), 0.0, metal)
        if i % 2 == 0:
            _add_roadside_barrier(Vector3(13.0, 0.55, z - 3.0), 0.0, metal)

    var skyline := [
        [Vector3(-22.0, 5.0, -8.0), Vector3(6.0, 10.0, 6.0)],
        [Vector3(23.0, 7.0, -22.0), Vector3(7.0, 14.0, 7.0)],
        [Vector3(-23.0, 8.0, -39.0), Vector3(8.0, 16.0, 8.0)],
        [Vector3(24.0, 6.0, -57.0), Vector3(7.0, 12.0, 7.0)]
    ]
    for item in skyline:
        _add_high_quality_building(item[0], item[1], concrete, glass)

    _add_environment_banner(Vector3(0.0, 5.0, -9.0), "NOVA RACING")
    _add_environment_banner(Vector3(7.0, 5.4, -49.0), "SPEED ZONE")

    for position in [Vector3(-9.0, 0.0, 9.0), Vector3(12.0, 0.1, -6.0), Vector3(-10.0, 0.1, -31.0), Vector3(14.0, 0.2, -52.0)]:
        _add_rock_cluster(position, terrain_edge)

    var accent_positions := [Vector3(-6.5, 1.1, 1.0), Vector3(11.5, 1.3, -27.0), Vector3(-9.0, 1.5, -45.0)]
    for position in accent_positions:
        _add_premium_sign(position + Vector3(0.0, 2.8, 0.0), "RACE", accent)

func _add_environment_terrain_layer(position: Vector3, size: Vector3, material: StandardMaterial3D) -> void:
    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh_instance.mesh = mesh
    mesh_instance.position = position
    mesh_instance.material_override = material
    add_child(mesh_instance)

func _add_high_quality_tree(position: Vector3, leaf_material: StandardMaterial3D, light_material: StandardMaterial3D, scale_value: float) -> void:
    var root := Node3D.new()
    root.position = position
    root.scale = Vector3.ONE * scale_value
    add_child(root)

    var trunk := MeshInstance3D.new()
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.11
    trunk_mesh.bottom_radius = 0.22
    trunk_mesh.height = 3.4
    trunk.mesh = trunk_mesh
    trunk.position.y = 1.7
    trunk.material_override = _make_material(Color(0.16, 0.07, 0.025), 0.0, 1.0)
    root.add_child(trunk)

    for data in [
        [Vector3(0.0, 3.15, 0.0), 1.25, 2.4],
        [Vector3(-0.75, 2.65, 0.15), 0.95, 1.9],
        [Vector3(0.72, 2.55, -0.12), 0.9, 1.8]
    ]:
        var crown := MeshInstance3D.new()
        var crown_mesh := SphereMesh.new()
        crown_mesh.radius = data[1]
        crown_mesh.height = data[2]
        crown.mesh = crown_mesh
        crown.position = data[0]
        crown.material_override = light_material if data[0].x != 0.0 else leaf_material
        root.add_child(crown)

func _add_roadside_barrier(position: Vector3, rotation_y: float, material: StandardMaterial3D) -> void:
    var root := Node3D.new()
    root.position = position
    root.rotation_degrees.y = rotation_y
    add_child(root)

    for x in [-1.8, 0.0, 1.8]:
        var post := MeshInstance3D.new()
        var post_mesh := CylinderMesh.new()
        post_mesh.top_radius = 0.06
        post_mesh.bottom_radius = 0.08
        post_mesh.height = 0.8
        post.mesh = post_mesh
        post.position = Vector3(x, 0.4, 0.0)
        post.material_override = material
        root.add_child(post)

    var rail := MeshInstance3D.new()
    var rail_mesh := BoxMesh.new()
    rail_mesh.size = Vector3(4.0, 0.16, 0.16)
    rail.mesh = rail_mesh
    rail.position.y = 0.65
    rail.material_override = material
    root.add_child(rail)

func _add_high_quality_building(position: Vector3, size: Vector3, body_material: StandardMaterial3D, glass_material: StandardMaterial3D) -> void:
    var root := Node3D.new()
    root.position = position
    add_child(root)

    var body := MeshInstance3D.new()
    var body_mesh := BoxMesh.new()
    body_mesh.size = size
    body.mesh = body_mesh
    body.material_override = body_material
    root.add_child(body)

    var roof := MeshInstance3D.new()
    var roof_mesh := BoxMesh.new()
    roof_mesh.size = Vector3(size.x * 1.08, 0.28, size.z * 1.08)
    roof.mesh = roof_mesh
    roof.position.y = size.y * 0.5 + 0.14
    roof.material_override = _make_material(Color(0.06, 0.07, 0.09), 0.45, 0.42)
    root.add_child(roof)

    var floors := max(3, int(size.y / 1.8))
    for y in range(floors):
        for side in [-1.0, 1.0]:
            var window := MeshInstance3D.new()
            var window_mesh := BoxMesh.new()
            window_mesh.size = Vector3(size.x * 0.7, 0.48, 0.07)
            window.mesh = window_mesh
            window.position = Vector3(0.0, -size.y * 0.5 + 1.15 + y * 1.65, side * size.z * 0.505)
            window.material_override = glass_material
            root.add_child(window)

func _add_rock_cluster(position: Vector3, material: StandardMaterial3D) -> void:
    for i in range(3):
        var rock := MeshInstance3D.new()
        var mesh := SphereMesh.new()
        mesh.radius = 0.6 + float(i) * 0.18
        mesh.height = 0.8 + float(i) * 0.2
        rock.mesh = mesh
        rock.position = position + Vector3(float(i) * 0.55, 0.35 + float(i % 2) * 0.12, float(i % 2) * 0.5)
        rock.scale = Vector3(1.2, 0.8, 1.0)
        rock.material_override = material
        add_child(rock)

func _build_professional_track() -> void:
    track_path = _get_map_track_path()
    for i in range(track_path.size() - 1):
        _add_curved_road_segment(track_path[i], track_path[i + 1], i)
    if track_path.size() > 17:
        _add_curve_apex_marker(track_path[5])
        _add_curve_apex_marker(track_path[11])
        _add_curve_apex_marker(track_path[17])

func _get_map_track_path() -> Array[Vector3]:
    if selected_map == "HIGHWAY":
        return [
            Vector3(0.0, 0.0, 18.0), Vector3(0.0, 0.0, 10.0), Vector3(1.0, 0.0, 2.0),
            Vector3(3.5, 0.02, -6.0), Vector3(7.0, 0.04, -14.0), Vector3(8.5, 0.08, -22.0),
            Vector3(7.0, 0.12, -30.0), Vector3(2.5, 0.16, -38.0), Vector3(-3.5, 0.2, -46.0),
            Vector3(-7.5, 0.24, -54.0), Vector3(-6.5, 0.28, -62.0), Vector3(-1.5, 0.32, -70.0),
            Vector3(5.0, 0.36, -78.0), Vector3(10.0, 0.4, -86.0), Vector3(12.0, 0.44, -94.0),
            Vector3(9.0, 0.48, -102.0), Vector3(3.0, 0.52, -108.0), Vector3(-4.0, 0.56, -112.0),
            Vector3(-10.0, 0.6, -108.0), Vector3(-12.0, 0.64, -100.0), Vector3(-9.0, 0.68, -92.0),
            Vector3(-3.0, 0.72, -84.0), Vector3(3.0, 0.76, -76.0)
        ]
    if selected_map == "DESERT":
        return [
            Vector3(0.0, 0.0, 16.0), Vector3(-4.0, 0.02, 9.0), Vector3(-8.0, 0.04, 2.0),
            Vector3(-9.0, 0.06, -6.0), Vector3(-5.0, 0.1, -14.0), Vector3(2.0, 0.14, -20.0),
            Vector3(9.0, 0.18, -25.0), Vector3(12.0, 0.22, -32.0), Vector3(10.0, 0.26, -40.0),
            Vector3(4.0, 0.3, -47.0), Vector3(-4.0, 0.34, -52.0), Vector3(-12.0, 0.38, -56.0),
            Vector3(-16.0, 0.42, -63.0), Vector3(-13.0, 0.46, -70.0), Vector3(-5.0, 0.5, -75.0),
            Vector3(4.0, 0.54, -77.0), Vector3(13.0, 0.58, -74.0), Vector3(17.0, 0.62, -67.0),
            Vector3(15.0, 0.66, -59.0), Vector3(8.0, 0.7, -54.0), Vector3(0.0, 0.74, -50.0),
            Vector3(-7.0, 0.78, -45.0), Vector3(-11.0, 0.82, -38.0)
        ]
    return [
        Vector3(0.0, 0.0, 15.0), Vector3(-0.8, 0.0, 11.0), Vector3(-2.2, 0.0, 7.0),
        Vector3(-3.8, 0.02, 3.0), Vector3(-4.8, 0.04, -1.0), Vector3(-4.5, 0.06, -5.0),
        Vector3(-2.8, 0.08, -9.0), Vector3(0.0, 0.1, -13.0), Vector3(3.5, 0.14, -17.0),
        Vector3(6.5, 0.18, -21.0), Vector3(8.2, 0.22, -25.0), Vector3(8.8, 0.28, -29.0),
        Vector3(8.0, 0.34, -33.0), Vector3(5.5, 0.4, -37.0), Vector3(2.0, 0.48, -40.0),
        Vector3(-1.5, 0.56, -43.0), Vector3(-3.8, 0.62, -47.0), Vector3(-4.5, 0.68, -51.0),
        Vector3(-3.2, 0.74, -55.0), Vector3(0.0, 0.8, -59.0), Vector3(4.0, 0.86, -63.0),
        Vector3(7.2, 0.92, -67.0), Vector3(8.5, 0.98, -71.0)
    ]

func _add_curved_road_segment(a: Vector3, b: Vector3, index: int) -> void:
    var midpoint := (a + b) * 0.5
    var direction := b - a
    var length := maxf(direction.length() + 0.35, 1.0)
    var angle := atan2(direction.x, direction.z)
    var road := StaticBody3D.new()
    road.name = "CurvedRoad%02d" % index
    road.position = midpoint
    road.rotation.y = angle
    add_child(road)

    var road_mesh := MeshInstance3D.new()
    var road_box := BoxMesh.new()
    road_box.size = Vector3(12.0, 0.24, length)
    road_mesh.mesh = road_box
    road_mesh.position.y = -0.08
    road_mesh.material_override = _make_pbr_material(Color(0.055, 0.06, 0.075), 0.84, 0.05, 5.0, 200 + index)
    road.add_child(road_mesh)

    var collision := CollisionShape3D.new()
    var collision_shape := BoxShape3D.new()
    collision_shape.size = Vector3(12.0, 0.24, length)
    collision.shape = collision_shape
    collision.position.y = -0.08
    road.add_child(collision)

    for side in [-1.0, 1.0]:
        var curb := MeshInstance3D.new()
        var curb_mesh := BoxMesh.new()
        curb_mesh.size = Vector3(0.32, 0.14, length)
        curb.mesh = curb_mesh
        curb.position = Vector3(side * 6.16, 0.08, 0.0)
        curb.material_override = _make_material(Color(0.72, 0.73, 0.75), 0.1, 0.68)
        road.add_child(curb)

        var red_curb := MeshInstance3D.new()
        var red_mesh := BoxMesh.new()
        red_mesh.size = Vector3(0.32, 0.15, minf(length * 0.5, 2.0))
        red_curb.mesh = red_mesh
        red_curb.position = Vector3(side * 6.16, 0.09, -length * 0.24)
        red_curb.material_override = _make_material(Color(0.72, 0.035, 0.025), 0.05, 0.7)
        road.add_child(red_curb)

    var dash := MeshInstance3D.new()
    var dash_mesh := BoxMesh.new()
    dash_mesh.size = Vector3(0.16, 0.035, minf(length * 0.55, 1.8))
    dash.mesh = dash_mesh
    dash.position.y = 0.065
    dash.material_override = _make_emission_material(Color(0.95, 0.92, 0.72), 0.2)
    road.add_child(dash)

    if index % 2 == 0:
        var edge := MeshInstance3D.new()
        var edge_mesh := BoxMesh.new()
        edge_mesh.size = Vector3(0.08, 0.05, length)
        edge.mesh = edge_mesh
        edge.position = Vector3(-5.72, 0.09, 0.0)
        edge.material_override = _make_emission_material(Color(0.95, 0.8, 0.18), 0.18)
        road.add_child(edge)

func _add_curve_apex_marker(position: Vector3) -> void:
    var marker := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.16
    mesh.bottom_radius = 0.16
    mesh.height = 0.8
    marker.name = "ApexMarker"
    marker.mesh = mesh
    marker.position = position + Vector3(0.0, 0.45, 0.0)
    marker.material_override = _make_emission_material(Color(1.0, 0.28, 0.05), 0.7)
    add_child(marker)

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
    _add_car_button(parent, "SUPERCAR", Vector2(-310.0, 25.0))
    _add_car_button(parent, "HYPER", Vector2(-105.0, 25.0))
    _add_car_button(parent, "RALLY", Vector2(100.0, 25.0))

    customization_label = Label.new()
    customization_label.text = "COLOR: RED   WHEELS: SPORT   UPGRADE: 0/3"
    customization_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    customization_label.set_anchors_preset(Control.PRESET_CENTER)
    customization_label.position = Vector2(-360.0, 95.0)
    customization_label.size = Vector2(720.0, 55.0)
    customization_label.add_theme_font_size_override("font_size", 19)
    parent.add_child(customization_label)

    _add_custom_button(parent, "RED", Vector2(-310.0, 165.0), "color_red")
    _add_custom_button(parent, "BLUE", Vector2(-105.0, 165.0), "color_blue")
    _add_custom_button(parent, "GREEN", Vector2(100.0, 165.0), "color_green")
    _add_custom_button(parent, "SPORT WHEELS", Vector2(-310.0, 225.0), "wheel_sport")
    _add_custom_button(parent, "BLACK WHEELS", Vector2(-105.0, 225.0), "wheel_black")
    _add_custom_button(parent, "GOLD WHEELS", Vector2(100.0, 225.0), "wheel_gold")
    _add_custom_button(parent, "UPGRADE +", Vector2(-95.0, 285.0), "upgrade")
    _build_garage(parent)

func _add_car_button(parent: Control, car_name: String, button_position: Vector2) -> void:
    var button := Button.new()
    button.text = car_name
    button.position = button_position
    button.size = Vector2(160.0, 55.0)
    parent.add_child(button)

func _add_custom_button(parent: Control, label_name: String, button_position: Vector2, action_name: String) -> void:
    var button := Button.new()
    button.text = label_name
    button.position = button_position
    button.size = Vector2(150.0, 42.0)
    parent.add_child(button)

func _build_garage(parent: Control) -> void:
    var label := Label.new()
    label.text = "Garage"
    label.position = Vector2(-20.0, 350.0)
    parent.add_child(label)
