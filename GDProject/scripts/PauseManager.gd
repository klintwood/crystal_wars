extends Panel

export(PackedScene) var options_scene

var crosshair
var activeOptions

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	hide()
	crosshair = get_parent().get_node("Crosshair")
	if not OS.get_name() in global_config.DESKTOP_OS:
		$"VBoxContainer/Quit Button".queue_free()

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		if get_tree().paused:
			if not activeOptions:
				unpause()
		else:
			pause()

func pause():
	notification_manager.emit_msg("pause");
	crosshair.hide()
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	show()

func unpause():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().paused = false
	hide()
	crosshair.show()
	notification_manager.emit_msg("unpause");

func _on_Quit_Button_pressed():
	get_tree().quit()


func _on_Menu_Button_pressed():
	get_tree().paused = false
	get_tree().change_scene("res://scenes/MainMenu.tscn")


func _on_Options_Button_pressed():
	hide()
	
	activeOptions = options_scene.instance()
	activeOptions.pass_camera(get_parent().get_node("Mate/Head/Camera"))
	activeOptions.connect("close_options", self, "_on_close_options")
	get_parent().add_child(activeOptions)

func _on_close_options():
	activeOptions.queue_free()
	activeOptions = null
	show()

func _on_Continue_Button_pressed():
	unpause()
