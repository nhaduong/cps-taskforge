# A basic countdown timer display that 
# can play a sound 

extends Label

# SFX defaults
@export var sfx_fn := "res://Audio/SFX/countdown.ogg"
var sfx_volume = -5.0

@export var timer: Timer

# countdown duration
@export var minutes := 0
@export var seconds := 20
# when to play sfx, in seconds
@export var secs_to_play_sfx := [1, 2, 3, 4, 5]

# track the current time
var curr_minutes
var curr_seconds
# auto add audioplayer for sfx
var countdown_sfx := AudioStreamPlayer.new()
# Called when the node enters the scene tree for the first time.
func _ready():
    add_child(countdown_sfx)
    countdown_sfx.stream = load(sfx_fn)
    countdown_sfx.volume_db = sfx_volume
    countdown_sfx.process_mode = Node.PROCESS_MODE_ALWAYS


func initialize(_minutes, _seconds):
    minutes = _minutes
    seconds = _seconds
    reinitialize()
func reinitialize():
    curr_minutes = minutes
    curr_seconds = seconds
    
    text = "%d" % [curr_seconds]
    
func start_timer():
    timer.start()
func stop_timer():
    timer.stop()
func start_countdown():
    if get_node("/root/Main/Game").Config.current_continue_to_next_level_automatically:
        visible = true
        return
    reinitialize()
    visible = true
    timer.start()
func _on_timer_timeout():
    if curr_seconds == 0:
        if curr_minutes > 0:
            curr_minutes -= 1
            curr_seconds = 59
    else:
        curr_seconds -= 1

    if curr_seconds in secs_to_play_sfx:
        countdown_sfx.play()

    if multiplayer.is_server():
        _sync_timer_values.rpc(curr_minutes, curr_seconds)
    
    if curr_seconds == 0:
        timer.stop()
        visible = false
        countdown_sfx.stop()
        
        if get_node("/root/Main/Game").Config.current_continue_to_next_level_automatically:
            # pretend someone clicked Close Leaderboard / Continue to next round button
            if multiplayer.is_server():
                print_debug("tryikng to auto run level")
                get_node("/root/Main/Game")._on_game_ui_continue_next_round()
    else:
        timer.start()

    if multiplayer.is_server():
        _sync_timer_values.rpc(curr_minutes, curr_seconds)
    
# sync the timer display across all clients
@rpc("authority", "call_local")
func _sync_timer_values(minutes, seconds):
    curr_minutes = minutes
    curr_seconds = seconds
    text = "%d" % [curr_seconds]
