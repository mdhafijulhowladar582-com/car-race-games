extends Node3D

var health_bar: ProgressBar
var health_label: Label
var mobile_controls: CanvasLayer
var game_over_overlay: ColorRect
var game_over_title: Label
var restart_button: Button

func _ready() -> void:
    _build_environment()
    _build_road()
    _build_mobile_controls()
    _build_health_hud()
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
    var road_body := StaticBody3D.new()
    road_body.position = Vector3(0.0, -0.1, -25.0)
    add_child(road_body)

    var road_mesh := MeshInstance3D.new()
    var road_box := BoxMesh.new()
    road_box.size = Vector3(12.0, 0.2, 80.0)
    road_mesh.mesh = road_box

    var road_material := StandardMaterial3D.new()
    road_material.albedo_color = Color(0.12, 0.12, 0.14)
    road_mesh.material_override = road_material
    road_body.add_child(road_mesh)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(12.0, 0.2, 80.0)
    collision.shape = shape
    road_body.add_child(collision)

func _build_road() -> void:
    var road_material := StandardMaterial3D.new()
    road_material.albedo_color = Color(0.12, 0.12, 0.14)
    road_material.roughness = 0.92

    var segment_data := [
        {"position": Vector3(0.0, -0.1, 10.0), "size": Vector3(12.0, 0.2, 20.0), "rotation": 0.0},
        {"position": Vector3(0.0, -0.1, -8.0), "size": Vector3(12.0, 0.2, 18.0), "rotation": 0.0},
        {"position": Vector3(4.0, 0.1, -25.0), "size": Vector3(12.0, 0.2, 18.0), "rotation": -8.0},
        {"position": Vector3(9.0, 0.45, -42.0), "size": Vector3(12.0, 0.2, 18.0), "rotation": -18.0},
        {"position": Vector3(10.0, 0.85, -59.0), "size": Vector3(12.0, 0.2, 18.0), "rotation": -2.0}
    ]

    for data in segment_data:
        _add_road_segment(data.position, data.size, data.rotation, road_material)

    _add_ramp(Vector3(-2.0, 0.0, -16.0), 0.0)
    _add_ramp(Vector3(6.0, 0.25, -51.0), -18.0)

    _add_barrier(Vector3(-4.0, 0.65, -5.0), 0.0)
    _add_barrier(Vector3(4.0, 0.65, -29.0), 0.0)
    _add_barrier(Vector3(11.0, 1.35, -45.0), -18.0)
    _add_barrel(Vector3(1.8, 0.7, -35.0))
    _add_barrel(Vector3(7.0, 1.0, -55.0))

func _add_road_segment(position: Vector3, size: Vector3, rotation_y: float, material: StandardMaterial3D) -> void:
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
