extends BaseBullet

# tower_type = 10
# Called when the node enters the scene tree for the first time.
func _ready():
    $AnimatedSprite2D.scale.x = 0.75
    $AnimatedSprite2D.scale.y = 0.75
    $AnimatedSprite2D.play("bullet11")
    $AnimatedSprite2D.visible = true

func _on_area_2d_area_entered(area):
    if "Enemy" in area.name:
        if is_equal_approx(area.Health, 0):
            return
    if "Enemy" in area.name:
        area.damage_self(bulletDamage, element_idx, towerType)
