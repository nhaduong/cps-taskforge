@tool
extends Node2D

var rect = Rect2(-32, -32, 64, 64)
var color = Color(0.4, 0.4, 0.4, 0.3)

func _draw():
    draw_rect(rect, color, true)
