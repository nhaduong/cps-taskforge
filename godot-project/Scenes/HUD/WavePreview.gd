extends Node2D

class_name WavePreview

@export var wave_preview_single: PackedScene
@export var previews_container: BoxContainer
# Called when the node enters the scene tree for the first time.
func _ready():
#    if GameState.current_config.current_is_rts:
#        visible = false
        
    for child in previews_container.get_children():
        child.queue_free()
    pass # Replace with function body.


func spawn_all_previews(enemy_wave_data: Array[EnemyWave]):
    # all_enemy_waves : Array[Enemy], all_enemy_wave_counts : Array[int], all_enemy_spawners : Array[int]) -> void:
    for child in previews_container.get_children():
        child.queue_free()
    for enemy_wave in enemy_wave_data:
        var preview_single = wave_preview_single.instantiate()
        preview_single.set_data(enemy_wave.enemy_wave_id, enemy_wave.spawner_id)
        preview_single.reinitialize()
        assert(enemy_wave.wave.size() == enemy_wave.wave_count.size())
        for i in range(enemy_wave.wave.size()):
            preview_single.spawn_preview(enemy_wave.wave[i], enemy_wave.wave_count[i])
            
            
        preview_single.visible = true
        
        previews_container.add_child(preview_single)

    
@rpc("authority", "call_local")
func show_appropriate_previews(inds: Array):
    for ind in inds:
        if ind < get_child_count():
            get_child(ind).visible = true
