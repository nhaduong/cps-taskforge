extends Node
class_name Networking

signal message_received(peer_id: int, message)
signal client_connected(peer_id: int)
signal client_disconnected(peer_id: int)

const DEF_PORT = 8080
const PROTO_NAME = "td"
const HOST_URL = "ws://localhost"
var peer = WebSocketMultiplayerPeer.new()

func _init():
    peer.supported_protocols = ["td"]

func _ready():
    multiplayer.peer_connected.connect(self._peer_connected)
    multiplayer.peer_disconnected.connect(self._peer_disconnected)
    multiplayer.server_disconnected.connect(self._close_network)
    multiplayer.connection_failed.connect(self._close_network)
    multiplayer.connected_to_server.connect(self._connected)

    # $AcceptDialog.get_label().horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    # $AcceptDialog.get_label().vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    # Set the player name according to the system username. Fallback to the path.
    # if OS.has_environment("USERNAME"):
    #     _name_edit.text = OS.get_environment("USERNAME")
    # else:
    #     var desktop_path = OS.get_system_dir(0).replace("\\", "/").split("/")
    #     _name_edit.text = desktop_path[desktop_path.size() - 2]
    
func _close_network():
    # stop_game()
    # $AcceptDialog.popup_centered()
    # $AcceptDialog.get_ok_button().grab_focus()
    multiplayer.multiplayer_peer = null
    peer.close()

func _connected():
    print("Connected")
    # _game.set_player_name.rpc(_name_edit.text)


func _peer_connected(id):
    print("Connected %d" % id)
    # _game.on_peer_add(id)


func _peer_disconnected(id):
    print("Disconnected %d" % id)
#    _game.on_peer_del(id)

func _host():
    multiplayer.multiplayer_peer = null
    peer.create_server(DEF_PORT)
    multiplayer.multiplayer_peer = peer
    # _game.add_player(1, _name_edit.text)
    # start_game()
    
func _connect():
    multiplayer.multiplayer_peer = null
    print_debug(HOST_URL + ":" + str(DEF_PORT))
    peer.create_client(HOST_URL + ":" + str(DEF_PORT))
    multiplayer.multiplayer_peer = peer


func _on_button_pressed():
    _host()
    pass # Replace with function body.


func _on_button_2_pressed():
    _connect()
    pass # Replace with function body.
