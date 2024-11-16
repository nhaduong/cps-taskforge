extends Node

var bg_music_1 := AudioStreamPlayer.new()
var bg_music_2 := AudioStreamPlayer.new()
@onready var volume_tween_1 = get_node("Tween")
@onready var volume_tween_2 = get_node("Tween")
var outgoing_stream
var error_sfx := AudioStreamPlayer.new()

@export var error_sfx_file := "res://Audio/SFX/sfx_error.ogg"

func _ready():
    add_child(error_sfx)
    error_sfx.stream = load(error_sfx_file)
    error_sfx.volume_db = -10
    
func background_music(track):
    # Instructions for removing fancy complicated track swapping, music fading stuff:
    # convert bg_music_1 declaration to bg_music at the start of this script (and delete bg_music_2 declaration)
    # bg_music.stream = load(track) <- uncomment this line and the two after
    # bg_music.autoplay = true
    # add_child(bg_music)
    # comment out everything below, including the music_fade and on_tween_finished functions
    if bg_music_1.playing == true:
        outgoing_stream = bg_music_1
        volume_tween_1 = create_tween()
        music_fade(bg_music_1, volume_tween_1, true)
        bg_music_2.stream = load(track)
        bg_music_2.volume_db = -80
        bg_music_2.autoplay = true
        add_child(bg_music_2)
        bg_music_2.process_mode = Node.PROCESS_MODE_ALWAYS
        volume_tween_2 = create_tween()
        music_fade(bg_music_2, volume_tween_2, false)
    elif bg_music_2.playing == true:
        outgoing_stream = bg_music_2
        volume_tween_2 = create_tween()
        music_fade(bg_music_2, volume_tween_2, true)
        bg_music_1.stream = load(track)
        bg_music_1.volume_db = -80
        bg_music_1.autoplay = true
        add_child(bg_music_1)
        bg_music_1.process_mode = Node.PROCESS_MODE_ALWAYS
        volume_tween_1 = create_tween()
        music_fade(bg_music_1, volume_tween_1, false)
    else:
        volume_tween_1 = create_tween()
        bg_music_1.stream = load(track)
        bg_music_1.volume_db = -80
        bg_music_1.autoplay = true
        add_child(bg_music_1)
        bg_music_1.process_mode = Node.PROCESS_MODE_ALWAYS
        volume_tween_1 = create_tween()
        music_fade(bg_music_1, volume_tween_1, false)

func music_fade(active_stream_player, vol_tween, outgoing):
    if outgoing == true:
        vol_tween.tween_property(active_stream_player, "volume_db", -80, 3)
        vol_tween.play()
        # signal to stop the music, otherwise it would keep playing silently
        vol_tween.finished.connect(on_tween_finished)
    elif outgoing == false:
        vol_tween.tween_property(active_stream_player, "volume_db", -15, 3)
        vol_tween.play()

func on_tween_finished():
    outgoing_stream.stop()
