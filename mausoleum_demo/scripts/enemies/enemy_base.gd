extends CharacterBody2D
class_name EnemyBase

signal killed(enemy: EnemyBase)

enum TargetMode { WALL, HERO }

@export var enemy_name: String = "Grunt"
@export var y_axis_weight: float = 0.85
@export var base_move_speed: float = 120.0
@export var base_max_health: int = 30
@export var base_attack_damage: float = 6.0
@export var attack_cooldown: float = 1.0
@export var attack_active_time: float = 0.1
@export var aggro_radius: float = 130.0
@export var lose_aggro_radius: float = 190.0
@export var aggro_hold_time: float = 2.0
@export var attack_range: float = 26.0
@export var wall_attack_range: float = 30.0
@export var hitbox_forward_offset: float = 18.0
@export var body_color: Color = Color(0.9, 0.15, 0.25, 1.0)
@export var outline_color: Color = Color.BLACK
@export var body_scale: float = 1.0

@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var outline_sprite: Sprite2D = $OutlineSprite2D
@onready var body_sprite: Sprite2D = $BodySprite2D
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $Hurtbox
@onready var hitbox: HitboxComponent = $AttackHitbox

static var _unit_texture: Texture2D = null
var _dead := false
var _hero: Node2D = null
var _wall: Node2D = null
var _wall_health: HealthComponent = null
var _stat_multiplier := 1.0
var _move_speed := 0.0
var _attack_damage := 0.0
var _target_mode: TargetMode = TargetMode.WALL
var _aggro_timer := 0.0
var _attack_cd := 0.0
var _attack_active := 0.0
var _pending_overlap_scan := false

func configure(hero: Node2D, wall: Node2D, stat_multiplier: float) -> void:
    _hero = hero
    _wall = wall
    _stat_multiplier = max(stat_multiplier, 0.01)

func _ready() -> void:
    _setup_visual()
    hurtbox.team_id = 1
    hitbox.team_id = 1
    hitbox.set_enabled(false)
    health_component.died.connect(_on_died)
    hurtbox.damaged.connect(_on_damaged)
    _apply_scaled_stats()
    if _wall != null:
        _wall_health = _find_health_component(_wall)

func _physics_process(delta: float) -> void:
    if _dead:
        velocity = Vector2.ZERO
        move_and_slide()
        return
    if _hero == null or _wall == null:
        velocity = Vector2.ZERO
        move_and_slide()
        return
    _update_timers(delta)
    _update_targeting()
    _update_movement_and_attack()
    _update_attack_window()
    move_and_slide()

func _update_timers(delta: float) -> void:
    if _aggro_timer > 0.0:
        _aggro_timer = max(_aggro_timer - delta, 0.0)
    if _attack_cd > 0.0:
        _attack_cd = max(_attack_cd - delta, 0.0)
    if _attack_active > 0.0:
        _attack_active = max(_attack_active - delta, 0.0)

func _update_targeting() -> void:
    var dist_to_hero := global_position.distance_to(_hero.global_position)
    if dist_to_hero <= aggro_radius:
        _target_mode = TargetMode.HERO
        return
    if _aggro_timer > 0.0 and dist_to_hero <= lose_aggro_radius:
        _target_mode = TargetMode.HERO
        return
    _target_mode = TargetMode.WALL

func _update_movement_and_attack() -> void:
    match _target_mode:
        TargetMode.HERO:
            _process_hero_target()
        TargetMode.WALL:
            _process_wall_target()

func _process_hero_target() -> void:
    var to_hero := _hero.global_position - global_position
    if to_hero.length() <= attack_range:
        velocity = Vector2.ZERO
        _try_attack_with_hitbox(to_hero)
        return
    var dir := to_hero.normalized()
    dir.y *= y_axis_weight
    if dir.length_squared() > 0.0:
        dir = dir.normalized()
    velocity = dir * _move_speed

func _process_wall_target() -> void:
    var to_wall := _wall.global_position - global_position
    if to_wall.length() <= wall_attack_range:
        velocity = Vector2.ZERO
        _try_attack_wall_direct()
        return
    var dir := to_wall.normalized()
    dir.y *= y_axis_weight
    if dir.length_squared() > 0.0:
        dir = dir.normalized()
    velocity = dir * _move_speed

func _try_attack_with_hitbox(direction: Vector2) -> void:
    if _attack_cd > 0.0:
        return
    _attack_cd = attack_cooldown
    _attack_active = attack_active_time
    _pending_overlap_scan = true
    hitbox.reset_hits()
    hitbox.damage = max(1, roundi(_attack_damage))
    var dir := direction.normalized() if direction.length_squared() > 0.0 else Vector2.RIGHT
    hitbox.position = dir * hitbox_forward_offset
    hitbox.set_enabled(true)

func _try_attack_wall_direct() -> void:
    if _attack_cd > 0.0 or _wall_health == null or _wall_health.is_dead():
        return
    _attack_cd = attack_cooldown
    _wall_health.take_damage(max(1, roundi(_attack_damage)))

func _update_attack_window() -> void:
    if _attack_active > 0.0:
        if _pending_overlap_scan and hitbox.monitoring:
            hitbox.apply_damage_to_overlaps()
            _pending_overlap_scan = false
        return
    if hitbox.monitoring:
        hitbox.set_enabled(false)

func _on_damaged(_amount: int, _attacker: Node) -> void:
    _aggro_timer = aggro_hold_time
    _target_mode = TargetMode.HERO

func _on_died() -> void:
    if _dead:
        return
    _dead = true
    body_collision.set_deferred("disabled", true)
    hurtbox.disable_hurtbox()
    hitbox.set_enabled(false)
    outline_sprite.visible = false
    body_sprite.visible = false
    killed.emit(self)
    queue_free()

func _apply_scaled_stats() -> void:
    _move_speed = base_move_speed * _stat_multiplier
    _attack_damage = base_attack_damage * _stat_multiplier
    health_component.max_health = max(1, roundi(float(base_max_health) * _stat_multiplier))
    health_component.current_health = health_component.max_health
    health_component.health_changed.emit(health_component.current_health, health_component.max_health)

func _find_health_component(node: Node) -> HealthComponent:
    for child in node.get_children():
        if child is HealthComponent:
            return child as HealthComponent
    return null

func _setup_visual() -> void:
    if _unit_texture == null:
        var img := Image.create(22, 22, false, Image.FORMAT_RGBA8)
        img.fill(Color.WHITE)
        _unit_texture = ImageTexture.create_from_image(img)
    outline_sprite.texture = _unit_texture
    body_sprite.texture = _unit_texture
    outline_sprite.modulate = outline_color
    body_sprite.modulate = body_color
    outline_sprite.scale = Vector2(1.35, 1.35) * body_scale
    body_sprite.scale = Vector2.ONE * body_scale
