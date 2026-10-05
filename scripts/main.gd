extends Node3D

func _ready() -> void:
    _create_environment()
    _create_track()
    _create_car()

func _create_environment() -> void:
    var world := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.08, 0.1, 0.14)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.7, 0.75, 0.85)
    environment.ambient_light_energy = 0.8
    world.environment = environment
    add_child(world)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55.0, -25.0, 0.0)
    sun.light_energy = 1.2
    add_child(sun)

func _create_track() -> void:
    var road := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(12.0, 0.2, 80.0)
    road.mesh = mesh
    road.position = Vector3(0.0, -0.1, -30.0)
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.08, 0.08, 0.09)
    road.material_override = material
    add_child(road)

func _create_car() -> void:
    var car := Node3D.new()
    car.name = "PlayerCar"
    car.position = Vector3(0.0, 0.8, 15.0)
    add_child(car)

    var body := MeshInstance3D.new()
    var body_mesh := BoxMesh.new()
    body_mesh.size = Vector3(2.2, 0.7, 4.0)
    body.mesh = body_mesh
    var body_material := StandardMaterial3D.new()
    body_material.albedo_color = Color(0.8, 0.08, 0.05)
    body.material_override = body_material
    car.add_child(body)

    var camera := Camera3D.new()
    camera.position = Vector3(0.0, 4.5, 8.0)
    camera.rotation_degrees = Vector3(-15.0, 180.0, 0.0)
    car.add_child(camera)
    camera.current = true
