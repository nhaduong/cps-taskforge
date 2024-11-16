extends Resource

# Starting resources for a level


class_name LevelData

@export var Gold = 4000
@export var Gold_RTS = 2000
@export var Health = 10
@export var AvailableUnits: Array[Dictionary]

@export var Map: PackedScene # which contains its own logic for spawning waves in the appropriate locations
@export var grid: Grid # used for drawing the coordinate grid
@export var valid_buy_tiles: Array[Vector2i] # which tiles towers are allowed to be placed on

@export var wave_timer_minutes_RTS = 5
@export var wave_timer_seconds_RTS = 0
@export var wave_timer_minutes = 5
@export var wave_timer_seconds = 0

# set this to a custom value to give specific levels 
# a certain number of rounds to repeat, like tutorial=1
@export var num_rounds_for_this_level_override = -1
