extends Spatial

const HQ_HITPOINTS = 1500

var hitpoints = HQ_HITPOINTS
var msg_state = 0

var explosion_audio_source


func _ready():
	explosion_audio_source = $ExplosionPlayer
    
func take_damage(num):
	hitpoints -= num
	
	if hitpoints <= HQ_HITPOINTS * 0.75 and msg_state == 0:
		notification_manager.emit_msg("user_warn", ["Your HQ's health is down to 75%!"]);
		msg_state = 1
	
	if hitpoints <= HQ_HITPOINTS * 0.5 and msg_state == 1:
		notification_manager.emit_msg("user_warn", ["Your HQ's health is down to 50%!"]);
		msg_state = 2
	
	if hitpoints <= HQ_HITPOINTS * 0.25 and msg_state == 2:
		notification_manager.emit_msg("user_warn", ["Your HQ's health is down to 25%!"]);
		msg_state = 3
	
	if hitpoints <= HQ_HITPOINTS * 0.10 and msg_state == 3:
		notification_manager.emit_msg("user_warn", ["Your HQ's health is down to 10%!"]);
		msg_state = 4
	
	if hitpoints <= HQ_HITPOINTS * 0.05 and msg_state == 4:
		notification_manager.emit_msg("user_warn", ["Your HQ's health is down to 5%!"]);
		msg_state = -1
	
	if hitpoints <= 0:
		die()

func die():
	explosion_audio_source.connect("finished", self, "_on_finished") # Should be called before play()
	explosion_audio_source.play()
	hide()

func _on_finished():
	queue_free()
	get_tree().change_scene("res://scenes/GameLost.tscn")
