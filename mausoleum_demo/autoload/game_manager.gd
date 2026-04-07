extends Node
class_name GameManager

signal game_started(hero: Node, wall: Node, mode_id: String)
signal game_over(reason: String)
signal wave_started(wave_number: int)

enum GameState { WAITING, RUNNING, GAME_OVER }

var state: GameState = GameState.WAITING
var current_wave: int = 0
var total_waves: int = 12
var mode_id: String = "waves12"

var hero: Node = null
var wall: Node = null

func _ready() -> void:
	EventBus.wall_destroyed.connect(_on_wall_destroyed)
	EventBus.hero_died.connect(_on_hero_died)

func reset_session() -> void:
	state = GameState.WAITING
	current_wave = 0
	total_waves = 12
	mode_id = "waves12"
	hero = null
	wall = null

func start_game(hero_instance: Node, wall_instance: Node, new_mode_id: String = "waves12") -> void:
	if state != GameState.WAITING:
		return
	hero = hero_instance
	wall = wall_instance
	mode_id = new_mode_id
	current_wave = 0
	state = GameState.RUNNING
	game_started.emit(hero, wall, mode_id)
	request_next_wave()

func request_next_wave() -> void:
	if state != GameState.RUNNING:
		return
	if total_waves > 0 and current_wave >= total_waves:
		_end_game("LevelComplete")
		return
	current_wave += 1
	wave_started.emit(current_wave)
	EventBus.wave_started.emit(current_wave)

func is_running() -> bool:
	return state == GameState.RUNNING

func _on_wall_destroyed() -> void:
	_end_game("WallDestroyed")

func _on_hero_died() -> void:
	_end_game("HeroDied")

func _end_game(reason: String) -> void:
	if state == GameState.GAME_OVER:
		return
	state = GameState.GAME_OVER
	game_over.emit(reason)
	EventBus.game_over.emit(reason)
