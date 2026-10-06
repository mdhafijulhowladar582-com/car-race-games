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
var minimap_canvas: CanvasLayer
var minimap_route: Line2D
var minimap_player_marker: ColorRect
var minimap_ai_markers: Array[ColorRect] = []
var minimap_root: Control
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

func _save_progress() -> void:
    var data := {
        "coins": coins,
        "xp": xp,
        "total_races": total_races,
        "best_time": best_time,
        "achievements": achievements
    }
    var file := FileAccess.open(save_path, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(data))

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
    _build_minimap()
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
    _build_car_select_button()
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

func _physics_process(delta: float) -> void:
    _update_minimap()
    var car := get_node_or_null("PlayerCar")
    if not car or race_finished:
        return

    if not race_started:
        countdown_time = maxf(countdown_time - delta, 0.0)
        car.speed = 0.0
        car.velocity = Vector3.ZERO
        if countdown_label:
            countdown_label.text = str(ceili(countdown_time)) if countdown_time > 0.0 else "GO!"
        if countdown_time <= 0.0:
            race_started = true
            race_elapsed = 0.0
            for ai in ai_opponents:
                if is_instance_valid(ai) and ai.has_method("start_race"):
                    ai.start_race()
        return

    race_elapsed += delta
    _update_ai_racing(delta)
    var progress := clampf((race_start_z - car.global_position.z) / (race_start_z - finish_z), 0.0, 1.0)
    current_checkpoint = clampi(int(floor(progress * total_checkpoints)), 0, total_checkpoints)

    if race_bar:
        race_bar.value = progress
    if timer_label:
        var minutes := int(race_elapsed / 60.0)
        var seconds := fmod(race_elapsed, 60.0)
        timer_label.text = "TIME %02d:%05.2f" % [minutes, seconds]
    if checkpoint_label:
        checkpoint_label.text = "CHECKPOINT %d/%d" % [current_checkpoint, total_checkpoints]

    player_race_position = 1
    for ai in ai_opponents:
        if is_instance_valid(ai) and ai.global_position.z < car.global_position.z:
            player_race_position += 1
    if position_label:
        position_label.text = "POSITION %d/%d" % [player_race_position, ai_opponents.size() + 1]

    if progress >= 1.0 or car.global_position.z <= finish_z:
        _finish_race()

func _build_mobile_controls() -> void:
    mobile_controls = CanvasLayer.new()
    mobile_controls.layer = 15
    add_child(mobile_controls)

    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    mobile_controls.add_child(root)

    var hint := Label.new()
    hint.text = "Touch Controls"
    hint.set_anchors_preset(Control.PRESET_TOP_LEFT)
    hint.position = Vector2(18.0, 18.0)
    hint.add_theme_font_size_override("font_size", 18)
    root.add_child(hint)

    _add_touch_button(root, "LEFT", "steer_left", true, 18.0)
    _add_touch_button(root, "RIGHT", "steer_right", true, 138.0)
    _add_touch_button(root, "BRAKE", "brake", false, 138.0)
    _add_touch_button(root, "GO", "accelerate", false, 18.0)

func _add_touch_button(parent: Control, label_text: String, action_name: String, left_side: bool, bottom_offset: float) -> void:
    var button := Button.new()
    button.text = label_text
    button.size = Vector2(100.0, 82.0)
    button.focus_mode = Control.FOCUS_NONE
    button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    if left_side:
        button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
        button.position = Vector2(bottom_offset, -100.0)
    else:
        button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
        button.position = Vector2(-100.0 - bottom_offset, -100.0)
    button.button_down.connect(func() -> void:
        Input.action_press(action_name)
    )
    button.button_up.connect(func() -> void:
        Input.action_release(action_name)
    )
    parent.add_child(button)

func _finish_race() -> void:
    if race_finished:
        return
    race_finished = true
    race_started = false
    var car := get_node_or_null("PlayerCar")
    if car:
        car.speed = 0.0
        car.velocity = Vector3.ZERO
    for ai in ai_opponents:
        if is_instance_valid(ai):
            ai.race_active = false

    total_races += 1
    var reward_coins := max(10, 60 - (player_race_position - 1) * 10)
    var reward_xp := max(25, 100 - (player_race_position - 1) * 15)
    coins += reward_coins
    xp += reward_xp
    if player_race_position == 1:
        career_wins += 1
        career_stars += 3
    elif player_race_position == 2:
        career_stars += 2
    elif player_race_position == 3:
        career_stars += 1
    career_races += 1
    if best_time <= 0.0 or race_elapsed < best_time:
        best_time = race_elapsed
    _save_progress()
    _update_rewards_hud()
    if race_label:
        race_label.text = "FINISH"
    _show_race_results(reward_coins, reward_xp)

func _show_race_results(reward_coins: int, reward_xp: int) -> void:
    if results_canvas and is_instance_valid(results_canvas):
        results_canvas.queue_free()
    results_canvas = CanvasLayer.new()
    add_child(results_canvas)

    var overlay := ColorRect.new()
    overlay.color = Color(0.0, 0.0, 0.0, 0.78)
    overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    results_canvas.add_child(overlay)

    var title := Label.new()
    title.text = "RACE COMPLETE"
    title.position = Vector2(470.0, 120.0)
    title.add_theme_font_size_override("font_size", 42)
    overlay.add_child(title)

    result_time_label = Label.new()
    var minutes := int(race_elapsed / 60.0)
    var seconds := fmod(race_elapsed, 60.0)
    result_time_label.text = "TIME %02d:%05.2f\nPOSITION %d/%d\n+%d COINS\n+%d XP" % [minutes, seconds, player_race_position, ai_opponents.size() + 1, reward_coins, reward_xp]
    result_time_label.position = Vector2(470.0, 200.0)
    result_time_label.add_theme_font_size_override("font_size", 24)
    overlay.add_child(result_time_label)

    var restart := Button.new()
    restart.text = "NEXT RACE"
    restart.position = Vector2(510.0, 400.0)
    restart.size = Vector2(260.0, 60.0)
    restart.pressed.connect(func() -> void:
        get_tree().reload_current_scene()
    )
    overlay.add_child(restart)

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

    countdown_label = Label.new()
    countdown_label.text = "3"
    countdown_label.position = Vector2(560.0, 120.0)
    countdown_label.add_theme_font_size_override("font_size", 64)
    add_child(countdown_label)

    timer_label = Label.new()
    timer_label.text = "TIME 00:00.00"
    timer_label.position = Vector2(500.0, 70.0)
    timer_label.add_theme_font_size_override("font_size", 22)
    add_child(timer_label)

    position_label = Label.new()
    position_label.text = "POSITION 1/4"
    position_label.position = Vector2(20.0, 90.0)
    position_label.add_theme_font_size_override("font_size", 20)
    add_child(position_label)

    checkpoint_label = Label.new()
    checkpoint_label.text = "CHECKPOINT 0/3"
    checkpoint_label.position = Vector2(20.0, 120.0)
    checkpoint_label.add_theme_font_size_override("font_size", 20)
    add_child(checkpoint_label)

    race_bar = ProgressBar.new()
    race_bar.min_value = 0.0
    race_bar.max_value = 1.0
    race_bar.value = 0.0
    race_bar.position = Vector2(420.0, 110.0)
    race_bar.size = Vector2(420.0, 18.0)
    add_child(race_bar)

func _build_minimap() -> void:
    minimap_canvas = CanvasLayer.new()
    minimap_canvas.layer = 20
    add_child(minimap_canvas)

    var panel := ColorRect.new()
    panel.name = "MinimapPanel"
    panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    panel.position = Vector2(-300.0, 70.0)
    panel.size = Vector2(285.0, 190.0)
    panel.color = Color(0.015, 0.02, 0.035, 0.88)
    minimap_canvas.add_child(panel)

    var title := Label.new()
    title.text = "MINIMAP"
    title.position = Vector2(12.0, 8.0)
    title.add_theme_font_size_override("font_size", 18)
    panel.add_child(title)

    minimap_root = Control.new()
    minimap_root.position = Vector2(12.0, 36.0)
    minimap_root.size = Vector2(261.0, 142.0)
    panel.add_child(minimap_root)

    minimap_route = Line2D.new()
    minimap_route.width = 4.0
    minimap_route.closed = false
    minimap_root.add_child(minimap_route)

    minimap_player_marker = ColorRect.new()
    minimap_player_marker.size = Vector2(10.0, 10.0)
    minimap_player_marker.color = Color(1.0, 0.82, 0.08, 1.0)
    minimap_root.add_child(minimap_player_marker)

    _update_minimap_route()

func _update_minimap_route() -> void:
    if not minimap_route or track_path.is_empty():
        return

    var min_x := INF
    var max_x := -INF
    var min_z := INF
    var max_z := -INF
    for point in track_path:
        min_x = minf(min_x, point.x)
        max_x = maxf(max_x, point.x)
        min_z = minf(min_z, point.z)
        max_z = maxf(max_z, point.z)

    var width := maxf(max_x - min_x, 1.0)
    var depth := maxf(max_z - min_z, 1.0)
    var points := PackedVector2Array()
    var margin := 8.0
    var draw_size := minimap_root.size - Vector2.ONE * margin * 2.0

    for point in track_path:
        var x := ((point.x - min_x) / width) * draw_size.x + margin
        var y := ((max_z - point.z) / depth) * draw_size.y + margin
        points.append(Vector2(x, y))

    minimap_route.points = points

    for marker in minimap_ai_markers:
        if is_instance_valid(marker):
            marker.queue_free()
    minimap_ai_markers.clear()

    for i in range(ai_opponents.size()):
        var marker := ColorRect.new()
        marker.size = Vector2(8.0, 8.0)
        marker.color = Color(0.25, 0.55, 1.0, 1.0)
        minimap_root.add_child(marker)
        minimap_ai_markers.append(marker)

    _update_minimap()

func _update_minimap() -> void:
    if not minimap_root or track_path.is_empty():
        return

    var min_x := INF
    var max_x := -INF
    var min_z := INF
    var max_z := -INF
    for point in track_path:
        min_x = minf(min_x, point.x)
        max_x = maxf(max_x, point.x)
        min_z = minf(min_z, point.z)
        max_z = maxf(max_z, point.z)

    var width := maxf(max_x - min_x, 1.0)
    var depth := maxf(max_z - min_z, 1.0)
    var margin := 8.0
    var draw_size := minimap_root.size - Vector2.ONE * margin * 2.0

    var car := get_node_or_null("PlayerCar")
    if car and minimap_player_marker:
        var px := ((car.global_position.x - min_x) / width) * draw_size.x + margin
        var py := ((max_z - car.global_position.z) / depth) * draw_size.y + margin
        minimap_player_marker.position = Vector2(px - 5.0, py - 5.0)

    for i in range(mini(ai_opponents.size(), minimap_ai_markers.size())):
        var ai := ai_opponents[i]
        if not is_instance_valid(ai):
            continue
        var ax := ((ai.global_position.x - min_x) / width) * draw_size.x + margin
        var ay := ((max_z - ai.global_position.z) / depth) * draw_size.y + margin
        minimap_ai_markers[i].position = Vector2(ax - 4.0, ay - 4.0)

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
        ai.race_active = false
    _update_minimap_route()

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
    _apply_professional_lighting(selected_weather)

    if rain_particles and is_instance_valid(rain_particles):
        rain_particles.queue_free()
        rain_particles = null

    if selected_weather == "RAIN":
        rain_particles = GPUParticles3D.new()
        rain_particles.name = "RainParticles"
        rain_particles.amount = 900
        rain_particles.lifetime = 1.2
        rain_particles.visibility_aabb = AABB(Vector3(-35.0, 0.0, -80.0), Vector3(70.0, 18.0, 110.0))

        var rain_mesh := QuadMesh.new()
        rain_mesh.size = Vector2(0.035, 1.2)
        var rain_material := StandardMaterial3D.new()
        rain_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        rain_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        rain_material.albedo_color = Color(0.55, 0.7, 1.0, 0.55)
        rain_mesh.material = rain_material
        rain_particles.draw_pass_1 = rain_mesh

        var process_material := ParticleProcessMaterial.new()
        process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
        process_material.emission_box_extents = Vector3(35.0, 1.0, 55.0)
        process_material.direction = Vector3(0.0, -1.0, 0.0)
        process_material.initial_velocity_min = 18.0
        process_material.initial_velocity_max = 26.0
        process_material.gravity = Vector3(0.0, -4.0, 0.0)
        process_material.spread = 4.0
        rain_particles.process_material = process_material
        rain_particles.position = Vector3(0.0, 12.0, -28.0)
        add_child(rain_particles)

    if fog_environment and is_instance_valid(fog_environment):
        fog_environment.volumetric_fog_enabled = selected_weather == "RAIN"
        fog_environment.volumetric_fog_density = 0.018 if selected_weather == "RAIN" else 0.008

func _apply_map(map_name: String) -> void:
    selected_map = map_name
    _rebuild_map()
    if map_label:
        map_label.text = "MAP: %s" % selected_map

func _rebuild_map() -> void:
    for child in get_children():
        if child.name.begins_with("CurvedRoad") or child.name == "ApexMarker" or child.name == "MapEnvironment":
            child.queue_free()

    await get_tree().process_frame

    _build_professional_track()
    _build_map_environment()
    _sync_race_start_to_map()
    _update_minimap_route()

func _build_map_environment() -> void:
    var environment_root := Node3D.new()
    environment_root.name = "MapEnvironment"
    add_child(environment_root)

    var material := _make_pbr_material(Color(0.035, 0.11, 0.045), 0.98, 0.0, 3.0, 700 + selected_map.length())

    if selected_map == "DESERT":
        material = _make_pbr_material(Color(0.45, 0.25, 0.08), 0.92, 0.0, 3.0, 711)
        for i in range(16):
            var z := 12.0 - float(i) * 5.5
            _add_map_tree_or_cactus(environment_root, Vector3(-12.0, 0.0, z), false)
            _add_map_tree_or_cactus(environment_root, Vector3(14.0, 0.0, z - 2.0), false)
    elif selected_map == "HIGHWAY":
        material = _make_pbr_material(Color(0.07, 0.08, 0.09), 0.9, 0.05, 3.0, 722)
        for i in range(12):
            var z := 12.0 - float(i) * 7.0
            _add_map_building(environment_root, Vector3(-14.0, 4.0, z), Vector3(6.0, 8.0, 6.0))
            _add_map_building(environment_root, Vector3(16.0, 5.0, z - 3.0), Vector3(7.0, 10.0, 7.0))
    else:
        for i in range(18):
            var z := 13.0 - float(i) * 5.0
            _add_map_tree_or_cactus(environment_root, Vector3(-12.0, 0.0, z), true)
            _add_map_tree_or_cactus(environment_root, Vector3(15.0, 0.0, z - 2.0), true)

func _add_map_tree_or_cactus(parent: Node3D, position: Vector3, tree: bool) -> void:
    var root := Node3D.new()
    root.position = position
    parent.add_child(root)

    var material := _make_material(Color(0.08, 0.25, 0.09) if tree else Color(0.35, 0.5, 0.16), 0.0, 0.9)
    var trunk := MeshInstance3D.new()
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.12 if tree else 0.22
    trunk_mesh.bottom_radius = 0.22 if tree else 0.28
    trunk_mesh.height = 2.6 if tree else 2.2
    trunk.mesh = trunk_mesh
    trunk.position.y = trunk_mesh.height * 0.5
    trunk.material_override = material
    root.add_child(trunk)

    if tree:
        var crown := MeshInstance3D.new()
        var crown_mesh := SphereMesh.new()
        crown_mesh.radius = 1.1
        crown_mesh.height = 2.2
        crown.mesh = crown_mesh
        crown.position.y = 2.9
        crown.material_override = material
        root.add_child(crown)
    else:
        for side in [-1.0, 1.0]:
            var arm := MeshInstance3D.new()
            var arm_mesh := CylinderMesh.new()
            arm_mesh.top_radius = 0.1
            arm_mesh.bottom_radius = 0.14
            arm_mesh.height = 0.9
            arm.mesh = arm_mesh
            arm.position = Vector3(side * 0.42, 1.7, 0.0)
            arm.rotation_degrees.z = side * 65.0
            arm.material_override = material
            root.add_child(arm)

func _add_map_building(parent: Node3D, position: Vector3, size: Vector3) -> void:
    var building := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    building.mesh = mesh
    building.position = position
    building.material_override = _make_material(Color(0.16, 0.18, 0.2), 0.25, 0.75)
    parent.add_child(building)

func _sync_race_start_to_map() -> void:
    if track_path.is_empty():
        return
    race_start_z = track_path[0].z
    finish_z = track_path[track_path.size() - 1].z
    race_finished = false
    race_started = false
    countdown_time = 3.0

    var car := get_node_or_null("PlayerCar")
    if car:
        car.global_position = track_path[0] + Vector3(0.0, 1.0, 0.0)
        car.velocity = Vector3.ZERO
        car.speed = 0.0

    for i in range(ai_opponents.size()):
        var ai := ai_opponents[i]
        if not is_instance_valid(ai):
            continue
        if ai.has_method("setup"):
            ai.setup(track_path, 0)
        ai.global_position = track_path[0] + Vector3(ai_racing_offsets[i], 1.0, 0.0)
        ai.velocity = Vector3.ZERO
        ai.speed = 0.0
        ai.race_active = false
        ai.finished = false

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
    var button := Button.new()
    button.text = "WEATHER"
    button.position = Vector2(930.0, 12.0)
    button.size = Vector2(115.0, 42.0)
    button.pressed.connect(_show_weather_selector)
    add_child(button)

func _show_weather_selector() -> void:
    weather_overlay = ColorRect.new()
    weather_overlay.name = "WeatherSelectorOverlay"
    weather_overlay.color = Color(0.02, 0.025, 0.04, 0.94)
    weather_overlay.position = Vector2(430.0, 150.0)
    weather_overlay.size = Vector2(420.0, 390.0)
    add_child(weather_overlay)

    var title := Label.new()
    title.text = "SELECT WEATHER"
    title.position = Vector2(105.0, 25.0)
    title.add_theme_font_size_override("font_size", 28)
    weather_overlay.add_child(title)

    var weather_types := ["DAY", "NIGHT", "RAIN"]
    for i in range(weather_types.size()):
        var weather_name := weather_types[i]
        var button := Button.new()
        button.text = weather_name
        button.position = Vector2(70.0, 85.0 + i * 75.0)
        button.size = Vector2(280.0, 55.0)
        button.pressed.connect(func() -> void:
            _apply_weather(weather_name)
            weather_overlay.queue_free()
            weather_overlay = null
        )
        weather_overlay.add_child(button)

    var close := Button.new()
    close.text = "CLOSE"
    close.position = Vector2(150.0, 315.0)
    close.size = Vector2(120.0, 45.0)
    close.pressed.connect(func() -> void:
        weather_overlay.queue_free()
        weather_overlay = null
    )
    weather_overlay.add_child(close)

func _build_map_select() -> void:
    map_label = Label.new()
    map_label.text = "MAP: %s" % selected_map
    map_label.position = Vector2(700.0, 15.0)
    map_label.add_theme_font_size_override("font_size", 20)
    add_child(map_label)

    var button := Button.new()
    button.text = "MAP"
    button.position = Vector2(840.0, 12.0)
    button.size = Vector2(90.0, 42.0)
    button.pressed.connect(_show_map_selector)
    add_child(button)

func _show_map_selector() -> void:
    var overlay := ColorRect.new()
    overlay.name = "MapSelectorOverlay"
    overlay.color = Color(0.02, 0.025, 0.04, 0.94)
    overlay.position = Vector2(430.0, 150.0)
    overlay.size = Vector2(420.0, 390.0)
    add_child(overlay)

    var title := Label.new()
    title.text = "SELECT MAP"
    title.position = Vector2(145.0, 25.0)
    title.add_theme_font_size_override("font_size", 28)
    overlay.add_child(title)

    var maps := ["CITY", "HIGHWAY", "DESERT"]
    for i in range(maps.size()):
        var map_name := maps[i]
        var button := Button.new()
        button.text = map_name
        button.position = Vector2(70.0, 85.0 + i * 75.0)
        button.size = Vector2(280.0, 55.0)
        button.pressed.connect(func() -> void:
            _apply_map(map_name)
            overlay.queue_free()
        )
        overlay.add_child(button)

    var close := Button.new()
    close.text = "CLOSE"
    close.position = Vector2(150.0, 315.0)
    close.size = Vector2(120.0, 45.0)
    close.pressed.connect(func() -> void:
        if is_instance_valid(garage_overlay):
            garage_overlay.queue_free()
        garage_overlay = null
    )
    overlay.add_child(close)

func _build_settings_button() -> void:
    var button := Button.new()
    button.text = "Settings"
    button.position = Vector2(1160.0, 20.0)
    button.size = Vector2(100.0, 42.0)
    button.pressed.connect(_show_settings)
    add_child(button)

func _show_settings() -> void:
    if settings_overlay and is_instance_valid(settings_overlay):
        settings_overlay.queue_free()
        settings_overlay = null
        settings_label = null
        return

    settings_overlay = ColorRect.new()
    settings_overlay.color = Color(0.02, 0.025, 0.04, 0.94)
    settings_overlay.position = Vector2(300.0, 120.0)
    settings_overlay.size = Vector2(680.0, 500.0)
    add_child(settings_overlay)

    settings_label = Label.new()
    settings_label.position = Vector2(35.0, 30.0)
    settings_label.size = Vector2(600.0, 80.0)
    settings_label.add_theme_font_size_override("font_size", 28)
    settings_overlay.add_child(settings_label)

    var sensitivity_label := Label.new()
    sensitivity_label.text = "Steering Sensitivity"
    sensitivity_label.position = Vector2(35.0, 130.0)
    sensitivity_label.add_theme_font_size_override("font_size", 22)
    settings_overlay.add_child(sensitivity_label)

    var sensitivity_slider := HSlider.new()
    sensitivity_slider.position = Vector2(35.0, 175.0)
    sensitivity_slider.size = Vector2(560.0, 40.0)
    sensitivity_slider.min_value = 0.5
    sensitivity_slider.max_value = 1.8
    sensitivity_slider.step = 0.05
    sensitivity_slider.value = steering_sensitivity
    sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
    settings_overlay.add_child(sensitivity_slider)

    var volume_label := Label.new()
    volume_label.text = "Master Volume"
    volume_label.position = Vector2(35.0, 235.0)
    volume_label.add_theme_font_size_override("font_size", 22)
    settings_overlay.add_child(volume_label)

    var volume_slider := HSlider.new()
    volume_slider.position = Vector2(35.0, 280.0)
    volume_slider.size = Vector2(560.0, 40.0)
    volume_slider.min_value = 0.0
    volume_slider.max_value = 1.0
    volume_slider.step = 0.05
    volume_slider.value = master_volume
    volume_slider.value_changed.connect(_on_master_volume_changed)
    settings_overlay.add_child(volume_slider)

    var close_button := Button.new()
    close_button.text = "CLOSE"
    close_button.position = Vector2(500.0, 410.0)
    close_button.size = Vector2(120.0, 48.0)
    close_button.pressed.connect(_show_settings)
    settings_overlay.add_child(close_button)

    _update_settings_label()

func _update_settings_label() -> void:
    if settings_label and is_instance_valid(settings_label):
        settings_label.text = "SETTINGS\n\nSensitivity: %.2f\nVolume: %d%%\nQuality: %s" % [steering_sensitivity, int(master_volume * 100.0), graphics_quality]

func _on_sensitivity_changed(value: float) -> void:
    steering_sensitivity = value
    var car := get_node_or_null("PlayerCar")
    if car and "steering_sensitivity" in car:
        car.steering_sensitivity = value
    _save_settings()
    _update_settings_label()

func _on_master_volume_changed(value: float) -> void:
    master_volume = value
    AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master_volume, 0.001)))
    _save_settings()
    _update_settings_label()

func _save_settings() -> void:
    var data := {
        "graphics_quality": graphics_quality,
        "master_volume": master_volume,
        "steering_sensitivity": steering_sensitivity,
        "vibration_enabled": vibration_enabled
    }
    var file := FileAccess.open(settings_path, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(data))

func _build_leaderboard_button() -> void:
    var button := Button.new()
    button.text = "Leaderboard"
    button.position = Vector2(1110.0, 70.0)
    button.size = Vector2(150.0, 52.0)
    button.pressed.connect(_show_leaderboard)
    add_child(button)

func _setup_online_leaderboard() -> void:
    leaderboard_http = HTTPRequest.new()
    leaderboard_http.name = "LeaderboardHTTP"
    add_child(leaderboard_http)
    leaderboard_http.request_completed.connect(_on_leaderboard_request_completed)
    online_leaderboard_status = "OFFLINE"

func _show_leaderboard() -> void:
    if leaderboard_overlay and is_instance_valid(leaderboard_overlay):
        leaderboard_overlay.queue_free()
        leaderboard_overlay = null
        leaderboard_label = null
        return

    leaderboard_overlay = ColorRect.new()
    leaderboard_overlay.color = Color(0.02, 0.025, 0.04, 0.94)
    leaderboard_overlay.position = Vector2(180.0, 90.0)
    leaderboard_overlay.size = Vector2(920.0, 560.0)
    add_child(leaderboard_overlay)

    leaderboard_label = Label.new()
    leaderboard_label.position = Vector2(35.0, 30.0)
    leaderboard_label.size = Vector2(850.0, 470.0)
    leaderboard_label.add_theme_font_size_override("font_size", 24)
    leaderboard_overlay.add_child(leaderboard_label)

    var close_button := Button.new()
    close_button.text = "CLOSE"
    close_button.position = Vector2(760.0, 485.0)
    close_button.size = Vector2(120.0, 48.0)
    close_button.pressed.connect(_show_leaderboard)
    leaderboard_overlay.add_child(close_button)

    _refresh_leaderboard()

func _refresh_leaderboard() -> void:
    if leaderboard_label == null:
        return

    if leaderboard_entries.is_empty():
        leaderboard_label.text = "LEADERBOARD\n\nNo local records yet."
    else:
        var sorted_entries: Array = leaderboard_entries.duplicate()
        sorted_entries.sort_custom(func(a, b) -> bool:
            return _leaderboard_time_value(a) < _leaderboard_time_value(b)
        )

        var text_lines := ["LEADERBOARD", ""]
        for i in range(mini(sorted_entries.size(), 10)):
            var entry = sorted_entries[i]
            text_lines.append("%02d. %s — %s" % [i + 1, str(entry.get("name", "PLAYER")), str(entry.get("time", "--"))])
        leaderboard_label.text = "\n".join(text_lines)

    if online_leaderboard_url.is_empty():
        online_leaderboard_status = "OFFLINE"

func _leaderboard_time_value(entry: Variant) -> float:
    if not (entry is Dictionary):
        return INF
    var raw_time = entry.get("time", INF)
    if raw_time is float or raw_time is int:
        return float(raw_time)

    var time_text := str(raw_time).strip_edges()
    if ":" in time_text:
        var parts := time_text.split(":")
        if parts.size() == 2:
            return float(parts[0]) * 60.0 + float(parts[1])
    return float(time_text) if time_text.is_valid_float() else INF

func _on_leaderboard_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    if response_code < 200 or response_code >= 300:
        online_leaderboard_status = "OFFLINE"
        return

    var parsed = JSON.parse_string(body.get_string_from_utf8())
    if parsed is Array:
        leaderboard_entries = parsed
        online_leaderboard_status = "ONLINE"
        if leaderboard_label and is_instance_valid(leaderboard_label):
            _refresh_leaderboard()

func _update_map_label() -> void:
    if map_label:
        map_label.text = "MAP: %s" % selected_map

func _update_rewards_hud() -> void:
    if coins_label:
        coins_label.text = "Coins: %d" % coins
    if reward_label:
        reward_label.text = "Rewards | XP: %d | Coins: %d" % [xp, coins]

func _update_ai_racing(_delta: float) -> void:
    ai_race_progress.clear()
    ai_last_positions.clear()

    var player := get_node_or_null("PlayerCar")
    var player_progress := 0.0
    if player:
        player_progress = clampf((race_start_z - player.global_position.z) / (race_start_z - finish_z), 0.0, 1.0)

    for ai in ai_opponents:
        if not is_instance_valid(ai):
            continue

        var progress := clampf((race_start_z - ai.global_position.z) / (race_start_z - finish_z), 0.0, 1.0)
        ai_race_progress.append(progress)

        if progress >= 1.0 and ai.has_method("start_race"):
            ai.race_active = false
            ai.finished = true

        if player_progress > progress:
            ai_last_positions.append(1)
        else:
            ai_last_positions.append(0)

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
    fog_environment = environment
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
    elif weather == "RAIN":
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

func _build_car_select_button() -> void:
    var button := Button.new()
    button.text = "CARS"
    button.position = Vector2(1035.0, 12.0)
    button.size = Vector2(115.0, 42.0)
    button.pressed.connect(_show_car_selector)
    add_child(button)

func _show_car_selector() -> void:
    if garage_overlay and is_instance_valid(garage_overlay):
        garage_overlay.queue_free()
        garage_overlay = null
        return

    var overlay := ColorRect.new()
    overlay.name = "CarSelectorOverlay"
    garage_overlay = overlay
    overlay.color = Color(0.02, 0.025, 0.04, 0.96)
    overlay.position = Vector2(300.0, 80.0)
    overlay.size = Vector2(680.0, 560.0)
    add_child(overlay)

    var title := Label.new()
    title.text = "GARAGE / CAR SELECT"
    title.position = Vector2(210.0, 20.0)
    title.add_theme_font_size_override("font_size", 28)
    overlay.add_child(title)

    var content := Control.new()
    content.position = Vector2(340.0, 300.0)
    overlay.add_child(content)
    _build_car_select(content)

    var close := Button.new()
    close.text = "CLOSE"
    close.position = Vector2(280.0, 500.0)
    close.size = Vector2(120.0, 42.0)
    close.pressed.connect(func() -> void:
        overlay.queue_free()
    )
    overlay.add_child(close)

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
    _update_car_selection_label()
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
    button.pressed.connect(func() -> void:
        selected_car = car_name
        _update_car_selection_label()
    )
    parent.add_child(button)

func _add_custom_button(parent: Control, label_name: String, button_position: Vector2, action_name: String) -> void:
    var button := Button.new()
    button.text = label_name
    button.position = button_position
    button.size = Vector2(150.0, 42.0)
    button.pressed.connect(func() -> void:
        _apply_customization(action_name)
    )
    parent.add_child(button)

func _apply_customization(action_name: String) -> void:
    match action_name:
        "color_red":
            selected_color = Color(0.82, 0.025, 0.02)
        "color_blue":
            selected_color = Color(0.04, 0.22, 0.88)
        "color_green":
            selected_color = Color(0.05, 0.7, 0.18)
        "wheel_sport":
            selected_wheels = "SPORT"
        "wheel_black":
            selected_wheels = "BLACK"
        "wheel_gold":
            selected_wheels = "GOLD"
        "upgrade":
            if upgrade_level < 3:
                upgrade_level += 1
        _:
            return
    _update_car_selection_label()

func _update_car_selection_label() -> void:
    var stats := {
        "SPORTS": [34, 18, 2.2],
        "MUSCLE": [31, 20, 1.9],
        "GT": [36, 17, 2.4],
        "SUPERCAR": [42, 23, 2.8],
        "HYPER": [48, 26, 3.0],
        "RALLY": [33, 21, 2.5]
    }
    var values: Array = stats.get(selected_car, [34, 18, 2.2])
    var speed_value := float(values[0]) + upgrade_level * 2.0
    var acceleration_value := float(values[1]) + upgrade_level * 1.5
    var handling_value := float(values[2]) + upgrade_level * 0.1
    if car_label:
        car_label.text = "CAR: %s\nSpeed %.0f | Acceleration %.1f | Handling %.1f" % [selected_car, speed_value, acceleration_value, handling_value]
    if customization_label:
        customization_label.text = "COLOR: %s   WHEELS: %s   UPGRADE: %d/3" % [_get_color_name(), selected_wheels, upgrade_level]
    _update_garage_info()

func _get_color_name() -> String:
    if selected_color.is_equal_approx(Color(0.04, 0.22, 0.88)):
        return "BLUE"
    if selected_color.is_equal_approx(Color(0.05, 0.7, 0.18)):
        return "GREEN"
    return "RED"

func _build_garage(parent: Control) -> void:
    garage_info_label = Label.new()
    garage_info_label.text = "GARAGE\nSelected: %s\nColor: %s\nWheels: %s\nUpgrade: %d/3" % [selected_car, _get_color_name(), selected_wheels, upgrade_level]
    garage_info_label.position = Vector2(-120.0, 340.0)
    garage_info_label.size = Vector2(240.0, 120.0)
    garage_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    parent.add_child(garage_info_label)

func _update_garage_info() -> void:
    if garage_info_label:
        garage_info_label.text = "GARAGE\nSelected: %s\nColor: %s\nWheels: %s\nUpgrade: %d/3" % [selected_car, _get_color_name(), selected_wheels, upgrade_level]
