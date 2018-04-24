extends Spatial

export(String) var player = "human"

func _ready():
	if player == "computer":
		var mat = load("res://materials/RedCoating.tres")
		$Ball.set_surface_material(0, mat)
