extends KinematicBody

export(AudioStream) var laserSound1
export(AudioStream) var laserSound2
export(AudioStream) var laserSound3

# movement
const MAX_WALKING_SPEED = 15
const MAX_RUNNING_SPEED = 30
const ACCEL = 2
const DEACCEL = 6
var gravity = -9.81 * 2.5
var max_speed = MAX_WALKING_SPEED
var jump_height = 10

# energy
const ENERGY_COOLDOWN_TIME = 0.8
const JETPACK_DELAY_TIME = 0.25
var energy_cooldown = 0
var max_energy = 10
var infinite_energy = false
var energy = max_energy
var sprint_energy_consumption = 5
var jetpack_energy_consumption = 5
var jetpackCanPlay = false
var jetpackDelay = 0
var jetpackAudioSource

# actions
var camera_width_center = 0
var camera_height_center = 0
var shoot_origin = Vector3()
var shoot_target = Vector3()
var interaction_target = Vector3()
var interact_range = 6
var interacting = 0
var action_cooldown = 0
var building_cooldown = 0
var max_building_cooldown = 5

# combat
var laser_audio_source
var fire_rate = 2.0
var shoot_cooldown = 0.0
var shoot_end_pos
var shoot_range = 1000
var gun
var laser_duration = 0.2
var remaining_laser_duration = 0.0
var weapon_damage = 100
var m = SpatialMaterial.new()
var im

var drone_prototype = preload("res://prefabs/UniversalDrone.tscn")
var drone_price = 100
var turret_prototype = preload("res://prefabs/TurretUniversal.tscn")
var turret_price = 200


var camera_angle = 0
var mouse_sensitivity = 0.3

var velocity = Vector3()
var direction = Vector3()

func _on_command_energy_on():
	infinite_energy = true
	return "Infinite energy is on!\nBut remember, with great power comes great responsibility.";


func _on_command_energy_off():
	infinite_energy = false
	return "Infinite energy is on!\nNow you are just as normal as everybody.";


func _on_command_spawn_drone():
	spawn_drone()
	return "Drone spawned.";


func _ready():
	dev_hooks.register_hook("energy_on", self, "_on_command_energy_on")
	dev_hooks.register_hook("energy_off", self, "_on_command_energy_off")
	dev_hooks.register_hook("spawn_drone", self, "_on_command_spawn_drone")
	
	camera_width_center = OS.get_real_window_size().x / 2
	camera_height_center = OS.get_real_window_size().y / 2
	jetpackAudioSource = $Head/Camera/JetPackAudio
	laser_audio_source = $Head/Camera/Weapon/LaserAudio
	gun = $Head/Camera/Weapon/LaserAperture
	
	m.flags_unshaded = true
	m.flags_use_point_size = true
	m.albedo_color = Color(0, 0.25, 1.0, 0.7)
	
	im = get_node("/root/Demo/Laser")
	im.set_material_override(m)	

		
func _process(delta):
	handle_cooldowns(delta)
	
	
func handle_interacting():
	var space_state = get_world().direct_space_state
	var result = space_state.intersect_ray(shoot_origin, interaction_target, [self], 1)
	if result:
		if result.collider is StaticBody and action_cooldown <= 0:
			if result.collider.is_in_group("mines"):
				action_cooldown = 0.1
				get_node("/root/Demo").harvest_crystals(1)  
			elif result.collider.is_in_group("bases"):
				handle_base_interaction()
				action_cooldown = 1
			elif result.collider.is_in_group("construction_site"):
				handle_construction(result)
				action_cooldown = 1
				
				
func handle_construction(result):
	if get_node("/root/Demo").crystals >= turret_price and building_cooldown <= 0:
		spawn_turret(result.collider.get_parent().get_parent())
		get_node("/root/Demo").crystals -= turret_price
		building_cooldown = max_building_cooldown
	else:
		if building_cooldown > 0:
			var message = "You need to wait %s seconds before you can build a turret." % building_cooldown
			notification_manager.emit_msg("user_info", [message]);
		if get_node("/root/Demo").crystals < turret_price:
			var message = "You need %s crystals to build a turret. Build more Drones or collect some yourself at the mines." % turret_price
			notification_manager.emit_msg("user_info", [message]);
	
func spawn_turret(site):
	var turret = turret_prototype.instance()
	get_node("/root/Demo").add_child(turret)
	turret.translation = site.translation
	building_cooldown = max_building_cooldown
	site.queue_free()
	
	
func handle_base_interaction():
	if get_node("/root/Demo").inventory_crystals > 0:
		get_node("/root/Demo").dump_crystals()	
	elif get_node("/root/Demo").crystals >= drone_price and building_cooldown <= 0:
		build_drone()
	else:
		if building_cooldown > 0:
			var message = "You must wait %s seconds before the HQ is ready to build another drone." % str(building_cooldown).pad_decimals(2)
			notification_manager.emit_msg("user_info", [message]);
		else:
			var message = "You need %s crystals to build a drone. You can collect them at the mines." % drone_price
			notification_manager.emit_msg("user_info", [message]);


func spawn_drone():
	var drone = drone_prototype.instance()
	get_node("/root/Demo").add_child(drone)
	drone.translation = get_node("/root/Demo/HQ").translation
	drone.translation.x -= 3.5
	drone.translation.z += 2.5
	get_node("/root/Demo").add_drone(drone)
	building_cooldown = max_building_cooldown
	
	
func build_drone():
	get_node("/root/Demo").crystals -= drone_price
	spawn_drone()
	
	
func handle_shooting():
	var space_state = get_world().direct_space_state
	
	var result = space_state.intersect_ray(shoot_origin, shoot_target, [self], 1)
	
	if result.collider.get_parent().get_parent().has_method("take_damage"):
		result.collider.get_parent().get_parent().take_damage(weapon_damage)	
	elif result.collider.get_parent().get_parent().get_parent():
		if result.collider.get_parent().get_parent().get_parent().has_method("take_damage"):
			result.collider.get_parent().get_parent().get_parent().take_damage(weapon_damage)
	
	fire_laser(gun.global_transform.origin, result.position)


func fire_laser(begin, end):
	shoot_end_pos = end
	draw_laser_vertices(begin)
	shoot_cooldown = 1.0 / fire_rate
	remaining_laser_duration = laser_duration
	play_laser_audio()
	

func draw_laser_vertices(begin):
	im.begin(Mesh.PRIMITIVE_LINE_STRIP, null)
	im.add_vertex(begin)
	im.add_vertex(shoot_end_pos)
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
		
		
func handle_cooldowns(delta):
	if action_cooldown > 0:
		action_cooldown -= delta
	
	if shoot_cooldown > 0:
		shoot_cooldown -= delta
		
	if building_cooldown > 0:
		building_cooldown -= delta
		
	if remaining_laser_duration > 0:
		im.clear()
		draw_laser_vertices(gun.global_transform.origin)
		remaining_laser_duration -= delta
	else:
		im.clear()	

	if energy_cooldown <= 0 and energy < max_energy:
		energy += delta
		get_node("/root/Demo").display_energy(energy)
	
func _physics_process(delta):
	if interacting > 0:
		if interacting == 1 and shoot_cooldown <= 0:
			handle_shooting()
		if interacting == 2:
			handle_interacting()
			
	walk(delta)


func _input(event):
	if event is InputEventMouseMotion:
		$Head.rotate_y(-deg2rad(event.relative.x * mouse_sensitivity))
	
		var change = -event.relative.y * mouse_sensitivity
		if change + camera_angle < 90 and change + camera_angle > -90:
			$Head/Camera.rotate_x(deg2rad(change))
			camera_angle += change
	
	# früher raycasting
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index != 0:
				interacting = event.button_index
		else:
			interacting = 0
	
	calc_crosshair_target()
			   
	
func calc_crosshair_target():
	var camera = $Head/Camera
	shoot_origin = camera.global_transform.origin
	shoot_target = shoot_origin + camera.global_transform.basis.z * -shoot_range
	interaction_target = shoot_origin + camera.global_transform.basis.z * -interact_range

func walk(delta):
	# reset direction of the player
	direction = Vector3()
	
	# get rotation of the camera
	var aim = $Head/Camera.get_global_transform().basis
	
	if Input.is_action_pressed("move_sprint") and energy > 0:
		max_speed = MAX_RUNNING_SPEED
		
		if not infinite_energy:
			energy -= delta*sprint_energy_consumption
			
		energy_cooldown = ENERGY_COOLDOWN_TIME
		get_node("/root/Demo").display_energy(energy)
	else:
		max_speed = MAX_WALKING_SPEED
		if is_on_floor():
			energy_cooldown -= delta
	
	# check input and change direction
	if Input.is_action_pressed("move_forward"):
		direction -= aim.z
	if Input.is_action_pressed("move_back"):
		direction += aim.z
	if Input.is_action_pressed("move_left"):
		direction -= aim.x
	if Input.is_action_pressed("move_right"):
		direction += aim.x
		
	direction.y = 0
	direction = direction.normalized()
	
	velocity.y += gravity * delta
	
	var temp_velocity = velocity
	temp_velocity.y = 0
			
	# where would the player go at max speed
	var target = direction * max_speed
	
	var acceleration
	if direction.dot(temp_velocity) > 0:
		acceleration = ACCEL
	else:
		acceleration = DEACCEL
	
	temp_velocity = temp_velocity.linear_interpolate(target, acceleration * delta)
	
	velocity.x = temp_velocity.x
	velocity.z = temp_velocity.z
	
	velocity = move_and_slide(velocity, Vector3(0, 1, 0))
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_height
		jetpackDelay = JETPACK_DELAY_TIME
		jetpackCanPlay = true
	elif Input.is_action_pressed("jump") and energy > 0:
		if jetpackDelay > 0:
			jetpackDelay -= delta
		if jetpackDelay <= 0:
			if not jetpackAudioSource.playing and jetpackCanPlay:
				jetpackAudioSource.play()
				jetpackCanPlay = false
				
			if not infinite_energy:
				energy -= delta*jetpack_energy_consumption
				
			get_node("/root/Demo").display_energy(energy)
			energy_cooldown = ENERGY_COOLDOWN_TIME
		
		velocity.y -= gravity * delta
		
	if Input.is_action_just_pressed("crouch"):
		velocity.y -= jump_height
	
 