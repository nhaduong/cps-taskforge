extends Resource
class_name GameConfig

# update this to keep track of your builds!
@export var build_version: String = "1.0.0.41"
@export_group("Game Parameters")
@export_subgroup("Unit Types")
# arrays because our units are given an idx
# so we look up the unit config file
@export var tower_types: Array[TowerData]
@export var enemy_types: Array[Enemy]
@export var tower_types_objects: Dictionary = {
    "base": preload("res://Scenes/Towers/BaseTower.tscn"),
    "fear": preload("res://Scenes/Towers/FearTower.tscn"),
    "freeze": preload("res://Scenes/Towers/FreezeTower.tscn"),
    "support": preload("res://Scenes/Towers/SupportTower.tscn"),
}
@export_subgroup("UI")
# used to give players different textchat and tower highlight colors
# can set to random colors later to support N players
@export var username_chat_colors: Array[Color]

# these are the parameters you want to adjust when
# running different experiments
@export_group("Experiment parameters")
# the levels in the experiment. these will be played 
# in order
@export var level_progression: Array[LevelData]
@export var num_rounds_per_level: int = 3
@export var text_chat_enabled: bool = true
@export var voice_chat_enabled: bool = false
@export var push_to_talk: bool = false
@export var shared_player_resources: bool = true
# can players sell/upgrade towers placed by other players
@export var can_modify_other_players_towers: bool = false
@export var show_enemy_preview_panel: bool = true
@export var is_rts: bool = false
@export var show_tower_name: bool = false
@export var show_tower_description: bool = true
@export var continue_to_next_level_automatically: bool = false
@export var show_coordinate_grid_on_map: bool = true
# add any internal notes you want logged into metadata
@export_group("Internal Notes")
@export var experiment_reference_id = ""
@export var is_remote_exp = true # is experiment being run remotely
@export_subgroup("Nakama")
@export var nakama_server_key: String = 'defaultkey'
@export var nakama_host: String = '198.12.103.208'
@export var nakama_port: int = 7350
@export var nakama_scheme: String = 'http'
@export_subgroup("Data Logging")
@export var do_data_logging: bool = false
@export var data_logging_server_url: String

# Internal modified config variables, useful in the future when you can
# run multiple experiment sessions in one game session

var current_level_progression: Array[LevelData]
var current_num_rounds_per_level: int = 3
var current_text_chat_enabled: bool = true
var current_voice_chat_enabled: bool = false
var current_push_to_talk: bool = false
var current_shared_player_resources: bool = true
# can players sell/upgrade towers placed by other players
var current_can_modify_other_players_towers: bool = false
var current_show_enemy_preview_panel: bool = true
var current_is_rts: bool = false
var current_show_tower_name: bool = false
var current_show_tower_description: bool = true
var current_continue_to_next_level_automatically: bool = false
var current_show_coordinate_grid_on_map: bool = true


# used to auto create tower icons in the purchase panel
var tower_data_map: Dictionary = {}
var tower_scenes_map_to_idx: Dictionary = {}

func _init():
    reintialize()
    GameState.current_config = self
        
func reintialize():
    tower_data_map.clear()
    for tower in tower_types:
        tower_data_map[tower.tower_type] = tower
    for tower in tower_types_objects.values():
        var tempTower = tower.instantiate()
        tower_scenes_map_to_idx[tempTower.tower_type] = tower
        tempTower.queue_free()

    current_level_progression = level_progression
    current_num_rounds_per_level = num_rounds_per_level
    current_text_chat_enabled = text_chat_enabled
    current_voice_chat_enabled = voice_chat_enabled
    current_push_to_talk = push_to_talk
    current_shared_player_resources = shared_player_resources
    current_can_modify_other_players_towers = can_modify_other_players_towers
    current_show_enemy_preview_panel = show_enemy_preview_panel
    current_is_rts = is_rts
    current_show_tower_name = show_tower_name
    current_show_tower_description = show_tower_description
    current_continue_to_next_level_automatically = continue_to_next_level_automatically
    current_show_coordinate_grid_on_map = show_coordinate_grid_on_map

func get_experiment_parameter_metadata() -> Dictionary:
    return {
        "num_rounds_per_level": current_num_rounds_per_level,
        "text_chat_enabled": current_text_chat_enabled,
        "voice_chat_enabled": current_voice_chat_enabled,
        "push_to_talk": current_push_to_talk,
        "shared_player_resources": current_shared_player_resources,
        "can_modify_other_players_towers": current_can_modify_other_players_towers,
        "show_enemy_preview_panel": current_show_enemy_preview_panel,
        "is_rts": current_is_rts,
        "show_tower_name": current_show_tower_name,
        "show_tower_description": current_show_tower_description,
        "continue_to_next_level_automatically": current_continue_to_next_level_automatically,
        "show_coordinate_grid_on_map": current_show_coordinate_grid_on_map,
        "experiment_reference_id": experiment_reference_id,
        "is_remote_experiment": is_remote_exp
    }
