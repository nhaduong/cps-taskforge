@tool
extends Node2D

var center = Vector2(0, 0)
var radius = 10
var color = Color(0.0, 0.0, 1.0, 0.2)

func _draw():
    draw_circle(center, radius, color)
