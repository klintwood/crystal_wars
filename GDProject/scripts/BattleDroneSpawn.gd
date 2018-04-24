extends Spatial

export(Array, NodePath) var waypoints;

const MAX_PLAYER_DISTANCE_SQR = 30.0 * 30.0

func _ready():
	get_node("/root/Demo").register_spawn_point(self)

func in_player_view():
	return translation.distance_squared_to(get_node("/root/Demo/Mate").translation) < MAX_PLAYER_DISTANCE_SQR
