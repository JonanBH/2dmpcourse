class_name HurtboxComponent
extends Area2D

@export var health_component : HealthComponent

func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(other_area : Area2D) -> void:
	if !is_multiplayer_authority() or other_area is not HitboxComponent:
		return
	
	var hitbox_component : HitboxComponent = other_area as HitboxComponent
	
	hitbox_component.register_hurtbox_hit(self)
	
	if health_component:
		health_component.damage(hitbox_component.damage)
	
