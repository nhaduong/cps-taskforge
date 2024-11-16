extends "res://Scenes/Screens/ReadyScreen.gd"

func set_status(peer_id: int, status: String) -> void:
    print("setting status for ", peer_id)
    var status_node = status_container.get_node(str(peer_id))
    var role = ""
    if GameState.instruction_follower == peer_id:
        role = "instruction FOLLOWER"
    elif GameState.instruction_giver == peer_id:
        role = "instruction GIVER"
    if status_node:
        status_node.set_status(status + " " + role)
@rpc("any_peer","call_local")
func _set_follower_status(peer_id: int):
    var status_node = status_container.get_node(str(peer_id))
    var _status = status_node.get_status()
    if "ready" in _status.to_lower():
        status_node.set_status("Ready! " + "INSTRUCTION FOLLOWER")
    else:
        status_node.set_status("INSTRUCTION FOLLOWER")
@rpc("any_peer","call_local")
func _set_giver_status(peer_id: int):
    var status_node = status_container.get_node(str(peer_id))
    var _status = status_node.get_status()
    if "ready" in _status.to_lower():
        status_node.set_status("Ready! " + "INSTRUCTION GIVER")
    else:
        status_node.set_status("INSTRUCTION GIVER")
func _on_follower_btn_pressed():
    GameState._set_instruction_follower.rpc(multiplayer.get_unique_id())
    _set_follower_status.rpc(multiplayer.get_unique_id())
func _on_giver_btn_pressed():
    GameState._set_instruction_giver.rpc(multiplayer.get_unique_id())
    _set_giver_status.rpc(multiplayer.get_unique_id())
