extends "res://Scenes/Screens/Screen.gd"

signal play_local
signal play_online

func _on_LocalButton_pressed() -> void:
    emit_signal("play_local")


func _on_CreditsButton_pressed() -> void:
    ui_layer.show_screen("CreditsScreen")


func _on_online_button_pressed():
    emit_signal("play_online")
