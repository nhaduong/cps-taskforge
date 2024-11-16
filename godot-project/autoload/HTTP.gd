extends Node

var url = '<YOUR_URL_HERE>'
var rng: RandomNumberGenerator
var json_headers = ["Content-Type: application/json"]
# Called when the node enters the scene tree for the first time.
func _ready():
    rng = RandomNumberGenerator.new()
    seed(42)

    process_mode = PROCESS_MODE_ALWAYS
#    get_scores()


func _post_data(data, endpoint):
    var http_node = HTTPRequest.new()
    add_child(http_node)
    http_node.request('%s/%s' % [url, endpoint], json_headers, HTTPClient.METHOD_POST, data)

    # result, status code, response headers, and body are now in indices 0, 1, 2, and 3 of response
    var _res = await http_node.request_completed
#    print_debug("posting data ", data) # TODO: add error handling
    http_node.queue_free()

func _get_data(endpoint):
    var http_node = HTTPRequest.new()
    add_child(http_node)
    http_node.request('%s/%s' % [url, endpoint], json_headers, HTTPClient.METHOD_GET)
    var res = await http_node.request_completed
    
    # TODO: add error handling
    var body = res[3].get_string_from_utf8()
    var json = JSON.parse_string(body)
    
    http_node.queue_free()
    return json
    
func post_chat(username: String, chat_text: String, endpoint = "/save_chat"):
    var data = {}
    data["metadata"] = await get_metadata()
    data["data"] = {
        "chat_username": username,
        "chat_text": chat_text
    }

    var json = JSON.stringify(data)
    _post_data(json, endpoint)
    
func get_scores():
    var res = await _get_data("/get_scores")
    if res:
        return res["scores"]
        
    res = await _get_data("/get_scores")
    if res:
        return res["scores"]
    res = await _get_data("/get_scores")
    if res:
        return res["scores"]
    return null

func post_score(level: int, score: int):
    if not multiplayer.is_server():
        return
    var data = {}
    data["metadata"] = await get_metadata()
    data["data"] = {
        "score": score,
        "score_breakdown": GameState.score_breakdown,
        "won": GameState.Health > 0
    }

    var json = JSON.stringify(data)
    await _post_data(json, "/save_score")
    
    
func get_metadata() -> Dictionary:
    await (get_node("/root/Main/Game") != null)
    var game = get_node("/root/Main/Game")
    var client_player_map = {}
    
    var metadata = {
        "build_version": GameState.current_config.build_version,
        "room_id": GameState.room_id,
        "game_id": GameState.game_id,
        "client_player_map": null,
        "current_level": null,
        "current_round": null,
        "timestamp": Time.get_unix_time_from_system(),
        "is_moderated": GameState.has_moderator_teammate,

    }
    
    # add multiplayer metadata if game is running
    if game.players_setup.size() > 1:
        metadata["client_submitting_data"] = multiplayer.get_unique_id()
        metadata["current_level"] = GameState.level_id
        metadata["current_round"] = GameState.num_times_played
    
        for _player in game.players_setup.values():
            client_player_map[_player.peer_id] = _player.get_dict()
    
        metadata["client_player_map"] = client_player_map
    
    if metadata["game_id"] == "":
        metadata["game_id"] = metadata["room_id"].split("-")[0]
    
    # add experiment parameter metadata
    metadata["experiment_parameters"] = GameState.current_config.get_experiment_parameter_metadata()

    return metadata
