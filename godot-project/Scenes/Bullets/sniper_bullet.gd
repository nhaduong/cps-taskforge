extends BaseBullet

# tower type 3

# Called when the node enters the scene tree for the first time.
func _ready():
    $AnimatedSprite2D.scale.x = 0.5
    $AnimatedSprite2D.scale.y = 0.5
    $AnimatedSprite2D.play("bullet4")

    $AnimatedSprite2D.visible = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    pass
