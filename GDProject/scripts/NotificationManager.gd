extends Node

var _message_listeners = {}

class MsgListener:
	var targetNode
	var methodName
	
	func get_target_ref():
		return targetNode.get_ref()
	
	func call_listener(args):
		targetNode.get_ref().call(methodName, args)

func register_listener(msg, targetNode, function):
	msg = msg.replace(" ", "").to_lower()
	
	if not targetNode.has_method(function):
		print("The target node for a '" + msg + "' listener doesn't have a '" + function + "' method!")
		return
	
	var listener = MsgListener.new()
	listener.targetNode = weakref(targetNode)
	listener.methodName = function
	
	if msg in _message_listeners:
		_message_listeners[msg].append(listener)
	else:
		_message_listeners[msg] = [listener]

func emit_msg(msg, args = []):
	msg = msg.replace(" ", "").to_lower()
	
	if not msg in _message_listeners:
		return
	
	var deleteIndizes = []
	for i in range(_message_listeners[msg].size()):
		if not _message_listeners[msg][i].get_target_ref():
			deleteIndizes.append(i)
		else:
			_message_listeners[msg][i].call_listener(args)
	
	for i in deleteIndizes:
		_message_listeners[msg].remove(i)
