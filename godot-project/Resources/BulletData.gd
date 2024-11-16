extends Resource

var BulletSprite : Sprite2D
@export var Speed = 200
@export var BulletDamage = 5

func _init(p_bulletSprite, p_speed,p_bulletDamage):
    BulletSprite = p_bulletSprite
    Speed = p_speed
    BulletDamage = p_bulletDamage
