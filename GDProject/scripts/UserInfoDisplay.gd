extends ReferenceRect

export(PackedScene) var infoBox

var container

func _ready():
	notification_manager.register_listener("user_info", self, "_on_user_info")
	notification_manager.register_listener("user_warn", self, "_on_user_warn")
	notification_manager.register_listener("pause", self, "_on_pause")
	notification_manager.register_listener("unpause", self, "_on_unpause")
	
	container = $VBoxContainer

func _on_user_info(args):
	
	if args.size() != 1:
		print("User info only accepts exactly one argument!")
		return
	
	var newBox = infoBox.instance()
	newBox.set_info(args[0])
	container.add_child(newBox)

func _on_user_warn(args):
	if args.size() != 1:
		print("User warn only accepts exactly one argument!")
		return
	
	var newBox = infoBox.instance()
	newBox.set_info(args[0])
	newBox.set_warning()
	container.add_child(newBox)

func _on_pause(args):
	hide()

func _on_unpause(args):
	show()
