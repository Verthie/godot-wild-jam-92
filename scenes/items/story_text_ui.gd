extends CanvasLayer

@export var title_label: Label
@export var body_label: RichTextLabel

var full_length := 0
var typing := false

var timer := 0.0
@export var chars_per_second := 60.0

var current_page := 0
var pages: Array = []



func _ready():
	body_label.visible_characters = 0
	
func _process(delta):
	if not typing:
		return

	timer += delta * chars_per_second
	
	body_label.visible_characters = min(int(timer), full_length)
	
	if body_label.visible_characters >= full_length:
		body_label.visible_characters = full_length
		typing = false
	
	#if char_index % 2 == 0:
	#	AudioManager.play_sound(...)


func start_page(title: String, text: String):
	typing = false
	
	title_label.text = title
	
	body_label.clear()
	body_label.append_text(text)
	
	full_length = text.length()
	timer = 0.0
	
	body_label.visible_characters = 0
	typing = true

func show_pages(new_pages):
	pages = new_pages
	current_page = 0
	show_current_page()
	
func show_current_page():
	var page = pages[current_page]
	start_page(page.title, page.text)

func finish_typing():
	body_label.visible_characters = full_length
	typing = false

func is_typing() -> bool:
	return typing

func has_next_page() -> bool:
	return current_page < pages.size() - 1

func next_page():
	current_page += 1
	show_current_page()
