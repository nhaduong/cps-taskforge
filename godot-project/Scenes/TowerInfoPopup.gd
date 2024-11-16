extends Panel

@export var firerate_label: RichTextLabel
@export var effect_dur_label: RichTextLabel
@export var damage_label: RichTextLabel
@export var range_label: RichTextLabel
@export var name_label: RichTextLabel
@export var buy_label: RichTextLabel
@export var description_label: RichTextLabel
@export var hotkey_label: RichTextLabel

@export var default_position = Vector2(1202, 15)
@export var alt_position = Vector2(1202, 686)
# Called when the node enters the scene tree for the first time.
func _ready():
    hide()
    pass # Replace with function body.


func set_label_texts(firerate, damage, effect_dur, _range, buy, description, tower_name, hotkey):
    firerate_label.text = "Fire rate: %s" % firerate
    damage_label.text = "Damage: %s" % damage
    effect_dur_label.text = "Duration: %s" % effect_dur
    range_label.text = "Range: %s" % _range
    name_label.text = "%s" % tower_name
    buy_label.text = "$%s" % buy
    description_label.text = description
    hotkey_label.text = "Hotkey: %s" % hotkey
    
    name_label.visible = GameState.current_config.current_show_tower_name
    description_label.visible = GameState.current_config.current_show_tower_description
 

func set_is_effect_duration_tower(tower_type):
    damage_label.show()
    effect_dur_label.show()
    firerate_label.show()
    
    if tower_type in [5, 8, 11]:
        damage_label.text = damage_label.text.replace("Damage", "Effect Strength")
    if tower_type in [2, 6]:
        effect_dur_label.visible = true
        damage_label.visible = false
    else:
        effect_dur_label.visible = false
    if tower_type in [5, 8, 11]:
        firerate_label.visible = false
        effect_dur_label.visible = false
    if tower_type == 1:
        firerate_label.visible = false
        effect_dur_label.visible = true

    if tower_type == 7:
        effect_dur_label.visible = false
        
func move_panel_location():
    self.global_position = alt_position
func reset_default_location():
    self.global_position = default_position


func _on_visibility_changed():
    pass # Replace with function body.
