extends Node2D
class_name BaseBullet

var target = Vector2.ZERO
@export var Speed = 300
var pathName = ""
var bulletDamage = 1.0
var initialTargetVector = 0
var element_idx = 0
@export var towerType = 0
var stop = false
var tick = false
var despawn = false


func _ready():
    $AnimatedSprite2D.scale.x = 0.6
    $AnimatedSprite2D.scale.y = 0.6
    $AnimatedSprite2D.play("bullet1")
    visible = true
func _physics_process(delta):
    if not visible:
        return
    var distance = Speed * delta
    var motion = transform.x * Speed * delta
    
    if stop == false:

        position += motion
        return

    
func _on_visible_on_screen_notifier_2d_screen_exited():
    # queue_free()
    deactivate_bullet()

func deactivate_bullet():
    visible = false
    set_process(false)
    set_physics_process(false)
    get_node("/root/Main/Game").bullet_pool.return_bullet(towerType, self)
    position = Vector2(-1000, -1000)


func activate_bullet():
    visible = true
    set_process(true)
    set_physics_process(true)

func _on_area_2d_area_entered(area):
#    print_debug("area 2d entered ", area.name, " ", "Enemy" in area.name)
    if "Enemy" in area.name:
        if is_equal_approx(area.Health, 0):
#            print_debug("do nothing because this is an invisible enemy")
            return
        else:
            area.damage_self(bulletDamage, element_idx, towerType)
            # queue_free()
            deactivate_bullet()
