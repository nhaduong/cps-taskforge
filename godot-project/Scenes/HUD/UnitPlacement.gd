extends Control

var currTowerPlacing

@export var towerBuyBtnsParent: Container

@export var tower_buy_btn_scene: PackedScene

var game
# Called when the node enters the scene tree for the first time.
func _ready():
    game = get_node("/root/Main/Game")
    pass # Replace with function body.


func initialize():
    # do nothing while players have the same elements
    var all_players_diff_elements = false
    while not all_players_diff_elements:
        var assigned_elements = {}
        for player in game.players_setup.values():
            assigned_elements[player.element_idx] = ""
        if assigned_elements.keys().size() == game.players_setup.keys().size():
            all_players_diff_elements = true
        else:
            await get_tree().process_frame
        
    var element_id = game.current_player.element_idx
    var enabled_towers = []
    if element_id != -1:
        enabled_towers = game.CurrentLevel.AvailableUnits[element_id][GameState.num_times_played]
        if not GameState.has_moderator_teammate:
            if game.players_setup.keys().size() == 2:
                enabled_towers += game.CurrentLevel.AvailableUnits[element_id + 2][GameState.num_times_played]
            if game.players_setup.keys().size() == 3:
                var leftover_towers = game.CurrentLevel.AvailableUnits[3][GameState.num_times_played]
                if element_id < leftover_towers.size():
                    enabled_towers += leftover_towers.slice(element_id, element_id + 1)
        else:
            if game.players_setup.keys().size() == 3:
                enabled_towers += game.CurrentLevel.AvailableUnits[element_id + 2][GameState.num_times_played]
            if game.players_setup.keys().size() == 4:
                var leftover_towers = game.CurrentLevel.AvailableUnits[3][GameState.num_times_played]
                if element_id < leftover_towers.size():
                    enabled_towers += leftover_towers.slice(element_id, element_id + 1)
    # print_debug("%d player with element %d and enabled_towers " % [multiplayer.get_unique_id(),element_id], enabled_towers)
    # print_debug("System-%d" % multiplayer.get_unique_id(),
    # "<user>%s</user> <element_id>%d</element_id> <enabled_towers>%s</enabled_towers> <peer_id>%d</peer_id>" % 
    # [Game.current_player.username,element_id,enabled_towers,Game.current_player.peer_id])
    Http.post_chat("System-%d" % multiplayer.get_unique_id(),
    "<user>%s</user> <element_id>%d</element_id> <enabled_towers>%s</enabled_towers> <peer_id>%d</peer_id> <notes>logging which elements/users have which enabled towers</notes>" %
    [game.current_player.username, element_id, enabled_towers, game.current_player.peer_id])
    for child in towerBuyBtnsParent.get_children():
        child.queue_free()
        
    await get_tree().process_frame
    for tower in GameState.current_config.tower_types:
        var tower_btn = tower_buy_btn_scene.instantiate()
        tower_btn.set_config(GameState.current_config.tower_data_map[tower.tower_type])
        towerBuyBtnsParent.add_child(tower_btn, true)
        tower_btn.name = "TowerType_%d" % tower.tower_type
        
        await get_tree().process_frame
        tower_btn.set_name_label_visible()
        
        if tower.tower_type not in enabled_towers:
            tower_btn.disabled = true
            tower_btn.visible = false
    
    set_tower_buy_btns_enabled(true)
    # rename all the tower buttons again?
    # these tower names are used to refer to specific buttons
    for tower in towerBuyBtnsParent.get_children():
        tower.name = "TowerType_%d" % tower.config.tower_type


func set_tower_buy_btns_enabled(value: bool) -> void:
    for btn in towerBuyBtnsParent.get_children():
        if btn.visible:
            btn.disabled = !value
