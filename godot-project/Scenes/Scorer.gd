extends Node2D

var score: int
var enemy_values = 0
var score_breakdown = {}

var Game
# Called when the node enters the scene tree for the first time.
func _ready():
    Game = get_node("/root/Main/Game")
    pass # Replace with function body.

func score_round(_enemy_values, health):
    # max score = kill all enemies with the most "strategic" purchase of towers
    # good tower buying strategy = ???
    # for now lets just take $ leftover - num towers built + num enemies killed

    
    if GameState.Health <= 0:
        score = _enemy_values
    else:
        score = GameState.Gold * 100 + _enemy_values + health * 100

    score_breakdown = {
        "score": score,
        "enemy_values": _enemy_values,
        "health": health,
        "money": GameState.Gold
    }

    if multiplayer.is_server():
        GameState.score = score
        GameState.score_breakdown = score_breakdown
   
    
func reinitialize():
    enemy_values = 0
    score_breakdown = {}
