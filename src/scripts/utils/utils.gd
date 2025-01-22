class_name Utils

static func is_game_exported():
	return OS.has_feature("standalone")

static func random_direction_2d() -> Vector2:
	return Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0)).normalized()

static func random_direction_3d() -> Vector3:
	return Vector3(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0), randf_range(-10.0, 10.0)).normalized()
