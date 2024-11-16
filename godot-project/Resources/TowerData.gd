extends Resource

class_name TowerData

@export var display_name := ""
@export var fire_animation := "fire"
@export var idle_animation := "idle"
@export var tower_type : int
@export var description = "A basic tower that attacks enemies."
@export var fireRate := 1.0
@export var dmg := 1.0
@export var duration := 1.0
@export var range := 1.0
@export var icon: Texture
@export var cost: int
@export var element := 1
@export var range_upgrade_costs = [0,10,30,50,100]
@export var damage_upgrade_costs =  [0,30,100,300,450]
@export var firerate_upgrade_costs = [0,20,80,150,250]
@export var duration_upgrade_costs = [0,30,100,300,450]
@export var hotkey_label := ""
@export var tower_to_instantiate := "base"
# Make sure that every parameter has a default value.
# Otherwise, there will be problems with creating and editing
# your resource via the inspector.
func _init(p_fireRate = 10, p_dmg = 1, p_range=400, p_icon = null,
p_cost = 10):
    fireRate = p_fireRate
    dmg = p_dmg
    icon = p_icon
    range = p_range
    cost = p_cost

    if tower_type < 9:
        hotkey_label = "%d" % (tower_type+1)
    elif tower_type == 9:
        hotkey_label = "0"
    elif tower_type == 10:
        hotkey_label = "Q"
    elif tower_type == 11:
        hotkey_label = "W"
    elif tower_type == 12:
        hotkey_label = "E" 
