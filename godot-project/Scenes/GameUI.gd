# Main game ui control that acts as a go-between with the various in-game ui
# controls that the world can react to.
extends Control

signal color_changed(color)
signal text_sent(text)
signal chat_edit_started
signal chat_edit_ended
signal logged_out
signal run_wave_requested
signal continue_next_round

@export var next_round_panel: Panel
#@onready var color_editor := $CharacterColorEditor
@onready var chat_box := $chatbox/ChatBox
@onready var notifications_ui := $NotificationsUI
@export var hp: RichTextLabel
@export var gold: RichTextLabel
@export var score: RichTextLabel
@export var wave_preview: WavePreview
@export var fastforward_btn: Button
@export var abort_btn: Button

@export var scores_child_scene: PackedScene
@export var scores_listing: Control

@onready var peerid = $"Peer id"
@onready var elementid = $"Element ID"
@export var unitplacement: Node
# is cursor over ui where clicking on map should do nothing?
var button_is_hovered = false
@export var run_wave_btn: Button
@export var wave_timer: Control

@export var tooltip_panel: Control
@export var countdown_next_round: Label

func _ready():
    GameState.health_update.connect(_set_hp_text)
    GameState.gold_update.connect(_set_gold_text)
    GameState.score_update.connect(_set_score_text)
    
    countdown_next_round.visible = false
    
    if not get_node("/root/Main/Game").Config.current_show_enemy_preview_panel:
        wave_preview.visible = false
    
func start_countdown():
    countdown_next_round.reinitialize()
    countdown_next_round.visible = true
    countdown_next_round.start_timer()
func stop_countdown():
    countdown_next_round.visible = false
    countdown_next_round.stop_timer()
func run_wave_callback():
    run_wave_btn.disabled = true
    if not GameState.current_config.current_is_rts:
        enable_unit_placement(false)
    # print_debug("my id %d, proxy id %d" % [multiplayer.get_unique_id(), GameState.proxy_server_id])
    if multiplayer.is_server() or multiplayer.get_unique_id() == GameState.proxy_server_id:
        fastforward_btn.disabled = false
        abort_btn.disabled = false

    if GameState.has_moderator_teammate:
        if not multiplayer.is_server():
            abort_btn.disabled = true

    # close all tooltips
    _on_close_tooltips_pressed()
    # close all upgrade menus
    get_node("/root/Main/Game")._deselect_active_unit()
    get_node("/root/Main/Game")._clear_active_unit()

func reset_ui_to_defaults():
    run_wave_btn.disabled = false

    if GameState.has_moderator_teammate:
        while GameState.proxy_server_id == -1:
            await get_tree().process_frame

    
    if not multiplayer.is_server() and multiplayer.get_unique_id() != GameState.proxy_server_id:
        run_wave_btn.disabled = true
        
    fastforward_btn.disabled = true
    abort_btn.disabled = true

    if GameState.has_moderator_teammate:
        if multiplayer.is_server():
            fastforward_btn.disabled = false

func enable_unit_placement(value: bool):
    unitplacement.set_tower_buy_btns_enabled(value)
    if value:
        unitplacement.set_enabled_towers_for_level()
func set_current_level_leaderboard():
    for child in scores_listing.get_children():
        child.queue_free()
    var scores = await Http.get_scores()
    
    # we only care about scores for current level
    var curr_level_scores = scores["level"][str(GameState.level_id)]
    for score in curr_level_scores:
        var score_listing = scores_child_scene.instantiate()
        score_listing.set_data(score["game_id"], score["score"])
        scores_listing.add_child(score_listing)
    
func set_time_scale(value):
    fastforward_btn.set_fastforward(value)
func _set_hp_text():
    hp.set_text(str(GameState.Health))
func _set_gold_text():
    gold.set_text(str(GameState.Gold))
func _set_score_text():
    score.set_text(str(GameState.score))
func _set_wave_previews(enemy_wave_data: Array[EnemyWave]):
    wave_preview.spawn_all_previews(enemy_wave_data)
    pass
func _set_peer_id():
    var game = get_node("/root/Main/Game")
    peerid.text = str(multiplayer.get_unique_id())
    
    var s = ""
    for player in game.players_setup.values():
        s += "id %d: element %d\n" % [player.peer_id, player.element_idx]
    elementid.text = s

@rpc("call_local", "any_peer")
func show_ui(ui_object: String, kwargs = {}):
    var _obj = get_node(ui_object)
    if _obj != null:
        _obj.visible = true
    if _obj.has_method("_on_visibility_changed_custom"):
        _obj._on_visibility_changed_custom(kwargs)
func hide_ui(ui_object: String):
    var _obj = get_node(ui_object)
    if _obj != null:
        _obj.visible = false
        
func set_score_content(score_breakdown, end_of_exp = false):
    next_round_panel.set_score_info(score_breakdown, end_of_exp)
    next_round_panel.set_current_level_leaderboard(true)
func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        chat_box.text_edit.release_focus()


#func _unhandled_input(event: InputEvent) -> void:
#    pass
#    if event.is_action_pressed("ui_accept"):
#        if not chat_box.visible:
#            toggle_chat_button.pressed = true
#        if not chat_box.line_edit.has_focus():
#            chat_box.line_edit.grab_focus()
    # if event.is_action_pressed("ui_cancel") and not chat_box.line_edit.has_focus():
    #     toggle_chat_button.pressed = false


func setup(_color: Color) -> void:
    pass
#	color_editor.color = _color


@rpc("any_peer", "call_local")
func add_chat_reply(text: String, sender: String, text_color: Color) -> void:
    var _game = get_node("/root/Main/Game")
    for player in _game.players_setup.values():
        if player.username == sender:
            text_color = GameState.current_config.username_chat_colors[player.element_idx]
    
    chat_box.add_reply(text, sender, text_color)

    if multiplayer.is_server():
        Http.post_chat(sender, text, "/save_displayed_chat")

        # log the chat
        var _text = "<speaker>%s</speaker> <chat_text>%s</chat_text>" % \
        [sender, text]

        Http.post_chat(sender, _text)

@rpc("any_peer", "call_local")
func add_system_chat_message(text: String):
    var channel = "system"
    if "--- STARTING" in text or "--- FINAL" in text:
        channel = "chat"

    chat_box.add_reply(text, "System", Color.RED, channel)

    if multiplayer.is_server():
        Http.post_chat("System", text, "/save_displayed_chat")

func add_notification(username: String, text_color: Color, disconnected := false) -> void:
    notifications_ui.add_notification(username, text_color, disconnected)


func _on_ChangeColorButton_pressed() -> void:
#	color_editor.show()
    pass


func _on_chat_box_text_sent(text: String) -> void:
    emit_signal("text_sent", text)


func _on_CharacterColorEditor_color_changed(_color: Color) -> void:
    emit_signal("color_changed", _color)
    setup(_color)


func _on_LogoutButton_pressed() -> void:
    emit_signal("logged_out")


func _on_chat_box_edit_started() -> void:
    emit_signal("chat_edit_started")


func _on_chat_box_edit_ended() -> void:
    emit_signal("chat_edit_ended")


func _on_run_wave_pressed(auto_start = false):
    emit_signal("run_wave_requested", auto_start)
    
    
func _on_close_pressed():
    emit_signal("continue_next_round")


func _on_pause_game_toggled(button_pressed):
    get_tree().set_pause(button_pressed)
    pass # Replace with function body.


func _on_button_pressed():
    get_tree().set_pause(true)
    pass # Replace with function body.


func _on_button_2_pressed():
    Http.post_score(10, 1000)
    pass # Replace with function body.
    
@rpc("any_peer", "call_local")
func unpause():
    get_tree().set_pause(false)


func _on_close_tooltips_pressed():
    for child in get_node("/root/Main/Game")._towers.values():
        if child:
            if child.info_panel:
                child.info_panel.hide()
    pass # Replace with function body.


func _on_abort_round_pressed():
    Http.post_chat("System", "<action>ABORT</action> <health_remaining>%d</health_remaining>" % GameState.Health)
    GameState._set_health(0)
    pass # Replace with function body.

var muted = false
func _on_mute_toggled(button_pressed):
    self.muted = !self.muted
    AudioServer.set_bus_mute(0, self.muted)
    pass # Replace with function body.
