extends Spatial

export(AudioStream) var laserSound1
export(AudioStream) var laserSound2
export(AudioStream) var laserSound3

export(AudioStream) var explosion_sound_1
export(AudioStream) var explosion_sound_2
export(AudioStream) var explosion_sound_3

const BATTLE_DRONE_RANGE = 18 * 18

var player = "computer" # "human"
var hitpoints = 170
var waypoints = null
var waypointTarget = 0

var laser_duration = 0.1
var remaining_laser_duration = 0
var firing_cooldown = 0
var fire_rate = 2.5
var laser_damage = 15

var shoot_end_pos
var gun

var m = SpatialMaterial.new()
var im

var drone_speed = 8

var explosion_audio_source

func init(player):
	self.player = player

func _ready():
	if player == "computer":
		var mat = load("res://materials/RedCoating.tres")
		$BattleDrone/Ball.set_surface_material(0, mat)
	explosion_audio_source = $BattleDrone/ExplosionAudio
	gun = $BattleDrone/Ball
	
	m.flags_unshaded = true
	m.flags_use_point_size = true
	m.albedo_color = Color(1.0, 0, 0, 0.7)
	
	im = $Laser
	im.set_material_override(m)

func _process(delta):
	
	if not is_visible_in_tree():
		return
	
	if remaining_laser_duration <= 0:
		im.clear()
	else:
		remaining_laser_duration -= delta
	
	if check_targets(delta):
		return
	
	if not waypoints or waypoints.size() < 1:
		return
	
	var targetPos = get_node(waypoints[waypointTarget]).transform.origin
	
	var direction = transform.origin - targetPos
	direction = direction.normalized()
	translation -= direction * delta * drone_speed
	
	look_at(targetPos, Vector3(0, 1, 0))
	rotation.x = 0
	rotation.z = 0
	
	if transform.origin.distance_squared_to(targetPos) < 2.5 * 2.5:
		waypointTarget += 1
		if waypointTarget >= waypoints.size():
			waypoints = null
		
	transform.origin.y = 0

func check_targets(delta):
	var targets = get_tree().get_nodes_in_group("human_objects")
	var distances = {}
	
	for target in targets:
		if target.has_method("take_damage") and target.is_visible_in_tree():
			var dist = translation.distance_squared_to(target.translation)
			if dist <= BATTLE_DRONE_RANGE:
				distances[target] = dist
	
	var distance_values = distances.values()
	distance_values.sort()
	for target in distances:
		if distances[target] == distance_values[0]:
			attack_object(delta, target)
			return true
	
	return false

func attack_object(delta, target):
	look_at(target.translation, Vector3(0, 1, 0))
	rotation.x = 0
	rotation.z = 0
	
	if firing_cooldown <= 0:
		target.take_damage(laser_damage)
		var laser_start = to_local(gun.global_transform.origin)
		var laser_end = to_local(target.global_transform.origin)
		#laser_end.y = enemy.get_node("BattleDrone").get_node("Ball").global_transform.origin.y
		fire_laser(laser_start, laser_end)
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
	if not explosion_audio_source.playing:
		var sample
		var laserSmapleNr = randi() % 3
		match laserSmapleNr:
			0:
				sample = laserSound1
			1:
				sample = laserSound2
			2:
				sample = laserSound3
		
		explosion_audio_source.stream = sample
		explosion_audio_source.play()

func take_damage(num):
	if not is_visible_in_tree():
		return
	
	hitpoints -= num
	if hitpoints <= 0:
		die()

func die():
	explosion_audio_source.stop()
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