extends Panel


@onready var close_btn = $Close
@onready var label = $RichTextLabel
# Called when the node enters the scene tree for the first time.
func _ready():
    visible = false
#
#func _start():
#    visible = false


func set_score_info(val,enemy_values,health,end_of_exp=false):
    if health <= 0:
        label.text = "You died!\nScore:\n%d" % enemy_values
    else:
        label.text = "You won!\nScore:\n%d\n%d\nFinal score: %d" % [enemy_values,val-enemy_values,val]

    if end_of_exp:
        label.text += "\nEnd of experiment! Thanks for participating!"
        
