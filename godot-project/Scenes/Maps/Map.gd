extends TileMap

@export var enemy_spawner_container: Node2D
@export var enemy_wave_data: Array[EnemyWave]
@export var enemy_spawner_scene: PackedScene
var all_paths: Array
var tracked_enemies: Dictionary = {} # enemy_name : object
var tracked_enemy_data: Dictionary = {} # enemy_name : data, for rpc, only updated by the server

var track_enemy_spawned_across_players = {} # enemy_name : player_id
signal request_to_kill_enemy(name)
signal out_of_enemies

var total_num_enemies_in_level = 0
var total_num_enemies_killed = 0

var Game

var sfx_player := AudioStreamPlayer.new()

func register_enemy_spawned(player_id, enemy_name):
    if enemy_name not in track_enemy_spawned_across_players.keys():
        track_enemy_spawned_across_players[enemy_name] = []
    track_enemy_spawned_across_players[enemy_name].append(player_id)
    # print(enemy_name, " is registered", tracked_enemies)
func is_ready_to_spawn_next_enemy():
    for enemies in track_enemy_spawned_across_players.values():
        if enemies.size() != Game.players_setup.keys().size():
            return false
    return true
@rpc("authority", "call_local")
func continue_spawning_enemies():
    for spawner in enemy_spawner_container.get_children():
        spawner.continue_spawning_enemies()
func _ready():
    Game = get_node("/root/Main/Game")
    if GameState.current_config.current_show_coordinate_grid_on_map:
        _label_tiles()

    add_child(sfx_player)
    sfx_player.volume_db = -10
    sfx_player.process_mode = Node.PROCESS_MODE_ALWAYS
    
    all_paths = get_node("Paths").get_children()
    
    for child in enemy_spawner_container.get_children():
        child.queue_free()

    track_enemy_spawned_across_players = {}
        
    total_num_enemies_in_level = 0
    total_num_enemies_killed = 0
    for i in range(enemy_wave_data.size()):
        var enemy_wave = enemy_wave_data[i]
        var _enemy_spawner = enemy_spawner_scene.instantiate()
        _enemy_spawner.set_data(enemy_wave.wave, enemy_wave.wave_count, all_paths[enemy_wave.spawner_id], i, enemy_wave.delay)
        enemy_spawner_container.add_child(_enemy_spawner)
        # print_debug(_enemy_spawner, enemy_wave.delay)

        for count in enemy_wave.wave_count:
            total_num_enemies_in_level += count

    Game = get_node("/root/Main/Game")


@rpc("any_peer", "call_local")
func enemy_in_tracked(enemy_name):
    return tracked_enemies.has(enemy_name)


# label the map with coordinates
func _label_tiles():
    var used_cells = get_used_cells(0)
    for coord in used_cells:
        var label = Label.new()
        label.horizontal_alignment = 1
        label.vertical_alignment = 1
        label.text = str(coord)
        $CellLabelsContainer.add_child(label)
        var local_pos = map_to_local(coord)
        label.position = local_pos
        label.position.x -= label.size.x / 2
        label.position.y -= label.size.y / 2

@rpc("any_peer", "call_local")
func set_enemy_info(enemy_name, health, pos):
    if enemy_name not in tracked_enemies:
        print_debug("enemy key %s missing from tracked enemies dict" % enemy_name, tracked_enemies.keys(), " ", multiplayer.get_unique_id())
        return
    tracked_enemies[enemy_name].Health = health
    tracked_enemies[enemy_name].position = pos
    
func update_enemy_info(enemy_name, remote_sender_id):
    if enemy_name not in tracked_enemies:
#        print_debug("enemy key %s missing from tracked enemies dict" % enemy_name, tracked_enemies.keys(), " ", multiplayer.get_unique_id())
        return
        
    set_enemy_info.rpc_id(remote_sender_id, enemy_name, \
    tracked_enemies[enemy_name].Health, tracked_enemies[enemy_name].position)

@rpc("any_peer", "call_local")
# this is used when we are syncing data from server
func update_enemy_state(data: Dictionary) -> void:
#    print_debug("updating local enemy state for client %d from caller %d" % [multiplayer.get_unique_id(),multiplayer.get_remote_sender_id()])
    for key in data.keys():
        var value = data[key]
        
        if not key in tracked_enemies:
            # print_debug("enemy key %s missing from tracked enemies dict" % key, tracked_enemies.keys(), " ", multiplayer.get_unique_id())
            continue

        if get_node(key) == null:
            print(key, " node doesn't exist, a bort")
            continue

        # print_debug("updating enemy %s hp on client %d. current hp: %d, server hp: %d" % [key,
#        multiplayer.get_unique_id(),value["hp"],tracked_enemies[key].Health])    
        tracked_enemies[key].Health = value["hp"]
        # probably need to interpolate/have fuzzy check this so it isn't jittery
        if tracked_enemies[key].position.distance_to(value["pos"]) > 5:
            print_debug("local enemy pos %v being updated to server value %v" % [tracked_enemies[key].position, value["pos"]])
            tracked_enemies[key].position = value["pos"]
        
        # i think the only thing we care about is killing the enemy when syncing states?
        # since base_enemy will locally handle doing damage to the player and killing itself
        # with do_damage()
    

func _on_enemy_spawner_enemy_spawned(enemy_obj):
#    print_debug("registering newly spanwed enemy: %s" % enemy_obj.get_path())
    tracked_enemies[enemy_obj.name] = enemy_obj
    tracked_enemy_data[enemy_obj.name] = {
        "hp": enemy_obj.Health,
        "pos": enemy_obj.position,
        "abs_path": enemy_obj.get_path()
    }
    enemy_obj.hit.connect(_on_enemy_hit)
    enemy_obj.move.connect(_on_enemy_move)
    enemy_obj.need_to_kill_self.connect(_on_enemy_need_to_kill_self.bind())
    
    # tell host we have spawned an enemy with obj name
    Game.register_enemy_spawned.rpc_id(1, enemy_obj.name)

func _on_enemy_need_to_kill_self(enemy_name) -> void:
    if !multiplayer.is_server():
        # print("request to kill enemey")
        request_to_kill_enemy.emit(enemy_name)
    else:
        # print("time to kill enemy")
        kill_enemy.rpc(enemy_name)
        
func _on_enemy_hit(enemy_name, hp, damage_source) -> void:
    if tracked_enemy_data.has(enemy_name):
        tracked_enemy_data[enemy_name]["hp"] = hp
    if tracked_enemies.has(enemy_name):
        tracked_enemies[enemy_name].Health = hp
    if damage_source == 0:
        sfx_player.stream = load("res://Audio/SFX/sfx_enemy_hit.ogg")
    elif damage_source == 1:
        sfx_player.stream = load("res://Audio/SFX/sfx_enemy_poison.ogg")
    sfx_player.play()
    
func _on_enemy_move(enemy_name, pos) -> void:
    if tracked_enemy_data.has(enemy_name):
        tracked_enemy_data[enemy_name]["pos"] = pos
    if tracked_enemies.has(enemy_name):
        tracked_enemies[enemy_name].position = pos

@rpc("any_peer", "call_local")
func kill_enemy(_name):
    if not _name in tracked_enemies:
        print_debug(_name, " not in tracked enemies? killing enemy ", tracked_enemies.keys(), " client ", multiplayer.get_unique_id())
        return
    get_node(str(tracked_enemy_data[_name]["abs_path"]))
    print("kill enemey ", _name, "path, ", tracked_enemy_data[_name]["abs_path"], get_node(str(tracked_enemy_data[_name]["abs_path"])))
    if get_node(str(tracked_enemy_data[_name]["abs_path"])) == null:
        print(_name, " is null for ", multiplayer.get_unique_id())

    print("trakced enemy health: ", tracked_enemies[_name].Health, " ", _name, " ", multiplayer.get_unique_id(), get_node(str(tracked_enemy_data[_name]["abs_path"])))
    if tracked_enemies[_name].Health <= 0:
        sfx_player.stream = load("res://Audio/SFX/sfx_enemy_dies.ogg")
        sfx_player.play()
    
    var earn_money = tracked_enemies[_name].Health <= 0
    if tracked_enemies[_name] == null:
        print("somehow we became null before we got to kill in this round ", _name)

    if tracked_enemies[_name] != null:
        tracked_enemies[_name].kill()
    else:
        print(_name, " was null, not running kill method")

    if GameState.current_config.current_is_rts and earn_money:
        if multiplayer.is_server():
            var money_to_earn = tracked_enemies[_name].enemy_config.money_earned_on_death
            get_node("/root/Main/Game").submit_purchase_request.rpc_id(1, false, -money_to_earn, "enemy_killed", self.name, multiplayer.get_unique_id(), Game.current_player.username, )

    print("erasing tracked enemies ", _name, " ", tracked_enemies.erase(_name))
    print("erasing tracked enemy data ", _name, " ", tracked_enemy_data.erase(_name))
    

    total_num_enemies_killed += 1

    if total_num_enemies_killed == total_num_enemies_in_level:
        out_of_enemies.emit()


@rpc("any_peer", "call_local")
func print_tracked_enemies_keys():
    print_debug("client id %d " % multiplayer.get_unique_id(), " ", tracked_enemies.keys())


func _on_damage_player_area_entered(area):
    if multiplayer.is_server():
        if "Enemy" in area.name:
            area.damage_player.rpc()
            area.need_to_kill_self.emit(area.name)
#            print_debug("trying to damage player")
    pass # Replace with function body.
