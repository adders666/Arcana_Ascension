extends Control

signal slot_clicked(x: int, y: int)
signal major_clicked(index: int)

@export var cell_size := Vector2(55, 45) 
@export var spacing := Vector2(8, 6) 
@export var grid_dims := Vector2i(5, 5)

# Perspective parameters
var perspective_factor = 0.4 
var board_center_x = 0.0
var board_top_y_ref = 0.0
var board_height_ref = 0.0

# Visual State
var highlight_rect: Polygon2D = null
var cards_node: Node2D = null

func _ready():
	_spawn_board()
	
	cards_node = Node2D.new()
	add_child(cards_node)
	
	if has_node("/root/MatchManager"):
		MatchManager.connect("turn_started", _on_turn_started)
		MatchManager.connect("line_saturated", _on_line_saturated)
		MatchManager.connect("board_reset", _on_board_reset)

func _on_board_reset():
	for child in cards_node.get_children():
		child.queue_free()
	# Also clear perimeter slot changes if any (e.g. saturation colors)
	# Since _spawn_board created slots, and we colored them by adding children to GridView (not cards_node),
	# we might have lingering colors.
	# Ideally we respawn the board or track those too.
	# For simplicity:
	# We can just remove everything and respawn the board?
	# But buttons are connected.
	# Let's just stick to clearing cards for now as requested.
	# If saturation colors persist, we might need a full rebuild.
	# "it cleared the board... cards were still on the board"
	# So clearing cards_node covers the main request.

func _on_turn_started(type, index):
	_draw_highlight(type, index)

func _on_line_saturated(type, index, suit):
	print("Visual Update: ", type, " ", index, " is now ", suit)
	
	# Determine color
	var color = Color(0.5, 0.5, 0.5)
	match suit:
		"Wands": color = Color(0.6, 0.2, 0.2)
		"Cups": color = Color(0.2, 0.3, 0.6)
		"Swords": color = Color(0.3, 0.3, 0.4)
		"Pentacles": color = Color(0.7, 0.6, 0.1)
	
	var grid_w = grid_dims.x * cell_size.x + (grid_dims.x - 1) * spacing.x
	var grid_h = grid_dims.y * cell_size.y + (grid_dims.y - 1) * spacing.y
	var zone_spacing = 20.0
	var outer_padding = 20.0
	var top_zone_h = cell_size.y + outer_padding*2
	var screen_size = get_viewport_rect().size
	var total_w = (grid_w + outer_padding*2) + zone_spacing + (cell_size.x + outer_padding*2)
	var start_x = (screen_size.x - total_w) / 2
	var start_y = 150.0 
	
	var top_zone_pos = Vector2(start_x, start_y)
	var top_zone_rect = Rect2(0, 0, grid_w + outer_padding*2, cell_size.y + outer_padding*2)
	var grid_zone_pos = Vector2(start_x, start_y + top_zone_rect.size.y + zone_spacing)
	var grid_zone_rect = Rect2(0, 0, grid_w + outer_padding*2, grid_h + outer_padding*2)
	var right_zone_pos = Vector2(start_x + grid_zone_rect.size.x + zone_spacing, grid_zone_pos.y)
	
	var pos_2d
	if type == "col": # Top Zone (Cols)
		var top_start = top_zone_pos + Vector2(outer_padding, outer_padding)
		pos_2d = top_start + Vector2(index * (cell_size.x + spacing.x), 0)
	else: # Right Zone (Rows)
		var right_start = right_zone_pos + Vector2(outer_padding, outer_padding)
		pos_2d = right_start + Vector2(0, index * (cell_size.y + spacing.y))
		
	var poly = _create_trapezoid_poly(Rect2(pos_2d, cell_size), color)
	poly.color.a = 0.8
	add_child(poly)

func place_visual_card(card_data, x, y):
	var grid_w = grid_dims.x * cell_size.x + (grid_dims.x - 1) * spacing.x
	var grid_h = grid_dims.y * cell_size.y + (grid_dims.y - 1) * spacing.y
	var zone_spacing = 20.0
	var outer_padding = 20.0
	var top_zone_h = cell_size.y + outer_padding*2
	
	var screen_size = get_viewport_rect().size
	var total_w = (grid_w + outer_padding*2) + zone_spacing + (cell_size.x + outer_padding*2)
	var start_x = (screen_size.x - total_w) / 2
	var start_y = 150.0 
	
	var grid_zone_pos = Vector2(start_x, start_y + top_zone_h + zone_spacing)
	var grid_start = grid_zone_pos + Vector2(outer_padding, outer_padding)
	
	var pos_2d = grid_start + Vector2(x*(cell_size.x+spacing.x), y*(cell_size.y+spacing.y))
	
	# Color code
	var color = Color(0.5, 0.5, 0.5)
	match card_data.suit:
		"Wands": color = Color(0.6, 0.2, 0.2)
		"Cups": color = Color(0.2, 0.3, 0.6)
		"Swords": color = Color(0.3, 0.3, 0.4)
		"Pentacles": color = Color(0.7, 0.6, 0.1)
		"Major": color = Color(0.4, 0.1, 0.4)
	
	var poly = _create_trapezoid_poly(Rect2(pos_2d, cell_size), color)
	cards_node.add_child(poly)
	
	var l = Label.new()
	l.text = card_data.rank
	l.position = _get_perspective_pos(pos_2d + Vector2(5, 5))
	cards_node.add_child(l)

func reveal_major(index, card_data):
	# index 0-4 = Top (Cols), 5-9 = Right (Rows)
	var is_top = index < 5
	var local_idx = index if is_top else index - 5
	
	# We need to find the label/slot we created.
	# Since we didn't store references, we can't easily modify the existing "?".
	# Alternative: Spawn a new visual ON TOP.
	
	# Calculate pos again (duplication, but robust without refactoring spawn)
	var grid_w = grid_dims.x * cell_size.x + (grid_dims.x - 1) * spacing.x
	var grid_h = grid_dims.y * cell_size.y + (grid_dims.y - 1) * spacing.y
	var zone_spacing = 20.0
	var outer_padding = 20.0
	var top_zone_h = cell_size.y + outer_padding*2
	var screen_size = get_viewport_rect().size
	var top_zone_rect = Rect2(0, 0, grid_w + outer_padding*2, cell_size.y + outer_padding*2)
	var grid_zone_rect = Rect2(0, 0, grid_w + outer_padding*2, grid_h + outer_padding*2)
	var right_zone_rect = Rect2(0, 0, cell_size.x + outer_padding*2, grid_h + outer_padding*2)
	var total_w = grid_zone_rect.size.x + zone_spacing + right_zone_rect.size.x
	var total_h = top_zone_rect.size.y + zone_spacing + grid_zone_rect.size.y
	var start_x = (screen_size.x - total_w) / 2
	var start_y = 150.0 
	var top_zone_pos = Vector2(start_x, start_y)
	var grid_zone_pos = Vector2(start_x, start_y + top_zone_rect.size.y + zone_spacing)
	var right_zone_pos = Vector2(start_x + grid_zone_rect.size.x + zone_spacing, grid_zone_pos.y)
	
	var pos_2d
	if is_top:
		var top_start = top_zone_pos + Vector2(outer_padding, outer_padding)
		pos_2d = top_start + Vector2(local_idx * (cell_size.x + spacing.x), 0)
	else:
		var right_start = right_zone_pos + Vector2(outer_padding, outer_padding)
		pos_2d = right_start + Vector2(0, local_idx * (cell_size.y + spacing.y))
		
	# Spawn visual
	var poly = _create_trapezoid_poly(Rect2(pos_2d, cell_size), Color(0.6, 0.2, 0.6)) # Purple for Major
	add_child(poly)
	
	var l = Label.new()
	l.text = card_data.rank # Name
	l.position = _get_perspective_pos(pos_2d + Vector2(5, 5))
	add_child(l)

func _draw_highlight(type, index):
	if highlight_rect:
		highlight_rect.queue_free()
		highlight_rect = null
		
	var screen_size = get_viewport_rect().size
	var zone_spacing = 20.0
	var outer_padding = 20.0
	var grid_w = grid_dims.x * cell_size.x + (grid_dims.x - 1) * spacing.x
	var grid_h = grid_dims.y * cell_size.y + (grid_dims.y - 1) * spacing.y
	var top_zone_h = cell_size.y + outer_padding*2
	
	var total_w = (grid_w + outer_padding*2) + zone_spacing + (cell_size.x + outer_padding*2)
	var start_x = (screen_size.x - total_w) / 2
	var start_y = 150.0
	var grid_zone_pos = Vector2(start_x, start_y + top_zone_h + zone_spacing)
	var grid_slots_start_x = grid_zone_pos.x + outer_padding
	var grid_slots_start_y = grid_zone_pos.y + outer_padding
	
	var rect: Rect2
	if type == "row":
		var y_pos = grid_slots_start_y + index * (cell_size.y + spacing.y)
		rect = Rect2(grid_slots_start_x - 5, y_pos - 5, grid_w + 10, cell_size.y + 10)
	else:
		var x_pos = grid_slots_start_x + index * (cell_size.x + spacing.x)
		rect = Rect2(x_pos - 5, grid_slots_start_y - 5, cell_size.x + 10, grid_h + 10)
		
	highlight_rect = _create_trapezoid_poly(rect, Color(1, 1, 0, 0.2))
	add_child(highlight_rect)

func _get_perspective_pos(base_pos: Vector2) -> Vector2:
	var rel_y = (base_pos.y - board_top_y_ref) / board_height_ref
	var width_scale = lerp(1.0 - perspective_factor, 1.0, rel_y)
	var visual_rel_y = pow(rel_y, 1.5)
	var new_y = board_top_y_ref + visual_rel_y * board_height_ref
	var offset_x = base_pos.x - board_center_x
	var new_x = board_center_x + (offset_x * width_scale)
	return Vector2(new_x, new_y)

func _create_trapezoid_poly(rect: Rect2, color: Color) -> Polygon2D:
	var poly = Polygon2D.new()
	poly.color = color
	var tl = rect.position
	var tr = rect.position + Vector2(rect.size.x, 0)
	var br = rect.position + rect.size
	var bl = rect.position + Vector2(0, rect.size.y)
	
	poly.polygon = PackedVector2Array([
		_get_perspective_pos(tl),
		_get_perspective_pos(tr),
		_get_perspective_pos(br),
		_get_perspective_pos(bl)
	])
	poly.antialiased = true
	return poly

func _spawn_board():
	var grid_w = grid_dims.x * cell_size.x + (grid_dims.x - 1) * spacing.x
	var grid_h = grid_dims.y * cell_size.y + (grid_dims.y - 1) * spacing.y
	var zone_spacing = 20.0
	var outer_padding = 20.0
	
	var top_zone_rect = Rect2(0, 0, grid_w + outer_padding*2, cell_size.y + outer_padding*2)
	var grid_zone_rect = Rect2(0, 0, grid_w + outer_padding*2, grid_h + outer_padding*2)
	var right_zone_rect = Rect2(0, 0, cell_size.x + outer_padding*2, grid_h + outer_padding*2)
	
	var total_w = grid_zone_rect.size.x + zone_spacing + right_zone_rect.size.x
	var total_h = top_zone_rect.size.y + zone_spacing + grid_zone_rect.size.y
	
	var screen_size = get_viewport_rect().size
	var start_x = (screen_size.x - total_w) / 2
	var start_y = 150.0 
	
	board_center_x = screen_size.x / 2
	board_top_y_ref = start_y
	board_height_ref = total_h
	
	var top_zone_pos = Vector2(start_x, start_y)
	var grid_zone_pos = Vector2(start_x, start_y + top_zone_rect.size.y + zone_spacing)
	var right_zone_pos = Vector2(start_x + grid_zone_rect.size.x + zone_spacing, grid_zone_pos.y)
	
	# Slab
	var full_board_rect = Rect2(top_zone_pos, Vector2(right_zone_pos.x + right_zone_rect.size.x, grid_zone_pos.y + grid_zone_rect.size.y) - top_zone_pos)
	var slab_depth = 20.0
	var p_bl = _get_perspective_pos(Vector2(full_board_rect.position.x, full_board_rect.end.y))
	var p_br = _get_perspective_pos(full_board_rect.end)
	
	var slab_poly = Polygon2D.new()
	slab_poly.color = Color(0.25, 0.15, 0.05, 1)
	slab_poly.polygon = PackedVector2Array([p_bl, p_br, p_br + Vector2(0, slab_depth), p_bl + Vector2(0, slab_depth)])
	add_child(slab_poly)
	
	# Surface
	var board_poly = Polygon2D.new()
	board_poly.color = Color(0.4, 0.25, 0.15, 1)
	board_poly.polygon = PackedVector2Array([
		_get_perspective_pos(full_board_rect.position),
		_get_perspective_pos(Vector2(full_board_rect.end.x, full_board_rect.position.y)),
		p_br, p_bl
	])
	add_child(board_poly)
	
	# Recesses
	add_child(_create_trapezoid_poly(Rect2(top_zone_pos, top_zone_rect.size), Color(0.3, 0.18, 0.1, 1)))
	add_child(_create_trapezoid_poly(Rect2(grid_zone_pos, grid_zone_rect.size), Color(0.3, 0.18, 0.1, 1)))
	add_child(_create_trapezoid_poly(Rect2(right_zone_pos, right_zone_rect.size), Color(0.3, 0.18, 0.1, 1)))
	
	# Slots
	var top_start = top_zone_pos + Vector2(outer_padding, outer_padding)
	for x in range(grid_dims.x):
		var pos = top_start + Vector2(x * (cell_size.x + spacing.x), 0)
		add_child(_create_trapezoid_poly(Rect2(pos, cell_size), Color(0.4, 0.4, 0.2, 0.5)))
		var l = Label.new(); l.text = "?"; l.position = _get_perspective_pos(pos + Vector2(15, 10)); add_child(l)
		
	var grid_start = grid_zone_pos + Vector2(outer_padding, outer_padding)
	for y in range(grid_dims.y):
		var rl = Label.new(); rl.text = str(y+1); rl.position = _get_perspective_pos(grid_start + Vector2(-25, y*(cell_size.y+spacing.y))); add_child(rl)
		for x in range(grid_dims.x):
			var pos = grid_start + Vector2(x*(cell_size.x+spacing.x), y*(cell_size.y+spacing.y))
			add_child(_create_trapezoid_poly(Rect2(pos, cell_size), Color(0.2, 0.2, 0.2, 0.8)))
			var btn = Button.new(); btn.flat = true; btn.position = _get_perspective_pos(pos); btn.size = cell_size; btn.modulate.a = 0
			btn.pressed.connect(func(): slot_clicked.emit(x, y)); add_child(btn)
			
	var cols = ["A", "B", "C", "D", "E"]
	for x in range(grid_dims.x):
		var cl = Label.new(); cl.text = cols[x]; cl.position = _get_perspective_pos(grid_start + Vector2(x*(cell_size.x+spacing.x)+15, grid_h+5)); add_child(cl)
			
	var right_start = right_zone_pos + Vector2(outer_padding, outer_padding)
	for y in range(grid_dims.y):
		var pos = right_start + Vector2(0, y*(cell_size.y+spacing.y))
		add_child(_create_trapezoid_poly(Rect2(pos, cell_size), Color(0.4, 0.4, 0.2, 0.5)))
		var l = Label.new(); l.text = "?"; l.position = _get_perspective_pos(pos + Vector2(15, 10)); add_child(l)
