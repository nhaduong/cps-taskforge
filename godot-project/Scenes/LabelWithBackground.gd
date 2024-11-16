extends ColorRect

@onready var label : RichTextLabel
func _ready():
    for child in get_children():
        if child is RichTextLabel:
            label = child
            break
func set_text(text : String):
    if label:
        label.text = text
    
