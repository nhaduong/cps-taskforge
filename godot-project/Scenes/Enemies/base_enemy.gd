extends Area2D

class_name base_enemy

signal move(pos)
signal hit(hp)
signal request_to_damage_player(dmg)
signal need_to_kill_self(name) # emit this so the map can handle killing enemy since map is tracking enemy existence
var speed = 400 # How fast the character will move (pixels/sec).
var score_value = 10

var map
var final_point_to_damage
var path_curve
var pathToFollow
var patrol_points
var patrol_index = 0
@export var Health = 12.0
var full_health
var velocity = Vector2.ZERO
var oldPosition = Vector2.ZERO

var amIFrozen = false
var amIAfraid = false
var canIBeAfraid = true
var canIBeFrozen = true
var canIBePoisoned = true
var amIPoisoned = false
var ExposureLevel = 1.0
var deceased = false
var poison_dmg = 0
var poison_element = -1

var damage_source = 0

var enemy_config: Enemy
@onready var damaged_animator = $Damaged
@export var hp_progress_bar: ProgressBar
@export var walking_animator: AnimatedSprite2D

# Called when the node enters the scene tree for the first time.
func _ready():
    GameState.wave_running_toggled.connect(_on_wave_running_toggled)
    pass
func _on_wave_running_toggled(val):
    if not val:
        process_mode = PROCESS_MODE_DISABLED
func start():
    
    $CollisionShape2D.disabled = false
    
    hp_progress_bar.value = 1

func set_config(config: Enemy, curve: Curve2D, path_to_follow: PathFollow2D, starting_pos: Vector2):
    enemy_config = config
    speed = enemy_config.speed
    path_curve = curve
    pathToFollow = path_to_follow
    position = starting_pos
    oldPosition = position
    score_value = config.score_value
    Health = config.health
    full_health = config.health
    $AnimatedSprite2D.animation = enemy_config.walking_animation
    $AnimatedSprite2D.play()
    
    # print_debug("health: %f %s" % [Health, Health == 0.0])
    if int(Health) == 0:
        visible = false
        $AnimatedSprite2D.stop()
        set_collision_layer_value(4, false)
        set_collision_layer_value(20, true)
        set_collision_mask_value(2, false)
        set_collision_mask_value(5, false)
        set_collision_mask_value(20, true)
        # $CollisionShape2D.disabled = true
        # print_debug("don't show enemy")
    else:
        show()
        # print_debug("show enemy")

# only server is allowed to request to do damage to everyone
@rpc("authority", "call_local")
func damage_player():
    GameState._set_health(GameState.Health - enemy_config.damage)
    
    # get_node("/root/Main/Game").gameui.add_system_chat_message("Enemy %s inflicted %d damage!" % [self.name,enemy_config.damage])
    if multiplayer.is_server():
        if enemy_config.damage > 0:
            Http.post_chat("System", "<action>DAMAGE_PLAYER</action> <enemy>%s</enemy> <damage>%d</damage> <enemy_health_remaining>%f</enemy_health_remaining>" % [self.name, enemy_config.damage, Health])
        
func _sync_state():
    get_node("/root/Main/Game").update_enemy_info.rpc_id(1, name)

var accumulate_delta = 0.0
var poll_rate = 0.2 # seconds

func _physics_process(delta):
    if not GameState.wave_running:
        process_mode = PROCESS_MODE_DISABLED
        
    accumulate_delta += delta
    if !multiplayer.is_server():
        if accumulate_delta >= poll_rate:
            _sync_state()
            accumulate_delta = 0
    if deceased == false:
        if !pathToFollow:
            return
        pathToFollow.progress += speed * delta
        var newPosition = pathToFollow.position.normalized()
        
        if pathToFollow.progress_ratio >= 1.0 or pathToFollow.progress == 0.0:
            return

        move.emit(self.name, newPosition)
        
        if sign(oldPosition.direction_to(newPosition)).x == -1:
            $AnimatedSprite2D.flip_h = true
        else:
            $AnimatedSprite2D.flip_h = false
            
        oldPosition = pathToFollow.position.normalized()

# unused? delete?
#func _on_body_entered(body):
##    print_debug(Health)
#    if Health <= 0:
#        print_debug(self.name + " killed! ")
#        hide() # Character disappears after being hit.
#        $Area2D.set_deferred("disabled", true)
#    hit.emit(self.name,Health)
    # Must be deferred as we can't change physics properties on a physics callback.


func _on_area_entered(_area):
    pass

func kill():
    var sigs = ["hit", "move", "need_to_kill_self", "request_to_damage_player"]
    var hit_conn_list = []
    for s in sigs:
        hit_conn_list += get_signal_connection_list(s)
    for conn in hit_conn_list:
        if conn. signal .is_connected(conn.callable):
            conn. signal .disconnect(conn.callable)

    if Health <= 0:
        print("health less than 0 time to kill animation")
        deceased = true
        $AnimatedSprite2D.animation = enemy_config.die_animation
        $AnimatedSprite2D.play()
        $AnimatedSprite2D.animation_finished.connect(_on_death_animation_finished)
    else:
        if get_parent() is PathFollow2D:
            print("get_parent() before queue free", get_parent())
            get_parent().queue_free()
            get_parent().visible = false
            get_parent().process_mode = PROCESS_MODE_DISABLED
        else:
            print("get_parent is not pathfollow2d: ", get_parent())
            # queue_free()
            visible = false
            process_mode = PROCESS_MODE_DISABLED

func _on_death_animation_finished():
    visible = false
    var _timer = Timer.new()
    add_child(_timer)
    _timer.wait_time = 1.0
    _timer.start()
    _timer.timeout.connect(_on_delay_queuefree_timer_timeout)
    
    
func _on_delay_queuefree_timer_timeout():
    if multiplayer.is_server() or multiplayer.get_unique_id() == GameState.proxy_server_id:
        Http.post_chat("System", "<action>KILL_SELF</action> <enemy>%s</enemy>" % self.name)
    if get_parent() is PathFollow2D:
        # get_parent().queue_free()
        get_parent().visible = false
        get_parent().process_mode = PROCESS_MODE_DISABLED
    else:
        # queue_free()
        visible = false
        process_mode = PROCESS_MODE_DISABLED
func damage_self(dmg, element_idx, towerType):
    if not visible:
        print("enemy is invisible, do not damage")
        return
#    print_debug("damaging self, ", dmg)
    # print_debug("initial health: ", self.name, " - ", Health, "; ", multiplayer.get_unique_id())
    Health -= enemy_config.get_final_damage(dmg * ExposureLevel, element_idx)
    # print_debug("health after damage: ", self.name, " - ", Health, "; ", multiplayer.get_unique_id())
    damage_source = 0
    hit.emit(self.name, Health, damage_source)
    if towerType != 7:
        damaged_animator.play("hit")
    hp_progress_bar.value = Health / full_health

     #print_debug("taking %f dmg after elemental modifiers %d with original dmg %d current health %f" % [enemy_config.get_final_damage(dmg,element_idx),element_idx,dmg,Health])

    if Health <= 0:
        print_debug("oh no I'm out of health ", "; ", multiplayer.get_unique_id(), self.name)
        need_to_kill_self.emit(self.name)
        # ? not sure if this is best place to put this
        get_node("/root/Main/Game").accumulate_enemy_killed_value(score_value)
        
func Poisoned(dmg, element_idx, duration):
    if amIPoisoned == false:
        $PoisonedAnimation.visible = true
        $PoisonedAnimation.play("poisoned")
        var poisonDurationTimer := Timer.new()
        add_child(poisonDurationTimer)
        poisonDurationTimer.wait_time = float(duration)
        poisonDurationTimer.one_shot = true
        poisonDurationTimer.start()
        poisonDurationTimer.timeout.connect(_on_poison_duration_timer_timeout)
        amIPoisoned = true
        $AnimatedSprite2D.set_modulate(Color(0, 1, 0, 1))
    if amIPoisoned == true:
        poison_dmg = dmg
        poison_element = element_idx
        Health -= enemy_config.get_final_damage(dmg, element_idx)
        damage_source = 1
        hit.emit(self.name, Health, damage_source)
        hp_progress_bar.value = Health / full_health
        if Health <= 0:
            need_to_kill_self.emit(self.name)
            get_node("/root/Main/Game").accumulate_enemy_killed_value(score_value)
        elif Health > 0:
            var poisonTimer := Timer.new()
            add_child(poisonTimer)
            poisonTimer.wait_time = 1.0
            poisonTimer.one_shot = true
            poisonTimer.start()
            poisonTimer.timeout.connect(_on_poison_timer_timeout)
        # print_debug("Poison tick on ", self.name, ", remaining health: ", Health)
        
func _on_poison_timer_timeout():
    if amIPoisoned == true:
        Poisoned(poison_dmg, poison_element, 0)
        
func _on_poison_duration_timer_timeout():
    amIPoisoned = false
    $PoisonedAnimation.stop()
    $PoisonedAnimation.visible = false
    if amIAfraid == true:
        $AnimatedSprite2D.set_modulate(Color(0.4, 0.2, 0.6, 1))
    elif amIFrozen == true:
        $AnimatedSprite2D.set_modulate(Color(0.5, 0.6, 0.98, 1))
    else:
        $AnimatedSprite2D.set_modulate(Color(1, 1, 1, 1))

func Frozen(duration):
    if amIFrozen == false and canIBeFrozen == true:
        $FrozenAnimation.visible = true
        $FrozenAnimation.play("frozen")
        var frozenTimer := Timer.new()
        add_child(frozenTimer)
        frozenTimer.wait_time = float(duration)
        frozenTimer.one_shot = true
        self.speed = self.speed / 2.0
        frozenTimer.start()
        frozenTimer.timeout.connect(_on_frozen_timer_timeout)
        amIFrozen = true
        $AnimatedSprite2D.set_modulate(Color(0.5, 0.6, 0.98, 1))
        
func Feared(duration):
    if amIAfraid == false and canIBeAfraid == true:
        $FearedAnimation.visible = true
        $FearedAnimation.play("feared")
        var fearTimer := Timer.new()
        add_child(fearTimer)
        fearTimer.wait_time = float(duration)
        fearTimer.one_shot = true
        self.speed = self.speed * -0.8
        fearTimer.start()
        fearTimer.timeout.connect(_on_fear_timer_timeout)
        amIAfraid = true
        $AnimatedSprite2D.set_modulate(Color(0.4, 0.2, 0.6, 1))

func _on_frozen_timer_timeout():
    self.speed = enemy_config.speed
    amIFrozen = false
    $FrozenAnimation.stop()
    $FrozenAnimation.visible = false
    if amIAfraid == true:
        $AnimatedSprite2D.set_modulate(Color(0.4, 0.2, 0.6, 1))
    elif amIPoisoned == true:
        $AnimatedSprite2D.set_modulate(Color(0, 1, 0, 1))
    else:
        $AnimatedSprite2D.set_modulate(Color(1, 1, 1, 1))

    var immuneTimer := Timer.new()
    add_child(immuneTimer)
    immuneTimer.wait_time = 5.0
    immuneTimer.one_shot = true
    immuneTimer.start()
    immuneTimer.timeout.connect(_on_immune_frozen_timer_timeout)
    canIBeFrozen = false
    
func _on_fear_timer_timeout():
    self.speed = enemy_config.speed
    amIAfraid = false
    if amIFrozen == true:
        $AnimatedSprite2D.set_modulate(Color(0.5, 0.6, 0.98, 1))
    elif amIPoisoned == true:
        $AnimatedSprite2D.set_modulate(Color(0, 1, 0, 1))
    else:
        $AnimatedSprite2D.set_modulate(Color(1, 1, 1, 1))
    var immuneTimer := Timer.new()
    add_child(immuneTimer)
    immuneTimer.wait_time = 5.0
    immuneTimer.one_shot = true
    immuneTimer.start()
    immuneTimer.timeout.connect(_on_immune_timer_timeout)
    canIBeAfraid = false

func _on_immune_timer_timeout():
    canIBeAfraid = true
func _on_immune_frozen_timer_timeout():
    canIBeFrozen = true
