extends Node3D

func _ready() -> void:
    _create_environment()
    _create_track()

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
    var road := StaticBody3D.new()
    road.name = "Road"

    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(12.0, 0.2, 80.0)
    mesh_instance.mesh = mesh
    mesh_instance.position = Vector3(0.0, -0.1, -25.0)

    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.08, 0.08, 0.09)
    mesh_instance.material_override = material
    road.add_child(mesh_instance)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(12.0, 0.2, 80.0)
    collision.shape = shape
    collision.position = Vector3(0.0, -0.1, -25.0)
    road.add_child(collision)

    add_child(road)
