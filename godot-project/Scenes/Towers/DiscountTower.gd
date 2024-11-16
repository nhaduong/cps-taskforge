extends BaseTower


func _initialize():
    firerate.visible = false
    effectDuration.visible = false

@rpc("any_peer", "call_local")
func _upgrade_damage(num_upgrades):
    bulletDamage += (num_upgrades ** 2 / 12.8 + .2 * num_upgrades)

    if support_factor.is_empty() == false:
        Discount(bulletDamage * support_factor.values().max())
    else:
        Discount(bulletDamage)

@rpc("any_peer", "call_local")
func _downgrade_damage(num_upgrades):
    bulletDamage -= (num_upgrades ** 2 / 12.8 + .2 * num_upgrades)

    if support_factor.is_empty() == false:
        Discount(bulletDamage * support_factor.values().max())
    else:
        Discount(bulletDamage)

func EraseSelf():
    for body in supportedTowers:
        body.get_parent().support_factor.erase(self)
        body.get_parent().SetRange()
        body.get_parent().SetFireRate()
    for body in discountedTowers:
        body.get_parent().discount.erase(self)

func _on_tower_area_exited(body):
    if "Tower" in body.name:
        body.get_parent().discount.erase(self)
        discountedTowers.erase(body)
        body.get_parent()._set_upgrade_button_states()
func _on_tower_area_entered(body):
    if "Tower" in body.name and body.get_parent() != self:
        await get_tree().create_timer(0.1).timeout
        discountedTowers.append(body)
        if support_factor.is_empty() == false:
            Discount(bulletDamage * support_factor.values().max())
        else:
            Discount(bulletDamage)
func _look_at_enemy():
    pass
func _do_shoot():
    pass

func Discount(amount):
    for body in discountedTowers:
        if not body:
            discountedTowers.erase(body)
            continue
        body.get_parent().discount[self] = amount
        body.get_parent()._set_upgrade_button_states()
        body.get_parent()._update_info()
