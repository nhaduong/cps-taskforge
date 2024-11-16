extends BaseTower

func _initialize():
    damage.visible = false
func Shoot():
    print(currTargets)
    if len(currTargets) > 0:
        fire_sfx.volume_db = -10
        fire_sfx.stream = load("res://Audio/SFX/sfx_freeze_tower.ogg")
        fire_sfx.play()
        $AnimatedSprite2D.stop()
        if $AnimatedSprite2D.sprite_frames.has_animation(config.fire_animation):
            $AnimatedSprite2D.animation = config.fire_animation
            $AnimatedSprite2D.play()
        for n in len(currTargets):
            currTargets[n].Frozen(duration)
        timer.wait_time = float(1 / float(fireRate)) * 2
        timer.start()

func _look_at_enemy():
    pass
