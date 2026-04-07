extends Area2D
class_name HitboxComponent

signal hit_landed(target: HurtboxComponent, damage: int, attacker: Node)

@export var damage: int = 10
@export var team_id: int = 0
@export var enabled_on_start: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _owner_entity: Node = null
var _hit_instance_ids: Dictionary = {}

func _ready() -> void:
    _owner_entity = get_parent()
    area_entered.connect(_on_area_entered)
    monitorable = false
    set_enabled(enabled_on_start)

func set_owner_entity(entity: Node) -> void:
    _owner_entity = entity

func reset_hits() -> void:
    _hit_instance_ids.clear()

func set_enabled(enabled: bool) -> void:
    set_deferred("monitoring", enabled)
    collision_shape.set_deferred("disabled", not enabled)

func apply_damage_to_overlaps() -> void:
    if not monitoring:
        return
    for area in get_overlapping_areas():
        _try_hit_area(area)

func _on_area_entered(area: Area2D) -> void:
    _try_hit_area(area)

func _try_hit_area(area: Area2D) -> void:
    if not monitoring:
        return
    if area is not HurtboxComponent:
        return
    var hurtbox := area as HurtboxComponent
    if _owner_entity != null and hurtbox.get_owner_entity() == _owner_entity:
        return
    if hurtbox.team_id == team_id:
        return
    var iid := hurtbox.get_instance_id()
    if _hit_instance_ids.has(iid):
        return
    _hit_instance_ids[iid] = true
    hurtbox.apply_damage(damage, _owner_entity)
    hit_landed.emit(hurtbox, damage, _owner_entity)
