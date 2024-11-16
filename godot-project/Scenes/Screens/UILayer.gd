extends CanvasLayer
class_name UILayer

@onready var screens = $Screens
@onready var message_label = $Overlay/Message
@onready var back_button_btn = $Overlay/BackButton
@export var version_label: Label

signal change_screen(name, screen)
signal back_button()

var current_screen: Control = null: set = _set_readonly_variable
var current_screen_name: String = '': set = _set_readonly_variable, get = get_current_screen_name

var _is_ready := false

func _set_readonly_variable(_value) -> void:
    pass

func _ready() -> void:
    for screen in screens.get_children():
        if screen.has_method('_setup_screen'):
            screen._setup_screen(self)
    
    show_screen("TitleScreen")
    _is_ready = true
    var game = get_node("/root/Main/Game")
    version_label.text = "v%s" % GameState.current_config.build_version

func get_current_screen_name() -> String:
    if current_screen:
        return current_screen.name
    return ''

func show_screen(screen_name: String, info: Dictionary = {}) -> void:
    var screen = screens.get_node(screen_name)
    if not screen:
        return
    
    hide_screen()
    screen.visible = true
    if screen.has_method("_show_screen"):
        screen.callv("_show_screen", [info])
    current_screen = screen
    
    if _is_ready:
        emit_signal("change_screen", screen_name, screen)

func hide_screen() -> void:
    if current_screen and current_screen.has_method('_hide_screen'):
        current_screen._hide_screen()
    
    for screen in screens.get_children():
        screen.visible = false
    current_screen = null

func show_message(text: String) -> void:
    message_label.text = text
    message_label.visible = true

func hide_message() -> void:
    message_label.visible = false

func show_back_button() -> void:
    back_button_btn.visible = true

func hide_back_button() -> void:
    back_button_btn.visible = false

func hide_all() -> void:
    hide_screen()
    hide_message()
    hide_back_button()
    $Control/Mute.disabled = true
    $Control/Mute.visible = false
func _on_back_button_pressed() -> void:
    emit_signal("back_button")

func _on_mute_button_toggled(button_pressed: bool) -> void:
    AudioServer.set_bus_mute(0, button_pressed)


func _on_mute_toggled(button_pressed):
    get_node("/root/Main/Game").gameui._on_mute_toggled(button_pressed)
    pass # Replace with function body.
