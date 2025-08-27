class_name HitboxComponent
extends Area2D

signal hit_hurtbox(hurtbox_component : HealthComponent)

var damage : int = 1
var source_peer_id : int = -1


func register_hurtbox_hit(hurtbox_component : HurtboxComponent) -> void:
	hit_hurtbox.emit(hurtbox_component)
