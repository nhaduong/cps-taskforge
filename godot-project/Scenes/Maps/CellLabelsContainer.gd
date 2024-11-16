extends Node2D


@onready var tilemap = $".."
# Called when the node enters the scene tree for the first time.
func _ready():
    queue_redraw()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
    queue_redraw()
    pass

func _draw():
    var used_cells = tilemap.get_used_cells(0)
    for coord in used_cells:
        var local_pos = tilemap.map_to_local(coord)
        draw_rect(Rect2(local_pos[0] - tilemap.cell_quadrant_size/2,
        local_pos[1] - tilemap.cell_quadrant_size/2,
        tilemap.cell_quadrant_size,tilemap.cell_quadrant_size),
        Color.ALICE_BLUE,false)
