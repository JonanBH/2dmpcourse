extends MarginContainer

@onready var display_name_text_edit: TextEdit = %DisplayNameTextEdit
@onready var port_text_edit: TextEdit = %PortTextEdit
@onready var host_button: Button = %HostButton
@onready var ip_address_text_edit: TextEdit = %IPAddressTextEdit
@onready var join_button: Button = %JoinButton
@onready var back_button: Button = %BackButton
@onready var main_menu_scene : PackedScene = load("uid://co73a1x8623p4")
@onready var client_error_label: Label = %ClientErrorLabel
@onready var server_error_label: Label = %ServerErrorLabel
@onready var error_confirm_button: Button = %ErrorConfirmButton
@onready var error_container: MarginContainer = %ErrorContainer

var main_scene : PackedScene = preload("uid://bhfns2kme5t0f")

var is_connecting : bool = false


func _ready() -> void:
	error_container.visible =  false
	
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	back_button.pressed.connect(_on_back_pressed)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(on_connection_failed)
	
	error_confirm_button.pressed.connect(_on_error_confirm_pressed)
	
	display_name_text_edit.text_changed.connect(_on_text_changed)
	port_text_edit.text_changed.connect(_on_text_changed)
	ip_address_text_edit.text_changed.connect(_on_text_changed)
	
	display_name_text_edit.text = MultiplayerConfig.display_name
	port_text_edit.text = str(MultiplayerConfig.port)
	ip_address_text_edit.text = MultiplayerConfig.ip_address
	
	validate()


func validate() -> void:
	host_button.disabled = is_connecting
	join_button.disabled = is_connecting
	
	MultiplayerConfig.display_name = display_name_text_edit.text
	MultiplayerConfig.ip_address = ""
	MultiplayerConfig.port = -1
	
	var port := port_text_edit.text
	if port.is_valid_int():
		MultiplayerConfig.port = int(port)
		if MultiplayerConfig.port <= 0:
			MultiplayerConfig.port = -1
	else:
		MultiplayerConfig.port = -1
	
	var ip := ip_address_text_edit.text
	if ip.is_valid_ip_address():
		MultiplayerConfig.ip_address = ip
	else:
		MultiplayerConfig.ip_address = ""
	
	var is_valid_port : bool = MultiplayerConfig.port > 0
	var is_valid_display_name := !MultiplayerConfig.display_name.is_empty()
	var is_valid_ip : = !MultiplayerConfig.ip_address.is_empty()
	
	host_button.disabled = !is_valid_port or !is_valid_display_name or is_connecting
	
	join_button.disabled = !is_valid_port or !is_valid_display_name or \
			!is_valid_ip or is_connecting


func show_error(is_client : bool = false) -> void:
	client_error_label.visible = is_client
	server_error_label.visible = !is_client
	error_container.visible = true
	

func _on_host_pressed() -> void:
	var server_peer := ENetMultiplayerPeer.new()
	var error := server_peer.create_server(MultiplayerConfig.port)
	
	if error != Error.OK:
		show_error()
		return
	
	multiplayer.multiplayer_peer = server_peer
	
	get_tree().change_scene_to_packed(main_scene)


func _on_join_pressed() -> void:
	is_connecting = true
	
	validate()
	var client_peer := ENetMultiplayerPeer.new()
	var error := client_peer.create_client(MultiplayerConfig.ip_address,\
			 MultiplayerConfig.port)
	
	if error != Error.OK:
		show_error(true)
		return
	
	multiplayer.multiplayer_peer = client_peer


func _on_connected_to_server() -> void:
	get_tree().change_scene_to_packed(main_scene)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_packed(main_menu_scene)


func _on_text_changed() -> void:
	validate()


func _on_error_confirm_pressed() -> void:
	error_container.visible = false


func on_connection_failed() -> void:
	is_connecting = false
	show_error(true)
	
	validate()
