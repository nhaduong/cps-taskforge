extends Button
signal buying_tower

var config: TowerData
@export var hotkey_label: Label
@export var cost_label: Label
@export var name_label: Label

var game
# Called when the node enters the scene tree for the first time.
func _ready():
    game = get_node("/root/Main/Game")
    
    self.mouse_entered.connect(_on_mouse_entered)
    self.mouse_exited.connect(_on_mouse_exited)

func set_config(tower_data: TowerData):
    config = tower_data
    self.icon = config.icon
    self.cost_label.text = "$%d" % config.cost
    if config.display_name:
        self.name_label.text = "%s" % config.display_name
    
    if config.tower_type < 9:
        self.hotkey_label.text = "%d" % (config.tower_type + 1)
    elif config.tower_type == 9:
        self.hotkey_label.text = "0"
    elif config.tower_type == 10:
        self.hotkey_label.text = "Q"
    elif config.tower_type == 11:
        self.hotkey_label.text = "W"
    elif config.tower_type == 12:
        self.hotkey_label.text = "E"
        
    if OS.has_feature("experiment"):
        name_label.visible = false
        
    
func set_name_label_visible():
    game = get_node("/root/Main/Game")
    name_label.visible = GameState.current_config.show_tower_name

func start_tower_buy(tower_type: int):
    # don't try to buy tower if we don't have enough money
    if GameState.Gold < config.cost:
        # print_debug("not enough cash to buy tower")
        return
    game.current_player.start_tower_buying_process(tower_type)

    self.release_focus()
    
        
func _on_data():
    # Print the received packet, you MUST always use get_peer(1).get_packet
    # to receive data from server, and not get_packet directly when not
    # using the MultiplayerAPI.
#    print("Got data from server: ", client.get_peer(1).get_packet().get_string_from_utf8())
    pass
    
func _input(event):
    if not GameState.current_config.current_is_rts:
        if GameState.wave_running:
            return

    if event.is_action_pressed("hotkey") and \
        game.game_started == true and game.game_over == false and \
        not disabled and visible and not game.gameui.chat_box.is_focused:
        var type_kc = event.keycode
        if type_kc == 48:
            type_kc = 9
        elif type_kc == 81:
            type_kc = 10
        elif type_kc == 87:
            type_kc = 11
        elif type_kc == 69:
            type_kc = 12
        else:
            type_kc -= 49
            
        if type_kc == config.tower_type:
            if GameState.Gold < config.cost:
                game.error_sfx.play()
            start_tower_buy(config.tower_type)
    
### SIGNALS ###
func _on_button_pressed():
    # print_debug("button pressed by " + str(multiplayer.get_unique_id()))
    if GameState.Gold < config.cost:
        game.error_sfx.play()
    game.gameui.tooltip_panel.hide()
    start_tower_buy(config.tower_type)
func _on_mouse_entered():
    game.gameui.button_is_hovered = true
    game.gameui.tooltip_panel.set_label_texts(\
    "%s" % config.fireRate,
    "%s" % config.dmg,
    "%s" % config.duration,
    "%s" % config.range,
    "%s" % config.cost,
    "%s" % config.description,
    "%s" % config.display_name,
    hotkey_label.text
    )
    game.gameui.tooltip_panel.reset_default_location()
    game.gameui.tooltip_panel.set_is_effect_duration_tower(config.tower_type)
    game.gameui.tooltip_panel.show()
    
func _on_mouse_exited():
    game.gameui.button_is_hovered = false
    game.gameui.tooltip_panel.hide()
