extends Node

export(PackedScene) var main_scene
export(PackedScene) var options_scene

var active_child

func _ready():
	global_config.loadConfig()
	global_config.configAudio()
	global_config.configCamera($MenuBackground/Camera)

	active_child = main_scene.instance()
	active_child.connect("open_options", self, "_on_MainMenuUI_open_options")
	add_child(active_child)

func _on_MainMenuUI_open_options():
	active_child.queue_free()
	active_child = options_scene.instance()
	active_child.pass_camera($MenuBackground/Camera)
	active_child.connect("close_options", self, "_on_close_options")
	add_child(active_child)

func _on_close_options():
	active_child.queue_free()
	active_child = main_scene.instance()
	active_child.connect("open_options", self, "_on_MainMenuUI_open_options")
	add_child(active_child)