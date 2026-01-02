class_name ScoringEngine

# Evaluates a completed line (Row or Column)
# input: items is an Array of dictionaries: { "card": CardData, "owner": int }
# owners: 0 for Player, 1 for AI (or inverted)
# is_row: true for Row Tally, false for Column Strike
# returns: Dictionary { "winner": int, "points": int, "action": "add" or "deduct" }

static func evaluate_line(items: Array, is_row: bool, target_suit: String, trump_suit: String) -> Dictionary:
	var total_sum = 0
	var highest_power = -1
	var winner_owner = -1
	
	# Calculate Sum and Find Winner based on Power
	for item in items:
		var card = item["card"]
		var owner = item["owner"]
		var val = card.rank_value 
		
		# Ace Value Adjustment check
		# Ideally DeckManager helper, but accessing static context or assuming pre-calc.
		# For now, use rank_value (1-14).
		
		total_sum += val
		
		# Calculate Power
		var power = val
		
		if card.suit == trump_suit:
			power += 1000 # Trumps beat everything
		elif card.suit == target_suit:
			power += 100 # Target suit beats off-suit
		else:
			power += 0 # Off-suit is weakest (Dump)
			
		if power > highest_power:
			highest_power = power
			winner_owner = owner
		elif power == highest_power:
			# Tie-breaker: First card priority (or could be last).
			# Keeping existing "first found" logic (since loop order matters).
			pass
			
	if is_row:
		return {
			"winner": winner_owner,
			"points": total_sum,
			"action": "add"
		}
	else:
		return {
			"winner": winner_owner,
			"points": total_sum,
			"action": "deduct"
		}
