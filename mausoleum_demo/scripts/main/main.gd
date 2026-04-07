extends Node2D

@onready var background: Sprite2D = $Background
@onready var wall: Node2D = $Wall
@onready var hero_spawn: Marker2D = $SpawnPoints/HeroSpawn
@onready var enemy_spawn: Marker2D = $SpawnPoints/EnemySpawn
@onready var actors: Node2D = $Actors
@onready var wave_director: WaveDirector = $WaveDirector
@onready var hero_mode_select: HeroModeSelect = $UI/HeroModeSelect

const HERO_SERGEY: PackedScene = preload("res://scenes/hero/sergey.tscn")
const HERO_SOLAR: PackedScene = preload("res://scenes/hero/solar_heroine.tscn")
const HERO_EARTH: PackedScene = preload("res://scenes/hero/earth_guardian.tscn")
const ENEMY_GRUNT: PackedScene = preload("res://scenes/enemies/enemy_grunt.tscn")
const ENEMY_RUNNER: PackedScene = preload("res://scenes/enemies/enemy_runner.tscn")
const ENEMY_BRUISER: PackedScene = preload("res://scenes/enemies/enemy_bruiser.tscn")

var _hero: HeroController = null
var _mode_id: String = "waves12"

func _ready() -> void:
    background.texture = preload("res://assets/reference/bg_forest.png")
    background.modulate = Color(1, 1, 1, 0.42)
    background.position = Vector2(640, 360)
    background.scale = Vector2(0.42, 0.42)
    GameManager.reset_session()
    EventBus.game_over.connect(_on_game_over)
    hero_mode_select.show_menu()
    hero_mode_select.start_requested.connect(_on_start_requested)

func _on_start_requested(hero_id: String, mode_id: String) -> void:
    _mode_id = mode_id
    _spawn_hero(hero_id)
    _configure_mode_and_start()

func _spawn_hero(hero_id: String) -> void:
    if _hero != null and is_instance_valid(_hero):
        _hero.queue_free()
    var scene := _get_hero_scene(hero_id)
    _hero = scene.instantiate() as HeroController
    actors.add_child(_hero)
    _hero.global_position = hero_spawn.global_position

func _get_hero_scene(hero_id: String) -> PackedScene:
    match hero_id:
        "solar": return HERO_SOLAR
        "earth": return HERO_EARTH
        _: return HERO_SERGEY

func _configure_mode_and_start() -> void:
    var mode_enum := WaveDirector.Mode.WAVES_12
    if _mode_id == "endless":
        mode_enum = WaveDirector.Mode.ENDLESS
        GameManager.total_waves = -1
    else:
        GameManager.total_waves = 12
    wave_director.configure(mode_enum, _hero, wall, actors, enemy_spawn, ENEMY_GRUNT, ENEMY_RUNNER, ENEMY_BRUISER)
    GameManager.start_game(_hero, wall, _mode_id)

func _on_game_over(_reason: String) -> void:
    await get_tree().create_timer(1.0).timeout
    get_tree().reload_current_scene()
