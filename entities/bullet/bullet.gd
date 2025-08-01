class_name Bullet extends Node2D

const SPEED = 600

@onready var life_timer: Timer = $LifeTimer
@onready var hitbox_component: HitboxComponent = $HitboxComponent

var direction := Vector2.ZERO

func _ready() -> void:
	life_timer.timeout.connect(_on_life_timer_timeout)
	hitbox_component.hit_hurtbox.connect(_on_hit_hurtbox)


func _process(delta: float) -> void:
	global_position += direction * SPEED * delta


func start(direction : Vector2) -> void:
	self.direction = direction
	rotation = direction.angle()
	


func _on_life_timer_timeout() -> void:
	if is_multiplayer_authority():
		queue_free()


func register_collision() -> void:
	queue_free()


func _on_hit_hurtbox(_hurtbox_component : HurtboxComponent) -> void:
	register_collision()
