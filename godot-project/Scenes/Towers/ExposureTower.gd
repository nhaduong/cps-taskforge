extends BaseTower

func _initialize():
    firerate.visible = false
    effectDuration.visible = false

func set_scale_modifier(modifier: Vector2):
    $AnimatedSprite2D.scale.x = modifier.x * 0.6
    $AnimatedSprite2D.scale.y = modifier.y * 0.6
func _on_tower_area_exited(body):

    if "Enemy" in body.name:
        body.ExposureLevel = 1.0
func _on_tower_area_entered(body):

    if "Enemy" in body.name:
        body.ExposureLevel += bulletDamage / 5
func _get_hotkey_text():
    return "W"
func Shoot():
    pass
