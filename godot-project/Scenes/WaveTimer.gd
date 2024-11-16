extends Control

@export var timer : Timer
@export var label : Label

@export var minutes := 5
@export var seconds := 0
var curr_minutes
var curr_seconds

var countdown_sfx := AudioStreamPlayer.new()
# Called when the node enters the scene tree for the first time.
func _ready():
    add_child(countdown_sfx)
    countdown_sfx.stream = load("res://Audio/SFX/countdown.ogg") #load("res://Audio/Music/Clock-Ticking-C-www.fesliyanstudios.com.mp3")
    countdown_sfx.volume_db = -5
    countdown_sfx.process_mode = Node.PROCESS_MODE_ALWAYS
#    countdown_sfx.autoplay = true
    pass # Replace with function body.



func initialize(_minutes,_seconds):
    minutes = _minutes
    seconds = _seconds
    reinitialize()
func reinitialize():
    curr_minutes = minutes
    curr_seconds = seconds
    
    label.text = "%d:%s" % [curr_minutes,_format_seconds()]

func _format_seconds():
    var seconds_text
    if curr_seconds > 9:
        seconds_text = "%d" % curr_seconds
    else:
        seconds_text = "0%d"% curr_seconds
    return seconds_text
func start_timer():
    timer.start()
    
func _on_timer_timeout():
    if curr_seconds == 0:
        if curr_minutes > 0:
            curr_minutes -= 1
            curr_seconds = 59
    else:
        curr_seconds -= 1
        
#    countdown_sfx.volume_db = -15
    if curr_minutes == 0:
        if curr_seconds in [1,2,3,4,5,6,7,8,9,10]:
            countdown_sfx.volume_db = -5
#            countdown_sfx.stream = load("res://Audio/SFX/countdown.ogg")

            countdown_sfx.play()
            
    if multiplayer.is_server():
        _sync_timer_values.rpc(curr_minutes,curr_seconds)
    if curr_seconds == 0 and curr_minutes == 0:
        get_node("/root/Main/Game").gameui._on_run_wave_pressed(true)
        label.text = "0:00"
        if multiplayer.is_server():
            _sync_timer_values.rpc(curr_minutes,curr_seconds)
        timer.stop()
        countdown_sfx.stop()
    else:
        label.text = "%d:%s" % [curr_minutes,_format_seconds()]
        timer.start()
        
    
    pass # Replace with function body.

func _on_game_wave_started():
    timer.stop()
    countdown_sfx.play()

@rpc("authority","call_local")
func _sync_timer_values(_minutes,_seconds):
    curr_minutes=_minutes
    curr_seconds=_seconds
    label.text = "%d:%s" % [curr_minutes,_format_seconds()]
