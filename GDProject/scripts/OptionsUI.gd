extends MarginContainer

var aaMenu
var aaPopup
var fovLabel
var camera = null
var effect_player
var effect_cooldown = -10

signal close_options

func pass_camera(cam):
	camera = cam

func _ready():
	effect_player = $EffectPlayer
	
	aaMenu = $"VBoxContainer/HBoxContainer/MarginContainer/HBoxContainer/VBoxContainer/AA Select"
	aaPopup = aaMenu.get_popup()
	aaPopup.add_item("Off", 0)
	aaPopup.add_item("MSAA 2X", 1)
	aaPopup.add_item("MSAA 4X", 2)
	aaPopup.add_item("MSAA 8X", 3)
	aaPopup.connect("id_pressed", self, "_on_aa_select_pressed")
	aaMenu.text = aaPopup.get_item_text(global_config.msaa)
	
	var musicSlider = $"VBoxContainer/HBoxContainer/MarginContainer/HBoxContainer/VBoxContainer/Music Slider"
	var sfxSlider = $"VBoxContainer/HBoxContainer/MarginContainer/HBoxContainer/VBoxContainer/SFX Slider"
	
	musicSlider.value = global_config.musicVolume
	sfxSlider.value = global_config.sfxVolume
	effect_cooldown = -10 # Workaround for Value changed event
	
	var fovSlider = $"VBoxContainer/HBoxContainer/MarginContainer/HBoxContainer/VBoxContainer/FOV Slider"
	fovLabel = $"VBoxContainer/HBoxContainer/MarginContainer/HBoxContainer/VBoxContainer/FOV"
	fovSlider.min_value = global_config.MIN_FOV
	fovSlider.max_value = global_config.MAX_FOV
	fovSlider.value = global_config.fov
	fovLabel.text = "FOV: " + str(global_config.fov)

func _process(delta):
	if effect_cooldown > 0:
		effect_cooldown -= delta
		if effect_cooldown <= 0:
			if not effect_player.playing:
				effect_player.play()
				effect_cooldown = -10
			else:
				effect_cooldown += 0.2

func _on_Return_Button_pressed():
	global_config.saveConfig()
	emit_signal("close_options")

func _on_aa_select_pressed(id):
	aaMenu.text = aaPopup.get_item_text(id)
	global_config.msaa = id
	if camera:
		global_config.configCamera(camera)


func _on_Music_Slider_value_changed(value):
	global_config.changeMusicVolume(value)


func _on_SFX_Slider_value_changed(value):
	global_config.changeSfxVolume(value)
	effect_cooldown = 0.3


func _on_FOV_Slider_value_changed(value):
	value = int(round(clamp(value, global_config.MIN_FOV, global_config.MAX_FOV)))
	global_config.fov = value
	fovLabel.text = "FOV: " + str(value)
	if camera:
		global_config.configCamera(camera)
