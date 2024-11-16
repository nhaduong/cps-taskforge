extends Panel

func _on_visibility_changed_custom(kwargs):
    if "correct_answer" in kwargs:
        #$RichTextLabel.text = "The correct answer was: %s" % kwargs["correct_answer"]
        $RichTextLabel.text = "Incorrect!"
    else:
        $RichTextLabel.text = "You're correct!"
