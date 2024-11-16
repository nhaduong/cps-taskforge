extends Game


signal s_end_round(result)


func _increment_level():

    if GameState.has_moderator_teammate and GameState.proxy_server_id == -1:
        var _peer_ids = players_setup.keys()
        for _peer in _peer_ids:
            if _peer != 1:
                _set_proxy_server_id.rpc(_peer)
                break


    if not gameui.visible:
        gameui.visible = true
    if GameState.level_id == LevelProgressions.size() - 1 and GameState.num_times_played == Config.current_num_rounds_per_level - 1:
        # print_debug("experiment complete! you can exit the game")
        gameui.show_ui("ExperimentDone")
        return

    if GameState.num_times_played == Config.current_num_rounds_per_level - 1 or \
            GameState.num_times_played == CurrentLevel.num_rounds_for_this_level_override - 1 \
            :
        GameState.level_id += 1
        CurrentLevel = LevelProgressions[GameState.level_id]
        
        GameState.num_times_played = 0

        
    else:
        GameState.num_times_played += 1
    
    map_scene = CurrentLevel.Map
    GameState.score = 0

    gameui.hide_ui("correct")
    gameui.hide_ui("RestartExperiment")
    if GameState.instruction_follower == multiplayer.get_unique_id():
        $HUD/GameUI/TargetObjectContainer.visible = false

    reload_map()

    await get_tree().process_frame

    get_tree().set_pause(false)

    
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

    
func _end_round(correct, target_object):
    if not multiplayer.is_server(): return
    correct = $Map.target_object == correct
    print("trying to end round!", correct, target_object)
    if correct:
        gameui.show_ui.rpc("correct", {})
    else:
        gameui.show_ui.rpc("correct", {"correct_answer": target_object})

func reload_map():
    remove_child(map)
    map.queue_free()

    map = map_scene.instantiate()
    map.name = 'Map'
    add_child(map)

    # maybe delete
    # set the grid for all players
    for player in players_setup.values():
        player.cursor.set_grid(CurrentLevel.grid)

    gameui.hide_ui("correct")

    if not map.is_connected("s_on_object_selected", _end_round):
        map.s_on_object_selected.connect(_end_round)

func _on_Cursor_accept_pressed(cell: Vector2) -> void:
    pass

func _unhandled_input(event: InputEvent) -> void:
    pass
