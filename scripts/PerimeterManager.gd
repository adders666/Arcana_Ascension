class_name PerimeterManager

var match_manager

func setup(mm):
	match_manager = mm

func get_effect_description(rank_name: String) -> String:
	match rank_name:
		"The Fool": return "Clears board and laws. Reshuffles hands and perimeter Arcana."
		"The Magician": return "Hand cards are Wild for one turn."
		"The High Priestess": return "Shows two possible identities for two perimeter cards (one true, one lie)."
		"The Empress": return "Next 3 lines give double points or strikes."
		"The Emperor": return "Next 2 highlights are Rows only."
		"The Hierophant": return "No Trump plays for 3 turns."
		"The Lovers": return "Links two cards. If one is struck, both are struck."
		"The Chariot": return "Turn order is no longer randomized. The player who flipped this always goes first."
		"Strength": return "Numerical values of all cards in both hands increase by 5 (max 14)."
		"The Hermit": return "The opponent's score is hidden until the match ends."
		"Wheel of Fortune": return "Inverts the suit hierarchy instantly."
		"Justice": return "Swaps player scores."
		"The Hanged Man": return "Winner skips next turn. Opponent must play two cards into the next target."
		"Death": return "Opponent must play cards from highest value to lowest."
		"Temperance": return "All values on the board are averaged. High cards drop and low cards rise."
		"The Devil": return "Court cards (Page, Knight, Queen, King) become value 5."
		"The Tower": return "Completed line score becomes zero."
		"The Star": return "Reveals the next 3 cards in the opponent's hand."
		"The Moon": return "Abolishes the 'Follow Suit' rule for the rest of the match."
		"The Sun": return "Reverses the current Ace orientation."
		"Judgement": return "Re-evaluates every card on the board based on current suit and Ace laws."
		"The World": return "Triggers a 5-turn countdown to match end."
		_: return "Global Law Activated."

func activate_arcana(card_name: String, context: Dictionary = {}):
	print("PerimeterManager: Activating ", card_name)
	
	match card_name:
		"The Fool":
			_effect_the_fool()
		"The Magician":
			match_manager.modifiers.wild_hands = 2 # 1 turn = 2 moves? or 1 full round?
			print("THE MAGICIAN: Hands are Wild!")
		"The High Priestess":
			# UI Effect primarily - needs visual logic
			pass
		"The Empress":
			match_manager.modifiers.double_score = 3
			print("THE EMPRESS: Next 3 lines double points!")
		"The Emperor":
			match_manager.modifiers.rows_only = 4 # 2 full turns (4 moves)
			print("THE EMPEROR: Rows Only!")
		"The Hierophant":
			match_manager.modifiers.no_trump = 6 # 3 turns
			print("THE HIEROPHANT: No Trump!")
		"The Lovers":
			pass # Complex visual
		"The Chariot":
			match_manager.modifiers.chariot_owner = context.get("winner", -1)
			print("THE CHARIOT: Winner takes initiative!")
		"Strength":
			# Increase values in hands
			pass # Need to iterate hands
		"The Hermit":
			match_manager.modifiers.score_hidden = true
			# Trigger UI update to hide score?
			match_manager.emit_signal("score_updated", match_manager.player_score, -1) # -1 = hidden
			print("THE HERMIT: Scores Hidden!")
		"Wheel of Fortune":
			match_manager.modifiers.suit_inverted = true
			print("WHEEL OF FORTUNE: Hierarchy Inverted!")
		"Justice":
			_effect_justice()
		"The Hanged Man":
			match_manager.modifiers.skip_turn = context.get("winner", -1)
			print("THE HANGED MAN: Winner skips turn!")
		"Death":
			match_manager.modifiers.force_high_low = 1 if context.get("winner", 0) == 0 else 0
			# Winner makes *opponent* play high to low.
			print("DEATH: Opponent forced High-to-Low!")
		"Temperance":
			pass # Average calculation
		"The Devil":
			# Court cards become 5
			# Need to scan grid? Or just future? GDD "Court cards... become value 5"
			# Usually immediate effect on board + hands?
			pass 
		"The Tower":
			_effect_the_tower(context)
		"The Star":
			pass # Reveal Hand UI
		"The Moon":
			match_manager.modifiers.no_follow_suit = true
			print("THE MOON: No Follow Suit!")
		"The Sun":
			DeckManager.ace_is_high = !DeckManager.ace_is_high
			print("THE SUN: Ace Orientation Reversed!")
		"Judgement":
			pass # Re-eval
		"The World":
			match_manager.modifiers.match_countdown = 5 # 5 Turns
			print("THE WORLD: 5 Turns Remaining!")
		_:
			print("Effect logic for ", card_name, " not yet implemented.")

func _effect_the_fool():
	# Clears board
	print("THE FOOL: Resetting Match!")
	match_manager.start_match() # Re-runs setup (clear grid, decks, etc)
	# Note: This might be drastic, but GDD says "Clears board and laws. Reshuffles..."

func _effect_justice():
	# Swaps scores
	var temp = match_manager.player_score
	match_manager.player_score = match_manager.ai_score
	match_manager.ai_score = temp
	match_manager.emit_signal("score_updated", match_manager.player_score, match_manager.ai_score)
	print("JUSTICE: Scores Swapped!")

func _effect_the_tower(context):
	# "Completed line score becomes zero."
	# Context must contain 'points' and 'winner' of the trigger event.
	if not context.has("points") or not context.has("winner"):
		return
		
	var points = context.points
	var winner = context.winner
	
	# Retroactively remove points
	if winner == 0: # Player
		match_manager.player_score -= points
	else:
		match_manager.ai_score -= points
		
	match_manager.emit_signal("score_updated", match_manager.player_score, match_manager.ai_score)
	print("THE TOWER: Line score nullified!")
