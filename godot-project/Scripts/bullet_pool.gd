class_name BulletPool
extends Node

var pool = {} # towerType : [ bullets ]
var tower_types = [0, 1, 3, 4, 9, 10, 12]
var bullets_to_instance = 100
var multi_bullets_to_instance = 100
@export var base_bullet_scene: PackedScene

var bullet_templates = {}

# Called when the node enters the scene tree for the first time.
func _ready():
    reinitialize()


    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
    pass
    
func reinitialize():
    for child in get_children():
        if is_instance_valid(child):
            child.queue_free()
    pool.clear()

    var _bullets = Util.get_scene_loads_from_dir("res://Scenes/Bullets/")
    for _scene in _bullets:
        for i in range(0, bullets_to_instance):
            var tempBullet = _scene.instantiate()
            tempBullet.visible = false
            tempBullet.set_process(false)
            tempBullet.set_physics_process(false)
            if tempBullet.towerType not in pool:
                pool[tempBullet.towerType] = []
                bullet_templates[tempBullet.towerType] = _scene
            pool[tempBullet.towerType].append(tempBullet)
            call_deferred("add_child", tempBullet, true)
    

func get_bullet(bullet_type):
    var tempBullet
    if bullet_type in pool.keys():
        if pool[bullet_type].size() > 0:
            return pool[bullet_type].pop_back()
        else:
            tempBullet = bullet_templates[bullet_type].instantiate()
            tempBullet.visible = false
            tempBullet.set_process(false)
            tempBullet.set_physics_process(false)
            pool[bullet_type].append(tempBullet)
            call_deferred("add_child", tempBullet, true)
            return tempBullet
    
func return_bullet(bullet_type, bullet):
    if bullet_type in pool.keys():
        pool[bullet_type].append(bullet)
    else:
        pool[bullet_type] = [bullet]
