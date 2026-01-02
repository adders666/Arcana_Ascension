extends Node

const DominionSystemScript = preload("res://scripts/DominionSystem.gd")
const PerimeterManagerScript = preload("res://scripts/PerimeterManager.gd")
const TacticalAI = preload("res://scripts/TacticalAI.gd")
const ScoringEngineScript = preload("res://scripts/ScoringEngine.gd")

signal turn_started(axis_type, axis_index)
signal line_saturated(axis_type, axis_index, suit)
signal opponent_move(card, x, y)
signal line_completed(type, index, winner, score)
signal match_ended(result)
signal score_updated(player_score, ai_score)
signal turn_ended 
signal board_reset

var dominion
var perimeter_manager
var active_axis = {"type": "row", "index": 0} 

var grid_state = []
var perimeter_majors = [] 

var player_score = 0
var ai_score = 0
var cards_played_in_turn = 0

# Modifiers for Arcana Effects
var modifiers = {
	"wild_hands": 0,      # Magician
	"double_score": 0,    # Empress
	"rows_only": 0,       # Emperor
	"no_trump": 0,        # Hierophant
	"chariot_owner": -1,  # Chariot (Winner goes first)
	"score_hidden": false,# Hermit
	"suit_inverted": false,# Wheel of Fortune
	"skip_turn": -1,      # Hanged Man (Player ID to skip)
	"force_high_low": -1, # Death (Player ID forced)
	"no_follow_suit": false, # Moon
	"match_countdown": -1 # World
}

# Store last line result for Arcana context
var last_line_result = {}

func _ready():
	dominion = DominionSystemScript.new()
	perimeter_manager = PerimeterManagerScript.new()
	perimeter_manager.setup(self)
	
	randomize()
	for i in range(5):
		grid_state.append([null, null, null, null, null])

func start_match():
	dominion.reset()
	DeckManager.initialize_decks()
	
	# Reset Modifiers
	modifiers = {
		"wild_hands": 0, "double_score": 0, "rows_only": 0, "no_trump": 0,
		"chariot_owner": -1, "score_hidden": false, "suit_inverted": false,
		"skip_turn": -1, "force_high_low": -1, "no_follow_suit": false,
		"match_countdown": -1
	}
	
	player_score = 0
	ai_score = 0
	emit_signal("score_updated", 0, 0)
	
	for y in range(5):
		for x in range(5):
			grid_state[y][x] = null
			
	emit_signal("board_reset")
	
	perimeter_majors = DeckManager.perimeter_pool.duplicate()
	next_turn()

func execute_flip(index):
	var card = perimeter_majors[index]
	perimeter_manager.activate_arcana(card.rank, last_line_result)

func next_turn():
	# Decrement Turn-based modifiers
	if modifiers.wild_hands > 0: modifiers.wild_hands -= 1
	if modifiers.rows_only > 0: modifiers.rows_only -= 1
	if modifiers.no_trump > 0: modifiers.no_trump -= 1
	if modifiers.match_countdown > 0:
		modifiers.match_countdown -= 1
		if modifiers.match_countdown == 0:
			_end_match()
			return

	# Gather all valid axes (not full)
	var valid_axes = []
	
	# Emperor Effect: Rows Only
	var allow_rows = true
	var allow_cols = true
	if modifiers.rows_only > 0:
		allow_cols = false
		
	if allow_rows:
		for i in range(5):
			if not _is_axis_full("row", i): valid_axes.append({"type": "row", "index": i})
	if allow_cols:
		for i in range(5):
			if not _is_axis_full("col", i): valid_axes.append({"type": "col", "index": i})
			
	if valid_axes.is_empty():
		_end_match()
		return
		
	active_axis = valid_axes[randi() % valid_axes.size()]
	cards_played_in_turn = 0
	
	emit_signal("turn_started", active_axis.type, active_axis.index)
	print("MatchManager: New Axis Selected: ", active_axis.type, " ", active_axis.index)

func _end_match():
	print("Match Over!")
	var winner = "draw"
	if player_score > ai_score: winner = "player"
	elif ai_score > player_score: winner = "ai"
	var souls = player_score if winner == "player" else 0
	var damage = 1 if winner == "ai" else 0
	emit_signal("match_ended", {"winner": winner, "player_score": player_score, "ai_score": ai_score, "souls": souls, "damage": damage})

func on_card_played(card, x, y):
	if dominion.try_claim_line(true, y, card.suit): emit_signal("line_saturated", "row", y, card.suit)
	if dominion.try_claim_line(false, x, card.suit): emit_signal("line_saturated", "col", x, card.suit)
		
	_check_line_completion(x, y)
	
	cards_played_in_turn += 1
	if _is_axis_full(active_axis.type, active_axis.index):
		next_turn()
		return

	if cards_played_in_turn == 1:
		_trigger_ai_turn()
	elif cards_played_in_turn >= 2:
		next_turn()

func _is_axis_full(type, index) -> bool:
	var count = 0
	if type == "row":
		for x in range(5): 
			if grid_state[index][x] != null: count += 1
	else:
		for y in range(5):
			if grid_state[y][index] != null: count += 1
	return count >= 5

func _check_line_completion(x, y):
	var trump = DeckManager.trump_suit
	if modifiers.no_trump > 0: trump = "None" # Hierophant
	
	var row_cards = _get_line_cards(true, y)
	if row_cards.size() == 5:
		var target_suit = dominion.get_row_suit(y)
		var result = ScoringEngineScript.evaluate_line(row_cards, true, target_suit, trump)
		_handle_line_result(result, "row", y)
		
	var col_cards = _get_line_cards(false, x)
	if col_cards.size() == 5:
		var target_suit = dominion.get_col_suit(x)
		var result = ScoringEngineScript.evaluate_line(col_cards, false, target_suit, trump)
		_handle_line_result(result, "col", x)

func _handle_line_result(result, type, index):
	last_line_result = result 
	
	# Empress: Double Score
	if modifiers.double_score > 0:
		result.points *= 2
		modifiers.double_score -= 1
		
	_apply_score(result)
	emit_signal("line_completed", type, index, result["winner"], result["points"])

func _apply_score(result):
	if result["action"] == "add":
		if result["winner"] == 0: player_score += result["points"]
		else: ai_score += result["points"]
	elif result["action"] == "deduct":
		if result["winner"] == 0: ai_score -= result["points"]
		else: player_score -= result["points"]
	emit_signal("score_updated", player_score, ai_score)

func _get_line_cards(is_row: bool, index: int) -> Array:
	var list = []
	if is_row:
		for x in range(5): if grid_state[index][x] != null: list.append(grid_state[index][x])
	else:
		for y in range(5): if grid_state[y][index] != null: list.append(grid_state[y][index])
	return list

func _trigger_ai_turn():
	var ai_hand = []
	for i in range(5):
		var c = DeckManager.draw_card(false)
		if c: ai_hand.append(c)
	if ai_hand.is_empty(): return
	var req_suit = ""
	if active_axis.type == "row": req_suit = dominion.get_row_suit(active_axis.index)
	else: req_suit = dominion.get_col_suit(active_axis.index)
	var move = TacticalAI.choose_best_move(grid_state, ai_hand, active_axis.type, active_axis.index, req_suit)
	if move.is_empty():
		cards_played_in_turn += 1
		if cards_played_in_turn >= 2: next_turn()
		return
	var card = ai_hand[move.card_index]
	grid_state[move.y][move.x] = { "card": card, "owner": 1 }
	emit_signal("opponent_move", card, move.x, move.y)
	on_card_played(card, move.x, move.y)
