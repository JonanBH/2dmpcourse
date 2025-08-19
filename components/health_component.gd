class_name HealthComponent 
extends Node

signal died
signal damaged
signal health_changed(current_health : int, max_health : int)

@export var max_health : int = 1

var _current_health : int
var current_health : int:
	get:
		return _current_health
	set(value):
		if value != _current_health:
			health_changed.emit(value, max_health)
		
		_current_health = value

func _ready() -> void:
	current_health = max_health


func damage(amount : int) -> void:
	current_health = clamp(current_health - amount, 0, max_health)
	damaged.emit()
	
	if current_health == 0:
		died.emit()
