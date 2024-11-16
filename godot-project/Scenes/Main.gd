### Entry node
# Contains matchroom/login setup logic/screens
# Just basic admin things
extends Node2D

@onready var game = $Game
@onready var ui_layer: UILayer = $UILayer
@onready var ready_screen = $UILayer/Screens/ReadyScreen

var players := {}

var players_ready := {}
var players_score := {}

var match_started := false

var bg_music := AudioStreamPlayer.new()

func _ready() -> void:
    game.set_nakama_config()
    
    OnlineMatch.error.connect(_on_OnlineMatch_error)
    OnlineMatch.disconnected.connect(_on_OnlineMatch_disconnected)
    OnlineMatch.player_joined.connect(_on_OnlineMatch_player_joined)
    OnlineMatch.player_left.connect(_on_OnlineMatch_player_left)

    randomize()
    
    game.MusicController.background_music("res://Audio/Music/menu.mp3")
    
    GameState.online_play = true
    ui_layer.show_screen("ConnectionScreen")

    _connect_screen_signals()

    if OS.has_feature("windows"):
        DisplayServer.window_set_size(Vector2i(1920, 1032))

func _connect_screen_signals():
    ready_screen.start_game_button.pressed.connect(start_game)

#####
# UI callbacks
#####

func _on_title_screen_play_local() -> void:
    GameState.online_play = false

    ui_layer.hide_screen()
    ui_layer.show_back_button()

    start_game()

func _on_title_screen_play_online() -> void:
    GameState.online_play = true

    # Show the game map in the background because we have nothing better.
#    game.reload_map()

    ui_layer.show_screen("ConnectionScreen")

func _on_ui_layer_change_screen(layer_name: String, _screen) -> void:
    # if layer_name == 'TitleScreen':
    #     ui_layer.hide_back_button()
    # else:
    #     ui_layer.show_back_button()

    if layer_name != 'ReadyScreen':
        if match_started:
            match_started = false
#            music.play_random()

# Buggy, so we removed the back button.
#func _on_ui_layer_back_button() -> void:
    #ui_layer.hide_message()
#
    #stop_game()
#
    #if GameState.online_play:
        #OnlineMatch.leave()
#
    #if ui_layer.current_screen_name in ['ConnectionScreen', 'MatchScreen', 'CreditsScreen']:
        #ui_layer.show_screen("TitleScreen")
    #elif not GameState.online_play:
        #ui_layer.show_screen("TitleScreen")
    #else:
        #ui_layer.show_screen("MatchScreen")

func _on_ready_screen_ready_pressed() -> void:
    player_ready.rpc(multiplayer.get_unique_id())

#####
# OnlineMatch callbacks
#####

func _on_OnlineMatch_error(message: String):
    if message != '':
        ui_layer.show_message(message)
    ui_layer.show_screen("MatchScreen")

func _on_OnlineMatch_disconnected():
    #_on_OnlineMatch_error("Disconnected from host")
    _on_OnlineMatch_error('')

func _on_OnlineMatch_player_left(player) -> void:
#    game.kill_player(player.peer_id)

    players.erase(player.peer_id)
    players_ready.erase(player.peer_id)

    if players.size() < 2:
        OnlineMatch.leave()
        _on_OnlineMatch_error(player.username + " has left - not enough players!")
    else:
        ui_layer.show_message(player.username + " has left")

func _on_OnlineMatch_player_joined(player) -> void:
    if multiplayer.is_server():
        # Tell this new player about all the other players that are already ready.
        for _player in players_ready.values():
            player_ready.rpc_id(_player.peer_id)

#####
# Gameplay methods and callbacks
#####

@rpc("call_local", "any_peer")
func player_ready(peer_id: int) -> void:
    ready_screen.set_status(peer_id, "READY!")

    if multiplayer.is_server() and not players_ready.has(peer_id):
        players_ready[peer_id] = true
        if players_ready.size() == OnlineMatch.players.size():
            ready_screen.start_game_button.disabled = false
        else:
            print(players_ready.size(), "", OnlineMatch.players.size())

            
# only the server can call this because we disable the start button for everyone else
func start_game() -> void:
    if OnlineMatch.match_state != OnlineMatch.MatchState.PLAYING:
        OnlineMatch.start_playing()

    if GameState.online_play:
        players = OnlineMatch.get_player_names_by_peer_id()
    else:
        players = {
            1: "Player1",
            2: "Player2",
        }

    if multiplayer.is_server():
        ready_screen.set_game_name.rpc(ready_screen.team_name_entry.text)


    # make sure all config files are updated across all clients 
    # before starting the game    
    game.set_game_round.rpc(GameState.num_times_played)
    game.set_game_level.rpc(GameState.level_id)
    
    
    game.game_start(players)


# func stop_game() -> void:
#     OnlineMatch.leave()

#     players.clear()
#     players_ready.clear()
#     players_score.clear()

#     game.game_stop()

# func restart_game() -> void:
#     stop_game()
#     start_game()

func _on_game_s_game_started() -> void:
    ui_layer.hide_screen()
    ui_layer.hide_all()
    # ui_layer.show_back_button()

#     if not match_started:
#         match_started = true
# #        music.play_random()

# func _on_Game_player_dead(peer_id: int) -> void:
#     if GameState.online_play:
#         var my_id = multiplayer.get_unique_id()
#         if peer_id == my_id:
#             ui_layer.show_message("You lose!")

# func _on_game_s_game_over(peer_id: int) -> void:
#     players_ready.clear()

#     if not GameState.online_play:
#         show_winner(players[peer_id])
#     elif multiplayer.is_server():
#         if not players_score.has(peer_id):
#             players_score[peer_id] = 1
#         else:
#             players_score[peer_id] += 1

#         var is_match: bool = players_score[peer_id] >= 5

#         rpc("show_winner", players[peer_id], peer_id, players_score[peer_id], is_match)


# @rpc("any_peer")
# func show_winner(name: String, peer_id: int = 0, score: int = 0, is_match: bool = false) -> void:
#     if is_match:
#         ui_layer.show_message(name + " WINS THE WHOLE MATCH!")
#     else:
#         ui_layer.show_message(name + " wins this round!")

#     await get_tree().create_timer(2.0).timeout
#     if not game.game_started:
#         return

#     if GameState.online_play:
#         if is_match:
#             stop_game()
#             if peer_id != 0 and peer_id == multiplayer.get_unique_id():
#                 update_wins_leaderboard()
#             ui_layer.show_screen("MatchScreen")
#         else:
#             ready_screen.hide_match_id()
#             ready_screen.reset_status("Waiting...")
#             ready_screen.set_score(peer_id, score)
#             ui_layer.show_screen("ReadyScreen")
#     else:
#         restart_game()

func _on_Music_song_finished(_song) -> void:
    pass
#    if not music.current_song.playing:
#        music.play_random()
