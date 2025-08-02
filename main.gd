extends Node

const ENEMY_SCENE : PackedScene = preload("res://entities/enemy/enemy.tscn")

@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var player_spawn_position: Marker2D = $PlayerSpawnPosition
@onready var enemy_manager: EnemyManager = $EnemyManager

var player_scene : PackedScene = preload("uid://bjmdbk30ebfj")

func _ready() -> void:
	multiplayer_spawner.spawn_function = func(data):
		var player : Player = player_scene.instantiate() as Player
		player.name = str(data.peer_id)
		player.global_position = player_spawn_position.global_position
		player.input_multiplayer_authority = data.peer_id
		return player
	
	peer_ready.rpc_id(1)


@rpc("any_peer", "call_local", "reliable")
func peer_ready() -> void:
	var sender_id =  multiplayer.get_remote_sender_id()
	multiplayer_spawner.spawn({"peer_id" : sender_id})
	enemy_manager.synchronize(sender_id)
