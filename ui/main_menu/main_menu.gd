extends Control


@onready var singleplayer_button: Button = $VBoxContainer/SingleplayerButton
@onready var multiplayer_button: Button = $VBoxContainer/MultiplayerButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var multiplayer_menu_scene : PackedScene = load("uid://dgc1uwdw0xx4d")
@onready var options_button: Button = $VBoxContainer/OptionsButton

var main_scene : PackedScene = preload("uid://bhfns2kme5t0f")
var options_scene : PackedScene = preload("uid://csqini3u8fjwq")


func _ready() -> void:
	singleplayer_button.pressed.connect(_on_singleplayer_button_pressed)
	multiplayer_button.pressed.connect(_on_multiplayer_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	options_button.pressed.connect(_on_options_pressed)
	
	UIAudioManager.register_buttons([
		singleplayer_button,
		multiplayer_button,
		quit_button,
		options_button
	])


func _on_singleplayer_button_pressed() -> void:
	get_tree().change_scene_to_packed(main_scene)


func _on_multiplayer_button_pressed() -> void:
	get_tree().change_scene_to_packed(multiplayer_menu_scene)


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_options_pressed() -> void :
	var options_menu := options_scene.instantiate()
	add_child(options_menu)
