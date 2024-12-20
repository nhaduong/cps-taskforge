extends Control

@onready var _client: WebSocketClient = $WebSocketClient
@onready var _log_dest = $Panel/VBoxContainer/RichTextLabel
@onready var _line_edit = $Panel/VBoxContainer/Send/LineEdit
@export var hostUrl = "ws://localhost:8000"

func info(msg):
    print_debug(msg)
    _log_dest.add_text(str(msg) + "\n")


# Client signals
func _on_web_socket_client_connection_closed():
    var ws = _client.get_socket()
    info("Client just disconnected with code: %s, reson: %s" % [ws.get_close_code(), ws.get_close_reason()])


func _on_web_socket_client_connected_to_server():
    info("Client just connected with protocol: %s" % _client.get_socket().get_selected_protocol())


func _on_web_socket_client_message_received(message):
    info("message received: %s" % message)
    


func _on_connect_pressed():
    var err = _client.connect_to_url(hostUrl)
    if err != OK:
        info("Error connecting to host: %s" % [hostUrl])
        return


func _on_send_pressed():
    if _line_edit.text == "":
        return
    _client.send(_line_edit.text)
    _log_dest.text += _line_edit.text + "\n"
    _line_edit.text = ""
    
    pass # Replace with function body.

