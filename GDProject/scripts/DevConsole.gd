extends Panel

var outputLabel
var inputEdit

func _on_command_fast_forward_on():
	global_config.configFile.set_value("development", "fast_forward", true)
	global_config.saveConfig()
	return "Fast forwarding is now on!\nOn the next start you will automaticly load the game insted of the menu."

func _on_command_fast_forward_off():
	global_config.configFile.set_value("development", "fast_forward", false)
	global_config.saveConfig()
	return "Fast forwarding is now on!\nNormal behaviour is restored."

func _ready():
	outputLabel = $OutputLabel
	inputEdit = $CommandEdit
	hide()
	
	dev_hooks.register_hook("fast_forward_on", self, "_on_command_fast_forward_on")
	dev_hooks.register_hook("fast_forward_off", self, "_on_command_fast_forward_off")

func _process(delta):
	if Input.is_action_just_pressed("dev_console"):
		if is_visible_in_tree():
			hide()
		else:
			inputEdit.text = ""
			inputEdit.grab_focus()
			outputLabel.text = "Enter help for more info."
			show()

func _on_CommandEdit_text_entered(new_text):
	var result = dev_hooks.execute_command(new_text)
	outputLabel.text = result
	inputEdit.text = ""


func _on_CommandEdit_focus_exited():
	hide()
