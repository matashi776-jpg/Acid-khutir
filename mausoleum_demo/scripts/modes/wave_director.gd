extends Node
class_name WaveDirector

enum Mode { WAVES_12, ENDLESS }

@export var spawn_interval: float = 0.35
@export var interwave_delay: float = 0.9

var mode: Mode = Mode.WAVES_12
var active := false
var hero: HeroController = null
var wall: Node2D = null
var wall_health: HealthComponent = null
var enemy_parent: Node = null
var enemy_spawn: Node2D = null
var grunt_scene: PackedScene = null
var runner_scene: PackedScene = null
var bruiser_scene: PackedScene = null
var _enemy_scale := 1.0
const SCALE_STEP := 1.005
var _spawn_queue: Array[PackedScene] = []
var _spawn_timer := 0.0
var _alive := 0
var _waiting_next_wave := false
var _next_wave_timer := 0.0
const WAVES_12_TABLE := [
    {"g": 3,  "r": 0, "b": 0},
    {"g": 4,  "r": 0, "b": 0},
    {"g": 5,  "r": 1, "b": 0},
    {"g": 6,  "r": 2, "b": 0},
    {"g": 6,  "r": 3, "b": 1},
    {"g": 7,  "r": 3, "b": 1},
    {"g": 7,  "r": 4, "b": 1},
    {"g": 8,  "r": 4, "b": 2},
    {"g": 8,  "r": 5, "b": 2},
    {"g": 9,  "r": 5, "b": 2},
    {"g": 9,  "r": 6, "b": 3},
    {"g": 10, "r": 6, "b": 3},
]

func _ready() -> void:
    EventBus.wave_started.connect(_on_wave_started)
    EventBus.game_over.connect(_on_game_over)

func configure(new_mode: Mode, new_hero: HeroController, new_wall: Node2D, new_enemy_parent: Node, new_enemy_spawn: Node2D, new_grunt_scene: PackedScene, new_runner_scene: PackedScene, new_bruiser_scene: PackedScene) -> void:
    mode = new_mode
    hero = new_hero
    wall = new_wall
    enemy_parent = new_enemy_parent
    enemy_spawn = new_enemy_spawn
    grunt_scene = new_grunt_scene
    runner_scene = new_runner_scene
    bruiser_scene = new_bruiser_scene
    wall_health = _find_health_component(wall)
    active = true
    _enemy_scale = 1.0
    _spawn_queue.clear()
    _spawn_timer = 0.0
    _alive = 0
    _waiting_next_wave = false
    _next_wave_timer = 0.0

func _process(delta: float) -> void:
    if not active or not GameManager.is_running():
        return
    if _spawn_queue.size() > 0:
        _spawn_timer -= delta
        if _spawn_timer <= 0.0:
            _spawn_timer = spawn_interval
            _spawn_one(_spawn_queue.pop_front())
    if _spawn_queue.is_empty() and _alive == 0:
        if not _waiting_next_wave:
            _waiting_next_wave = true
            _next_wave_timer = interwave_delay
        else:
            _next_wave_timer -= delta
            if _next_wave_timer <= 0.0:
                _waiting_next_wave = false
                GameManager.request_next_wave()

func _on_wave_started(wave_number: int) -> void:
    if not active:
        return
    if wave_number > 0 and (wave_number % 5) == 0:
        _apply_scaling_step()
    _build_spawn_queue(wave_number)
    _spawn_timer = 0.0
    _waiting_next_wave = false
    _next_wave_timer = 0.0

func _build_spawn_queue(wave_number: int) -> void:
    _spawn_queue.clear()
    var g:=0; var r:=0; var b:=0
    if mode == Mode.WAVES_12:
        var idx := clampi(wave_number - 1, 0, WAVES_12_TABLE.size() - 1)
        var wave: Dictionary = WAVES_12_TABLE[idx]
        g = wave["g"]; r = wave["r"]; b = wave["b"]
    else:
        g = 3 + wave_number
        r = int(floor(float(wave_number) * 0.6))
        b = int(floor(float(wave_number) * 0.2))
    for i in range(g): _spawn_queue.append(grunt_scene)
    for i in range(r): _spawn_queue.append(runner_scene)
    for i in range(b): _spawn_queue.append(bruiser_scene)

func _spawn_one(scene: PackedScene) -> void:
    if scene == null or enemy_parent == null or enemy_spawn == null:
        return
    var enemy := scene.instantiate() as EnemyBase
    if enemy == null:
        return
    enemy.configure(hero, wall, _enemy_scale)
    enemy.killed.connect(_on_enemy_killed)
    enemy_parent.add_child(enemy)
    enemy.global_position = enemy_spawn.global_position + Vector2(0.0, float(_alive) * 6.0)
    _alive += 1

func _on_enemy_killed(_enemy: EnemyBase) -> void:
    _alive = max(_alive - 1, 0)

func _apply_scaling_step() -> void:
    _enemy_scale *= SCALE_STEP
    if hero != null:
        hero.apply_scaling(SCALE_STEP)
    if wall_health != null:
        wall_health.scale_stats(SCALE_STEP)

func _find_health_component(node: Node) -> HealthComponent:
    for child in node.get_children():
        if child is HealthComponent:
            return child as HealthComponent
    return null

func _on_game_over(_reason: String) -> void:
    active = false
    _spawn_queue.clear()
