extends Panel


@onready var close_btn = $Close
@onready var label = $RichTextLabel

@export var scores_child_scene: PackedScene
@export var scores_listing: Control
# Called when the node enters the scene tree for the first time.
func _ready():
    visible = false
#
#func _start():
#    visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.

func set_score_info(score_breakdown, end_of_exp = false):
    if score_breakdown["health"] <= 0:
        label.text = "You DIED!\nFinal Score:\n%d" % score_breakdown["enemy_values"]
    else:
        label.text = "You WON!\n\n
        Enemies:%d\n\
        Money left:%d x 10 = %d\n\
        Health:%d x 100 = %d\n\
        Final score:%d" \
        % [ \
            score_breakdown["enemy_values"],
        GameState.Gold, GameState.Gold * 10,
        GameState.Health, GameState.Health * 100,
        score_breakdown["score"]
        ]
        
    if not end_of_exp:
        label.text += "\n\nTry to get a higher score next time by spending less money and/or killing more enemies!"

    if end_of_exp:
        label.text += "\nEnd of experiment! Thanks for participating!"
        

    else:
        get_node("/root/Main/Game").gameui.countdown_next_round.start_countdown()

func set_current_level_leaderboard(need_to_highlight_current_score = true):
    for child in scores_listing.get_children():
        child.queue_free()
        
    # we only care about scores for current level
    if GameState.level_id == -1:
        return
        
    var scores = await Http.get_scores()

    if not scores:
        return
    
    if need_to_highlight_current_score and visible == true:
#        print_debug("pause set true here in line 57 of GoToNextRound.gd")
#        get_tree().set_pause(true)
        pass
    
#    print_debug("scores from set leaderboard ", scores)
    if str(GameState.level_id) not in scores.keys():
        # print_debug("level is not in scores, retrying get scores 1x")
        scores = await Http.get_scores()
    if str(GameState.level_id) not in scores.keys():
        # print_debug("level still not in scores. abort")
        if visible:
            # print_debug("pause set true here in line 77 of GoToNextRound.gd")
            get_tree().set_pause(true)
        return
    var curr_level_scores = scores[str(GameState.level_id)]
    # sort the scores from highest to lowest
    curr_level_scores.sort_custom(func(a, b): return a["score"] > b["score"])
#    print_debug("scores from set leaderboard sorted ", scores)
    for score in curr_level_scores:
        
        # if score["game_id"].strip_edges().to_lower() in ["test", "can you beat me", "delete me"]:
        #     continue

        if str(GameState.current_config.current_is_rts) != score["rts_mode"]:
            continue
            
        var _score_listing = scores_child_scene.instantiate()
        var score_listing = _score_listing.scores_child
        score_listing.set_data(score["game_id"], score["score"])
        scores_listing.add_child(_score_listing)
        
        # print_debug("need to highlight score: ", need_to_highlight_current_score, " ", \
        # score["score"], "  global score ", GameState.score, \
        # " ", score["score"] == GameState.score, score["room_id"], " global room id ", GameState.room_id)
        
        if need_to_highlight_current_score and \
        int(score["score"]) == GameState.score and \
        score["room_id"] == GameState.room_id:
            
            need_to_highlight_current_score = false
        elif score["room_id"] == GameState.room_id:
            _score_listing.bg.color.a = .65
        else:
            _score_listing.bg.color.a = 0
    
    if visible:
        # print_debug("pause set true here in line 77 of GoToNextRound.gd")
        get_tree().set_pause(true)

func _on_visibility_changed():
    if not get_node("/root/Main/Game").game_started:
        return
    if GameState.has_moderator_teammate:
        if not multiplayer.is_server():
            close_btn.visible = false
            close_btn.disabled = true
    if not multiplayer.is_server() and not multiplayer.get_unique_id() == GameState.proxy_server_id:
        close_btn.visible = false
        close_btn.disabled = true
    if not visible:
        # print_debug("pause set false here line 86 in GoToNextRound.gd")
        get_tree().set_pause(false)
#        set_current_level_leaderboard()
    pass # Replace with function body.

func _on_close_pressed():
    visible = false
    # print_debug("pause set false here line 92 in GoToNextRound.gd")
    get_tree().set_pause(false)
    

func _on_leaderboard_2_pressed():
    set_current_level_leaderboard(false)
    visible = true
    pass # Replace with function body.
