extends Spatial

export(AudioStream) var laserSound1
export(AudioStream) var laserSound2
export(AudioStream) var laserSound3

export(AudioStream) var explosion_sound_1
export(AudioStream) var explosion_sound_2
export(AudioStream) var explosion_sound_3

var player = "human"
var hitpoints = 500

var distances = {}
var firing_cooldown = 0
var fire_rate = 5
var laser_damage = 10

var shoot_end_pos

var laser_audio_source
var gun
var laser_duration = 0.1
var remaining_laser_duration = 0

var m = SpatialMaterial.new()
var im

func _ready():
	laser_audio_source = $TurretBase/TurretBaseModel/Drum/LaserAudio
	gun = $TurretBase/TurretBaseModel/Drum
	
	m.flags_unshaded = true
	m.flags_use_point_size = true
	m.albedo_color = Color(0, 1.0, 0, 0.7)
	
	im = $Laser
	im.set_material_override(m)

func _process(delta):
	
	if not is_visible_in_tree():
		return
	
	distances.clear()
	var bots = get_tree().get_nodes_in_group("battle_drones")
	for bot in bots:
		if bot.has_method("take_damage") and bot.is_visible_in_tree():
			distances[bot] = bot.translation.distance_squared_to(self.translation)
	var distance_values = distances.values()
	distance_values.sort()
	for bot in distances:
		if distances[bot] == distance_values[0]:
			attack_enemy(delta, bot)
	
	if remaining_laser_duration <= 0:
		im.clear()
	else:
		remaining_laser_duration -= delta
	

func attack_enemy(delta, enemy):
	if distances[enemy] < 900:
		$TurretBase.look_at(enemy.translation, Vector3(0, 1, 0))
		$TurretBase.rotation.x = 0
		$TurretBase.rotation.z = 0
		if firing_cooldown <= 0:
			enemy.take_damage(laser_damage)
			var barrel = gun.get_node("LaserAperture").global_transform.origin
			barrel = to_local(barrel)
			var target = to_local(enemy.global_transform.origin)
			target.y = enemy.get_node("BattleDrone").get_node("Ball").global_transform.origin.y
			fire_laser(barrel, target)
		else:
			firing_cooldown -= delta
			
			
func fire_laser(begin, end):
	firing_cooldown = 1.0 / fire_rate
	draw_laser_vertices(begin, end)
	play_laser_audio()
	remaining_laser_duration = laser_duration
	

func draw_laser_vertices(begin, end):
	im.begin(Mesh.PRIMITIVE_LINE_STRIP, null)
	im.add_vertex(begin)
	im.add_vertex(end)
	im.end()
			
			
func play_laser_audio():
	if not laser_audio_source.playing:
		var sample
		var laserSmapleNr = randi() % 3
		match laserSmapleNr:
			0:
				sample = laserSound1
			1:
				sample = laserSound2
			2:
				sample = laserSound3
		
		laser_audio_source.stream = sample
		laser_audio_source.play()
		
func take_damage(num):
	hitpoints -= num
	if hitpoints <= 0:
		die()

func die():
	
	notification_manager.emit_msg("user_warn", ["Turret destroyed!"]);
	
	laser_audio_source.connect("finished", self, "_on_finished") # Should be called before play()
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
	
	laser_audio_source.stream = sample
	laser_audio_source.play()
	
func _on_finished():
	queue_free()