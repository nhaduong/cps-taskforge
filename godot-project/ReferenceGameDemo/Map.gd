extends Node
class_name ReferenceGameMap

var target_object_texture
@export var target_object: String = "sniper"
@export var reference_objects_to_spawn: Array = []

@onready var polygon: Array = $PolygonToSpawnPointsIn.polygon
@onready var n = polygon.size()

var p_radius: int = 100
var k: int = 0
var points := []

var reference_objects = {}
var reference_object_textures = {}
var object_entered = ""
var object_locations_by_name = {}

signal s_on_object_selected(value, target_object)

# the list of objects to automatically randomly spawn on the map
# method for spawning objects randomly without overlap
# the objects will have their own signals where if clicked by player
# then they send an end-round signal, which is checked against the
# correct object to click, and the actual object clicked

# Called when the node enters the scene tree for the first time.
func _ready():
    for child in $ReferenceObjectContainer.get_children():
        child.queue_free()
    _load_reference_objects()
    
    if multiplayer.is_server():
        _spawn_reference_objects()
        get_node("/root/Main/Game/HUD/GameUI/TargetObjectContainer").set_target_obj_image(target_object_texture)
        _sync_server_map_to_clients.rpc()
    
func _load_reference_objects():
    var _ref_scenes = Util.get_scene_loads_from_dir("res://ReferenceGameDemo/ReferenceObjects")
    for _scene in _ref_scenes:
        var _temp_scene = _scene.instantiate()
        reference_objects[_temp_scene.target_name] = _scene
        reference_object_textures[_temp_scene.target_name] = _temp_scene.get_child(0).texture
        _temp_scene.queue_free()
@rpc("authority", "call_local")
func _sync_server_map_to_clients():
    _server_set_target_object.rpc(self.target_object)
    _server_spawn_client_objects.rpc(object_locations_by_name)
    pass
    
@rpc("any_peer", "call_local")
func _server_set_target_object(obj_name):
    if multiplayer.is_server(): return

    print_debug("setting target object on client ", obj_name, " ", multiplayer.get_unique_id())
    self.target_object = obj_name
    if obj_name in reference_object_textures:
        get_node("/root/Main/Game/HUD/GameUI/TargetObjectContainer").set_target_obj_image(reference_object_textures[obj_name])
    
@rpc("any_peer", "call_local")
func _server_spawn_client_objects(obj_locs):
    for obj in obj_locs:
        var loc = obj_locs[obj]
        if obj in reference_objects:
            _spawn_object(reference_objects[obj], loc)
    
func _spawn_reference_objects():
    reference_objects_to_spawn = reference_objects.values()
    points = PoissonDiscSampling.generate_points_for_polygon(polygon, p_radius, 200)
    var random_idxs = range(points.size())
    var random_obj_idxs = range(reference_objects_to_spawn.size())
    random_idxs.shuffle()
    random_obj_idxs.shuffle()
    for i in range(reference_objects_to_spawn.size() - 1):
        print_debug(i)
        _spawn_object(reference_objects_to_spawn[random_obj_idxs[i]], points[random_idxs[i]], i == 0)

    
func _spawn_object(object, point, set_target = false):
    var new_obj = object.instantiate()
    new_obj.position.x = point.x
    new_obj.position.y = point.y
    new_obj.visible = true
    new_obj.name = new_obj.target_name
    
    $ReferenceObjectContainer.add_child(new_obj)

    new_obj.connect("object_selected", _on_object_selected)
    new_obj.connect("mouse_entered", _on_object_mouse_entered.bind(new_obj.target_name))
    new_obj.connect("mouse_exited", _on_object_mouse_exited)
    if set_target:
        target_object = new_obj.target_name
        target_object_texture = new_obj.get_child(0).texture
    object_locations_by_name[new_obj.name] = new_obj.position

func _on_object_selected(obj_name):
    print("emitting object selected signal")
    s_on_object_selected.emit(obj_name, target_object)

func _on_object_mouse_entered(obj_name):
    object_entered = obj_name
func _on_object_mouse_exited():
    object_entered = ""
