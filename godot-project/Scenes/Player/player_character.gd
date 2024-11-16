extends Node2D
class_name PlayerCharacter

@onready var mouse_pos = $Cursor
@onready var username_label = $Cursor/ColorRect/username
@onready var cursor = $Cursor
var username: String: get = _get_username
var player_controlled = false
var peer_id: int
var element_idx: int = 0

var temp_tower_buying: BaseTower = null
var temp_tower_buying_cost_hold: int
var num_towers_built = 0

var Game
func get_dict():
    return {"username": username, "peer_id": peer_id, "element_id": element_idx}
# Called when the node enters the scene tree for the first time.
func _ready():
    Game = get_node("/root/Main/Game")
    pass # Replace with function body.
func get_temp_tower_buying():
    return temp_tower_buying


func submit_purchase_request():
    if temp_tower_buying != null:
        # don't try to buy tower if we don't have enough money
        if GameState.Gold < temp_tower_buying.config.cost:
            print_debug("not enough cash to buy tower")
            return

        num_towers_built += 1

        temp_tower_buying.name = "Tower_Type-%d_%d" % \
         [temp_tower_buying.config.tower_type, num_towers_built]

        Game.submit_purchase_request.rpc_id(1, true, temp_tower_buying.config.cost, "", temp_tower_buying.name, multiplayer.get_unique_id(), Game.current_player.username, temp_tower_buying.config.tower_type, cursor.cell)


# temporary purchase attempt, where we spawn a tower under the
# player cursor so they think they can try to buy a tower
func start_tower_buying_process(tower_type: int):
#    print_debug("starting tower buying type %d for player %d on client %d" % [tower_type,player_idx,multiplayer.get_unique_id()])
    Game._deselect_active_unit()
    

    var config = GameState.current_config.tower_types[tower_type]
    var tower = GameState.current_config.tower_types_objects[config.tower_to_instantiate].instantiate()
    tower.set_config(config)
    
    tower.purchased_by_player_id = multiplayer.get_unique_id()
    tower.tower_type = tower_type
    
    tower.position = Vector2.ZERO
    
    var scale_modifier = Game.CurrentLevel.grid.cell_size
    scale_modifier.x /= tower.sprite_width * tower.scale.x
    scale_modifier.y /= tower.sprite_height * tower.scale.y
    tower.set_scale_modifier(scale_modifier)
    tower.set_tower_collision(false)
    cursor.add_child(tower)
    
    temp_tower_buying = tower
    temp_tower_buying_cost_hold = config.cost
    
    tower.show()
        
    if Game.hoverOverValidCell == false:
        tower.show_invalid_tile_style()
    else:
        tower.show_valid_tile_style()

    Game.gameui.tooltip_panel.hide()
    
@rpc("any_peer", "call_local")
func cancel_tower_buying_process():
    if temp_tower_buying != null:
        temp_tower_buying.queue_free()
    temp_tower_buying = null
    temp_tower_buying_cost_hold = 0
    Game._clear_active_unit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
    _move_mouse()
    
    
func _move_mouse():
    var mouse_position = get_node("/root/Main/Game").get_viewport().get_mouse_position() # find the position of mouse in viewport

    # mouse_position -= (get_node("/root/Main/Game").get_viewport_rect().size/2) #adjust for screen size

    mouse_position /= get_node("/root/Main/Game").camera.zoom.x # offset for camera zoom
    mouse_pos.set_cell(mouse_pos.get_cell_from_position(mouse_position))

 
func set_username(_username):
    username_label.text = _username

func _get_username():
    return username_label.text
