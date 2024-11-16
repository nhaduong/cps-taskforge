extends Node

const PORT = 4433
# Entry point for the whole app
# Determine the type of app this is, and load the entry point for that type
func _ready():
    print_debug("pause set true here in line 7 of Entry.gd")
    get_tree().paused = true
    # You can save bandwith by disabling server relay and peer notifications.
    multiplayer.server_relay = false
    if OS.has_feature("tdServer") or DisplayServer.get_name() == "headless":
        print("Is server")
        get_tree().change_scene_to_file("res://Scenes/Networking/Server/ServerEntry.tscn")
    elif OS.has_feature("tdClient"):
        print("Is client")
        get_tree().change_scene_to_file("res://Scenes/ClientEntry/ClientEntry.tscn")
    # When running from the editor, this is how we'll default to being a client
    else:
        print("Could not detect application type! Defaulting to client.")
        get_tree().change_scene_to_file("res://Scenes/ClientEntry/ClientEntry.tscn")
