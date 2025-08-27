extends Node

@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

static var instance : UIAudioManager

func _ready() -> void:
	instance = self


static func register_buttons(buttons : Array) -> void:
	for button in buttons:
		button.pressed.connect(instance._on_button_pressed)


func _on_button_pressed() -> void:
	instance.audio_stream_player_2d.play()
