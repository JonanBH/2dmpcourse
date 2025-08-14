class_name GameCamera
extends Camera2D

const NOISE_GROWTH : float = 750
const SHAKE_DECAY_RATE : float = 10

@export var noise_texture : FastNoiseLite
@export var shake_strength : float = 10

static var instance : GameCamera

var noise_offset_x : float
var noise_offset_y : float

var current_shake_percent : float


func _ready() -> void:
	instance = self


func _process(delta: float) -> void:
	if current_shake_percent == 0:
		return
	
	noise_offset_x += NOISE_GROWTH * delta
	noise_offset_y += NOISE_GROWTH * delta
	
	var offset_sample_x := noise_texture.get_noise_2d(noise_offset_x, 0)
	var offset_sample_y := noise_texture.get_noise_2d(0, noise_offset_x)
	
	offset = Vector2(offset_sample_x, offset_sample_y) * shake_strength \
			* current_shake_percent * current_shake_percent
	
	current_shake_percent = max(current_shake_percent - \
			(SHAKE_DECAY_RATE * delta), 0)


static func shake(shake_percent : float) -> void:
	instance.current_shake_percent = clamp(shake_percent, 0, 1)
