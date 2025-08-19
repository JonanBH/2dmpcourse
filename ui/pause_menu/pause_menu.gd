class_name PauseMenu
extends CanvasLayer

signal quit_requested

@onready var resume_button: Button = %ResumeButton
@onready var quit_button: Button = %QuitButton

var current_paused_peer : int = -1


func _ready() -> void:
	resume_button.pressed.connect(_on_resume_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	if is_multiplayer_authority():
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			request_unpause.rpc_id(MultiplayerPeer.TARGET_PEER_SERVER)
		else:
			request_pause.rpc_id(MultiplayerPeer.TARGET_PEER_SERVER)
		get_viewport().set_input_as_handled()


@rpc("any_peer", "call_local", "reliable")
func request_pause() -> void:
	if current_paused_peer > -1:
		return
	
	pause.rpc(multiplayer.get_remote_sender_id())


@rpc("any_peer", "call_local", "reliable")
func request_unpause() -> void:
	if current_paused_peer != multiplayer.get_remote_sender_id():
		return
	unpause.rpc()


@rpc("authority", "call_local", "reliable")
func pause(paused_peer : int) -> void:
	current_paused_peer = paused_peer
	resume_button.disabled = current_paused_peer != multiplayer.get_unique_id()
	get_tree().paused = true
	visible = true


@rpc("authority", "call_local", "reliable")
func unpause() -> void:
	current_paused_peer = -1
	get_tree().paused = false
	visible = false


func _on_resume_pressed() -> void:
	request_unpause.rpc(MultiplayerPeer.TARGET_PEER_SERVER)


func _on_quit_pressed() -> void:
	quit_requested.emit()


func _on_peer_disconnected(peer_id : int) -> void:
	if current_paused_peer == peer_id:
		unpause.rpc()
