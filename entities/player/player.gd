class_name Player extends CharacterBody2D

signal died

@onready var player_input_syncronizer_component: PlayerInputSynchronizerComponent = $PlayerInputSyncronizerComponent
@onready var visuals: Node2D = $Visuals
@onready var weapon_root: Node2D = $Visuals/WeaponRoot
@onready var fire_rate_timer: Timer = $FireRateTimer
@onready var health_component: HealthComponent = $HealthComponent
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var barrel_position: Marker2D = %BarrelPosition
@onready var display_name_label: Label = $DisplayNameLabel

var bullet_scene : PackedScene = preload("uid://i6a54pjcj6nb")
var muzzle_flash_scene : PackedScene = preload("uid://fx6cvfwb5xo4")
var is_dying : bool = false
var display_name : String

var input_multiplayer_authority : int = 1
var is_respawn : bool = false

func _ready() -> void:
	player_input_syncronizer_component.set_multiplayer_authority(input_multiplayer_authority)
	
	if multiplayer.multiplayer_peer is OfflineMultiplayerPeer or \
			player_input_syncronizer_component.is_multiplayer_authority():
		display_name_label.visible = false
	else:
		display_name_label.text = display_name
	
	if is_respawn:
		health_component.current_health = 1
	
	if is_multiplayer_authority():
		health_component.died.connect(_on_died)
	

func _process(_delta: float) -> void:
	_update_aim_position()
	
	if is_multiplayer_authority():
		if is_dying:
			global_position = Vector2.RIGHT * 1000
			return
		
		velocity = player_input_syncronizer_component.movement_vector * 100
		move_and_slide()
		
		if(player_input_syncronizer_component.is_attack_pressed):
			try_fire()


func _update_aim_position() -> void:
	var aim_position = weapon_root.global_position \
			+ player_input_syncronizer_component.aim_vector
	
	var aim_vector :Vector2 = player_input_syncronizer_component.aim_vector
	
	visuals.scale = Vector2.ONE if aim_vector.x >= 0 else Vector2(-1, 1)
	
	weapon_root.look_at(aim_position)


func try_fire() -> void:
	if not fire_rate_timer.is_stopped():
		return
	
	var bullet := bullet_scene.instantiate() as Bullet
	bullet.global_position = barrel_position.global_position
	
	bullet.start(player_input_syncronizer_component.aim_vector.normalized())
	get_parent().add_child(bullet, true)
	
	fire_rate_timer.start()
	
	_play_fire_effects.rpc()

@rpc("authority", "call_local", "unreliable")
func _play_fire_effects() -> void:
	if animation_player.is_playing():
		animation_player.stop()
	
	animation_player.play("fire")
	
	var muzzle_flash : Node2D = muzzle_flash_scene.instantiate()
	muzzle_flash.global_position = barrel_position.global_position
	muzzle_flash.rotation = barrel_position.global_rotation
	get_parent().add_child(muzzle_flash)
	
	if player_input_syncronizer_component.is_multiplayer_authority():
		GameCamera.shake(1)


func kill() -> void:
	if !is_multiplayer_authority():
		push_error("Can not kill on non-server client")
		return
	
	_kill.rpc()
	
	await get_tree().create_timer(0.5).timeout
	
	died.emit()
	queue_free()


@rpc("authority", "call_local", "reliable")
func _kill() -> void:
	is_dying = true
	
	player_input_syncronizer_component.public_visibility = false


func set_display_name(new_display_name : String) -> void:
	display_name = new_display_name


func _on_died() -> void:
	kill()
