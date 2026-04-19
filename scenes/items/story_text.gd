extends StaticBody3D

@export var text_tag := "journal_1"
@export var ui_type := Globals.UITextType.JOURNAL

func interact(player, hand):
	if hand != "none":
		return
	
	if player.is_ui_open():
		return
	
	player.show_ui(text_tag, ui_type)

func fyi_ui_should_never_be_tied_to_the_player_there_is_no_way_to_call_it_from_other_nodes_and_i_need_to_use_this_hacky_solution(player: Player):
	player.show_ui(text_tag, ui_type)
