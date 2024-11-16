extends Node

# metadata for logging
var game_id := ""
var room_id := ""
var online_play := false
var level_id = 0
var num_times_played = 0
var team_name = ""
var has_moderator_teammate := false

# used for reference game 
var instruction_follower := -1
var instruction_giver := -1

# used only if we have a moderator. we need to assign some other 
# peer_id to play "server" for access to UI buttons like RunWave
var proxy_server_id = -1

var current_config: GameConfig


# In game
var Health: int = 100
var Gold: int = 100
var score: int
var score_breakdown: Dictionary
var wave_running := false

signal out_of_health
signal gold_update
signal health_update
signal score_update
signal wave_running_toggled(val)

@rpc("any_peer", "call_local")
func set_wave_running(val):
    wave_running = val
    wave_running_toggled.emit(val)

@rpc("any_peer", "call_local")
func _set_score(val):
    score = val
    self.score_update.emit()
#    print_debug("setting score to ", val)
    
@rpc("any_peer", "call_local")
func _set_gold(val):
    Gold = val
    self.gold_update.emit()
#    print_debug("setting gold to ", val)

@rpc("any_peer", "call_local")
func _set_health(val):
#    print_debug("starting hp: ",Health,"setting hp to ",val, " on client ", multiplayer.get_unique_id(), " called by client ", multiplayer.get_remote_sender_id())
    
    Health = val
    self.health_update.emit()
    if Health <= 0:
        out_of_health.emit()

@rpc("any_peer", "call_local")
func _set_instruction_follower(peer_id):
    instruction_follower = peer_id

@rpc("any_peer", "call_local")
func _set_instruction_giver(peer_id):
    instruction_giver = peer_id
