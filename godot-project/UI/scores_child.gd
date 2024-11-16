extends HBoxContainer

@export var team_name_label : Label
@export var score_label : Label

func set_data(team,score):
    team_name_label.text = team
    if typeof(score) != 4:
        score = "%d" % score
    score_label.text = score
