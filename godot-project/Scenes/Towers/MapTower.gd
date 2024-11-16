extends BaseTower

func _initialize():
    effectDuration.visible = false
    rangecontainer.visible = false
func Shoot():
    if len(currTargets) > 0:
        $AnimatedSprite2D.stop()
        if $AnimatedSprite2D.sprite_frames.has_animation(config.fire_animation):
            $AnimatedSprite2D.animation = config.fire_animation
            $AnimatedSprite2D.play()
        var dmg = bulletDamage / 2
        if support_factor.is_empty() == false:
            dmg = (bulletDamage * support_factor.values().max()) / 2
        for n in len(currTargets):
            currTargets[n].damage_self(dmg, element_idx, tower_type)
        if support_factor.is_empty() == false:
            timer.wait_time = float(1 / (fireRate * 0.25) * support_factor.values().max())
        else:
            timer.wait_time = float(1 / (fireRate * 0.25))
        timer.start()
        mapwide_sfx_should_play = true
        
func _extra_process():
    if timer.time_left <= 0.4 and mapwide_sfx_should_play == true and GameState.wave_running == true:
        if timer.time_left == 0.0:
            var firstTimeTimer := Timer.new()
            add_child(firstTimeTimer)
            firstTimeTimer.wait_time = float(0.4)
            firstTimeTimer.one_shot = true
            firstTimeTimer.start()
            firstTimeTimer.timeout.connect(_on_first_time_timer_timeout)
        else:
            fire_sfx.stream = load("res://Audio/SFX/sfx_mapwide_tower.ogg")
            fire_sfx.play()
            mapwide_sfx_should_play = false
            
func SetFireRate():
    var _wait_time = 1.0 / (fireRate * 0.25)
    if support_factor.is_empty() == false:
        _wait_time = 1.0 / ((fireRate * 0.25) * support_factor.values().max())
func _look_at_enemy():
    pass
