extends VBoxContainer

class_name WavePreviewSingle
@export var info_label : Label
@export var preview_container : Control
@export var enemy_preview_single : PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
    
    pass # Replace with function body.

func reinitialize():
    if preview_container:
        for child in preview_container.get_children():
            child.queue_free()
func set_data(_wave_num,spawner_num):
    info_label.text = "Spawner: %d" % [spawner_num]
# Called every frame. 'delta' is the elapsed time since the previous frame.
func spawn_preview(enemy : Enemy, wave_count : int) -> void:
    if is_equal_approx(enemy.health,0):
        return
    var enemy_preview = enemy_preview_single.instantiate()
    enemy_preview.set_data(enemy.icon,wave_count)
    if enemy.health > 0:
        enemy_preview.visible = true
#    print_debug("enemy ", enemy, "wave count ", wave_count)
    preview_container.add_child(enemy_preview)
