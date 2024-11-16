extends BaseTower


func Shoot():
    if curr != null:
        # while curr != null:
        while curr.position.x < 0 and curr.position.x > get_viewport_rect().size.x \
            and curr.position.y < 0 and curr.position.y > get_viewport_rect().size.y:
                continue
        # 4 way bullets        
        var tempBullet1 = Game.bullet_pool.get_bullet(tower_type) # Bullet.instantiate()
        var tempBullet2 = Game.bullet_pool.get_bullet(tower_type) # Bullet.instantiate()
        var tempBullet3 = Game.bullet_pool.get_bullet(tower_type) # Bullet.instantiate()
        var tempBullet4 = Game.bullet_pool.get_bullet(tower_type) # Bullet.instantiate()
        tempBullet1.rotation = Vector2.UP.angle()
        tempBullet2.rotation = Vector2.RIGHT.angle()
        tempBullet3.rotation = Vector2.DOWN.angle()
        tempBullet4.rotation = Vector2.LEFT.angle()
        var tempBulletTarget = global_position
        tempBulletTarget.y -= 50
        tempBullet1.initialTargetVector = global_position.direction_to(tempBulletTarget)
        tempBulletTarget.y += 100
        tempBullet3.initialTargetVector = global_position.direction_to(tempBulletTarget)
        tempBulletTarget.y -= 50
        tempBulletTarget.x -= 50
        tempBullet4.initialTargetVector = global_position.direction_to(tempBulletTarget)
        tempBulletTarget.x += 100
        tempBullet2.initialTargetVector = global_position.direction_to(tempBulletTarget)
        tempBullet1.element_idx = element_idx
        tempBullet2.element_idx = element_idx
        tempBullet3.element_idx = element_idx
        tempBullet4.element_idx = element_idx
        # $BulletContainer.call_deferred("add_child",tempBullet1,true)
        # $BulletContainer.call_deferred("add_child",tempBullet2,true)
        # $BulletContainer.call_deferred("add_child",tempBullet3,true)
        # $BulletContainer.call_deferred("add_child",tempBullet4,true)

        tempBullet1.activate_bullet()
        tempBullet2.activate_bullet()
        tempBullet3.activate_bullet()
        tempBullet4.activate_bullet()

        tempBullet1.global_position = $Aim.global_position
        tempBullet2.global_position = $Aim.global_position
        tempBullet3.global_position = $Aim.global_position
        tempBullet4.global_position = $Aim.global_position
        # tempBullet1.towerType = tower_type
        # tempBullet2.towerType = tower_type
        # tempBullet3.towerType = tower_type
        # tempBullet4.towerType = tower_type
        if support_factor.is_empty() == false:
            tempBullet1.bulletDamage = bulletDamage * support_factor.values().max()
            tempBullet2.bulletDamage = bulletDamage * support_factor.values().max()
            tempBullet3.bulletDamage = bulletDamage * support_factor.values().max()
            tempBullet4.bulletDamage = bulletDamage * support_factor.values().max()
        else:
            tempBullet1.bulletDamage = bulletDamage
            tempBullet2.bulletDamage = bulletDamage
            tempBullet3.bulletDamage = bulletDamage
            tempBullet4.bulletDamage = bulletDamage
            
        if support_factor.is_empty() == false:
            timer.wait_time = float(1 / float(fireRate * support_factor.values().max()))
        else:
            timer.wait_time = float(1 / float(fireRate))
            
        fire_sfx.play()
        $AnimatedSprite2D.stop()
        if $AnimatedSprite2D.sprite_frames.has_animation(config.fire_animation):
            $AnimatedSprite2D.animation = config.fire_animation
            $AnimatedSprite2D.play()
            
func _on_timer_timeout():
    if is_instance_valid(curr):

        _do_shoot()

        if is_instance_valid(curr):
            timer.start()
    else:
        timer.stop()
        
func _get_hotkey_text():
    return "E"
    
func _look_at_enemy():
    pass
