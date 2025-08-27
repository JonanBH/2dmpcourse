class_name Bullet extends Node2D

const SPEED = 600

@onready var life_timer: Timer = $LifeTimer
@onready var hitbox_component: HitboxComponent = $HitboxComponent

var direction := Vector2.ZERO
var source_peer_id : int = -1
var damage := 1

func _ready() -> void:
	hitbox_component.source_peer_id = source_peer_id
	life_timer.timeout.connect(_on_life_timer_timeout)
	hitbox_component.hit_hurtbox.connect(_on_hit_hurtbox)
	hitbox_component.damage = damage


func _process(delta: float) -> void:
	global_position += direction * SPEED * delta


func start(dir : Vector2) -> void:
	self.direction = dir
	rotation = dir.angle()
	


func _on_life_timer_timeout() -> void:
	if is_multiplayer_authority():
		queue_free()


func register_collision() -> void:
	queue_free()


func _on_hit_hurtbox(_hurtbox_component : HurtboxComponent) -> void:
	register_collision()
