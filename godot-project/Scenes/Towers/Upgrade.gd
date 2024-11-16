# Upgrade menu UI container
# contains logic to automatically ensure the menu
# doesn't run off the sides of the screen
# and manual overrides to prevent getting hidden underneath a fixed UI panel
extends Node2D

# padding so bg isn't exactly the width of the UI buttons
@export var bg_padding := 25
@export var upgrade_menu_bg : TextureRect
# max size of the playable map grid
@export var manual_viewport_size : Vector2i
@export var upgrade_menu_container : Container

@export var offset : Vector2i

func _on_visibility_changed():
    
    upgrade_menu_container.size.x = 0
    await get_tree().process_frame
    # resize the bg because menus can have different number of buttons
    var bg_width = upgrade_menu_container.size.x + bg_padding
    upgrade_menu_bg.size.x = bg_width
    # check if we need to move to right
    var final_x = -upgrade_menu_bg.size.x/2 
    if upgrade_menu_bg.global_position.x < 0:
        final_x = offset.x
    # check if ndeed to move left
    elif upgrade_menu_bg.global_position.x + upgrade_menu_bg.size.x > manual_viewport_size.x:
        final_x = -upgrade_menu_bg.size.x - offset.x
    # check if we need to move down
    
    var final_y = -128 - offset.y - upgrade_menu_bg.size.y/4
    if upgrade_menu_bg.global_position.y + upgrade_menu_bg.size.y/2 < 0:
        final_y = 128 + offset.y + upgrade_menu_bg.size.y/4
        
    upgrade_menu_bg.set_position(Vector2(final_x,final_y))
    pass # Replace with function body.


func _on_texture_rect_visibility_changed():
    _on_visibility_changed()
