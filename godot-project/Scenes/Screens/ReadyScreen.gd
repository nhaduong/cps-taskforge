extends "res://Scenes/Screens/Screen.gd"

var PeerStatus = preload("res://Scenes/Screens/PeerStatus.tscn");

@export var start_game_button: Button
@export var ready_button: Button
@export var team_name_entry: LineEdit
@export var team_container: Control
@export var team_name_preview: Label
@onready var match_id_container := $Panel/MatchIDContainer
@onready var match_id_label := $Panel/MatchIDContainer/MatchID
@onready var status_container := $Panel/StatusContainer/PeerStatus

@export var moderator_controls: Control
@export var select_level_container: BoxContainer
@export var has_moderator: Control
@export var rts_mode: Control
@export var is_online_exp: Control
@export var ready_btn_toggle: Control
@export var current_level_label: Label
signal ready_pressed()

var team_names_fn = "res://Resources/team_names.txt"
var team_names_list = []

func _ready() -> void:
    clear_players()

    OnlineMatch.player_joined.connect(_on_OnlineMatch_player_joined)
    OnlineMatch.player_left.connect(_on_OnlineMatch_player_left)
    OnlineMatch.match_ready.connect(_on_OnlineMatch_match_ready)
    OnlineMatch.match_not_ready.connect(_on_OnlineMatch_match_not_ready)
    
    if not multiplayer.is_server():
        start_game_button.visible = false
        select_level_container.visible = false
        
    _set_ready_buttons_visible(false)
    start_game_button.disabled = true
    
    if multiplayer.is_server():
        team_names_list = Util.load_file(team_names_fn)
        var rng = RandomNumberGenerator.new()
        seed(42)
        var _idx = rng.randi_range(0, team_names_list.size() - 1)
        if team_names_list.size() > 0:
            set_game_name.rpc(team_names_list[_idx])
            
        rts_mode.button_pressed = GameState.current_config.current_is_rts
        is_online_exp.button_pressed = GameState.current_config.is_remote_exp
#        has_moderator.button_pressed = GameState.has_moderator_teammate
        
    current_level_label.text = "LEVEL: %d\nROUND: %d" % \
            [GameState.level_id + 2, GameState.num_times_played + 2]
        

@rpc("any_peer", "call_local")
func set_game_name(game_name):
    GameState.game_id = game_name
    GameState.room_id = match_id_label.text
    team_name_preview.text = game_name
    var jump_to_end = false
    var curr_carat_col = team_name_entry.caret_column
    if team_name_entry.caret_column == team_name_entry.text.length() - 1:
        jump_to_end = true
    team_name_entry.text = game_name
    if jump_to_end:
        team_name_entry.caret_column = team_name_entry.text.length()
    else:
        team_name_entry.caret_column = curr_carat_col
    
func _show_screen(info: Dictionary = {}) -> void:
    var players: Dictionary = info.get("players", {})
    var match_id: String = info.get("match_id", '')
    var clear: bool = info.get("clear", false)

    if players.size() > 0 or clear:
        clear_players()

    for peer_id in players:
        add_player(peer_id, players[peer_id]['username'])

    if match_id:
        match_id_container.visible = true
        match_id_label.text = match_id
    else:
        match_id_container.visible = false

    ready_button.grab_focus()

func clear_players() -> void:
    for child in status_container.get_children():
        status_container.remove_child(child)
        child.queue_free()
    ready_button.disabled = true

func hide_match_id() -> void:
    match_id_container.visible = false

func add_player(peer_id: int, username: String) -> void:
    if not status_container.has_node(str(peer_id)):
        var status = PeerStatus.instantiate()
        status_container.add_child(status)
        status.initialize(username)
        status.name = str(peer_id)

func remove_player(peer_id: int) -> void:
    var status = status_container.get_node(str(peer_id))
    if status:
        status.queue_free()

func set_status(peer_id: int, status: String) -> void:
    var status_node = status_container.get_node(str(peer_id))
    if status_node:
        status_node.set_status(status)

func get_status(peer_id: int) -> String:
    var status_node = status_container.get_node(str(peer_id))
    if status_node:
        return status_node.status
    return ''

func reset_status(status: String) -> void:
    for child in status_container.get_children():
        child.set_status(status)

func set_score(peer_id: int, score: int) -> void:
    var status_node = status_container.get_node(str(peer_id))
    if status_node:
        status_node.set_score(score)

func set_ready_button_enabled(enabled: bool = true) -> void:
    ready_button.disabled = !enabled
    if enabled:
        ready_button.grab_focus()

func _on_ready_button_pressed() -> void:
    emit_signal("ready_pressed")

func _on_match_copy_button_pressed() -> void:
    DisplayServer.clipboard_set(match_id_label.text)

#####
# OnlineMatch callbacks:
#####

func _on_OnlineMatch_player_joined(player) -> void:
    add_player(player.peer_id, player.username)
    if multiplayer.is_server():
        set_game_name.rpc_id(player.peer_id, GameState.game_id)

func _on_OnlineMatch_player_left(player) -> void:
    remove_player(player.peer_id)

func _on_OnlineMatch_match_ready(_players: Dictionary) -> void:
    set_ready_button_enabled(true)

func _on_OnlineMatch_match_not_ready() -> void:
    set_ready_button_enabled(false)


func _on_visibility_changed():
    if multiplayer:
        if not multiplayer.is_server():
            start_game_button.disabled = true
            start_game_button.visible = false
#            team_name_entry.visible = false
#            team_name_preview.visible = true
            select_level_container.visible = false
            moderator_controls.visible = false
        else:
#            team_name_preview.visible = false
            pass
    pass # Replace with function body.


func _on_team_name_text_changed(new_text):
    set_game_name.rpc(new_text)
    pass # Replace with function body.

@rpc("call_local", "any_peer")
func set_starting_level(level: int):
    get_node("/root/Main/Game").set_game_level(level)
    current_level_label.text = "LEVEL: %d\nROUND: %d" % [GameState.level_id + 2, GameState.num_times_played + 2]

@rpc("call_local", "any_peer")
func set_starting_round(level: int):
    get_node("/root/Main/Game").set_game_round(level)
    current_level_label.text = "LEVEL: %d\nROUND: %d" % [GameState.level_id + 2, GameState.num_times_played + 2]

func _on_level_select_pressed():
    set_starting_level.rpc(int($"Panel/ModeratorControls/Level select/Level Select/LineEdit".text) - 2)
func _on_round_select_pressed():
    set_starting_round.rpc(int($"Panel/ModeratorControls/Level select/Round Select/LineEdit".text) - 2)


func _on_moderator_button_toggled(button_pressed):
    set_has_moderator.rpc(button_pressed)

@rpc("any_peer", "call_local")
func set_has_moderator(val):
    GameState.has_moderator_teammate = val

@rpc("any_peer", "call_local")
func set_is_rts(val):
    GameState.current_config.current_is_rts = val
@rpc("any_peer", "call_local")
func set_is_online_exp(val):
    GameState.current_config.is_remote_exp = val
func _on_rts_toggled(button_pressed):
    set_is_rts.rpc(button_pressed)
    pass # Replace with function body.


func _on_tutorial_pressed():
    set_starting_round.rpc(0)
    pass # Replace with function body.


func _on_online_exp_toggled(button_pressed):
    set_is_online_exp.rpc(button_pressed)
    pass # Replace with function body.

@rpc("any_peer", "call_local")
func _set_ready_buttons_visible(val):
    ready_button.visible = val
func _on_toggle_ready_buttons_toggled(button_pressed):
    _set_ready_buttons_visible.rpc(button_pressed)
    pass # Replace with function body.
