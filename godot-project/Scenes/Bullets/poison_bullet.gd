extends BaseBullet

# tower_type == 1
@export var splashArea: Area2D
@export var splash_collision_shape2D: CollisionShape2D
@export var splash_animated_sprite: AnimatedSprite2D

var poison_duration = 0
# Called when the node enters the scene tree for the first time.
func _ready():
    $AnimatedSprite2D.play("bullet2")

    $AnimatedSprite2D.visible = true
    $SplashArea.monitoring = true
    pass # Replace with function body.


func _on_area_2d_area_entered(area):
    if "Enemy" in area.name:
        if is_equal_approx(area.Health, 0):
#            print_debug("do nothing because this is an invisible enemy")
            return

    Splash(area.global_position)

func Splash(pos):
    $AnimatedSprite2D.visible = false
    despawn = true
    stop = true
    $SplashArea.visible = true
    $SplashArea/AnimatedSprite2D.visible = true
    
    for area in $SplashArea.get_overlapping_areas():
        if "Enemy" in area.name and area.amIPoisoned == false:
            area.Poisoned(bulletDamage, element_idx, poison_duration)
    self.rotation = 0
    self.position = pos
    
    $SplashArea/AnimatedSprite2D.play("poison")
    if not $SplashArea/AnimatedSprite2D.is_connected("animation_finished", _on_despawn_poison_animation_finished):
        $SplashArea/AnimatedSprite2D.animation_finished.connect(_on_despawn_poison_animation_finished)


func _on_despawn_poison_animation_finished():
    #deactivate_bullet()
    queue_free()

func deactivate_bullet():
    super()
    $SplashArea.visible = false
