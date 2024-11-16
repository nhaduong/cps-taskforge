extends StaticBody2D
class_name BaseTower

@export var tower_info_panel: PackedScene = preload("res://UI/tower_info_panel.tscn")
var info_panel

@export var Bullet = preload("res://Scenes/Bullets/base_bullet.tscn")
var bulletDamage = 5.0
var pathName
var currTargets = []
var curr = null
var purchased_by_player_id = 0
var tower_type = 0

# enemies under effect from tower bullet
var frozenEnemies = []

var wave_running_sell_penalty = .7
var total_cost_of_tower_upgrades = 0
var cost_to_buy = 10
var upgrades_cost
var display_name
var range = 400.0
var fireRate = 1.0
var duration = 2.0
var support_factor = {}
var discount = {}

# location of tower on map grid
var cell: Vector2
var range_upgrade_costs: Array
var damage_upgrade_costs: Array
var firerate_upgrade_costs: Array
var duration_upgrade_costs: Array
var num_range_upgrades = 0
var num_damage_upgrades = 0
var num_firerate_upgrades = 0
var num_duration_upgrades = 0
var upgrade_purchase_history = {"range": [], "damage": [], "firerate": [], "duration": []}
var curr_upgrade_purchase_history
var curr_upgrade_costs
var curr_num_upgrades
# prevent accidental purchase attempt when
# no more upgrades are available
var maxed_out_upgrade_cost = 999999999999

var element_idx = 0

var sprite_width = 32
var sprite_height = 32

var directionOfTarget = 0.0

# track which surrounding towers are being affected
# by a tower effect
var supportedTowers = []
var discountedTowers = []


### UI ###
# upgrade menu
@onready var upgradeRangeButton = $Upgrade/TextureRect/UpgradeMenu/Range/VBoxContainer/UpgradeRange
@onready var upgradeDamageButton = $Upgrade/TextureRect/UpgradeMenu/Damage/VBoxContainer/UpgradeDamage
@onready var upgradeFireRateButton = $Upgrade/TextureRect/UpgradeMenu/Firerate/VBoxContainer/UpgradeFireRate
@onready var upgradeDurationButton = $Upgrade/TextureRect/UpgradeMenu/EffectDuration/VBoxContainer/UpgradeDuration
@onready var sellButton = $Upgrade/TextureRect/SellContainer/Sell
@onready var downgradeRangeButton = $Upgrade/TextureRect/UpgradeMenu/Range/VBoxContainer/DowngradeRange
@onready var downgradeDamageButton = $Upgrade/TextureRect/UpgradeMenu/Damage/VBoxContainer/DowngradeDamage
@onready var downgradeFireRateButton = $Upgrade/TextureRect/UpgradeMenu/Firerate/VBoxContainer/DowngradeFireRate
@onready var downgradeDurationButton = $Upgrade/TextureRect/UpgradeMenu/EffectDuration/VBoxContainer/DowngradeDuration
@onready var damage = $Upgrade/TextureRect/UpgradeMenu/Damage
@onready var firerate = $Upgrade/TextureRect/UpgradeMenu/Firerate
@onready var effectDuration = $Upgrade/TextureRect/UpgradeMenu/EffectDuration
@onready var rangecontainer = $Upgrade/TextureRect/UpgradeMenu/Range
@onready var UpgradeMenu = $Upgrade/TextureRect
@onready var DowngradeMenu = $Upgrade/TextureRect/SellContainer

# bullet reloading
@onready var timer = $ProgressBar/Timer
@onready var progress_bar = $ProgressBar

@onready var outline_color = $Sprite2D/outline_color

@onready var idle_animator = $AnimatedSprite2D
@onready var fire_animator = $AnimatedSprite2D

@export var stat_text_color: Color = Color(0, 0.835294, 0, 1)
@export var username_text_color: Color = Color(0.807843, 0.211765, 0.592157, 1)
@export var level_text_color: Color = Color(0.890196, 0.847059, 0, 1)
@export var downgrade_cost_color: Color = Color(0, 1, 0, 1)
@export var upgrade_cost_color: Color = Color(1, 0, 0, 1)


@onready var range_label = $Upgrade/TextureRect/UpgradeMenu/Range/RichTextLabel
@onready var damage_label = $Upgrade/TextureRect/UpgradeMenu/Damage/RichTextLabel
@onready var duration_label = $Upgrade/TextureRect/UpgradeMenu/EffectDuration/RichTextLabel
@onready var firerate_label = $Upgrade/TextureRect/UpgradeMenu/Firerate/RichTextLabel

@onready var particle_system = $Sprite2D/CPUParticles2D
var startShooting = false

var Game
var config: TowerData

var fire_sfx := AudioStreamPlayer.new()
var mapwide_sfx_should_play = true

func _connect_upgrade_signals():
    if not downgradeRangeButton.is_connected("pressed", _on_upgrade_btn_pressed):
        downgradeRangeButton.pressed.connect(_on_upgrade_btn_pressed.bind("range", true))
    if not downgradeDurationButton.is_connected("pressed", _on_upgrade_btn_pressed):
        downgradeDurationButton.pressed.connect(_on_upgrade_btn_pressed.bind("duration", true))
    if not downgradeDamageButton.is_connected("pressed", _on_upgrade_btn_pressed):
        downgradeDamageButton.pressed.connect(_on_upgrade_btn_pressed.bind("damage", true))
    if not downgradeFireRateButton.is_connected("pressed", _on_upgrade_btn_pressed):
        downgradeFireRateButton.pressed.connect(_on_upgrade_btn_pressed.bind("firerate", true))

    if not upgradeRangeButton.is_connected("pressed", _on_upgrade_btn_pressed):
        upgradeRangeButton.pressed.connect(_on_upgrade_btn_pressed.bind("range", false))
    if not upgradeDurationButton.is_connected("pressed", _on_upgrade_btn_pressed):
        upgradeDurationButton.pressed.connect(_on_upgrade_btn_pressed.bind("duration", false))
    if not upgradeDamageButton.is_connected("pressed", _on_upgrade_btn_pressed):
        upgradeDamageButton.pressed.connect(_on_upgrade_btn_pressed.bind("damage", false))
    if not upgradeFireRateButton.is_connected("pressed", _on_upgrade_btn_pressed):
        upgradeFireRateButton.pressed.connect(_on_upgrade_btn_pressed.bind("firerate", false))
func _initialize():
    effectDuration.visible = false
# Called when the node enters the scene tree for the first time.
func _ready():
    Game = get_node("/root/Main/Game")
    outline_color.visible = false
    _initialize()
    _connect_upgrade_signals()

    hide_menu()
    add_child(fire_sfx)
    fire_sfx.stream = load("res://Audio/SFX/sfx_tower_fire.ogg")
    fire_sfx.volume_db = -5
    fire_sfx.process_mode = Node.PROCESS_MODE_ALWAYS
    
    if $AnimatedSprite2D.sprite_frames.has_animation(config.idle_animation):
        $AnimatedSprite2D.animation = config.idle_animation
        $AnimatedSprite2D.play()
        
    if purchased_by_player_id != Game.current_player.peer_id:
        if not GameState.current_config.current_can_modify_other_players_towers:
            # show other player's towers as disabled if we aren't allow to modify them
            $AnimatedSprite2D.set_modulate(Color(0.6, 0.6, 0.6, 0.6))
    

func set_tower_collision(val: bool):
    var tower_collider = $RangeArea2D
    tower_collider.monitoring = val
    tower_collider.monitorable = val
    tower_collider.input_pickable = val

func set_scale_modifier(modifier: Vector2):
    if tower_type == 0:
        $AnimatedSprite2D.scale.x = modifier.x * 0.75
        $AnimatedSprite2D.scale.y = modifier.y * 0.75
    elif tower_type == 3:
        $AnimatedSprite2D.scale.x = modifier.x * 0.6
        $AnimatedSprite2D.scale.y = modifier.y * 0.6
    else:
        $AnimatedSprite2D.scale.x = modifier.x
        $AnimatedSprite2D.scale.y = modifier.y

        
func SetFireRate():

    var _wait_time = 1.0 / fireRate
    if support_factor.is_empty() == false:
        _wait_time = 1.0 / (fireRate * support_factor.values().max())

#    if GameState.current_config.current_is_rts:
#        if Game:
#            if GameState.wave_running:
#                _on_timer_timeout()
        
func SetRange():
    if support_factor.is_empty() == false:
        $RangeArea2D/Range.scale.x = range * support_factor.values().max()
        $RangeArea2D/Range.scale.y = range * support_factor.values().max()
    else:
        $RangeArea2D/Range.scale.x = range
        $RangeArea2D/Range.scale.y = range
    

func set_config(_config: TowerData) -> void:
    self.config = _config
    bulletDamage = _config.dmg
    range = _config.range
    fireRate = _config.fireRate
    duration = _config.duration
    cost_to_buy = _config.cost

    # for CPSTaskForge pilot, we hide tower names
    if OS.has_feature("experiment"):
        display_name = "Tower"
    else:
        display_name = _config.display_name

    #self.SetIcon(config.icon)
    self.SetFireRate()
    self.SetRange()

    element_idx = _config.element

    range_upgrade_costs = _config.range_upgrade_costs
    damage_upgrade_costs = _config.damage_upgrade_costs
    firerate_upgrade_costs = _config.firerate_upgrade_costs
    duration_upgrade_costs = _config.duration_upgrade_costs

    num_range_upgrades = 0
    num_damage_upgrades = 0
    num_firerate_upgrades = 0
    num_duration_upgrades = 0

var _discount_modifier = .6

func _get_upgrade_cost(variant, isDowngrade = false):
    curr_upgrade_costs = null
    curr_num_upgrades = null
    if variant == "range":
        curr_upgrade_costs = range_upgrade_costs
        curr_num_upgrades = num_range_upgrades
    elif variant == "damage":
        curr_upgrade_costs = damage_upgrade_costs
        curr_num_upgrades = num_damage_upgrades
    elif variant == "firerate":
        curr_upgrade_costs = firerate_upgrade_costs
        curr_num_upgrades = num_firerate_upgrades
    elif variant == "duration":
        curr_upgrade_costs = duration_upgrade_costs
        curr_num_upgrades = num_duration_upgrades

    curr_upgrade_purchase_history = upgrade_purchase_history[variant]

    # Upgrading
    if not isDowngrade:
        if curr_num_upgrades == null or curr_upgrade_costs == null:
            print("abort, we have a null value")
            print(variant, curr_upgrade_costs, curr_num_upgrades, curr_upgrade_purchase_history)
            return maxed_out_upgrade_cost

        if curr_num_upgrades >= curr_upgrade_costs.size():
            return maxed_out_upgrade_cost

        var discount_modifier = _discount_modifier
        if discount.is_empty() == false:
            return clamp(floor(curr_upgrade_costs[num_duration_upgrades] / \
                    (discount.values().max() * discount_modifier)), 1, \
                    maxed_out_upgrade_cost)
        else:
            return floor(curr_upgrade_costs[curr_num_upgrades])

    # Downgrading
    else:
        if not curr_upgrade_costs and not curr_num_upgrades and not curr_upgrade_purchase_history:
            print("abort, we have a null value when downgrading")
            print(variant, curr_upgrade_costs, curr_num_upgrades, curr_upgrade_purchase_history)
            return 0
        if curr_num_upgrades == 0:
            return 0
        if curr_num_upgrades > curr_upgrade_costs.size():
            return 0
        
        
        var discount_modifier = _discount_modifier
        var actual_downgrade_value
        if curr_num_upgrades == curr_upgrade_purchase_history.size():
            actual_downgrade_value = curr_upgrade_purchase_history[curr_num_upgrades - 1]
        if discount.is_empty() == false:
            actual_downgrade_value = clamp(floor(curr_upgrade_costs[curr_num_upgrades - 1] / \
                    (discount.values().max() * discount_modifier)), 1, maxed_out_upgrade_cost)
        else:
            actual_downgrade_value = floor(curr_upgrade_costs[curr_num_upgrades - 1])

        # for RTS
        if GameState.wave_running:
            actual_downgrade_value = wave_running_sell_penalty * actual_downgrade_value

        return clamp(actual_downgrade_value, 1, maxed_out_upgrade_cost)


@rpc("any_peer", "call_local")
func _upgrade_stat(purchaser_id, purchaser_username, stat):
    var _cost = _get_upgrade_cost(stat)
    if _cost == maxed_out_upgrade_cost:
        return
    var curr_num_stat_upgrades
    if stat == "range":
        num_range_upgrades += 1
        curr_num_stat_upgrades = num_range_upgrades
        _upgrade_range(num_range_upgrades)
    elif stat == "damage":
        num_damage_upgrades += 1
        curr_num_stat_upgrades = num_damage_upgrades
        _upgrade_damage(num_damage_upgrades)

        # vfx
        particle_system.amount = num_damage_upgrades
        particle_system.emitting = true
        particle_system.restart()
    elif stat == "duration":
        num_duration_upgrades += 1
        curr_num_stat_upgrades = num_duration_upgrades
        _upgrade_duration(num_duration_upgrades)
    elif stat == "firerate":
        num_firerate_upgrades += 1
        curr_num_stat_upgrades = num_firerate_upgrades
        _upgrade_firerate(num_firerate_upgrades)

    upgrade_purchase_history[stat].append(_cost)
    _set_upgrade_button_states()
    
    GameState._set_gold(GameState.Gold - _cost)
    total_cost_of_tower_upgrades += _cost

    _log_stat_update(stat, purchaser_id, purchaser_username, false)
    
@rpc("any_peer", "call_local")
func _upgrade_range(num_upgrades):
    range += 1.0 * float(num_upgrades)
    SetRange()
    

@rpc("any_peer", "call_local")
func _upgrade_damage(num_upgrades):
    bulletDamage += (num_upgrades ** 2 / 12.8 + .2 * num_upgrades)


@rpc("any_peer", "call_local")
func _upgrade_firerate(num_upgrades):
    fireRate += (num_upgrades ** 2 / 14.2 + .24 * num_upgrades)
    SetFireRate()
    
@rpc("any_peer", "call_local")
func _upgrade_duration(num_upgrades):
    duration += (num_upgrades ** 2 / 35.2 + .1)
    
@rpc("any_peer", "call_local")
func _downgrade_stat(purchaser_id, purchaser_username, stat):
    if upgrade_purchase_history[stat].size() == 0:
        # print_debug("spam clicking range, cost is null, aborting downgrade")
        return
    var _cost = _get_upgrade_cost(stat, true)
    upgrade_purchase_history[stat].pop_back()
    if not _cost:
        # print_debug("spam clicking range, cost is null, aborting downgrade")
        return

    var curr_num_stat_upgrades
    if stat == "range":
        _downgrade_range(num_range_upgrades)
        num_range_upgrades -= 1
        curr_num_stat_upgrades = num_range_upgrades
    elif stat == "damage":
        _downgrade_damage(num_damage_upgrades)
        num_damage_upgrades -= 1
        curr_num_stat_upgrades = num_damage_upgrades

        # vfx
        if num_damage_upgrades == 0:
            particle_system.emitting = false
        else:
            particle_system.emitting = true
            particle_system.amount = num_damage_upgrades
    elif stat == "duration":
        _downgrade_duration(num_duration_upgrades)
        num_duration_upgrades -= 1
        curr_num_stat_upgrades = num_duration_upgrades
    elif stat == "firerate":
        _downgrade_firerate(num_firerate_upgrades)
        num_firerate_upgrades -= 1
        curr_num_stat_upgrades = num_firerate_upgrades

    GameState._set_gold(GameState.Gold + _cost)
    total_cost_of_tower_upgrades -= _cost
    _set_upgrade_button_states()

    _log_stat_update(stat, purchaser_id, purchaser_username, true)

    
@rpc("any_peer", "call_local")
func _downgrade_range(num_upgrades):
    range -= 1.0 * num_range_upgrades
    SetRange()
    
    
@rpc("any_peer", "call_local")
func _downgrade_damage(num_upgrades):
    bulletDamage -= (num_upgrades ** 2 / 12.8 + .2 * num_upgrades)

    
@rpc("any_peer", "call_local")
func _downgrade_firerate(num_upgrades):

    fireRate -= (num_upgrades ** 2 / 14.2 + .24 * num_upgrades)
    SetFireRate()
    

@rpc("any_peer", "call_local")
func _downgrade_duration(num_upgrades):
    duration -= (num_upgrades ** 2 / 35.2 + .1)

    
func _log_stat_update(variant: String, purchaser_id, purchaser_username, isDowngrade):
    var variant_upper = variant.to_upper()
    var update_direction = "Upgraded" if not isDowngrade else "Downgraded"
    Game.gameui.add_system_chat_message("%s %.v [color=#%s]%s[/color] %s to level [color=#%s]%d[/color] by [color=#%s]%s[/color] " \
    % [display_name, cell, \
    stat_text_color.to_html(), variant_upper, update_direction, level_text_color.to_html(), \
    num_duration_upgrades, username_text_color.to_html(), \
    purchaser_username])
    if multiplayer.get_unique_id() == purchaser_id:
        Http.post_chat("System-%d" % multiplayer.get_unique_id(),
    "<action>%s</action> <stat>DURATION</stat> <current_level>%d</current_level> <user>%s</user> <tower_type>%d</tower_type> <location>%.v</location> <peer_id>%d</peer_id>" %
    [variant_upper, num_duration_upgrades, Game.current_player.username, config.tower_type, cell, Game.current_player.peer_id])

func _get_sell_amount() -> int:
    var _final_sell = floor(cost_to_buy + total_cost_of_tower_upgrades)
    if GameState.wave_running:
        _final_sell = wave_running_sell_penalty * _final_sell

    return clamp(_final_sell, 1, maxed_out_upgrade_cost)
    
@rpc("any_peer", "call_local")
func _sell(purchaser_id, purchaser_username):
    
    EraseSelf()
    
    Game.gameui.add_system_chat_message("%s %.v sold by [color=#%s]%s[/color]" %
    [display_name, cell, username_text_color.to_html(),
    Game.players_setup[multiplayer.get_remote_sender_id()].username])
    
    if info_panel:
        info_panel.queue_free()
    GameState._set_gold(GameState.Gold + _get_sell_amount())
    get_node("/root/Main/Game").remove_tower_from_log_by_tower(self)
    queue_free()
    # print_debug("selling tower on client %d" % multiplayer.get_unique_id())

    if multiplayer.get_unique_id() == purchaser_id:
        Http.post_chat("System-%d" % multiplayer.get_unique_id(),
    "<action>SELL</action> <stat></stat> <current_level></current_level> <user>%s</user> <tower_type>%d</tower_type> <location>%.v</location> <peer_id>%d</peer_id>" %
    [Game.current_player.username, config.tower_type, cell, Game.current_player.peer_id])
func _on_done_buying():
    _set_upgrade_button_states()
    _update_info()
func _physics_process(delta):
    # reload timer
    if timer.is_stopped() == false:
        progress_bar.value = (timer.wait_time - timer.time_left) / timer.wait_time

# RTS
func on_build_try_to_shoot():
    var areas = $RangeArea2D.get_overlapping_areas()
    for area in areas:
        if "Enemy" in area.name:
            # do nothing if enemy is invisible and has no health
            if is_equal_approx(area.Health, 0):
                return
            
            currTargets.append(area)
            
            if curr == null:
                currTargets.sort_custom(func(a, b): return a.pathToFollow.progress_ratio > b.pathToFollow.progress_ratio)
                curr = currTargets[0]
                
            if timer.is_stopped():
                _do_shoot()
                timer.start()
    pass

func _look_at_enemy():
    if is_instance_valid(curr):
        var enemy_progress = 1.0
        enemy_progress = curr.pathToFollow.progress + ((global_position.distance_to(curr.global_position) / 500) * curr.speed)
        directionOfTarget = self.get_angle_to(curr.path_curve.sample_baked(enemy_progress))
        directionOfTarget += PI / 2
        $AnimatedSprite2D.rotation = directionOfTarget
func _process(delta):
    if currTargets.size() > 0:
        if curr.deceased == true:
            currTargets.erase(curr)
            if len(currTargets) > 0:
                currTargets.sort_custom(func(a, b): return a.pathToFollow.progress_ratio > b.pathToFollow.progress_ratio)
                curr = currTargets[0]
            else:
                curr = null
        elif curr == null:
            currTargets.sort_custom(func(a, b): return a.pathToFollow.progress_ratio > b.pathToFollow.progress_ratio)
            curr = currTargets[0]
        
    _look_at_enemy()

            
    if $AnimatedSprite2D.is_playing() == false:
        if $AnimatedSprite2D.sprite_frames.has_animation(config.idle_animation):
            $AnimatedSprite2D.animation = config.idle_animation
            $AnimatedSprite2D.play()
            
    if support_factor.is_empty() == false and $SupportAnimation.is_playing() == false:
        $SupportAnimation.visible = true
        $SupportAnimation.play("support")
    elif discount.is_empty() == false and $DiscountAnimation.is_playing() == false:
        $DiscountAnimation.visible = true
        $DiscountAnimation.play("discount")
    elif support_factor.is_empty() == true and $SupportAnimation.is_playing() == true:
        $SupportAnimation.stop()
        $SupportAnimation.visible = false
    elif discount.is_empty() == true and $DiscountAnimation.is_playing() == true:
        $DiscountAnimation.stop()
        $DiscountAnimation.visible = false
        
    _extra_process()

# var shouldShoot = true
func _extra_process():
    pass
func Shoot():
    if curr != null:
        while curr.position.x < 0 and curr.position.x > get_viewport_rect().size.x \
            and curr.position.y < 0 and curr.position.y > get_viewport_rect().size.y:
                continue

        var tempBullet = Game.bullet_pool.get_bullet(tower_type) # Bullet.instantiate()

        var enemy_progress = 1.0
#        if enemy_speed > 200:
#            enemy_speed = 200
        enemy_progress = curr.pathToFollow.progress + ((global_position.distance_to(curr.global_position) / (tempBullet.Speed * get_physics_process_delta_time())) * (curr.speed * get_physics_process_delta_time()))
        tempBullet.target = curr.path_curve.sample_baked(enemy_progress)
#        tempBullet.target = curr.global_position
        if tower_type == 3:
            if support_factor.is_empty() == false:
                tempBullet.bulletDamage = bulletDamage * support_factor.values().max() + (curr.speed / 100)
            else:
                tempBullet.bulletDamage = bulletDamage + (curr.speed / 100)
        else:
            if support_factor.is_empty() == false:
                tempBullet.bulletDamage = bulletDamage * support_factor.values().max()
            else:
                tempBullet.bulletDamage = bulletDamage
        tempBullet.element_idx = element_idx
        tempBullet.initialTargetVector = global_position.direction_to(tempBullet.target)
        tempBullet.rotation = position.angle_to_point(tempBullet.target)
        # $BulletContainer.call_deferred("add_child",tempBullet,true)
        tempBullet.activate_bullet()
#        get_node("/root/Main/Game/BulletContainer").call_deferred("add_child",tempBullet,true)
        tempBullet.global_position = $Aim.global_position
        

        if support_factor.is_empty() == false:
            timer.wait_time = float(1 / float(fireRate * support_factor.values().max()))
        else:
            timer.wait_time = float(1 / float(fireRate))

        
        fire_sfx.play()
        $AnimatedSprite2D.stop()
        if $AnimatedSprite2D.sprite_frames.has_animation(config.fire_animation):
            $AnimatedSprite2D.animation = config.fire_animation
            $AnimatedSprite2D.play()

func EraseSelf():
    pass
        

func _on_tower_area_exited(body):
    if "Enemy" in body.name:
        if len(currTargets) > 0:
            currTargets.erase(body)
            if len(currTargets) > 0:
                currTargets.sort_custom(func(a, b): return a.pathToFollow.progress_ratio > b.pathToFollow.progress_ratio)
                curr = currTargets[0]
            else:
                curr = null

func _do_shoot():
    Shoot()


func _on_timer_timeout():
    if is_instance_valid(curr):
        _look_at_enemy()

        _do_shoot()

        # check again in case enemy died
        if is_instance_valid(curr):
            timer.start()
    else:
        timer.stop()
    pass

func _on_tower_area_entered(body):
    if "Enemy" in body.name:
        # do nothing if enemy is invisible and has no health
        if is_equal_approx(body.Health, 0):
            return
        
        currTargets.append(body)
        
        if curr == null:
            currTargets.sort_custom(func(a, b): return a.pathToFollow.progress_ratio > b.pathToFollow.progress_ratio)
            curr = currTargets[0]
            
        if timer.is_stopped():
            _do_shoot()
            timer.start()

var _is_mouse_entered = false
func _on_mouse_mouse_entered():
    $RangeArea2D/Range/RangeCanvas.visible = true
    _is_mouse_entered = true

    if Game == null:
        Game = get_node("/root/Main/Game")
    if not self in Game._towers.values() or self.get_parent().name == "Cursor":
        return
    
    if not info_panel:
        info_panel = tower_info_panel.instantiate()
        get_node("/root/Main/Game/PopupsContainer").add_child.call_deferred(info_panel)
        await get_tree().process_frame
    _update_info()
    if self in Game._towers.values() and self.get_parent().name != "Cursor":
        if info_panel:
            info_panel.show()
    else:
        if info_panel:
            info_panel.hide()

func _get_hotkey_text():
    return "%d" % (config.tower_type + 1)

var info_panel_mod_color = "#14e34b"
func _update_info():
    if not info_panel:
        return
    var support_factor_panel_info = 1.0
    if support_factor.is_empty() == false:
        support_factor_panel_info = support_factor.values().max()
    var _firerate_text = "%.1f ([color=%s]+%.2f[/color]) ([color=%s]x%.2f[/color])" % [config.fireRate, info_panel_mod_color, (fireRate - config.fireRate), "#DA70D6", support_factor_panel_info]
    var _dmg_text = "%.1f ([color=%s]+%.2f[/color]) ([color=%s]x%.2f[/color])" % [config.dmg, info_panel_mod_color, (bulletDamage - config.dmg), "#DA70D6", support_factor_panel_info]
    var _duration_text = "%.1f ([color=%s]+%.2f[/color]) ([color=%s]x%.2f[/color])" % [config.duration, info_panel_mod_color, (duration - config.duration), "#DA70D6", support_factor_panel_info]
    var _range_text = "%.1f ([color=%s]+%.2f[/color]) ([color=%s]x%.2f[/color])" % [config.range, info_panel_mod_color, (range - config.range), "#DA70D6", support_factor_panel_info]
    var _sell_amount_text = "%d" % _get_sell_amount()

    var _hotkey_text = _get_hotkey_text()

    if config.tower_type == 10:
        _hotkey_text = "Q"
    
    info_panel.set_label_texts(\
    "%s" % _firerate_text,
    "%s" % _dmg_text,
    "%s" % _duration_text,
    "%s" % _range_text,
    "%s" % _sell_amount_text,
    "%s" % config.description,
    "%s" % display_name,
    _hotkey_text
    )
    info_panel.set_is_effect_duration_tower(config.tower_type)
    
    if cell.x >= 16 and cell.y <= 7:
        info_panel.move_panel_location()
    else:
        info_panel.reset_default_location()
func _on_mouse_mouse_exited():
    _is_mouse_entered = false
    var _game = get_node("/root/Main/Game")
    if not UpgradeMenu.visible and self in _game._towers.values():
        $RangeArea2D/Range/RangeCanvas.visible = false
        
        await get_tree().process_frame
        if info_panel:
            info_panel.queue_free()
            info_panel = null

func _on_sell_pressed():
    if not sell_btn_entered and UpgradeMenu.visible: return
    submit_sell_request()
    
func submit_sell_request():
    var amount = _get_sell_amount()
    Game.submit_purchase_request.rpc_id(1, false, -amount, "sell", self.name, multiplayer.get_unique_id(), Game.current_player.username, config.tower_type)

func submit_purchase_request(is_upgrade, amount, stat_type):
    if not amount:
        # print_debug("not submitting purchase request, amount is null")
        return
    # print_debug("submitting purchase request for ", stat_type)
    if not is_upgrade:
        amount = -amount
    # ask server if we can make our purchase
    Game.submit_purchase_request.rpc_id(1, is_upgrade, amount, stat_type, self.name, multiplayer.get_unique_id(), Game.current_player.username)
@rpc("any_peer", "call_local")
func make_purchase(is_upgrade, amount, stat_type, tower_name, purchaser_id, purchaser_username):
    if amount == maxed_out_upgrade_cost:
        print_debug("maxed out upgrade cost requested, abort!")
        return

    if is_upgrade:
        _upgrade_stat(purchaser_id, purchaser_username, stat_type)
    else:
        _downgrade_stat(purchaser_id, purchaser_username, stat_type)

func _on_upgrade_btn_pressed(stat, isDowngrade = false):
    if not UpgradeMenu.visible: return
    if stat == "range":
        if not range_btn_entered and not downgrade_range_btn_entered: return
    elif stat == "duration":
        if not duration_btn_entered and not downgrade_duration_btn_entered: return
    elif stat == "firerate":
        if not firerate_btn_entered and not downgrade_firerate_btn_entered: return
    elif stat == "damage":
        if not dmg_btn_entered and not downgrade_dmg_btn_entered: return

    var _cost
    if isDowngrade:
        _cost = upgrade_purchase_history[stat].max()
    else:
        _cost = _get_upgrade_cost(stat)
        if _cost == maxed_out_upgrade_cost:
            return

    #_disable_all_upgrade_buttons()

    submit_purchase_request(!isDowngrade, _cost, stat)


func _disable_all_upgrade_buttons():
    upgradeRangeButton.disabled = true
    upgradeDamageButton.disabled = true
    upgradeFireRateButton.disabled = true
    upgradeDurationButton.disabled = true
    downgradeRangeButton.disabled = true
    downgradeDamageButton.disabled = true
    downgradeFireRateButton.disabled = true
    downgradeDurationButton.disabled = true


func _on_first_time_timer_timeout():
    mapwide_sfx_should_play = false
    fire_sfx.stream = load("res://Audio/SFX/sfx_mapwide_tower.ogg")
    fire_sfx.play()

func _on_tree_exited():
    Game.gameui.button_is_hovered = false
    pass # Replace with function body.

func _on_invalid_tile_gui_input(event):
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            Game.error_sfx.play()

func _on_upgrade_visibility_changed():
    if Game == null:
        Game = get_node("/root/Main/Game")
    if visible:
        if not self in Game._towers.values() or self.get_parent().name == "Cursor":
            return
        if not info_panel:
            info_panel = tower_info_panel.instantiate()
            add_child.call_deferred(info_panel)
            await get_tree().process_frame
        _update_info()
        info_panel.show()
    else:
        if info_panel:
            await get_tree().process_frame
            info_panel.queue_free()
            info_panel = null
    pass # Replace with function body.

func _on_texture_rect_mouse_entered():
    if info_panel:
        info_panel.z_index = 100
        
    pass # Replace with function body.

func _on_texture_rect_mouse_exited():
    if info_panel:
        info_panel.z_index = 5
    pass # Replace with function body.


func upgrade_hotkey(stat):
    var _cost
    if stat == "range":
        if upgradeRangeButton.disabled or !rangecontainer.visible: return
    elif stat == "damage":
        if upgradeDamageButton.disabled or !damage.visible: return
    elif stat == "firerate":
        if upgradeFireRateButton.disabled or !firerate.visible: return
    elif stat == "duration":
        if upgradeDurationButton.disabled or !effectDuration.visible: return
    _cost = _get_upgrade_cost(stat)

    if _cost == maxed_out_upgrade_cost:
        return
    #_disable_all_upgrade_buttons()

    submit_purchase_request(true, _cost, stat)

func downgrade_hotkey(stat):
    if stat not in upgrade_purchase_history.keys(): return
    var _cost = upgrade_purchase_history[stat].max()
    if stat == "range":
        if downgradeRangeButton.disabled or !rangecontainer.visible: return
    elif stat == "damage":
        if downgradeDamageButton.disabled or !damage.visible: return
    elif stat == "firerate":
        if downgradeFireRateButton.disabled or !firerate.visible: return
    elif stat == "duration":
        if downgradeDurationButton.disabled or !effectDuration.visible: return

    submit_purchase_request(false, _cost, stat)


### VFX ###
@onready var invalid_tile_style = $Sprite2D/InvalidTile
@onready var valid_tile_style = $Sprite2D/ValidTile
func show_invalid_tile_style() -> void:
    $RangeArea2D/Range/RangeCanvas.color = Color(1.0, 0.0, 0.0, 0.3)
    $RangeArea2D/Range/RangeCanvas.queue_redraw()
    invalid_tile_style.visible = true
    valid_tile_style.visible = false
    
func hide_validity_tile_style() -> void:
    $RangeArea2D/Range/RangeCanvas.color = Color(0.0, 0.0, 1.0, 0.2)
    $RangeArea2D/Range/RangeCanvas.queue_redraw()
    invalid_tile_style.visible = false
    valid_tile_style.visible = false
    
func show_valid_tile_style() -> void:
    $RangeArea2D/Range/RangeCanvas.color = Color(0.0, 0.0, 1.0, 0.2)
    $RangeArea2D/Range/RangeCanvas.queue_redraw()
    invalid_tile_style.visible = false
    valid_tile_style.visible = true

func set_outline_color(color):
    outline_color.modulate = color
    outline_color.visible = true

### End VFX


### UI 
@rpc("any_peer", "call_local")
func _set_upgrade_button_states():

    upgradeRangeButton.disabled = _get_upgrade_cost("range") > GameState.Gold or not UpgradeMenu.visible or num_range_upgrades == range_upgrade_costs.size() or GameState.Gold <= 0
    upgradeDamageButton.disabled = _get_upgrade_cost("damage") > GameState.Gold or not UpgradeMenu.visible or num_damage_upgrades == damage_upgrade_costs.size() or GameState.Gold <= 0
    upgradeFireRateButton.disabled = _get_upgrade_cost("firerate") > GameState.Gold or not UpgradeMenu.visible or num_firerate_upgrades == firerate_upgrade_costs.size() or GameState.Gold <= 0
    upgradeDurationButton.disabled = _get_upgrade_cost("duration") > GameState.Gold or not UpgradeMenu.visible or num_duration_upgrades == duration_upgrade_costs.size() or GameState.Gold <= 0
    
    sellButton.disabled = not UpgradeMenu.visible

    downgradeRangeButton.disabled = num_range_upgrades == 0 and UpgradeMenu.visible or GameState.wave_running
    downgradeFireRateButton.disabled = num_firerate_upgrades == 0 and UpgradeMenu.visible or GameState.wave_running
    downgradeDamageButton.disabled = num_damage_upgrades == 0 and UpgradeMenu.visible or GameState.wave_running
    downgradeDurationButton.disabled = num_duration_upgrades == 0 and UpgradeMenu.visible or GameState.wave_running
    
    range_label.text = "Range\n[color=%s]%s[/color]/[color=%s]%s[/color]" % \
     [downgrade_cost_color.to_html(), _format_cost(_get_upgrade_cost("range", true)), upgrade_cost_color.to_html(), _format_cost(_get_upgrade_cost("range"))]
    firerate_label.text = "Firerate\n[color=%s]%s[/color]/[color=%s]%s[/color]" % \
     [downgrade_cost_color.to_html(), _format_cost(_get_upgrade_cost("firerate", true)), upgrade_cost_color.to_html(), _format_cost(_get_upgrade_cost("firerate"))]
    duration_label.text = "Duration\n[color=%s]%s[/color]/[color=%s]%s[/color]" % \
     [downgrade_cost_color.to_html(), _format_cost(_get_upgrade_cost("duration", true)), upgrade_cost_color.to_html(), _format_cost(_get_upgrade_cost("duration"))]
    if tower_type == 5 or tower_type == 8 or tower_type == 11:
        damage_label.text = "Effect Strength\n[color=%s]%s[/color]/[color=%s]%s[/color]" % \
     [downgrade_cost_color.to_html(), _format_cost(_get_upgrade_cost("damage", true)), upgrade_cost_color.to_html(), _format_cost(_get_upgrade_cost("damage"))]
    else:
        damage_label.text = "Damage\n[color=%s]%s[/color]/[color=%s]%s[/color]" % \
     [downgrade_cost_color.to_html(), _format_cost(_get_upgrade_cost("damage", true)), upgrade_cost_color.to_html(), _format_cost(_get_upgrade_cost("damage"))]

    _update_info()

func show_menu():
    # do nothing if wave is running
    if not GameState.current_config.current_is_rts:
        if GameState.wave_running:
            return

    # toggle upgrade button enable if enough cash on hand
    
    UpgradeMenu.visible = true
    DowngradeMenu.visible = true
    _set_upgrade_button_states()

    if not info_panel:
        info_panel = tower_info_panel.instantiate()
        add_child.call_deferred(info_panel)
        await get_tree().process_frame
    _update_info()
    info_panel.show()

    $RangeArea2D/Range/RangeCanvas.visible = true
    
func hide_menu():
    UpgradeMenu.visible = false
    DowngradeMenu.visible = false
    $RangeArea2D/Range/RangeCanvas.visible = false
    _set_upgrade_button_states()

### End UI
    
func hide_range_ui():
    $RangeArea2D/Range/RangeCanvas.visible = false


### Utilities
func _format_cost(val):
    if val == 0 or val == maxed_out_upgrade_cost:
        return "---"
    return "%d".replace('+', '').replace('-', '') % val

# All of these should only be necessary if using radial menu
# since the radial menu magically selects anything in the degree
# area of mouse cursor, allowing you to Press a button without
# the cursor being over the Button Collision area
var sell_btn_entered: bool = false
var range_btn_entered: bool = false
var dmg_btn_entered: bool = false
var firerate_btn_entered: bool = false
var duration_btn_entered: bool = false
var downgrade_range_btn_entered: bool = false
var downgrade_firerate_btn_entered: bool = false
var downgrade_dmg_btn_entered: bool = false
var downgrade_duration_btn_entered: bool = false
func _on_sell_mouse_entered():
    sell_btn_entered = true
    get_node("/root/Main/Game").gameui.button_is_hovered = true

func _on_sell_mouse_exited():
    sell_btn_entered = false
    get_node("/root/Main/Game").gameui.button_is_hovered = false

func _on_upgrade_range_mouse_entered():
    range_btn_entered = true
    get_node("/root/Main/Game").gameui.button_is_hovered = true
    # print_debug("gameui button is hovered value: ", get_node("/root/Main/Game").gameui.button_is_hovered)
func _on_upgrade_range_mouse_exited():
    range_btn_entered = false
    get_node("/root/Main/Game").gameui.button_is_hovered = false
    # print_debug("gameui button is hovered value: ", get_node("/root/Main/Game").gameui.button_is_hovered)
func _on_upgrade_damage_mouse_entered():
    dmg_btn_entered = true
    get_node("/root/Main/Game").gameui.button_is_hovered = true
    # print_debug("gameui button is hovered value: ", get_node("/root/Main/Game").gameui.button_is_hovered)
func _on_upgrade_damage_mouse_exited():
    dmg_btn_entered = false
    get_node("/root/Main/Game").gameui.button_is_hovered = false
    # print_debug("gameui button is hovered value: ", get_node("/root/Main/Game").gameui.button_is_hovered)
func _on_upgrade_fire_rate_mouse_entered():
    firerate_btn_entered = true
    get_node("/root/Main/Game").gameui.button_is_hovered = true
    # print_debug("gameui button is hovered value: ", get_node("/root/Main/Game").gameui.button_is_hovered)
func _on_upgrade_fire_rate_mouse_exited():
    firerate_btn_entered = false
    get_node("/root/Main/Game").gameui.button_is_hovered = false
    # print_debug("gameui button is hovered value: ", get_node("/root/Main/Game").gameui.button_is_hovered)    
func _on_downgrade_range_mouse_entered():
    downgrade_range_btn_entered = true
    get_node("/root/Main/Game").gameui.button_is_hovered = true
    # print_debug("gameui button is hovered value: ", get_node("/root/Main/Game").gameui.button_is_hovered)
func _on_downgrade_range_mouse_exited():
    downgrade_range_btn_entered = false
    get_node("/root/Main/Game").gameui.button_is_hovered = false
    # print_debug("gameui button is hovered value: ", get_node("/root/Main/Game").gameui.button_is_hovered)
func _on_downgrade_damage_mouse_entered():
    downgrade_dmg_btn_entered = true
    get_node("/root/Main/Game").gameui.button_is_hovered = true
    # print_debug("gameui button is hovered value: ", get_node("/root/Main/Game").gameui.button_is_hovered)
func _on_downgrade_damage_mouse_exited():
    downgrade_dmg_btn_entered = false
    get_node("/root/Main/Game").gameui.button_is_hovered = false
    # print_debug("gameui button is hovered value: ", get_node("/root/Main/Game").gameui.button_is_hovered)
func _on_downgrade_fire_rate_mouse_entered():
    downgrade_firerate_btn_entered = true
    get_node("/root/Main/Game").gameui.button_is_hovered = true
    # print_debug("gameui button is hovered value: ", get_node("/root/Main/Game").gameui.button_is_hovered)
func _on_downgrade_fire_rate_mouse_exited():
    downgrade_firerate_btn_entered = false
    get_node("/root/Main/Game").gameui.button_is_hovered = false
    # print_debug("gameui button is hovered value: ", get_node("/root/Main/Game").gameui.button_is_hovered)
func _on_upgrade_duration_mouse_entered():
    duration_btn_entered = true
    get_node("/root/Main/Game").gameui.button_is_hovered = true
    # print_debug("gameui button is hovered value: ", get_node("/root/Main/Game").gameui.button_is_hovered)
func _on_upgrade_duration_mouse_exited():
    duration_btn_entered = false
    get_node("/root/Main/Game").gameui.button_is_hovered = false
    # print_debug("gameui button is hovered value: ", get_node("/root/Main/Game").gameui.button_is_hovered)
func _on_downgrade_duration_mouse_entered():
    downgrade_duration_btn_entered = true
    get_node("/root/Main/Game").gameui.button_is_hovered = true
    # print_debug("gameui button is hovered value: ", get_node("/root/Main/Game").gameui.button_is_hovered)
func _on_downgrade_duration_mouse_exited():
    downgrade_duration_btn_entered = false
    get_node("/root/Main/Game").gameui.button_is_hovered = false
    # print_debug("gameui button is hovered value: ", get_node("/root/Main/Game").gameui.button_is_hovered)
