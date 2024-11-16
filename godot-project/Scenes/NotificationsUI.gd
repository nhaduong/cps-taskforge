extends VBoxContainer

const Notification := preload("res://Scenes/HUD/Notification.tscn")


func add_notification(username: String, color: Color, disconnected := false) -> void:
    if not Notification:
        return
    var _notification := Notification.instantiate()
    add_child(_notification)
    _notification.setup(username, color, disconnected)
