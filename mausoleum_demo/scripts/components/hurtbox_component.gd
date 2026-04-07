extends Area2D
class_name HurtboxComponent

signal damaged(amount: int, attacker: Node)
signal owner_died

@export var team_id: int = 0
@export var health_component_path: NodePath

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var health_component: HealthComponent = null
var _owner_entity: Node = null

func _ready() -> void:
    _owner_entity = get_parent()
    monitoring = false
    monitorable = true
    health_component = _resolve_health_component()
    assert(health_component != null, "HurtboxComponent needs HealthComponent")
    health_component.died.connect(_on_health_owner_died)

func get_owner_entity() -> Node:
    return _owner_entity

func apply_damage(amount: int, attacker: Node) -> void:
    if health_component == null or health_component.is_dead() or amount <= 0:
        return
    health_component.take_damage(amount)
    damaged.emit(amount, attacker)

func disable_hurtbox() -> void:
    collision_shape.set_deferred("disabled", true)
    set_deferred("monitorable", false)

func _on_health_owner_died() -> void:
    disable_hurtbox()
    owner_died.emit()

func _resolve_health_component() -> HealthComponent:
    if health_component_path != NodePath():
        var candidate := get_node_or_null(health_component_path)
        if candidate is HealthComponent:
            return candidate as HealthComponent
    for child in _owner_entity.get_children():
        if child is HealthComponent:
            return child as HealthComponent
    return null
