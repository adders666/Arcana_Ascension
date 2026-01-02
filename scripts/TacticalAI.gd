class_name TacticalAI

const ScoringEngineScript = preload("res://scripts/ScoringEngine.gd")

# Evaluates the best move for the AI given the current constraints.
# grid: 5x5 Array of dictionaries/nulls. { "card": CardData, "owner": int }
# hand: Array of CardData
# axis_type: "row" or "col"
# axis_idx: 0-4 (The locked axis index)
# returns: Dictionary { "card_index": int, "x": int, "y": int, "score": float }

static func choose_best_move(grid: Array, hand: Array, axis_type: String, axis_idx: int, required_suit: String = "") -> Dictionary:
	var best_move = null
	var best_score = -99999.0
	
	# Filter Hand for Suit Following Logic
	var legal_hand = []
	if required_suit != "":
		# Check if we have ANY card of required suit
		var has_suit = false
		for card in hand:
			if card.suit == required_suit:
				has_suit = true
				break
		
		if has_suit:
			# Must play matching suit
			for card in hand:
				if card.suit == required_suit:
					legal_hand.append(card)
		else:
			# Can play anything (Dump)
			legal_hand = hand.duplicate()
	else:
		legal_hand = hand.duplicate()
	
	# Identify valid slots in the locked axis
	var valid_slots = []
	if axis_type == "row":
		# Row is fixed (y = axis_idx), check x (0-4)
		for x in range(5):
			if grid[axis_idx][x] == null:
				valid_slots.append(Vector2i(x, axis_idx))
	else:
		# Col is fixed (x = axis_idx), check y (0-4)
		for y in range(5):
			if grid[y][axis_idx] == null:
				valid_slots.append(Vector2i(axis_idx, y))
	
	if valid_slots.is_empty():
		return {}

	# Iterate all cards in LEGAL hand
	for i in range(legal_hand.size()):
		var card = legal_hand[i]
		
		# Iterate all valid slots
		for slot in valid_slots:
			var score = _evaluate_move(grid, card, slot.x, slot.y, axis_type, axis_idx)
			
			if score > best_score:
				best_score = score
				# Find original index in full hand to return correct card_index? 
				# Actually, the caller (MatchManager) expects an index into 'ai_hand'.
				# So we need to find this card's index in the original 'hand' array.
				var original_index = hand.find(card)
				
				best_move = {
					"card_index": original_index,
					"x": slot.x,
					"y": slot.y,
					"score": score
				}
				
	return best_move if best_move else {}

static func _evaluate_move(grid: Array, card, x: int, y: int, axis_type: String, axis_idx: int) -> float:
	var score = 0.0
	
	# 1. Base Heuristic
	score += card.rank_value * 0.5
	
	# 2. Line Completion Potential
	# Check Row Completion
	var row_cards = _get_line_cards(grid, true, y)
	row_cards.append({ "card": card, "owner": 1 }) # 1 is AI
	
	if row_cards.size() == 5:
		# We need target/trump suit for accurate scoring simulation.
		# TacticalAI signature doesn't pass them easily.
		# For prototype, we'll assume target is the card's suit (if it claimed it) or unknown?
		# Actually, if we are in choose_best_move, we DO know the locked axis suit.
		# But we are evaluating completion of BOTH axes.
		# If checking ROW completion, and axis_type was 'row', we know the suit.
		# If axis_type was 'col', we don't know the Row's suit unless we pass ALL suits.
		# This is getting complex for a prototype.
		# Approximation: Pass "" as suits, falling back to raw value scoring?
		# OR pass card.suit as target if we think we set it?
		# Let's pass "" for now to avoid crash, accepting imperfect AI foresight.
		var result = ScoringEngineScript.evaluate_line(row_cards, true, "", "") 
		if result["winner"] == 1:
			score += result["points"] * 2.0
		else:
			score -= result["points"] * 1.0
			
	# Check Col Completion
	var col_cards = _get_line_cards(grid, false, x)
	col_cards.append({ "card": card, "owner": 1 })
	
	if col_cards.size() == 5:
		var result = ScoringEngineScript.evaluate_line(col_cards, false, "", "")
		if result["winner"] == 1:
			score += result["points"] * 2.5
		else:
			score -= result["points"] * 2.5
			
	return score

static func _get_line_cards(grid: Array, is_row: bool, index: int) -> Array:
	var list = []
	if is_row:
		for x in range(5):
			if grid[index][x] != null:
				list.append(grid[index][x])
	else:
		for y in range(5):
			if grid[y][index] != null:
				list.append(grid[y][index])
	return list