extends Node

# For developers to set from the outside, for example:
#   Online.nakama_host = 'nakama.example.com'
#   Online.nakama_scheme = 'https'

# local
var nakama_server_key: String = 'defaultkey'
var nakama_host: String = 'localhost'
var nakama_port: int = 5555
var nakama_scheme: String = 'http'

# For other scripts to access:
var nakama_client: NakamaClient : set = _set_nakama_client, get = _get_nakama_client
var nakama_session: NakamaSession : set = set_nakama_session
var nakama_socket: NakamaSocket : set = _set_nakama_socket, get = _get_nakama_socket

var _storage_worker: StorageWorker
var _exception_handler := ExceptionHandler.new()
var _authenticator : Authenticator

# Internal variable for initializing the socket.
var _nakama_socket_connecting := false

signal session_changed (nakama_session)
signal session_connected (nakama_session)
signal socket_connected (nakama_socket)

func _set_readonly_variable(_value) -> void:
    pass

func _ready() -> void:
    # Don't stop processing messages from Nakama when the game is paused.
#    Nakama.pause_mode = Node.PROCESS_MODE_ALWAYS
    pass

func _get_nakama_client() -> NakamaClient:
    if nakama_client == null:
        print_debug("setting new nakama client")
        var client = Nakama.create_client(
            nakama_server_key,
            nakama_host,
            nakama_port,
            nakama_scheme,
            Nakama.DEFAULT_TIMEOUT,
            NakamaLogger.LOG_LEVEL.ERROR)
        _set_nakama_client(client)

    return nakama_client
func _set_nakama_client(client: NakamaClient) -> void:
    nakama_client = client
func _get_nakama_socket() -> NakamaSocket:
#    if nakama_socket == null:
#        connect_nakama_socket()
    return nakama_socket
        
func set_nakama_session(_nakama_session: NakamaSession) -> void:
    nakama_session = _nakama_session

    emit_signal("session_changed", nakama_session)

    if nakama_session and not nakama_session.is_exception() and not nakama_session.is_expired():
        emit_signal("session_connected", nakama_session)
    
    _authenticator = Authenticator.new(nakama_client, _exception_handler)
    _storage_worker = StorageWorker.new(nakama_session, nakama_client, _exception_handler)
    
func _set_nakama_socket(socket: NakamaSocket) -> void:
    nakama_socket = socket
func connect_nakama_socket() -> void:
    if nakama_socket != null:
        return
    if _nakama_socket_connecting:
        return
    _nakama_socket_connecting = true

    var new_socket = Nakama.create_socket_from(nakama_client)
    await new_socket.connect_async(nakama_session)
    
    nakama_socket = new_socket
    _nakama_socket_connecting = false

    emit_signal("socket_connected", nakama_socket)

func is_nakama_socket_connected() -> bool:
    return nakama_socket != null && nakama_socket.is_connected_to_host()
