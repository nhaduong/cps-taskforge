extends BaseBullet

# tower_type == 9
@export var puddle_animated_sprite: AnimatedSprite2D
@export var puddleArea: Area2D
@export var puddle_collision_shape2d: CollisionShape2D

var puddle_duration = 0
# Called when the node enters the scene tree for the first time.
func _ready():
    $AnimatedSprite2D.play("bullet0")
    $AnimatedSprite2D.visible = true

    $Puddle/PuddleArea.monitoring = true


func _physics_process(delta):
    if not visible:
        return
    var distance = Speed * delta
    var motion = transform.x * Speed * delta

    if self.position.distance_to(target) <= 1:
        Puddle(target)
    if stop == true and tick == true and despawn == false:
        var hit = false
        for area in $Puddle/PuddleArea.get_overlapping_areas():
            if "Enemy" in area.name:
                area.damage_self(bulletDamage, element_idx, towerType)
                hit = true
        if hit == true:
            $Puddle.stop()
            $Puddle.play("fire")
            tick = false
            var puddleTickTimer := Timer.new()
            add_child(puddleTickTimer)
            puddleTickTimer.wait_time = 1.0
            puddleTickTimer.start()
            puddleTickTimer.timeout.connect(_on_puddle_tick_timer_timeout)
    if stop == true and $Puddle.is_playing() == false and despawn == false:
        $Puddle.play("idle")

    if stop == false:
#        move_and_slide()
        position += motion

func _on_area_2d_area_entered(area):
    if "Enemy" in area.name:
        if is_equal_approx(area.Health, 0):
#            print_debug("do nothing because this is an invisible enemy")
            return

    if "Enemy" in area.name and stop == false:
        Puddle(area.global_position)

func Puddle(pos):
    stop = true
    $AnimatedSprite2D.visible = false
    self.rotation = 0
    self.position = pos
    $Puddle.scale.x = 0.75
    $Puddle.scale.y = 0.75
    $Puddle.visible = true
    $Puddle.play("instantiate")
    var puddleTimer := Timer.new()
    add_child(puddleTimer)
    puddleTimer.wait_time = float(puddle_duration)
    puddleTimer.one_shot = true
    puddleTimer.start()
    puddleTimer.timeout.connect(_on_puddle_duration_timer_timeout)
    tick = true

func _on_puddle_duration_timer_timeout():
    despawn = true
    $Puddle.stop()
    $Puddle.play_backwards("instantiate")
    if not $Puddle.is_connected("animation_finished", _on_despawn_puddle_animation_finished):
        $Puddle.animation_finished.connect(_on_despawn_puddle_animation_finished)

func _on_puddle_tick_timer_timeout():
    tick = true
    
func _on_despawn_puddle_animation_finished():
    #deactivate_bullet()
    queue_free()

func deactivate_bullet():
    super()
    $Puddle.visible = false
