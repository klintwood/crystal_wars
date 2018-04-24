extends Spatial

export(AudioStream) var explosion_sound_1
export(AudioStream) var explosion_sound_2
export(AudioStream) var explosion_sound_3

var player = "human"
var drone_ready = false
var hitpoints = 100

var explosion_audio_source

func init(player):
	self.player = player

func _ready():
	if player == "computer":
		var mat = load("res://materials/RedCoating.tres")
		$DroneBase/Ball.set_surface_material(0, mat)
	explosion_audio_source = $DroneBase/ExplosionAudio

func start_fly():
	drone_ready = true
	$DroneBase/AnimationPlayer.play("FlyDrone")
    
func take_damage(num):
	hitpoints -= num
	if hitpoints <= 0:
		die()

func die():
	get_node("/root/Demo").remove_drone_data(self)
	
	var message = "Drone destroyed."
	notification_manager.emit_msg("user_warn", [message]);
	
	explosion_audio_source.connect("finished", self, "_on_finished") # Should be called before play()
	play_death_sound()	
	hide()

func play_death_sound():	
	var sample
	var sample_nr = randi() % 3
	match sample_nr:
		0:
			sample = explosion_sound_1
		1:
			sample = explosion_sound_2
		2:
			sample = explosion_sound_3
	
	explosion_audio_source.stream = sample
	explosion_audio_source.play()
	
func _on_finished():
	queue_free()