class_name EnemyManager
extends Node

signal round_changed(round_number : int)
signal round_completed
signal game_completed

const ROUND_BASE_TIME := 10
const ROUND_GROWTH := 5
const BASE_ENEMY_SPAWN_TIME : float = 2.0
const ENEMY_SPAWN_TIME_GROWTH : float = -0.15
const MAX_ROUNDS : int = 10

@export var enemy_scene : PackedScene
@export var enemy_spawn_root : Node
@export var spawn_rect : ReferenceRect

@onready var spawn_interval_timer: Timer = $SpawnIntervalTimer
@onready var round_timer: Timer = $RoundTimer

var _round_count : int
var round_count : int = 0:
	get:
		return _round_count
	set(value):
		_round_count = value
		round_changed.emit(_round_count)

var spawned_enemies : int = 0

func _ready() -> void:
	spawn_interval_timer.timeout.connect(_on_spawn_interval_timer_timeout)
	round_timer.timeout.connect(_on_round_timer_timeout)
	
	GameEvents.enemy_died.connect(_on_enemy_died)


func start() -> void:
	if is_multiplayer_authority():
		begin_round()


func synchronize(to_peer_id : int = -1) -> void:
	if !is_multiplayer_authority():
		return
	
	var data : Dictionary = {
		"round_time_is_running": !round_timer.is_stopped(),
		"round_timer_time_left": round_timer.time_left,
		"round_count": round_count
	}
	
	if to_peer_id > -1 and to_peer_id != 1:
		_synchronize.rpc_id(to_peer_id, data)
	else:
		_synchronize.rpc(data)


@rpc("authority", "call_remote", "reliable")
func _synchronize(data : Dictionary) -> void:
	var wait_time : float = data.round_timer_time_left
	
	if wait_time > 0:
		round_timer.wait_time = wait_time
	else:
		round_timer.wait_time = 0.1
	 
	if data.round_time_is_running:
		round_timer.start()
	
	round_count = data.round_count


func get_round_time_remaining() -> float:
	return round_timer.time_left


func begin_round() -> void:
	round_count += 1
	round_timer.wait_time = ROUND_BASE_TIME + (ROUND_GROWTH * (round_count - 1))
	round_timer.start()
	
	spawn_interval_timer.wait_time = BASE_ENEMY_SPAWN_TIME + \
		((round_count - 1) * ENEMY_SPAWN_TIME_GROWTH)
	
	spawn_interval_timer.start()
	
	synchronize()
	
	print("Begining round %s" % round_count)


func _check_round_completed() -> void:
	if !round_timer.is_stopped():
		return
	
	if spawned_enemies == 0:
		print("Round completed")
		round_completed.emit()
		
		if round_count == MAX_ROUNDS:
			complete_game()
		else:
			begin_round()


func complete_game() -> void:
	await get_tree().create_timer(2).timeout
	
	game_completed.emit()


func _on_spawn_interval_timer_timeout() -> void:
	if is_multiplayer_authority():
		spawn_enemy()
		spawn_interval_timer.start()


func get_random_spawn_position() -> Vector2 :
	var x = randf_range(0, spawn_rect.size.x)
	var y = randf_range(0, spawn_rect.size.y)
	
	return spawn_rect.global_position + Vector2(x, y)


func spawn_enemy() -> void :
	if is_multiplayer_authority():
		var enemy = enemy_scene.instantiate() as Node2D
		enemy.global_position = get_random_spawn_position()
		enemy_spawn_root.add_child(enemy, true)
		
		spawned_enemies += 1


func _on_round_timer_timeout() -> void:
	if is_multiplayer_authority():
		spawn_interval_timer.stop()
		print("Round over")
		
		_check_round_completed()


func _on_enemy_died() -> void:
	spawned_enemies -= 1
	
	_check_round_completed()
