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
var race_finished := false
var race_start_z := 15.0
var finish_z := -66.0


func _ready() -> void:
    _build_environment()
    _build_road()
    _build_mobile_controls()
    _build_health_hud()
    _build_race_system()
    _build_game_over_ui()

    var car := get_node_or_null("PlayerCar")
    if car:
        car.health_changed.connect(_on_health_changed)
        car.game_over.connect(_on_game_over)
        _on_health_changed(car.health, car.max_health)

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

func _build_race_system() -> void:
    _add_finish_line()
    
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

    var checkpoint_label := Label.new()
    checkpoint_label.name = "CheckpointInfo"
    checkpoint_label.position = Vector2(28.0, 184.0)
    checkpoint_label.size = Vector2(330.0, 30.0)
    checkpoint_label.text = "FINISH: 81m"
    checkpoint_label.add_theme_font_size_override("font_size", 16)
    canvas.add_child(checkpoint_label)

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

func _process(_delta: float) -> void:
    if race_finished:
        return

    var car := get_node_or_null("PlayerCar")
    if not car:
        return

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
    race_finished = true
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
    message.text = "You reached the finish line!"
    message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    message.set_anchors_preset(Control.PRESET_CENTER)
    message.position = Vector2(-320.0, -35.0)
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
    add_child(mobile_controls)

    var title := Label.new()
    title.text = "TOUCH CONTROLS"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 18)
    title.modulate = Color(1.0, 1.0, 1.0, 0.75)
    title.set_anchors_preset(Control.PRESET_TOP_WIDE)
    title.position = Vector2(0.0, 18.0)
    title.size = Vector2(1280.0, 30.0)
    mobile_controls.add_child(title)

    _add_touch_button(mobile_controls, "LEFT", "steer_left", Vector2(35.0, 585.0), Vector2(130.0, 95.0))
    _add_touch_button(mobile_controls, "RIGHT", "steer_right", Vector2(180.0, 585.0), Vector2(130.0, 95.0))
    _add_touch_button(mobile_controls, "BRAKE", "brake", Vector2(965.0, 585.0), Vector2(130.0, 95.0))
    _add_touch_button(mobile_controls, "GO", "accelerate", Vector2(1110.0, 585.0), Vector2(130.0, 95.0))

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
