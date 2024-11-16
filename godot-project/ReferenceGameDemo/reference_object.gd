extends Area2D

@export var target_name = ""
signal object_selected(_name)
# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    pass

func _input_event(viewport, event, shape_idx):
    if event is InputEventMouseButton and \
            event.button_index == MOUSE_BUTTON_LEFT and \
            event.is_pressed():
                self._on_click()
                
func _on_click():
    # do nothing if instruction giver
    if GameState.instruction_giver == multiplayer.get_unique_id():
        return
    
    object_selected.emit(self.target_name)
    

func _on_mouse_entered():
    pass # Replace with function body.


func _on_mouse_exited():
    pass # Replace with function body.
