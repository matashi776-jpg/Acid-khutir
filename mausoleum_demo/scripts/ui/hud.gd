extends CanvasLayer

@onready var hero_hp_label: Label = $Root/HeroHP
@onready var wall_hp_label: Label = $Root/WallHP
@onready var wave_label: Label = $Root/Wave
@onready var status_label: Label = $Root/Status

func _ready() -> void:
    EventBus.hero_health_changed.connect(_on_hero_health_changed)
    EventBus.wall_health_changed.connect(_on_wall_health_changed)
    EventBus.wave_started.connect(_on_wave_started)
    EventBus.game_over.connect(_on_game_over)

func _on_hero_health_changed(current: int, max_value: int) -> void:
    hero_hp_label.text = "Hero HP: %d / %d" % [current, max_value]

func _on_wall_health_changed(current: int, max_value: int) -> void:
    wall_hp_label.text = "Wall HP: %d / %d" % [current, max_value]

func _on_wave_started(wave: int) -> void:
    wave_label.text = "Wave: %d" % wave
    status_label.text = "Fight"

func _on_game_over(reason: String) -> void:
    status_label.text = "Game Over: %s" % reason
