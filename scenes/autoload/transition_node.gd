extends ColorRect

func fade_in(duration: float = 1.5):
	var tween: Tween = create_tween()
	tween.tween_property(TransitionNode, "color:a", 1.0, duration)
	await tween.finished

func fade_out(duration: float = 1.5):
	var tween: Tween = create_tween()
	tween.tween_property(TransitionNode, "color:a", 0.0, duration)
	await tween.finished
