# Panel that displays and enables sending of chat messages
extends Control

signal text_sent(text)
signal edit_started
signal edit_ended

var is_focused = false
var is_mouse_entered = false

# Number of replies stored in the chat history
const HISTORY_LENGTH := 20

# Count of replies currently stored in the chat history
var reply_count := 0

#@onready var chat_log: RichTextLabel = $ScrollContainer/ChatLog
var chatlog_scene = preload("res://UI/ChatLog.tscn")
@export var text_edit: TextEdit
@export var chat_log_vbox: VBoxContainer
@export var scroll_container: ScrollContainer

@export var text_edit_system: TextEdit
@export var chat_log_vbox_system: VBoxContainer
@export var scroll_container_system: ScrollContainer

@export var new_msgs_icon: Texture2D
@export var no_new_msgs_icon: Texture2D

func _init() -> void:
#    visible = false
    pass


func _ready() -> void:
    for child in chat_log_vbox.get_children():
        child.queue_free()
    for child in chat_log_vbox_system.get_children():
        child.queue_free()
        
    ## DEBUG
#    for i in range(100):
#        add_reply("text reply","User",Color.AQUA)
    text_edit.text = ""
    $BG/TabContainer.set_tab_icon(0, no_new_msgs_icon)
    $BG/TabContainer.set_tab_icon(1, no_new_msgs_icon)

    if not get_node("/root/Main/Game").Config.current_text_chat_enabled:
        $BG/TabContainer/Chat/HBoxContainer.visible = false
        text_edit.editable = false
func _unhandled_key_input(event):
    if not get_node("/root/Main/Game").Config.current_text_chat_enabled:
        return
    if event.is_action("ui_text_completion_accept"):
        if text_edit.has_focus():
            _on_send_button_pressed()
    if event.is_action("click") and not mouse_entered:
        text_edit.release_focus()
        text_edit.hide()
        text_edit.show()
        

# Add a new reply to the chat box, taking `HISTORY_LENGTH` into account.
func add_reply(text: String, sender_name: String, color: Color, channel = "chat") -> void:
#    if reply_count == HISTORY_LENGTH:
#        chat_log.text = chat_log.text.substr(chat_log.text.find("\n"))
#    else:
    reply_count += 1
        
    var formatted_text = (
        "\n[color=#%s]%s[/color]: %s"
        % [color.to_html(false), sender_name, text]
    ).rstrip("\n").lstrip("\n")

    var _scroll_bar
    var label = chatlog_scene.instantiate()
    label.text = formatted_text
    
    if channel == "chat":
    
        _scroll_bar = scroll_container.get_v_scroll_bar()
        
        chat_log_vbox.add_child(label)
        
        if $BG/TabContainer.current_tab != 0:
            $BG/TabContainer.set_tab_icon(0, new_msgs_icon)
        
    else:
        _scroll_bar = scroll_container_system.get_v_scroll_bar()
        chat_log_vbox_system.add_child(label)
        if $BG/TabContainer.current_tab != 1:
            $BG/TabContainer.set_tab_icon(1, new_msgs_icon)
        
    label.show()
    await get_tree().process_frame
    await get_tree().process_frame

func send_chat_message() -> void:
    if text_edit.text.length() == 0:
        return
    var text: String = text_edit.text.replace("[", "{").replace("]", "}")
    emit_signal("text_sent", text)
    text_edit.text = ""


func _on_send_button_pressed() -> void:
    send_chat_message()
    print_debug("sending chat message")


func _on_line_edit_text_submitted(_new_text: String) -> void:
    send_chat_message()


func _on_line_edit_focus_entered() -> void:
    emit_signal("edit_started")
    is_focused = true
    

func _on_line_edit_focus_exited() -> void:
    emit_signal("edit_ended")
    is_focused = false
 

func _on_toggle_chat_box_button_toggled(button_pressed: bool) -> void:
    visible = button_pressed


func _on_text_edit_focus_entered():
    emit_signal("edit_started")
    is_focused = true
    pass # Replace with function body.


func _on_text_edit_focus_exited():
    emit_signal("edit_ended")
    is_focused = false
    pass # Replace with function body.


func _on_text_edit_mouse_entered():
    is_mouse_entered = true
#    print_debug("MOUSE ENTERED")
    pass # Replace with function body.


func _on_text_edit_mouse_exited():
    is_mouse_entered = false
#    print_debug("MOUSE EXITED")
    pass # Replace with function body.

func _on_tab_container_tab_changed(tab):
    $BG/TabContainer.set_tab_icon(tab, no_new_msgs_icon)

func _on_tab_container_tab_clicked(tab):
    $BG/TabContainer.set_tab_icon(tab, no_new_msgs_icon)
