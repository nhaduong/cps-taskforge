extends BaseBullet

#tower_type == 12
# Called when the node enters the scene tree for the first time.
func _ready():
    $AnimatedSprite2D.play("bullet13")
    $AnimatedSprite2D.visible = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    pass
