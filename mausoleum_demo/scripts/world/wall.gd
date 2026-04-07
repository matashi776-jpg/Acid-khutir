extends StaticBody2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var outline_sprite: Sprite2D = $OutlineSprite2D
@onready var body_sprite: Sprite2D = $BodySprite2D
@onready var health_component: HealthComponent = $HealthComponent

var destroyed := false

func _ready() -> void:
    health_component.health_changed.connect(_on_health_changed)
    health_component.died.connect(_on_died)
    EventBus.wall_health_changed.emit(health_component.current_health, health_component.max_health)

func _on_health_changed(current: int, max_value: int) -> void:
    EventBus.wall_health_changed.emit(current, max_value)

func _on_died() -> void:
    if destroyed:
        return
    destroyed = true
    collision_shape.set_deferred("disabled", true)
    outline_sprite.visible = false
    body_sprite.visible = false
    EventBus.wall_destroyed.emit()
