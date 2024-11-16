extends "res://Scenes/Main.gd"

# only the server can call this because we disable the start button for everyone else
func start_game() -> void:
    if GameState.instruction_follower == GameState.instruction_giver \
            or GameState.instruction_follower == -1 or \
            GameState.instruction_giver == -1:
                return
    print_debug("start game")
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
    GameState._set_instruction_follower.rpc(GameState.instruction_follower)
    GameState._set_instruction_giver.rpc(GameState.instruction_giver)
    
    
    game.game_start(players)


@rpc("call_local", "any_peer")
func player_ready(peer_id: int) -> void:
    var _role = ""
    if GameState.instruction_follower == peer_id:
        _role = "INSTRUCTION FOLLOWER"
    elif GameState.instruction_giver == (peer_id):
        _role = "INSTRUCTION GIVER"
    else:
        _role = " PLEASE SELECT A ROLE"
    ready_screen.set_status(peer_id, "READY!" + " " + _role)

    if multiplayer.is_server() and not players_ready.has(peer_id):
        players_ready[peer_id] = true
        if players_ready.size() == OnlineMatch.players.size():
            ready_screen.start_game_button.disabled = false
        else:
            print(players_ready.size(), "", OnlineMatch.players.size())
