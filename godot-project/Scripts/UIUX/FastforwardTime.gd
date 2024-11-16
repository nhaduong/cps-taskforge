# change engine time scale so that
# players can fast forward the game

extends Button

func _on_toggled(_button_pressed):
    _cycle_fastforward.rpc(_button_pressed)
        
@rpc("any_peer","call_local")
func _cycle_fastforward(value : bool):
    if value:
        text = "4x"
        Engine.time_scale = 4
    else:
        text = "1x"
        Engine.time_scale = 1

    if multiplayer.is_server():
        Http.post_chat("System","<action>FASTFORWARD</action> <value>%d</value>" % Engine.time_scale)
    
func set_fastforward(value):
    Engine.time_scale = value
    text = "%dx" % value
    button_pressed = false
