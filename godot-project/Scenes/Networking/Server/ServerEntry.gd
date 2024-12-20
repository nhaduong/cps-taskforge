extends Control

@onready var _server: WebSocketServer = $WebSocketServer
@onready var _log_dest = $Panel/VBoxContainer/RichTextLabel
@onready var _listen_port = $Panel/VBoxContainer/HBoxContainer/port
@onready var _url = $Panel/VBoxContainer/HBoxContainer/url

const PORT = 4433
func info(msg):
    print_debug(msg)
    _log_dest.add_text(str(msg) + "\n")

# Called when the node enters the scene tree for the first time.
func _ready():
    
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    pass


# Server signals
func _on_web_socket_server_client_connected(peer_id):
    var peer: WebSocketPeer = _server.peers[peer_id]
    info("Remote client connected: %d. Protocol: %s" % [peer_id, peer.get_selected_protocol()])
    _server.send(-peer_id, "[%d] connected" % peer_id)


func _on_web_socket_server_client_disconnected(peer_id):
    var peer: WebSocketPeer = _server.peers[peer_id]
    info("Remote client disconnected: %d. Code: %d, Reason: %s" % [peer_id, peer.get_close_code(), peer.get_close_reason()])
    _server.send(-peer_id, "[%d] disconnected" % peer_id)


func _on_web_socket_server_message_received(peer_id, message):
    info("Server received data from peer %d: %s" % [peer_id, message])
    _server.send(-peer_id, "[%d] Says: %s" % [peer_id, message])
    
func _on_listen_toggled(button_pressed):
    if not button_pressed:
        _server.stop()
        info("Server stopped")
        return
    var port = int(_listen_port.text)
    var err = _server.listen(port)
    if err != OK:
        info("Error listing on port %s" % port)
        return
    info("Listing on port %s, supported protocols: %s" % [port, _server.supported_protocols])
    pass # Replace with function body.
    
@rpc
func place_towers(peer_id,position):
    _server.send(-peer_id, "[%d] placed tower at : %s" % [peer_id, position])
    pass
