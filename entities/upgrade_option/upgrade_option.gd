class_name UpgradeOption
extends Node2D

signal selected(index : int, for_peer_id : int)

@onready var impact_particles_scene : PackedScene = preload("uid://dq7xj8covnp6s")
@onready var ground_particles_scene : PackedScene = preload("uid://c5xs14wqlw742")

@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hit_flash_sprite_component: Sprite2D = $HitFlashSpriteComponent
@onready var player_detection_area: Area2D = $PlayerDetectionArea

@onready var info_container: VBoxContainer = $InfoContainer
@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel


var upgrade_index : int
var assigned_resource : UpgradeResource
var peer_id_filter : int = -1


func _ready() -> void:
	hurtbox_component.hit.connect(_on_hit)
	health_component.died.connect(_on_died)
	set_peer_id_filter(peer_id_filter)
	info_container.hide()
	
	player_detection_area.area_entered.connect(_on_player_entered_detection_area)
	player_detection_area.area_exited.connect(_on_player_exited_detection_area)
	
	update_info()
	
	if is_multiplayer_authority():
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)


func set_peer_id_filter(peer_id : int) -> void:
	peer_id_filter = peer_id
	hurtbox_component.peer_id_filter = peer_id_filter
	hit_flash_sprite_component.peer_id_filter = peer_id_filter


func set_upgrade_resource(upgrade_resource : UpgradeResource) -> void:
	assigned_resource = upgrade_resource
	update_info()


func update_info() -> void:
	if !is_instance_valid(title_label) or !is_instance_valid(description_label):
		return
	
	if assigned_resource == null:
		return
	
	title_label.text = assigned_resource.display_name
	description_label.text = assigned_resource.description


func set_upgrade_index(index : int) -> void:
	upgrade_index = index


func kill() -> void:
	spawn_death_particles()
	queue_free()


func despawn() -> void:
	animation_player.play("despawn")


func play_in(delay : float = 0) -> void:
	animation_player.stop()
	hit_flash_sprite_component.scale = Vector2.ZERO
	
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_callback(func():
		animation_player.play("spawn")
	)


func spawn_death_particles() -> void:
	var death_particles : Node2D = ground_particles_scene.instantiate()
	var background_node : Node = Main.background_mask
	
	if !is_instance_valid(background_node):
		background_node = get_parent()
	
	background_node.add_child(death_particles)
	death_particles.global_position = global_position


@rpc("authority", "call_local", "reliable")
func kill_all(killed_name : String) -> void:
	var upgrade_option_nodes := get_tree().get_nodes_in_group("upgrade_option")
	
	for upgrade_option : UpgradeOption in upgrade_option_nodes:
		if upgrade_option.peer_id_filter == peer_id_filter:
			if upgrade_option.name == killed_name:
				upgrade_option.kill()
			else:
				upgrade_option.despawn()


@rpc("authority", "call_local")
func spawn_hit_particles() -> void:
	var hit_particle : Node2D = impact_particles_scene.instantiate()
	hit_particle.global_position = hurtbox_component.global_position
	get_parent().add_child(hit_particle)


func _on_died() -> void:
	selected.emit(upgrade_index, peer_id_filter)
	
	if peer_id_filter != MultiplayerPeer.TARGET_PEER_SERVER:
		kill_all.rpc_id(peer_id_filter, name)
	
	kill_all.rpc_id(MultiplayerPeer.TARGET_PEER_SERVER, name)
	

func _on_peer_disconnected(peer_id : int) -> void:
	if peer_id == peer_id_filter:
		despawn()


func _on_hit() -> void:
	spawn_hit_particles.rpc_id(peer_id_filter)


func _on_player_entered_detection_area(other_area : Area2D) -> void:
	info_container.visible = true
	print("Player entered dection area")


func _on_player_exited_detection_area(_other_area : Area2D) -> void:
	info_container.visible = false
	print("Player exited dection area")
