extends BaseTower

func _initialize():
    firerate.visible = false

func Shoot():
    if curr != null:
        # while curr != null:
        while curr.position.x < 0 and curr.position.x > get_viewport_rect().size.x \
            and curr.position.y < 0 and curr.position.y > get_viewport_rect().size.y:
                continue

        print("getting poison bullet tower type: ", tower_type)
        var tempBullet = Game.bullet_pool.get_bullet(tower_type) # Bullet.instantiate()
        tempBullet.poison_duration = duration
        
        var enemy_progress = 1.0
        enemy_progress = curr.pathToFollow.progress + ((global_position.distance_to(curr.global_position) / (tempBullet.Speed * get_physics_process_delta_time())) * (curr.speed * get_physics_process_delta_time()))
        tempBullet.target = curr.path_curve.sample_baked(enemy_progress)

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
