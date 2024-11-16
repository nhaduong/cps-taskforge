extends Tooltip

@export var tower_config_parent : Node


func _custom_show() -> void:
    _timer.stop()
    
    var tower_config = tower_config_parent.config
    
    if tower_config_parent is BaseTower:
    
        _visuals.set_label_texts("%.1f (+%.1f)" % [tower_config.fireRate, tower_config_parent.fireRate - tower_config.fireRate],
        "%.1f (+%.2f)" % [tower_config.dmg, tower_config_parent.bulletDamage - tower_config.dmg],
        "%.1f (+%.1f)" % [tower_config.duration, tower_config_parent.duration - tower_config.duration],
        "%.1f (+%.1f)" % [tower_config.range, tower_config_parent.range - tower_config.range],
        "%.1f" % [tower_config_parent._get_sell_amount()],
        "%.1f" % [tower_config.cost],
        "%s" % tower_config.description,
        tower_config.display_name + " Tower")
    else:
        _visuals.set_label_texts("%.1f" % [tower_config.fireRate],
        "%.2f" % [tower_config.dmg],
        "%.1f" % [tower_config.duration],
        "%.1f" % [tower_config.range],
        "" , # sell amount
        "%.1f" % [tower_config.cost],
        "%s" % tower_config.description,
        tower_config.display_name + " Tower")

    var game = get_node("/root/Main/Game")
    
    if tower_config_parent is BaseTower:
        if tower_config_parent.cell in game._towers:
            _visuals.set_is_sell()
    else:
        _visuals.set_is_buy()
    _visuals.set_is_effect_duration_tower(tower_config.tower_type)
    _visuals.show()
