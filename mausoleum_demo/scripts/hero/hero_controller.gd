extends CharacterBody2D
class_name HeroController

@export var display_name: String = "Sergey"
@export var weapon_label: String = "Neon Pernach"
@export var team_id: int = 0
@export var move_speed: float = 220.0
@export var y_axis_weight: float = 0.85
@export var attack_damage_base: float = 12.0
@export var attack_cooldown: float = 0.35
@export var attack_active_time: float = 0.10
@export var attack_offset: float = 30.0
@export var body_color: Color = Color(0.2, 0.9, 1.0, 1.0)
@export var outline_color: Color = Color.BLACK
@export var body_scale: float = 1.0

@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var outline_sprite: Sprite2D = $OutlineSprite2D
@onready var body_sprite: Sprite2D = $BodySprite2D
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $Hurtbox
@onready var hitbox: HitboxComponent = $MeleeHitbox

static var _unit_texture: Texture2D = null
var _dead := false
var _facing_dir := Vector2.RIGHT
var _attack_damage: float = 0.0
var _attack_cd: float = 0.0
var _attack_active: float = 0.0
var _pending_overlap_scan := false

func _ready() -> void:
    _attack_damage = attack_damage_base
    _setup_visual()
    hurtbox.team_id = team_id
    hitbox.team_id = team_id
    hitbox.set_enabled(false)
    health_component.health_changed.connect(_on_health_changed)
    health_component.died.connect(_on_died)
    EventBus.hero_health_changed.emit(health_component.current_health, health_component.max_health)

func _physics_process(delta: float) -> void:
    if _dead:
        velocity = Vector2.ZERO
        move_and_slide()
        return
    if _attack_cd > 0.0:
        _attack_cd = max(_attack_cd - delta, 0.0)
    if _attack_active > 0.0:
        _attack_active = max(_attack_active - delta, 0.0)
    _handle_movement()
    _handle_attack_input()
    _update_attack_window()
    move_and_slide()

func apply_scaling(multiplier: float) -> void:
    if multiplier <= 0.0:
        return
    move_speed *= multiplier
    _attack_damage *= multiplier
    health_component.scale_stats(multiplier)

func _handle_movement() -> void:
    var input_vector := Vector2.ZERO
    input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
    input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
    input_vector.y *= y_axis_weight
    if input_vector.length_squared() > 0.0:
        input_vector = input_vector.normalized()
        _facing_dir = input_vector
    velocity = input_vector * move_speed

func _handle_attack_input() -> void:
    if _attack_cd > 0.0:
        return
    if Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("ui_accept"):
        _start_attack()

func _start_attack() -> void:
    _attack_cd = attack_cooldown
    _attack_active = attack_active_time
    _pending_overlap_scan = true
    hitbox.reset_hits()
    hitbox.damage = max(1, roundi(_attack_damage))
    hitbox.position = _facing_dir * attack_offset
    hitbox.set_enabled(true)

func _update_attack_window() -> void:
    if _attack_active > 0.0:
        if _pending_overlap_scan and hitbox.monitoring:
            hitbox.apply_damage_to_overlaps()
            _pending_overlap_scan = false
        return
    if hitbox.monitoring:
        hitbox.set_enabled(false)

func _setup_visual() -> void:
    if _unit_texture == null:
        var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
        img.fill(Color.WHITE)
        _unit_texture = ImageTexture.create_from_image(img)
    outline_sprite.texture = _unit_texture
    body_sprite.texture = _unit_texture
    outline_sprite.modulate = outline_color
    body_sprite.modulate = body_color
    outline_sprite.scale = Vector2(1.35, 1.35) * body_scale
    body_sprite.scale = Vector2.ONE * body_scale

func _on_health_changed(current: int, max_value: int) -> void:
    EventBus.hero_health_changed.emit(current, max_value)

func _on_died() -> void:
    if _dead:
        return
    _dead = true
    body_collision.set_deferred("disabled", true)
    outline_sprite.visible = false
    body_sprite.visible = false
    hurtbox.disable_hurtbox()
    hitbox.set_enabled(false)
    EventBus.hero_died.emit()
