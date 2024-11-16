extends BaseTower


func _initialize():
    firerate.visible = false
    effectDuration.visible = false

func _on_tower_area_entered(body):
    if "Tower" in body.name and body.get_parent() != self:
        supportedTowers.append(body)
        Support(1.0 + float(bulletDamage / 10))
func _on_tower_area_exited(body):
    if "Tower" in body.name and body.get_parent() != self:
        body.get_parent().support_factor.erase(self)
        supportedTowers.erase(body)
        body.get_parent().SetRange()
        body.get_parent()._set_upgrade_button_states()

func Support(support_number):
    for body in supportedTowers:
        if body.get_parent().tower_type != 5:
            body.get_parent().support_factor[self] = support_number
            body.get_parent().SetRange()
            body.get_parent().SetFireRate()
            body.get_parent()._update_info()
@rpc("any_peer", "call_local")
func _upgrade_range(num_upgrades):
    
    # default base tower
    range += 1.0 * float(num_upgrades)
    SetRange()
    

    if support_factor.is_empty() == false:
        Support((1.0 + float(bulletDamage / 10)) * support_factor.values().max())
    else:
        Support(1.0 + float(bulletDamage / 10))

func _upgrade_damage(num_upgrades):
    bulletDamage += (num_upgrades ** 2 / 12.8 + .2 * num_upgrades)
    
    if support_factor.is_empty() == false:
        Support((1.0 + float(bulletDamage / 10)) * support_factor.values().max())
    else:
        Support(1.0 + float(bulletDamage / 10))

func _downgrade_range(num_upgrades):
    range -= 1.0 * num_upgrades
    SetRange()
    
    if support_factor.is_empty() == false:
        Support((1.0 + float(bulletDamage / 10)) * support_factor.values().max())
    else:
        Support(1.0 + float(bulletDamage / 10))

func _downgrade_damage(num_upgrades):
    bulletDamage -= (num_upgrades ** 2 / 12.8 + .2 * num_upgrades)
    
    if support_factor.is_empty() == false:
        Support((1.0 + float(bulletDamage / 10)) * support_factor.values().max())
    else:
        Support(1.0 + float(bulletDamage / 10))

func _look_at_enemy():
    pass
func _do_shoot():
    pass

func EraseSelf():
    for body in supportedTowers:
        body.get_parent().support_factor.erase(self)
        body.get_parent().SetRange()
        body.get_parent().SetFireRate()
    for body in discountedTowers:
        body.get_parent().discount.erase(self)
