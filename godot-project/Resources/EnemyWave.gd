extends Resource

# ordered list of enemies and the delay between each enemy spawned


class_name EnemyWave

@export var wave : Array[Enemy] # list of (count, enemy)
@export var wave_count : Array[int]
@export var delay : float
@export var spawner_id = 0
@export var enemy_wave_id = 0


    
