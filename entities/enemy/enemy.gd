extends CharacterBody2D

var default_collision_mask : int
var default_collision_layer : int
var target_position : Vector2
var state_machine : CallableStateMachine = CallableStateMachine.new()
var alert_tween : Tween
var current_state : String:
	get:
		return state_machine.current_state
	set(value):
		if !is_node_ready():
			await ready
		
		var state : Callable = Callable.create(self, value)
		state_machine.change_state(state)

@onready var target_aquisition_timer: Timer = $TargetAquisitionTimer
@onready var health_component: HealthComponent = $HealthComponent
@onready var visuals: Node2D = $Visuals
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer
@onready var charge_attack_timer: Timer = $ChargeAttackTimer
@onready var hitbox_collision_shape: CollisionShape2D = %HitboxCollisionShape
@onready var alert_sprite: Sprite2D = $AlertSprite
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent
@onready var impact_particles_scene : PackedScene = preload("uid://dq7xj8covnp6s")
@onready var ground_particles_scene : PackedScene = preload("uid://c5xs14wqlw742")
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	state_machine.add_states(state_spawn, enter_state_spawn, Callable())
	state_machine.add_states(state_normal, enter_state_normal, leave_state_normal)
	state_machine.add_states(state_charge_attack, \
			enter_state_charge_attack, \
			leave_state_charge_attack)
	state_machine.add_states(state_attack, enter_state_attack, leave_state_attack)
	
	alert_sprite.scale = Vector2.ZERO
	default_collision_mask = collision_mask
	default_collision_layer = collision_layer
	hitbox_collision_shape.disabled = true
	
	if is_multiplayer_authority():
		state_machine.set_initial_state(state_spawn)
		health_component.died.connect(_on_died)
		hurtbox_component.hit.connect(_on_hit)


func _process(_delta: float) -> void:
	state_machine.update()
	if is_multiplayer_authority():
		move_and_slide()


func enter_state_spawn() -> void:
	var tween := create_tween()
	
	tween.tween_property(visuals, "scale", Vector2.ONE, 0.4)\
		.from(Vector2.ZERO)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_BACK)
	
	await tween.finished
	
	state_machine.change_state(state_normal)


func state_spawn() -> void:
	pass


func enter_state_normal() -> void:
	animation_player.play("run")
	if is_multiplayer_authority():
		acquire_target()
		target_aquisition_timer.start()


func state_normal() -> void:
	if is_multiplayer_authority():
		velocity = global_position.direction_to(target_position) * 40
		
		if target_aquisition_timer.is_stopped():
			acquire_target()
			target_aquisition_timer.start()
	
		if attack_cooldown_timer.is_stopped() and \
				global_position.distance_to(target_position) < 150:
			
			state_machine.change_state(state_charge_attack)
	 
	flip()


func leave_state_normal() -> void:
	animation_player.play("RESET")


func enter_state_charge_attack() -> void:
	if is_multiplayer_authority():
		acquire_target()
		charge_attack_timer.start()
	
	flip()
	
	if alert_tween != null and alert_tween.is_valid():
		alert_tween.kill()
	
	alert_tween = create_tween()
	alert_tween.tween_property(alert_sprite, "scale", Vector2.ONE, 0.2)\
			.from(Vector2.ZERO)\
			.set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_BACK)


func state_charge_attack() -> void:
	if is_multiplayer_authority():
		velocity = velocity.lerp(Vector2.ZERO, 1.0 - exp(-15 * get_process_delta_time()))
		if charge_attack_timer.is_stopped():
			state_machine.change_state(state_attack)


func leave_state_charge_attack() -> void:
	if alert_tween != null and alert_tween.is_valid():
		alert_tween.kill()
	
	alert_tween = create_tween()
	alert_tween.tween_property(alert_sprite, "scale", Vector2.ZERO, 0.2)\
			.from(Vector2.ONE)\
			.set_ease(Tween.EASE_IN)\
			.set_trans(Tween.TRANS_BACK)


func enter_state_attack() -> void:
	if is_multiplayer_authority():
		collision_mask = 1 << 0
		collision_layer = 0
		hitbox_collision_shape.disabled = false
		velocity = global_position.direction_to(target_position) * 400


func state_attack() -> void:
	if is_multiplayer_authority():
		velocity = velocity.lerp(Vector2.ZERO, 1.0 - exp(-3 * get_process_delta_time()))
		if velocity.length() < 25:
			state_machine.change_state(state_normal)


func leave_state_attack() -> void:
	if is_multiplayer_authority():
		collision_mask = default_collision_mask
		collision_layer = default_collision_layer
		hitbox_collision_shape.disabled = true
		attack_cooldown_timer.start()
		


func flip() -> void:
	visuals.scale = Vector2.ONE if global_position.x < target_position.x\
		else Vector2(-1, 1)


func acquire_target() -> void:
	var players := get_tree().get_nodes_in_group("player")
	var nearest_player : Player = null
	var nearest_squared_distance : float
	
	for player in players:
		if nearest_player == null:
			nearest_player = player as Player
			nearest_squared_distance = nearest_player.global_position.\
				distance_squared_to(global_position)
			
			continue
		
		var player_squared_distance : float = player.global_position.\
				distance_squared_to(global_position)
		
		if player_squared_distance < nearest_squared_distance:
			nearest_player = player
			nearest_squared_distance = player_squared_distance
	
	if nearest_player != null:
		target_position = nearest_player.global_position


@rpc("authority", "call_local")
func spawn_hit_particles() -> void:
	var hit_particle : Node2D = impact_particles_scene.instantiate()
	hit_particle.global_position = hurtbox_component.global_position
	get_parent().add_child(hit_particle)


@rpc("authority", "call_local")
func spawn_death_particles() -> void:
	var death_particles : Node2D = ground_particles_scene.instantiate()
	var background_node : Node = Main.background_mask
	
	if !is_instance_valid(background_node):
		background_node = get_parent()
	
	background_node.add_child(death_particles)
	death_particles.global_position = global_position


func _on_died() -> void:
	GameEvents.emit_enemy_died()
	spawn_death_particles.rpc()
	queue_free()


func _on_hit() -> void:
	spawn_hit_particles.rpc()
