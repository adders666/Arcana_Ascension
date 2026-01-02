extends Panel

signal card_clicked(view)

var card_data = null
var rank_label: Label
var suit_label: Label # New label for full name/suit

func _ready():
	custom_minimum_size = Vector2(80, 110)
	
	# Enable mouse input
	gui_input.connect(_on_gui_input)
	
	# Basic styling
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.9, 0.9, 0.9) 
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.4, 0.4)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	add_theme_stylebox_override("panel", style)

	rank_label = Label.new()
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	rank_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	rank_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	rank_label.add_theme_constant_override("margin_left", 8)
	rank_label.add_theme_constant_override("margin_top", 4)
	rank_label.add_theme_color_override("font_color", Color.BLACK)
	rank_label.add_theme_font_size_override("font_size", 18)
	add_child(rank_label)
	
	suit_label = Label.new()
	suit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	suit_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	suit_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	suit_label.add_theme_constant_override("margin_bottom", 8)
	suit_label.add_theme_color_override("font_color", Color.BLACK)
	suit_label.add_theme_font_size_override("font_size", 12)
	suit_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(suit_label)

func setup(data):
	card_data = data
	rank_label.text = data.rank
	suit_label.text = data.get_display_name()
	
	# Color coding based on suit
	var bg_color = Color(0.9, 0.9, 0.9)
	var text_color = Color.BLACK
	
	match data.suit:
		"Wands":
			bg_color = Color(0.95, 0.8, 0.8) # Light Red
			text_color = Color(0.5, 0.1, 0.1)
		"Cups":
			bg_color = Color(0.8, 0.9, 0.95) # Light Blue
			text_color = Color(0.1, 0.1, 0.6)
		"Swords":
			bg_color = Color(0.9, 0.9, 0.95) # Light Grey/Blue
			text_color = Color(0.2, 0.2, 0.3)
		"Pentacles":
			bg_color = Color(0.95, 0.95, 0.8) # Light Gold
			text_color = Color(0.6, 0.5, 0.1)
		"Major":
			bg_color = Color(0.9, 0.8, 0.95) # Light Purple
			text_color = Color(0.4, 0.1, 0.5)
			
	var style = get_theme_stylebox("panel").duplicate()
	style.bg_color = bg_color
	style.border_color = text_color
	add_theme_stylebox_override("panel", style)
	
	rank_label.add_theme_color_override("font_color", text_color)
	suit_label.add_theme_color_override("font_color", text_color)

func set_rank(rank: String):
	# Legacy support if needed, but setup() is preferred
	pass

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("card_clicked", self)

func set_selected(selected: bool):
	var style = get_theme_stylebox("panel")
	if selected:
		style.border_width_left = 4
		style.border_width_top = 4
		style.border_width_right = 4
		style.border_width_bottom = 4
		style.border_color = Color.YELLOW
		position.y -= 20 # Pop up
	else:
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		# Revert border color (would need to store original, or re-run setup logic. 
		# For prototype, just set to gray or re-call setup color logic)
		setup(card_data) 
		# Note: setup() resets style, which is fine. 
		# position reset needs to be handled by the layout manager (Match.gd fanning)
