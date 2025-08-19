extends Control


@onready var singleplayer_button: Button = $VBoxContainer/SingleplayerButton
@onready var multiplayer_button: Button = $VBoxContainer/MultiplayerButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var multiplayer_menu_scene : PackedScene = load("uid://dgc1uwdw0xx4d")

var main_scene : PackedScene = preload("uid://bhfns2kme5t0f")


func _ready() -> void:
	singleplayer_button.pressed.connect(_on_singleplayer_button_pressed)
	multiplayer_button.pressed.connect(_on_multiplayer_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)


func _on_singleplayer_button_pressed() -> void:
	get_tree().change_scene_to_packed(main_scene)


func _on_multiplayer_button_pressed() -> void:
	get_tree().change_scene_to_packed(multiplayer_menu_scene)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
