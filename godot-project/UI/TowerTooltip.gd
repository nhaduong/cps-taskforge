extends Control




@export var firerate_label : Label
@export var effect_dur_label : Label
@export var damage_label : Label
@export var range_label : Label
@export var sell_label : Label
@export var buy_label : Label
@export var description_label : Label
# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.




func set_label_texts(firerate,damage,effect_dur,_range,sell,buy,description,tower_name):
    firerate_label.text = "Firerate: %s" % firerate
    damage_label.text = "Damage: %s" % damage
    effect_dur_label.text = "Effect Dur.: %s" % effect_dur
    range_label.text = "Range: %s" % _range
    sell_label.text = "Sell: %s" % sell
    buy_label.text = "Buy: %s" % buy
    description_label.text = tower_name + "\n" + description
func set_is_sell():
    sell_label.visible = true
    buy_label.visible = false
func set_is_buy():
    sell_label.visible = false
    buy_label.visible = true

func set_is_effect_duration_tower(tower_type):
    if tower_type in [2,6]:
        effect_dur_label.visible = true
        damage_label.visible = false
    else:
        effect_dur_label.visible = false
        damage_label.visible = true
