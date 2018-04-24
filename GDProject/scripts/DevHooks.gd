extends Node

var _hooks = {}
var watchedScene
var fast_forward_once = true # Somewhat shitty hack but who cares

func printHelpCallback():
	return "This is the developer console!\nEnter 'list' to see available commands."

func printListCallback():
	var listString = ""
	for cmd in _hooks:
		listString += cmd + ", "
		
	listString.erase(len(listString) - 2, 2)
	return listString

func _registerOwnCallbacks():
	_hooks["help"] = funcref(self, "printHelpCallback")
	_hooks["list"] = funcref(self, "printListCallback")

func _clear():
	_hooks = {}
	_registerOwnCallbacks()

func _ready():
	_registerOwnCallbacks()
	watchedScene = weakref(get_tree().current_scene)

func register_hook(cmd, targetNode, function):
	if not watchedScene.get_ref():
		_clear()
		watchedScene = weakref(get_tree().current_scene)
	
	cmd = cmd.replace(" ", "").to_lower()
	if cmd in _hooks:
		print("Hook overwriting is not supported!")
	else:
		_hooks[cmd] = funcref(targetNode, function) 

func execute_command(cmd):
	cmd = cmd.replace(" ", "").to_lower()
	
	var result = "Command not found!"
	if cmd in _hooks:
		result = _hooks[cmd].call_func()
	
	return result
