extends HBoxContainer

@onready var coordInput = $coordinates
var BaseTower = preload("res://Scenes/Towers/BaseTower.tscn")
# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    pass
    
@rpc("any_peer","call_local")
func _spawn_the_tower():
    var pos = StringHelpers.string_to_vector2(coordInput.text)
    
    var tower = BaseTower.instantiate()
    
    tower.global_position = pos
    add_child(tower,true)
    tower.show()
    
    print_debug("spawning new tower")
func _on_spawn_tower_pressed():
    _spawn_the_tower.rpc()
