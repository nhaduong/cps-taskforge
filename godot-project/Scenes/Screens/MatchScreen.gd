extends "res://Scenes/Screens/Screen.gd"

@onready var join_match_id_control := $PanelContainer/TextureRect/VBoxContainer/JoinPanel/VBoxContainer/HBoxContainer/LineEdit
@onready var custom_match_id := $PanelContainer/TextureRect/VBoxContainer/CreatePanel/VBoxContainer/HBoxContainer/LineEdit
@export var enter_key_edit: LineEdit
func _ready() -> void:
    $PanelContainer/TextureRect/VBoxContainer/CreatePanel/VBoxContainer/CreateButton.pressed.connect(_on_match_button_pressed.bind(OnlineMatch.MatchMode.CREATE))
    $PanelContainer/TextureRect/VBoxContainer/JoinPanel/VBoxContainer/JoinButton.pressed.connect(_on_match_button_pressed.bind(OnlineMatch.MatchMode.JOIN))

    OnlineMatch.match_joined.connect(_on_OnlineMatch_joined)
    enter_key_edit.text_changed.connect(enable_join_btn)
    
func enable_join_btn(_test_changed):
    $PanelContainer/TextureRect/VBoxContainer/JoinPanel/VBoxContainer/JoinButton.disabled = false

func _show_screen(_info: Dictionary = {}) -> void:
    pass

func _on_match_button_pressed(mode) -> void:
    $PanelContainer/TextureRect/VBoxContainer/CreatePanel/VBoxContainer/CreateButton.disabled = true
    # If our session has expired, show the ConnectionScreen again.
    if Online.nakama_session == null or Online.nakama_session.is_expired():
        ui_layer.show_screen("ConnectionScreen", {reconnect = true, next_screen = null})
        
        # Wait to see if we get a new valid session.
        await Online.session_changed
        if Online.nakama_session == null:
            return

    # Connect socket to realtime Nakama API if not connected.
    if not Online.is_nakama_socket_connected():
        await Online.connect_nakama_socket()
#        await Online.socket_connected

    ui_layer.hide_message()

    # Call internal method to do actual work.
    match mode:
        OnlineMatch.MatchMode.CREATE:
            _create_match()
        OnlineMatch.MatchMode.JOIN:
            _join_match()
    $PanelContainer/TextureRect/VBoxContainer/CreatePanel/VBoxContainer/CreateButton.disabled = false
func _start_matchmaking() -> void:
    pass


func _create_match() -> void:
    OnlineMatch.create_match(Online.nakama_socket, custom_match_id.text)

func _join_match() -> void:
    $PanelContainer/TextureRect/VBoxContainer/JoinPanel/VBoxContainer/JoinButton.disabled = true
    var match_id = join_match_id_control.text.strip_edges()
    if match_id == '':
        ui_layer.show_message("Need to paste Match ID to join")
        $PanelContainer/TextureRect/VBoxContainer/JoinPanel/VBoxContainer/JoinButton.disabled = false
        return
    if not match_id.ends_with('.'):
        match_id += '.'

    OnlineMatch.join_match(Online.nakama_socket, match_id)
    

func _on_OnlineMatch_joined(match_id: String, match_mode: int):
    var info = {
        players = OnlineMatch.players,
        clear = true,
    }

    if match_mode != OnlineMatch.MatchMode.MATCHMAKER:
        info['match_id'] = match_id

    ui_layer.show_screen("ReadyScreen", info)

func _on_paste_button_pressed() -> void:
    join_match_id_control.text = DisplayServer.clipboard_get()


func _on_clear_button_pressed():
    custom_match_id.text = ''
    pass # Replace with function body.
