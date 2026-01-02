extends Control

const CARD_VIEW_SCRIPT = preload("res://scenes/CardView.gd")

@onready var hand_container = $Hand
@onready var grid_view = $GridView
@onready var player_score_label = $ScoreContainer/PlayerScore
@onready var ai_score_label = $ScoreContainer/AIScore
@onready var smash_text = $SmashText
@onready var trump_label = $RuleInfo/TrumpLabel
@onready var ace_label = $RuleInfo/AceLabel

var selected_card_view = null
var line_event_queue = []
var is_dialog_active = false

func _ready():
	if MatchManager:
		MatchManager.start_match()
		MatchManager.connect("opponent_move", _on_opponent_move)
		MatchManager.connect("line_completed", _on_line_completed)
		MatchManager.connect("score_updated", _on_score_updated)
		MatchManager.connect("match_ended", _on_match_ended)
		
	# Update Rules UI
	trump_label.text = "Trump: " + DeckManager.trump_suit
	ace_label.text = "Ace: " + ("High (14)" if DeckManager.ace_is_high else "Low (1)")
		
	grid_view.slot_clicked.connect(_on_slot_clicked)
	_spawn_hand()

# --- Score and Results ---

func _on_score_updated(p_score, a_score):
	player_score_label.text = "Player: " + str(p_score)
	ai_score_label.text = "AI: " + str(a_score)

func _on_match_ended(result):
	line_event_queue.append({ "type": "match_over", "result": result })
	_process_line_queue()

func _show_match_over_dialog(result):
	var outcome = "DRAW"
	var details = ""
	if result.winner == "player":
		outcome = "VICTORY!"
		details = "Souls Earned: " + str(result.souls)
	elif result.winner == "ai":
		outcome = "DEFEAT"
		details = "Collection Damage: " + str(result.damage)
		
	var dialog = AcceptDialog.new()
	dialog.title = "Match Over"
	dialog.dialog_text = outcome + "\n" + details + "\n\nFinal Score:\nPlayer: " + str(result.player_score) + "\nAI: " + str(result.ai_score)
	dialog.get_ok_button().text = "Continue"
	dialog.confirmed.connect(func(): GauntletManager.complete_match(result.winner))
	add_child(dialog)
	dialog.popup_centered()

# --- Line Completion Queue ---

func _on_line_completed(type, index, winner, score):
	line_event_queue.append({ "type": "line", "line_type": type, "index": index, "winner": winner, "score": score })
	_process_line_queue()

func _process_line_queue():
	if is_dialog_active or line_event_queue.is_empty():
		return
		
	var event = line_event_queue.pop_front()
	
	if event.type == "match_over":
		_show_match_over_dialog(event.result)
		return
		
	var type = event.line_type
	var index = event.index
	var winner = event.winner
	
	var major_idx = index if type == "col" else (index + 5)
	var major_card = MatchManager.perimeter_majors[major_idx]
	
	if winner == 0: # Player
		is_dialog_active = true
		var confirm = ConfirmationDialog.new()
		confirm.title = "Arcana Ascension"
		confirm.dialog_text = "You won the line! Flip the Arcana?"
		confirm.get_ok_button().text = "Flip"
		confirm.get_cancel_button().text = "Pass"
		
		confirm.confirmed.connect(func(): 
			_flip_major(major_idx, major_card)
			is_dialog_active = false
			confirm.queue_free()
			_process_line_queue()
		)
		confirm.canceled.connect(func():
			is_dialog_active = false
			confirm.queue_free()
			_process_line_queue()
		)
		add_child(confirm)
		confirm.popup_centered()
	else:
		if randf() > 0.5:
			_flip_major(major_idx, major_card)
		else:
			print("AI chose to PASS (Hidden)")
		_process_line_queue()

func _flip_major(index, card):
	grid_view.reveal_major(index, card)
	MatchManager.execute_flip(index)
	
	smash_text.text = card.get_display_name().to_upper() + " ACTIVATED!\n" + MatchManager.perimeter_manager.get_effect_description(card.rank)
	smash_text.visible = true
	await get_tree().create_timer(3.0).timeout
	smash_text.visible = false

# --- Combat and Hand ---

func _on_opponent_move(card, x, y):
	grid_view.place_visual_card(card, x, y)

func _spawn_hand():
	for child in hand_container.get_children():
		child.queue_free()
	for i in range(6):
		var data = DeckManager.draw_card()
		if data == null: break
		var card = Panel.new()
		card.set_script(CARD_VIEW_SCRIPT)
		hand_container.add_child(card)
		card.setup(data)
		card.card_clicked.connect(_on_card_clicked)
	_update_hand_layout()

func _update_hand_layout():
	var cards = hand_container.get_children()
	var card_count = cards.size()
	if card_count == 0: return
	var center_x = hand_container.size.x / 2
	var radius = 800.0 
	var angle_spread = 5.0 
	var start_angle = -((card_count - 1) * angle_spread) / 2.0
	var pivot_y = hand_container.size.y + radius - 50.0 
	for i in range(card_count):
		var card = cards[i]
		var angle_deg = start_angle + (i * angle_spread)
		var angle_rad = deg_to_rad(angle_deg)
		var x = center_x + radius * sin(angle_rad)
		var y = pivot_y - radius * cos(angle_rad)
		if card == selected_card_view: y -= 30
		card.position = Vector2(x - card.custom_minimum_size.x / 2, y - card.custom_minimum_size.y / 2)
		card.rotation_degrees = angle_deg

func _on_card_clicked(view):
	if selected_card_view == view:
		selected_card_view = null
		view.set_selected(false)
	else:
		if selected_card_view: selected_card_view.set_selected(false)
		selected_card_view = view
		view.set_selected(true)
	_update_hand_layout()

func _on_slot_clicked(x, y):
	if not selected_card_view: return
	var card_data = selected_card_view.card_data
	var active = MatchManager.active_axis
	var legal = (active.type == "row" and active.index == y) or (active.type == "col" and active.index == x)
	if not legal or MatchManager.grid_state[y][x] != null: return
	_place_card(card_data, x, y)

func _place_card(card_data, x, y):
	MatchManager.grid_state[y][x] = { "card": card_data, "owner": 0 }
	MatchManager.on_card_played(card_data, x, y)
	grid_view.place_visual_card(card_data, x, y)
	selected_card_view.queue_free()
	selected_card_view = null
	if hand_container.get_child_count() <= 1: _spawn_hand()
	else: _update_hand_layout()