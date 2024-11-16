extends MarginContainer

class_name EnemyPreviewSingle

@export var sprite_texture : TextureRect
@export var enemy_count : Label

# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.


    
func set_data(_sprite : Texture, _count : int) -> void:
    sprite_texture.texture = _sprite
    enemy_count.text = "%d" % _count
