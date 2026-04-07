extends Node

signal wall_health_changed(current: int, max_value: int)
signal hero_health_changed(current: int, max_value: int)
signal wave_started(wave_number: int)
signal game_over(reason: String)
signal wall_destroyed
signal hero_died
