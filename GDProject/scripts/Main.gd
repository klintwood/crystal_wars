extends Node

var crystals = 100
var crystals_display = 0
var inventory_crystals = 0
var inventory_crystals_display = 0
var inventory_size = 50
var drone_speed = 6

var intro_message_timer = 20
var intro_message_state = 0

var wave = 0
var wave_timeout = 80
var wave_remaining_time = wave_timeout
var wave_enemy_count = 1
var wave_max = 6


var notification_cooldown = 0

var battle_drone_prototype = preload("res://prefabs/BattleDrone.tscn")
var spawnPoints = []
var lastSpawn = 0

var drone_datas = []
var turrets = []

func _on_command_reset():
	get_tree().reload_current_scene()
	return ""

func _on_command_quit():
	get_tree().quit()
	return ""

func _on_command_get_crystals():
	crystals += 500
	return "Added 500 crystals.\nDon't spent it all at once!"

func _on_command_spawn_enemy():
	spawn_battle_drone()
	return "Battle drone spawned.\nINCOMING!"

func _ready():
	global_config.configCamera($Mate/Head/Camera)
	
	dev_hooks.register_hook("reset", self, "_on_command_reset")
	dev_hooks.register_hook("quit", self, "_on_command_quit")
	dev_hooks.register_hook("get_crystals", self, "_on_command_get_crystals")
	dev_hooks.register_hook("spawn_enemy", self, "_on_command_spawn_enemy")
	
	notification_manager.emit_msg("user_info", ["Hi, welcome to the game!"])
	
	add_drone($Drones/UniversalDrone)

func register_spawn_point(spawn):
	spawnPoints.append(spawn)

func spawn_battle_drone(depth = 0):
	if spawnPoints.empty():
		print("No spawn points found.")
		return
	
	lastSpawn += 1
	if lastSpawn >= spawnPoints.size():
		lastSpawn = 0
		
	if spawnPoints[lastSpawn].in_player_view() and depth < 3:
		spawn_battle_drone(depth + 1)
		return
	else:
		var new_battle_drone = battle_drone_prototype.instance()
		new_battle_drone.translation = spawnPoints[lastSpawn].translation
		new_battle_drone.waypoints = spawnPoints[lastSpawn].waypoints
		get_node("/root/Demo/BattleDrones").add_child(new_battle_drone)

func flexible_difference(from, to):
	var diff = abs(to - from)
	var change
	
	if diff < 100:
		change = 1
	else:
		change = int(round(diff / 50))
	
	return change

func _process(delta):
	
	if intro_message_timer > 0:
		intro_message_timer -= delta
		if intro_message_timer <= 15 and intro_message_state == 0:
			notification_manager.emit_msg("user_info", ["Prepare yourself by mining crystal, building drones at the HQ and building turrets."])
			intro_message_state = 1
		if intro_message_timer <= 10 and intro_message_state == 1:
			notification_manager.emit_msg("user_info", ["You can interact with Mines, the HQ and turret construction sites with the right mouse button."])
			intro_message_state = 2
		if intro_message_timer <= 5 and intro_message_state == 2:
			notification_manager.emit_msg("user_warn", ["You have " + str(wave_remaining_time) + " seconds to prepare for the first wave!"])
			intro_message_state = -1
	
	process_waves(delta)
	
	$GUI/CrystalCount.text = String(crystals_display)
	if crystals_display < crystals:
		crystals_display += flexible_difference(crystals, crystals_display)
	elif crystals_display > crystals:
		crystals_display -= flexible_difference(crystals, crystals_display)
	
	$GUI/InventoryCount.text = String(inventory_crystals_display)
	if inventory_crystals_display < inventory_crystals:
		inventory_crystals_display += 1
	elif inventory_crystals_display > inventory_crystals:
		inventory_crystals_display -= 1
		
	if notification_cooldown > 0:
		notification_cooldown -= delta
		
	navigation(delta)

func process_waves(delta):
	
	if wave >= wave_max:
			if get_tree().get_nodes_in_group("battle_drones").size() <= 0:
				get_tree().change_scene("res://scenes/GameWon.tscn")
				return
	
	wave_remaining_time -= delta
	if wave_remaining_time <= 0 and wave < wave_max:
		wave += 1
		
		for i in range(wave_enemy_count):
			spawn_battle_drone()
		
		wave_enemy_count *= 2
		wave_timeout *= 0.85
		wave_remaining_time = wave_timeout
		notification_manager.emit_msg("user_warn", ["Wave " + str(wave) + " of " + str(wave_max) + " is on the way!"])
		
		if wave < wave_max:
			notification_manager.emit_msg("user_warn", ["You have " + str(wave_timeout) + " seconds until the next wave."])

func harvest_crystals(amount):
	if inventory_crystals < inventory_size:
		inventory_crystals += amount
	elif notification_cooldown <= 0:
		var message = "Your inventory is full. Bring some crystals back to the base."
		notification_manager.emit_msg("user_info", [message]);
		notification_cooldown = 5
		
func dump_crystals():
	crystals += inventory_crystals
	inventory_crystals = 0
		
func display_energy(val):
	$GUI/EnergyAnchor/TextureProgress.value = clamp(val, 0, 10)

func add_drone(drone):
	var drone_data = {'drone': drone, 'targets': [$Mines/MineBody1, $HQ], 'target_num': 0, 'direction': Vector3()}
	drone_datas.append(drone_data)

# Should the navigation method change to not using _process the AudioStreamPlayer Doppler Settings 
# in the Universal Drone Preset MUST be changed.
func navigation(delta):
	for drone_data in drone_datas:
		var unit = drone_data['drone']
		if unit.drone_ready:
			var direction = drone_data['direction']
			var target_num = drone_data['target_num']
			if target_num > 1:
				drone_data['target_num'] = 0
				target_num = 0
				crystals += 25   
			var target = drone_data['targets'][target_num]
			
			direction = unit.transform.origin - target.transform.origin
			direction = direction.normalized()
			unit.translation -= direction * delta * drone_speed	
			
			if unit.transform.origin.distance_to(target.transform.origin) < 5:
				drone_data['target_num'] += 1
				
			unit.transform.origin.y = 0
		
func remove_drone_data(drone):
	for data in drone_datas:
		if data['drone'] == drone:
			drone_datas.remove(drone_datas.find(data))
			