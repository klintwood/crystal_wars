extends MarginContainer

export(PackedScene) var game_scene

signal open_options



func _ready():
	if global_config.configFile.get_value("development", "fast_forward", false):
		if dev_hooks.fast_forward_once:
			get_tree().change_scene_to(game_scene)
			dev_hooks.fast_forward_once = false
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if not OS.get_name() in global_config.DESKTOP_OS:
		var quitButton = $"VBoxContainer/HBoxContainer/MarginContainer/HBoxContainer/VBoxContainer/Quit Button"
		quitButton.get_parent().remove_child(quitButton) # Is this right?

func _process(delta):
	if OS.get_name() in global_config.DESKTOP_OS and Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

func _on_Quit_Button_pressed():
	get_tree().quit()


func _on_Option_Button_pressed():
	emit_signal("open_options")


func _on_Start_Button_pressed():
	get_tree().change_scene_to(game_scene)
