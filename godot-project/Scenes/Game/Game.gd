extends Node2D
class_name Game
@export var playerCharacter = preload("res://Scenes/Player/PlayerCharacter.tscn")
var map_scene: PackedScene # the level we instantiate
var CurrentLevel: LevelData
@export var bullet_pool: BulletPool

# use this to hold all the 3 levels + tutorial we want to progress through
# this is an array of LevelDatas
# every Level is responsible for its own logic in setting up the available resources
# and any other things like displaying tutorial hints
var LevelProgressions: Array

@export var Config: GameConfig

@onready var map: Node2D = $Map
@onready var players_node := $Players
@onready var camera := $Camera2D
@onready var gameui := $HUD/GameUI
@onready var scorer := $Scorer
@onready var MusicController := $MusicController

var game_started := false
var game_over := false
var players_alive := {} # prob delete
var players_setup := {}

var current_player
var queued_tower_buying: BaseTower

var hoverOverValidCell = true

signal s_game_started()
signal s_game_over()
signal wave_started

# holds all placed towers. resets with map reload
var _towers = {} # tower_object : cell_coord
# when cursor clicks on a placed tower, or we are buying a tower
var _selected_tower


# Called when the node enters the scene tree for the first time.
func _ready():
    LevelProgressions = Config.level_progression
    
    # set up progression
    CurrentLevel = LevelProgressions[0]
    GameState.level_id = -1
    GameState.num_times_played = -1
    
    Config.reintialize()

    
    gameui.visible = false
    
    bullet_pool.reinitialize()

func _process(_delta):
    if multiplayer:
        if multiplayer.is_server():
            _process_buy_sell_queue()

func game_start(players: Dictionary) -> void:
    if GameState.online_play:
        _do_game_setup.rpc(players)
    else:
        _do_game_setup(players)

### Set up players
## Element assignment
# we use this to assign players Colors
# and available tower subsets
# For CPS-TaskForge pilot study, we 
# hard code the tower subsets because we
# want to evenly distribute unique towers
# to each player and have 3--4 players
# TODO: (future) if needed,
# redo the element system to be more flexible
@rpc("any_peer")
func _server_assign_players_elements(_player_idxs: Array, _player_elements: Array):
    for i in range(_player_idxs.size()):
        _assign_single_player_element(_player_idxs[i], _player_elements[i])
# Initializes the game so that it is ready to really start.
func _assign_players_elements():
    # print_debug("now assigning player elements for player count: %d by server %d" % [players_setup.keys().size(), multiplayer.get_unique_id()])
    var player_keys = players_setup.keys()
    if GameState.has_moderator_teammate:
        players_setup[1].element_idx = -1
        player_keys.erase(1)
        
    var elements = range(player_keys.size())
    elements.shuffle()
    
    for i in range(elements.size()):
        players_setup[player_keys[i]].element_idx = elements[i]

func _assign_single_player_element(player_id: int, element_id: int):
    players_setup[player_id].element_idx = element_id


# the server needs to tell all the clients to assign each player
# to the same element 
@rpc("authority", "call_remote")
func _assign_players_elements_clients():
    var player_keys = players_setup.keys()
    var player_elements = []
    for key in player_keys:
        player_elements.append(players_setup[key].element_idx)
    for key in players_setup.keys():
        # we don't want to call assign elements again on our server player
        if key != 1:
            _server_assign_players_elements.rpc_id(key, player_keys, player_elements)
func _elements_done_assigning():
    var assigned_elements = {}
    for player in players_setup.values():
        assigned_elements[player.element_idx] = ""
    return assigned_elements.keys().size() == players_setup.keys().size()
@rpc("call_local", "any_peer")
func _do_game_setup(players: Dictionary) -> void:
    get_tree().set_pause(true)

    if game_started:
        game_stop()

    game_started = true
    game_over = false

    var player_number := 1
    for peer_id in players:
        var other_player = playerCharacter.instantiate()
        other_player.name = str(peer_id)
        other_player.peer_id = peer_id

        players_node.add_child(other_player)
        
        players_alive[peer_id] = other_player
        players_setup[peer_id] = other_player
        
        other_player.set_multiplayer_authority(1)
        other_player.set_username(players[peer_id])

        other_player.cursor.accept_pressed.connect(_on_Cursor_accept_pressed)
        other_player.cursor.moved.connect(_on_Cursor_moved)
        other_player.visible = false

        if not GameState.online_play:
            other_player.player_controlled = true
            other_player.input_prefix = "player" + str(player_number) + "_"
            other_player.visible = true

        player_number += 1
        
    if GameState.online_play:
        if multiplayer.is_server():
            _assign_players_elements()
            _assign_players_elements_clients()


    if GameState.online_play:
        var my_id := multiplayer.get_unique_id()
        var my_player := players_node.get_node(str(my_id))
        my_player.player_controlled = true
        
        current_player = my_player
        current_player.visible = true
        
        # Tell the host that we've finished setup.
        _finished_game_setup(my_id)
    else:
        _do_game_start()
        
    _increment_level()
    
@rpc("any_peer", "call_local")
func _set_proxy_server_id(val):
    GameState.proxy_server_id = val

# Records when each player has finished setup so we know when all players are ready.
@rpc("any_peer", "call_local")
func _finished_game_setup(peer_id: int) -> void:
    
    if peer_id in players_alive:
        players_setup[peer_id] = players_alive[peer_id]
    # wait until elements are assigned
    await _elements_done_assigning()
    _tell_server_done_setup()

var players_done_setup = []
@rpc("any_peer", "call_local")
func _register_player_done_setup():
    players_done_setup.append(multiplayer.get_remote_sender_id())

    if players_done_setup.size() == players_setup.keys().size():
        _server_start_game_for_everyone()
func _tell_server_done_setup():
    _register_player_done_setup.rpc_id(1)

### End setting up players

func _server_start_game_for_everyone():
    _do_game_start.rpc()
# Actually start the game on this client.
@rpc("any_peer", "call_local")
func _do_game_start() -> void:
    if map.has_method('map_start'):
        map.map_start()
    s_game_started.emit()
    get_tree().set_pause(false)
    MusicController.background_music("res://Audio/Music/level_1.mp3")
func game_stop() -> void:
    if map.has_method('map_stop'):
        map.map_stop()

    game_started = false
    players_setup.clear()
    players_alive.clear()

    for child in players_node.get_children():
        players_node.remove_child(child)
        child.queue_free()
        
### Reset maps/tracked towers so that the
# next level/round starts fresh
func _reinitialize() -> void:
    _towers.clear()

    for child in $TowersContainer.get_children():
        var unit := child as BaseTower
        if not unit:
            continue
        _towers[unit.cell] = unit
func reload_map() -> void:
    remove_child(map)
    map.queue_free()
    
    # destroy all bullets and towers
    for child in $BulletContainer.get_children():
        child.queue_free()
    for child in $TowersContainer.get_children():
        child.queue_free()

    map = map_scene.instantiate()
    map.name = 'Map'
    add_child(map)
    
    # set the grid for all players
    for player in players_setup.values():
        player.cursor.set_grid(CurrentLevel.grid)

    # set available units depending on the player
    gameui._set_peer_id()
    gameui.unitplacement.initialize()
    scorer.reinitialize()
    gameui.wave_timer.reinitialize()

    # make sure the game is running at 1x speed in case
    # it was set to fastforward during the game
    _set_time_scale.rpc(1)
    

    _deselect_active_unit()
    _clear_active_unit()

    await get_tree().process_frame

    if multiplayer.is_server():
        if not map.is_connected("out_of_enemies", _out_of_enemies):
            map.out_of_enemies.connect(_out_of_enemies)
        if not GameState.is_connected("out_of_health", _out_of_health):
            GameState.out_of_health.connect(_out_of_health)

    gameui.wave_timer.start_timer()


### PURCHASE LOGIC ###
## buy/sell towers and upgrades 
## a purchase request is made and sent to the server
## the server processes the purchase queue every _delta
var buy_sell_queue = [] # obj(is_buy, amount)
@rpc("any_peer", "call_local")
func submit_purchase_request(is_upgrade, amount, stat_type, tower_name, purchaser_id, purchaser_username, tower_type = -1, cell = Vector2(-1, -1)):
    var purchase_request = PurchaseRequest.new(is_upgrade, amount, stat_type, tower_name, purchaser_id, purchaser_username, tower_type, cell)
    # print_debug("game submitting purchase request")
    if multiplayer.is_server():
        buy_sell_queue.append(purchase_request)

@rpc("any_peer", "call_local")
func buy_tower(cell, tower_type, tower_name, purchaser_id):
    var config = Config.tower_types[tower_type]
    var tower = Config.tower_types_objects[config.tower_to_instantiate].instantiate()
    
    tower.set_config(config)
    tower.purchased_by_player_id = purchaser_id
    tower.tower_type = tower_type
    tower.position = CurrentLevel.grid.calculate_map_position(cell)
    
    var scale_modifier = CurrentLevel.grid.cell_size
    scale_modifier.x /= tower.sprite_width * tower.scale.x
    scale_modifier.y /= tower.sprite_height * tower.scale.y
    tower.set_scale_modifier(scale_modifier)
    tower.set_tower_collision(false)

    $TowersContainer.add_child(tower, true)
    tower.name = tower_name
    tower.show()

    tower.cell = cell
    tower.hide_validity_tile_style()
    tower.set_tower_collision(true)
    tower.hide_range_ui()
    tower.SetRange()
    tower._set_upgrade_button_states()
    tower.set_outline_color(Config.username_chat_colors[players_setup[purchaser_id].element_idx])
    
    log_tower(tower, cell)

    var tower_name_msg = config.display_name

    # in pilot study, we replace tower names with "TOWER" instead of
    # showing a blank or informative name
    if OS.has_feature("experiment"):
        tower_name_msg = "Tower"
        
    gameui.add_system_chat_message("%s purchased by %s at %.v" % [tower_name_msg,
        players_setup[purchaser_id].username, cell])
    GameState._set_gold(GameState.Gold - config.cost)

    if multiplayer.get_unique_id() == purchaser_id:
        Http.post_chat(players_setup[purchaser_id].username, "<action>BUY</action> <tower_type>%d</tower_type> <location>%.v</location> <user>%s</user> <peer_id>%d</peer_id>" %
        [tower_type, cell, players_setup[purchaser_id].username, multiplayer.get_unique_id()])

        current_player.cancel_tower_buying_process()
    if GameState.current_config.current_is_rts and GameState.wave_running:
        tower.on_build_try_to_shoot()

func _process_buy_sell_queue():
    if buy_sell_queue.size() > 0:
        while buy_sell_queue.size() > 0:
            var curr_request = buy_sell_queue.pop_front()
            if curr_request.amount > 0:
                if GameState.Gold >= curr_request.amount and \
                (GameState.Gold - curr_request.amount) >= 0:
                    if curr_request.tower_type == -1:
                        var _tower_to_upgrade = get_node("TowersContainer/%s" % curr_request.tower_name)
                        if _tower_to_upgrade:
                            _tower_to_upgrade.make_purchase.rpc(curr_request.is_upgrade, curr_request.amount, curr_request.stat_type, curr_request.tower_name, curr_request.purchaser_id, curr_request.purchaser_username)
                        else:
                            pass
                            # print_debug("could not find tower %s to upgrade" % curr_request.tower_name)
                    else:
                        # buy tower
                        # do nothing if cell occupied
                        if is_occupied(curr_request.cell):
                            continue
                        else:
                            buy_tower.rpc(curr_request.cell, curr_request.tower_type, curr_request.tower_name, curr_request.purchaser_id)
                        pass
            else:
                if curr_request.stat_type == "enemy_killed":
                    if GameState.current_config.current_is_rts:
                        GameState._set_gold.rpc(GameState.Gold - curr_request.amount)
                        continue
                var _tower_to_downgrade = get_node("TowersContainer/%s" % curr_request.tower_name)
                if _tower_to_downgrade:
                    if curr_request.tower_type == -1:
                        _tower_to_downgrade.make_purchase.rpc(curr_request.is_upgrade, curr_request.amount, curr_request.stat_type, curr_request.tower_name, curr_request.purchaser_id, curr_request.purchaser_username)
                    else:
                        _tower_to_downgrade._sell.rpc(curr_request.purchaser_id, curr_request.purchaser_username)

### END PURCHASE LOGIC ###


### Signal logic for ending a level
func _out_of_health():
    if not GameState.wave_running:
        return
    GameState.set_wave_running.rpc(false)
    _set_time_scale.rpc(1)
    # stop the game
    
    # display confirm panel
    print_debug("out of health end round")
    scorer.score_round(scorer.enemy_values, GameState.Health)
    print("scorer done scoring round")
    if multiplayer.is_server():
        if GameState.current_config.do_data_logging:
            Http.post_score(GameState.level_id, scorer.score)
        print("time to set score")
        GameState._set_score.rpc(scorer.score)
        var _msg = "--- FINAL SCORE: %d ---" % scorer.score
        gameui.add_system_chat_message.rpc(_msg)
        
        var _text = "<speaker>SYSTEM</speaker> <chat_text>%s</chat_text>" % [_msg]
        Http.post_chat("System", _text)
        show_next_round_panel.rpc(GameState.score_breakdown)

        if map.is_connected("out_of_enemies", _out_of_enemies):
            map.out_of_enemies.disconnect(_out_of_enemies)
        if GameState.is_connected("out_of_health", _out_of_health):
            GameState.out_of_health.disconnect(_out_of_health)
    
func _out_of_enemies():
    if not GameState.wave_running:
        return
    # stop the game
    GameState.set_wave_running.rpc(false)
    _set_time_scale.rpc(1)
    
    # display confirm panel
    scorer.score_round(scorer.enemy_values, GameState.Health)

    if multiplayer.is_server():
        await Http.post_score(GameState.level_id, scorer.score)
        GameState._set_score.rpc(scorer.score)
        var _msg = "--- FINAL SCORE: %d ---" % scorer.score
        gameui.add_system_chat_message.rpc(_msg)

        var _text = "<speaker>SYSTEM</speaker> <chat_text>%s</chat_text>" % [_msg]
        Http.post_chat("System", _text)
        show_next_round_panel.rpc(GameState.score_breakdown)

        if map.is_connected("out_of_enemies", _out_of_enemies):
            map.out_of_enemies.disconnect(_out_of_enemies)
        if GameState.is_connected("out_of_health", _out_of_health):
            GameState.out_of_health.disconnect(_out_of_health)
    
### End signal logic for ending level

### Level logic
@rpc("call_local", "any_peer")
func set_game_level(level: int):
    GameState.level_id = level
    CurrentLevel = LevelProgressions[GameState.level_id]

@rpc("call_local", "any_peer")
func set_game_round(game_round: int):
    GameState.num_times_played = game_round

@rpc("any_peer", "call_local")
func _increment_level():
    
    bullet_pool.reinitialize()

    if GameState.has_moderator_teammate and GameState.proxy_server_id == -1:
        var _peer_ids = players_setup.keys()
        for _peer in _peer_ids:
            if _peer != 1:
                _set_proxy_server_id.rpc(_peer)
                break
    
    for tower in _towers.values():
        if tower != null:
            tower.queue_free()

    _towers = {}
    
    GameState.set_wave_running.rpc(false)
    
    if not gameui.visible:
        gameui.visible = true
    if GameState.level_id == LevelProgressions.size() - 1 and GameState.num_times_played >= Config.current_num_rounds_per_level - 1:
        gameui.show_ui("ExperimentDone")
        return

    if GameState.num_times_played >= Config.current_num_rounds_per_level - 1 or \
            GameState.num_times_played >= CurrentLevel.num_rounds_for_this_level_override - 1 \
            :
        GameState.level_id += 1
        CurrentLevel = LevelProgressions[GameState.level_id]
        
        GameState.num_times_played = 0

        
    else:
        GameState.num_times_played += 1
    
    map_scene = CurrentLevel.Map
    GameState.Health = CurrentLevel.Health

    GameState.Gold = CurrentLevel.Gold_RTS if GameState.current_config.current_is_rts else CurrentLevel.Gold
    GameState.score = 0
    gameui._set_hp_text()
    gameui._set_gold_text()
    gameui._set_score_text()
    if GameState.current_config.current_is_rts:
        gameui.wave_timer.initialize(CurrentLevel.wave_timer_minutes_RTS, CurrentLevel.wave_timer_seconds_RTS)
    else:
        gameui.wave_timer.initialize(CurrentLevel.wave_timer_minutes_RTS, CurrentLevel.wave_timer_seconds_RTS)
    gameui.hide_ui("GoToNextRound")
    gameui.hide_ui("RestartExperiment")
    get_tree().set_pause(false)
    reload_map()

    await get_tree().process_frame

    get_tree().set_pause(false)
    
    gameui._set_wave_previews(map.enemy_wave_data)
    gameui.reset_ui_to_defaults()
    gameui.stop_countdown()

    var msg = ""
    if GameState.level_id == 0:
        msg = "--- STARTING TUTORIAL LEVEL ---\n"
    else:
        msg = "--- STARTING LEVEL %d ROUND %d ---\n" % \
    [GameState.level_id, GameState.num_times_played + 1]

    gameui.add_system_chat_message(msg)

    if multiplayer.is_server():
        var _text = "<speaker>SYSTEM</speaker> <chat_text>%s</chat_text>" % [msg]
        Http.post_chat("System", _text)

@rpc("any_peer", "call_local")
func play_level(level: int) -> void:
    for tower in _towers.values():
        if tower != null:
            tower.queue_free()

    _towers = {}
    
    GameState.set_wave_running.rpc(false)
    
    if not gameui.visible:
        gameui.visible = true
    
    GameState.level_id = level
    CurrentLevel = LevelProgressions[GameState.level_id]
    
    GameState.num_times_played = 0

    map_scene = CurrentLevel.Map
    GameState.Health = CurrentLevel.Health
    GameState.Gold = CurrentLevel.Gold
    GameState.score = 0
    gameui._set_hp_text()
    gameui._set_gold_text()
    gameui._set_score_text()
    gameui.hide_ui("GoToNextRound")
    gameui.hide_ui("RestartExperiment")
    # print_debug("pause set false here line 551 in Game.gd")
    get_tree().set_pause(false)
    reload_map()
    
    gameui.reset_ui_to_defaults()

### End level logic

### Text Chat
# when you click on [SEND TEXT] in the chat box
func _on_game_ui_text_sent(text):
    # tell server about a new message
    print("on game ui text sent")
    _server_receive_text_message.rpc_id(1, text, multiplayer.get_unique_id(), current_player.username)

@rpc("any_peer", "call_local")
func _server_receive_text_message(text, sender_id, sender_username):
    if multiplayer.is_server():
        var color := Color.GRAY
        if not sender_username:
            sender_username = "User"
        # tell everyone to add a new text chat
        gameui.add_chat_reply.rpc(text, sender_username, color)
    
### End text chat

### Used for manually syncing enemy states across all clients
# TODO: use godot's native syncing
# this is called by each individual enemy
# adjust the polling rate in base_enemy.gd
@rpc("call_remote", "any_peer")
func update_enemy_info(enemy_name):
    map.update_enemy_info(enemy_name, multiplayer.get_remote_sender_id())

# after the board is set up, we call this 
# to run the simulation

# var num_enemy_spawners_running = 0
@rpc("any_peer", "call_local")
func _run_wave():
    wave_started.emit()
    for spawner in $Map/EnemySpawnersContainer.get_children():
        spawner.start_spawning_enemies()
    GameState.set_wave_running.rpc(true)
    gameui.run_wave_callback()
    for tower in _towers.values():
        tower.hide_range_ui()

    current_player.cancel_tower_buying_process()
func _on_game_ui_run_wave_requested(auto_start):
    _deselect_active_unit()
    _clear_active_unit()
    _run_wave.rpc()

    Http.post_chat("System-%d" % multiplayer.get_unique_id(),
    "<action>START</action> <current_level>%d</current_level> <current_round>%d</current_round> <time_at_start>%dMIN%dSEC</time_at_start> <time_remaining>%dMIN%dSEC</time_remaining> <auto_start>%s</auto_start> <user>%s</user> <peer_id>%d</peer_id>" %
    [GameState.level_id, GameState.num_times_played, CurrentLevel.wave_timer_minutes_RTS if GameState.current_config.current_is_rts else CurrentLevel.wave_timer_minutes, CurrentLevel.wave_timer_seconds_RTS if GameState.current_config.current_is_rts else CurrentLevel.wave_timer_seconds, gameui.wave_timer.curr_minutes, gameui.wave_timer.curr_seconds, auto_start, current_player.username, current_player.peer_id])
func _on_game_ui_continue_next_round():
    _increment_level.rpc()

@rpc("call_local", "authority")
func show_next_round_panel(score_breakdown):
    print("showing score panel now")
    gameui.set_score_content(score_breakdown, GameState.level_id == LevelProgressions.size())
    gameui.show_ui("GoToNextRound")

### Tower registration ###
func log_tower(tower, location):
    _towers[location] = tower
func remove_tower_from_log_by_coord(coord):
    if coord in _towers:
        _towers.erase(coord)
func remove_tower_from_log_by_tower(tower):
    if tower in _towers.values():
        var _key = _towers.find_key(tower)
        _towers.erase(_key)
### End registering towers         


### Enemy spawn logic
# manually polled for because of multiplayer syncing
# and our manual enemy behavior syncing logic
# We want to make sure enemies spawn at the same time 
# across all clients
@rpc("any_peer", "call_local")
func register_enemy_spawned(enemy_name):
    map.register_enemy_spawned(multiplayer.get_remote_sender_id(), enemy_name)

    if multiplayer.is_server():
        client_can_spawn_next_enemy()

func client_can_spawn_next_enemy():
    if map.is_ready_to_spawn_next_enemy():
        map.continue_spawning_enemies.rpc()

## Inputs
func _select_tower(cell: Vector2):
    if not _towers.has(cell):
        return
    _selected_tower = _towers[cell]
    _selected_tower.show_menu()

func is_occupied(cell: Vector2) -> bool:
    return true if _towers.has(cell) else false
func is_invalid_cell(cell: Vector2) -> bool:
    if map.get_cell_atlas_coords(0, cell, false) in CurrentLevel.valid_buy_tiles:
        return false
    
    return true
func _on_Cursor_moved(cell: Vector2) -> void:
    # print_debug("mouse moved, eating input?")
    if current_player.temp_tower_buying != null:
        if is_occupied(cell) or is_invalid_cell(cell):
            current_player.temp_tower_buying.show_invalid_tile_style()
            hoverOverValidCell = false
        else:
            current_player.temp_tower_buying.show_valid_tile_style()
            hoverOverValidCell = true
    else:
        if is_occupied(cell) or is_invalid_cell(cell):
            hoverOverValidCell = false
        else:
            hoverOverValidCell = true
            
func _on_Cursor_accept_pressed(cell: Vector2) -> void:
    # print_debug("cursor accept pressed")

    if not gameui.chat_box.is_mouse_entered:
        gameui.chat_box.text_edit.release_focus()
        gameui.chat_box.text_edit.hide()
        gameui.chat_box.text_edit.show()

    # we only try to buy tower for our own player
    # if we do need to buy this then we go tell all the other clients to buy the tower
    if current_player.temp_tower_buying != null:
        if is_occupied(cell) or is_invalid_cell(cell):
            MusicController.error_sfx.play()
            # print_debug("not allowed to buy tower on occupied invalid cell!")
            return
        # print_debug("trying to buy tower for current player")
        current_player.submit_purchase_request()
        return

    # we don't want to do anything if we clicked over a button
    if gameui.button_is_hovered:
        # print_debug("gameui button  is hovered, do nothing")
        return

    # are we trying to select a tower
    if is_occupied(cell):
        # don't select tower if it was built by someone else
        if _towers.has(cell):
            var _tower_check = _towers[cell]
            if _tower_check.purchased_by_player_id != current_player.peer_id and \
                        !Config.current_can_modify_other_players_towers:
                # print("not selecting tower because it was built by someone else")
                return
        # print_debug("selecting existing tower if exists")
        _deselect_active_unit()
        _select_tower(cell)
    else: # did we click on map randomly
        # print_debug("clicked on map randomly, deselecting everything")
        
        _deselect_active_unit()
        _clear_active_unit()

func _unhandled_input(event: InputEvent) -> void:

    if event.is_action_pressed("ui_cancel"):
        _deselect_active_unit()
        _clear_active_unit()

    # upgrading hotkeys
    if _selected_tower and event is InputEventKey and event.pressed:
        if !event.shift_pressed:
            if event.is_action_pressed("upgrade_hk"):
                if event.keycode == KEY_R:
                    _selected_tower.upgrade_hotkey("range")
                elif event.keycode == KEY_F:
                    _selected_tower.upgrade_hotkey("firerate")
                elif event.keycode == KEY_D:
                    _selected_tower.upgrade_hotkey("duration")
                elif event.keycode == KEY_S:
                    _selected_tower.upgrade_hotkey("damage")
        else:
            if event.is_action_pressed("downgrade_hk"):
                if event.keycode == KEY_R:
                    _selected_tower.downgrade_hotkey("range")
                elif event.keycode == KEY_F:
                    _selected_tower.downgrade_hotkey("firerate")
                elif event.keycode == KEY_D:
                    _selected_tower.downgrade_hotkey("duration")
                elif event.keycode == KEY_S:
                    _selected_tower.downgrade_hotkey("damage")

func _deselect_active_unit():
    # if the upgrade menu is open, close it
    if _selected_tower != null:
        _selected_tower.hide_menu()
        if not _selected_tower._is_mouse_entered:
            if _selected_tower.info_panel:
                _selected_tower.info_panel.hide()

    # if we are buying a tower and decide to Cancel it, destroy the temp tower
    if current_player != null:
        current_player.cancel_tower_buying_process()

func _clear_active_unit():
    _selected_tower = null
    pass

## End Inputs

# scoring
func accumulate_enemy_killed_value(value):
    scorer.enemy_values += value
    if multiplayer.is_server():
        GameState._set_score.rpc(scorer.enemy_values)
# utilities
@rpc("any_peer", "call_local")
func _set_time_scale(value):
    gameui.set_time_scale(value)

func set_nakama_config():
    Online.nakama_server_key = Config.nakama_server_key
    Online.nakama_host = Config.nakama_host
    Online.nakama_port = Config.nakama_port
    Online.nakama_scheme = Config.nakama_scheme
