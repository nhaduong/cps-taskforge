extends BaseTower

func _initialize():
    damage.visible = false
    effectDuration.visible = true


func set_scale_modifier(modifier: Vector2):
    $AnimatedSprite2D.scale.x = modifier.x * 0.6
    $AnimatedSprite2D.scale.y = modifier.y * 0.6
    
func Shoot():
    if len(currTargets) > 0:
        fire_sfx.volume_db = -15
        fire_sfx.stream = load("res://Audio/SFX/sfx_fear_tower.ogg")
        fire_sfx.play()
        $AnimatedSprite2D.stop()
        if $AnimatedSprite2D.sprite_frames.has_animation(config.fire_animation):
            $AnimatedSprite2D.animation = config.fire_animation
            $AnimatedSprite2D.play()
        for n in len(currTargets):
            currTargets[n].Feared(duration)
        timer.wait_time = float(1 / float(fireRate)) * 2
        timer.start()

func _look_at_enemy():
    pass
