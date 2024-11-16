extends Node2D
class_name EnemySpawner

# temp content so init isn't empty
@export var path: Path2D
var startingPosition = Vector2.ZERO
@export var baseEnemy = preload("res://Scenes/Enemies/base_enemy.tscn")
@export var delay: float = 0
@export var wave: Array[Enemy] # [ (count,enemy_scene.tscn) ]
@export var wave_count_info: Array[int]
var wave_count = 0
var num_enemies_to_spawn = 0
var current_enemy_scene
var curr_wave_idx = -1
var wave_idx = 0
var most_recent_spawned_enemy: Node
var is_done_spawning_enemies = false

signal enemy_spawned(enemy_obj)
signal done_spawning_enemies

# Called when the node enters the scene tree for the first time.
func _ready():
    enemy_spawned.connect($"../.."._on_enemy_spawner_enemy_spawned)
    _increment_wave()

func _increment_wave():
    #print_debug("increment wave, ", multiplayer.get_unique_id())
    curr_wave_idx += 1
    if curr_wave_idx < wave.size():
        num_enemies_to_spawn = wave_count_info[curr_wave_idx]
        current_enemy_scene = wave[curr_wave_idx]
        wave_count = 0
    else:
        stop_spawning_enemies()
        
func set_data(_wave, _wave_count_info, _path, _wave_idx, _delay):
    self.wave = _wave
    self.wave_count_info = _wave_count_info
    self.path = _path
    self.wave_idx = _wave_idx
    # self.delay = _delay
    # print_debug("now setting delay ", _delay)
func _start():
    pass

func spawnEnemy():
    #print_debug("now spawning the enemy, ", multiplayer.get_unique_id())
    var newEnemy = baseEnemy.instantiate()
    newEnemy.name += "_%s_%d_%d_%d" % [path.name, curr_wave_idx, wave_count, wave_idx]
    #print_debug("spawning enemy %s" % newEnemy.name, " ",  multiplayer.get_unique_id())
    var pathFollowInstance = PathFollow2D.new()
    pathFollowInstance.loop = false
    pathFollowInstance.rotates = false
    pathFollowInstance.add_child(newEnemy)
    pathFollowInstance.name = "Path2DFollow_%d_%d_%d" % [curr_wave_idx, wave_count, wave_idx]
    path.add_child(pathFollowInstance)
    #print_debug("done add child new enemy to path, ",  multiplayer.get_unique_id())
    newEnemy.position = startingPosition
    
    newEnemy.set_config(current_enemy_scene, path.curve, pathFollowInstance, startingPosition)
#    newEnemy.show()
    wave_count += 1
    
    newEnemy.process_mode = Node.PROCESS_MODE_DISABLED

    most_recent_spawned_enemy = newEnemy
    
    enemy_spawned.emit(newEnemy)
    #print_debug("done spawning enemy emit signal ", multiplayer.get_unique_id())
    

func _on_timer_timeout():
    #print_debug("timer timeout, spawn an enemy ", multiplayer.get_unique_id())
    spawnEnemy()
    #print_debug("done spawn enemy timer timeout ", multiplayer.get_unique_id())
    if wave_count == num_enemies_to_spawn:
        _increment_wave()
        #print_debug("need to increment wave ", multiplayer.get_unique_id())

    # stop the timer after a single enemy is spawned because
    # we need to wait for the host to tell us all clients have spawned
    # a single enemy appropriately  
    $Timer.stop()
    #print_debug("stop timer on timer timeou ", multiplayer.get_unique_id())
    
func continue_spawning_enemies():
    #print_debug("continue spawning enemies? ", multiplayer.get_unique_id())
    if most_recent_spawned_enemy != null:
        most_recent_spawned_enemy.process_mode = Node.PROCESS_MODE_INHERIT
        most_recent_spawned_enemy = null

    if not is_done_spawning_enemies and GameState.wave_running:
        #print_debug("not done spawning enemies, restart timer ", multiplayer.get_unique_id())
        $Timer.start()

func stop_spawning_enemies():
    #print_debug("stop spawning enemies ", multiplayer.get_unique_id())
    $Timer.stop()
    # get_node("/root/Main/Game").num_enemy_spawners_running -= 1
    is_done_spawning_enemies = true
    done_spawning_enemies.emit()
func start_spawning_enemies():
    #print_debug("start spawning enemies ", multiplayer.get_unique_id())
    is_done_spawning_enemies = false
    curr_wave_idx = 0
    # print_debug("our delay before spawning enemies: ", self.delay, self.delay == 0)
    # if self.delay != 0:
    #     print_debug("delay before start spawning enemies, ", delay)
    #     await get_tree().create_timer(delay).timeout
    $Timer.start()
