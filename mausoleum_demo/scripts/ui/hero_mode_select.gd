extends CanvasLayer
class_name HeroModeSelect

signal start_requested(hero_id: String, mode_id: String)

@onready var root_control: Control = $Root
@onready var hero_option: OptionButton = $Root/Panel/VBox/HeroOption
@onready var mode_option: OptionButton = $Root/Panel/VBox/ModeOption
@onready var preview_texture: TextureRect = $Root/Panel/VBox/PreviewTexture
@onready var start_button: Button = $Root/Panel/VBox/StartButton

var hero_previews := {
    0: preload("res://assets/reference/hero_sergey.png"),
    1: preload("res://assets/reference/hero_solar.png"),
    2: preload("res://assets/reference/hero_earth.png"),
}

func _ready() -> void:
    hero_option.clear()
    hero_option.add_item("Sergey — Neon Pernach", 0)
    hero_option.add_item("Solar Heroine — Solar Crescent", 1)
    hero_option.add_item("Earth Guardian — Forest Staff", 2)
    mode_option.clear()
    mode_option.add_item("12 Waves", 0)
    mode_option.add_item("Endless", 1)
    hero_option.item_selected.connect(_on_hero_selected)
    start_button.pressed.connect(_on_start_pressed)
    _on_hero_selected(0)

func show_menu() -> void:
    root_control.visible = true

func hide_menu() -> void:
    root_control.visible = false

func _on_hero_selected(index: int) -> void:
    if hero_previews.has(index):
        preview_texture.texture = hero_previews[index]

func _on_start_pressed() -> void:
    var hero_id := "sergey"
    match hero_option.get_selected_id():
        1: hero_id = "solar"
        2: hero_id = "earth"
    var mode_id := "waves12"
    if mode_option.get_selected_id() == 1:
        mode_id = "endless"
    hide_menu()
    start_requested.emit(hero_id, mode_id)
