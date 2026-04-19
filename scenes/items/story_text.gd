extends StaticBody3D

@export var text_tag := "journal_1"
@export var ui_type := Globals.UITextType.JOURNAL

func interact(player, hand):
	if hand != "none":
		return
	
	if player.is_ui_open():
		return
	
	# Remove interaction label before displaying UI, slightly lesser visual noise
	player.interaction_label.text = ""
	player.crosshair.visible = false
	player.show_ui(text_tag, ui_type)
