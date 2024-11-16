extends BaseBullet

# tower_type == 4
@export var splashArea: Area2D
@export var splash_collision_shape2D: CollisionShape2D
@export var splash_animated_sprite: AnimatedSprite2D
# Called when the node enters the scene tree for the first time.
func _ready():
    $AnimatedSprite2D.scale.x = 0.75
    $AnimatedSprite2D.scale.y = 0.75
    $AnimatedSprite2D.play("bullet5")

    $AnimatedSprite2D.visible = true
    $SplashArea.monitoring = true

func _on_area_2d_area_entered(area):
    if "Enemy" in area.name and stop == false:
        Splash(area.global_position)

func Splash(pos):
    $AnimatedSprite2D.visible = false
    despawn = true
    stop = true
    $SplashArea.visible = true
    $SplashArea/AnimatedSprite2D.visible = true
    
    for area in $SplashArea.get_overlapping_areas():
        if "Enemy" in area.name:
            area.damage_self(bulletDamage, element_idx, towerType)
    self.rotation = 0
    self.position = pos

    $SplashArea/AnimatedSprite2D.play("cannon")
    if not $SplashArea/AnimatedSprite2D.is_connected("animation_finished", _on_despawn_splash_animation_finished):
        $SplashArea/AnimatedSprite2D.animation_finished.connect(_on_despawn_splash_animation_finished)


func _on_despawn_splash_animation_finished():
    #deactivate_bullet()
    queue_free()

func deactivate_bullet():
    super()
    $SplashArea.visible = false
