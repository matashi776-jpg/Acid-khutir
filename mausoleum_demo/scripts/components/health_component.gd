extends Node
class_name HealthComponent

signal health_changed(current: int, max_value: int)
signal died

@export var max_health: int = 100
var current_health: int = 0

func _ready() -> void:
    current_health = max_health
    health_changed.emit(current_health, max_health)

func take_damage(amount: int) -> void:
    if amount <= 0 or current_health <= 0:
        return
    current_health = max(current_health - amount, 0)
    health_changed.emit(current_health, max_health)
    if current_health == 0:
        died.emit()

func heal(amount: int) -> void:
    if amount <= 0 or current_health <= 0:
        return
    current_health = min(current_health + amount, max_health)
    health_changed.emit(current_health, max_health)

func is_dead() -> bool:
    return current_health <= 0

func scale_stats(multiplier: float) -> void:
    if multiplier <= 0.0:
        return
    if max_health <= 0:
        max_health = 1
    var ratio := float(current_health) / float(max_health)
    max_health = max(1, roundi(float(max_health) * multiplier))
    current_health = clampi(roundi(float(max_health) * ratio), 0, max_health)
    health_changed.emit(current_health, max_health)
