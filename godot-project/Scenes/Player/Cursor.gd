# Player-controlled cursor. Allows them to navigate the game grid, select units, and move them.
# Supports both keyboard and mouse (or touch) input.
# The `tool` mode allows us to preview the drawing code you'll see below in the editor.
@tool
class_name Cursor
extends Node2D

# We'll use signals to keep the cursor decoupled from other nodes.
# When the player moves the cursor or wants to interact with a cell, we emit a signal and let
# another node handle the interaction.

# Emitted when clicking on the currently hovered cell or when pressing "ui_accept".
signal accept_pressed(cell)
# Emitted when the cursor moved to a new cell.
signal moved(new_cell)

# Grid resource, giving the node access to the grid size, and more.
# needs to be set every time a new map is loaded up
@export var grid: Resource = preload("res://Resources/Level1/Level1Grid.tres")
# Time before the cursor can move again in seconds.
# You can see how we use it in the unhandled input function below.
@export var ui_cooldown := 0.1

# Coordinates of the current cell the cursor is hovering.
var cell := Vector2.ZERO : set = set_cell #, get = _get_cell

# We use the timer to have a cooldown on the cursor movement.
@onready var _timer: Timer = $Timer

var game
# When the cursor enters the scene tree, we snap its position to the centre of the cell and we
# initialise the timer with our ui_cooldown variable.
func _ready() -> void:
    _timer.wait_time = ui_cooldown
    position = grid.calculate_map_position(cell)
    game = get_node("/root/Main/Game")

func set_grid(_grid: Grid):
    grid = _grid
    position = grid.calculate_map_position(cell)
    
func _unhandled_input(event: InputEvent) -> void:
    # If the user moves the mouse, we capture that input and update the node's cell in priority.
    if event is InputEventMouseMotion and not game.gameui.button_is_hovered:
        # print_debug("mouse moved, recalculating sell")
        self.cell = grid.calculate_grid_coordinates(event.position)
    # If we are already hovering the cell and click on it, or we press the enter key, the player
    # wants to interact with that cell.
    elif event.is_action_pressed("click") or event.is_action_pressed("ui_accept") and not game.gameui.button_is_hovered:
        #  In that case, we emit a signal to let another node handle that input. The game board will
        #  have the responsibility of looking at the cell's content.
        emit_signal("accept_pressed", cell)
        get_viewport().set_input_as_handled()
        # print_debug("mouse clicked, eating input")

func _process(_delta):
    # constantly draw the white box that shows where the cursor is
    queue_redraw()

    # check for overlap and visually indicate whether a tile is valid 
    # tower placement location
    if get_parent() != null:
        if !get_parent().is_class("PlayerCharacter"):
            return

# We use the draw callback to a rectangular outline the size of a grid cell, with a width of two
# pixels.
func _draw() -> void:
    # Rect2 is built from the position of the rectangle's top-left corner and its size. To draw the
    # square around the cell, the start position needs to be `-grid.cell_size / 2`.
    
    if not game.gameui.button_is_hovered:
        draw_rect(Rect2(-grid.cell_size / 2, grid.cell_size), Color.ALICE_BLUE, false, 2.0)
#    print_debug("drawing rect", cell)

# This function controls the cursor's current position.
func set_cell(value: Vector2) -> void:
    
    # We first clamp the cell coordinates and ensure that we weren't trying to move outside the
    # grid's boundaries.
    var new_cell: Vector2 = grid.clamp(value)
    if new_cell.is_equal_approx(cell):
        return

    cell = new_cell
    # If we move to a new cell, we update the cursor's position, emit a signal, and start the
    # cooldown timer that will limit the rate at which the cursor moves when we keep the direction
    # key down.
    position = grid.calculate_map_position(cell)
    # print_debug("set a cell for cursor position %v to cell %v with cell_pos %v" % [value,cell,position])
    emit_signal("moved", cell)
#    _timer.start()

func _get_cell() -> Vector2:
    return grid.calculate_grid_coordinates(position)

func get_cell_from_position(pos: Vector2) -> Vector2:
    return grid.calculate_grid_coordinates(pos)
