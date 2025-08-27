class_name UpgradeManager
extends Node

signal upgrades_completed

static var instance : UpgradeManager

@export var enemy_manager : EnemyManager
@export var available_upgrades : Array[UpgradeResource]
@export var spawn_position : Node2D
@export var spawn_root : Node

var upgrade_option_scene : PackedScene = preload("uid://dmphjqymc5tmf")
var peer_id_to_upgrade_options : Dictionary[int, Array] = {}
var peer_id_to_upgrades_acquired : Dictionary[int, Dictionary] = {}
var outstanding_peers_to_upgrade : Array[int] = []


static func get_peer_upgrade_count(peer_id : int, upgrade_id : String) -> int:
	if !is_instance_valid(instance):
		return 0
	
	if !instance.peer_id_to_upgrades_acquired.has(peer_id):
		return 0
	
	if !instance.peer_id_to_upgrades_acquired[peer_id].has(upgrade_id):
		return 0
	
	
	return instance.peer_id_to_upgrades_acquired[peer_id][upgrade_id]


static func peer_has_upgrade(peer_id : int, upgrade_id : String) -> bool:
	return get_peer_upgrade_count(peer_id, upgrade_id) > 0


func _ready() -> void:
	enemy_manager.round_completed.connect(_on_round_completed)
	instance = self
	
	if is_multiplayer_authority():
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)


func generate_upgrade_options() -> void:
	var all_peers := multiplayer.get_peers()
	all_peers.append(MultiplayerPeer.TARGET_PEER_SERVER)
	peer_id_to_upgrade_options.clear()
	outstanding_peers_to_upgrade.clear()
	
	for peer_id in all_peers:
		var available_upgrades_copy : Array[UpgradeResource] = Array(available_upgrades)
		available_upgrades.shuffle()
		
		outstanding_peers_to_upgrade.append(peer_id)
		
		var chosen_upgrades : Array[UpgradeResource] = available_upgrades_copy.slice(0, 3)
		
		peer_id_to_upgrade_options[peer_id] = chosen_upgrades
		
		var upgrade_options := create_upgrade_option_nodes(chosen_upgrades)
		var selected_upgrades : Array = []
		
		for i in upgrade_options.size():
			var upgrade_option := upgrade_options[i]
			var uid := ResourceUID.create_id()
			var upgrade_resource := chosen_upgrades[i]
			
			upgrade_option.set_peer_id_filter(peer_id)
			upgrade_option.name = str(uid)
			
			selected_upgrades.append({
				"name" : upgrade_option.name,
				"id" : upgrade_resource.id
			})
			
			upgrade_option.visible = peer_id == MultiplayerPeer.TARGET_PEER_SERVER
		
		if peer_id != MultiplayerPeer.TARGET_PEER_SERVER:
			set_upgrade_options.rpc_id(peer_id, selected_upgrades)


func create_upgrade_option_nodes(upgrade_resources : Array[UpgradeResource]) -> Array[UpgradeOption]:
	var initial_x = -96
	var x_diference = 96
	var result : Array[UpgradeOption] = []
	
	for i in range(upgrade_resources.size()):
		var upgrade_option : UpgradeOption = upgrade_option_scene.instantiate()
		
		upgrade_option.global_position = spawn_position.global_position
		upgrade_option.global_position += Vector2.RIGHT * (initial_x + (x_diference * i))
		upgrade_option.selected.connect(_on_upgrade_option_selected)
		
		upgrade_option.set_upgrade_index(i)
		upgrade_option.set_upgrade_resource(upgrade_resources[i])
		
		spawn_root.add_child(upgrade_option, true)
		upgrade_option.play_in(i * 0.1)
		result.append(upgrade_option)
	
	return result


@rpc("authority", "call_local", "reliable")
func set_upgrade_options(selected_upgrades : Array) -> void:
	var upgrade_resources : Array[UpgradeResource] = []
	
	for upgrade in selected_upgrades:
		var resource_index := available_upgrades.find_custom(func(item : UpgradeResource):
			return item.id == upgrade.id
		) 
		upgrade_resources.append(available_upgrades[resource_index])
	
	var created_nodes := create_upgrade_option_nodes(upgrade_resources)
	for i in created_nodes.size():
		created_nodes[i].name = selected_upgrades[i].name


func check_upgrades_complete() -> void:
	if outstanding_peers_to_upgrade.size() > 0:
		return
	
	upgrades_completed.emit()


func handle_upgrade_selected(index : int, for_peer_id : int) -> void:
	if !peer_id_to_upgrades_acquired.has(for_peer_id):
		peer_id_to_upgrades_acquired[for_peer_id] = {}
	
	var upgrade_dictionary := peer_id_to_upgrades_acquired[for_peer_id]
	var chosen_upgrade : UpgradeResource = peer_id_to_upgrade_options[for_peer_id][index]
	var upgrade_count : int = 0
	if upgrade_dictionary.has(chosen_upgrade.id):
		upgrade_count = upgrade_dictionary[chosen_upgrade.id]
	
	upgrade_dictionary[chosen_upgrade.id] = upgrade_count + 1
	
	print("Peer %s has selected upgrade with id %s" % \
	[for_peer_id,
	peer_id_to_upgrade_options[for_peer_id][index].id])
	
	outstanding_peers_to_upgrade.erase(for_peer_id)
	check_upgrades_complete()


func _on_round_completed() -> void:
	generate_upgrade_options()


func _on_upgrade_option_selected(upgrade_index : int, for_peer_id : int) -> void:
	handle_upgrade_selected(upgrade_index, for_peer_id)


func _on_peer_disconnected(peer_id : int) -> void:
	if outstanding_peers_to_upgrade.has(peer_id):
		outstanding_peers_to_upgrade.erase(peer_id)
		check_upgrades_complete()
