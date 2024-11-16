extends VBoxContainer

func _reinitialize():
    if GameState.instruction_follower == multiplayer.get_unique_id():
        self.visible = false
    else:
        self.visible = true
        
        
func set_target_obj_image(tex):
    $target_obj_sprite.texture = tex
