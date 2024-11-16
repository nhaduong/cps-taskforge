extends Resource

class_name Enemy

@export var walking_animation := "walk"
@export var die_animation := "die"
@export var icon : Texture
@export var speed  = 5
@export var health = 10.0
@export var damage = 1
@export var score_value = 10
@export var money_earned_on_death = 50
# multiply modifiers by bullet type to get final damage to enemy

@export var fireResistance = .3
@export var waterResistance = .3
@export var earthResistance = .3
@export var airResistance = .3

#func _init(p_icon,p_speed,p_health,p_fireModifier,p_waterModifier,p_earthModifier,p_airModifier):
#        pass

func get_final_damage(dmg,element_idx):
    # print_debug("dmg %d element_idx %d" % [dmg,element_idx])
    if element_idx == 1: # fire bullet
        return float(dmg * fireResistance)
    elif element_idx == 2: # water bullet
        return float(dmg * waterResistance)
    elif element_idx == 3:
        return float(dmg * earthResistance)
    elif element_idx == 4:
        return float(dmg * airResistance)
    else:
        return float(dmg)
