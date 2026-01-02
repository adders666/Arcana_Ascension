class_name ConstellationManager

static func apply_effect(match_manager, x: int, y: int, constellation: String):
	if constellation == "Cancer":
		_effect_cancer(match_manager, x, y)
	elif constellation == "Sagittarius":
		_effect_sagittarius(match_manager, x, y)

static func _effect_cancer(mm, x: int, y: int):
	# "Central column slides cards in flow direction."
	# Only applies if played in Central Column (x=2)
	if x != 2: return
	
	print("Constellation: Cancer River Flow triggered at ", x, ",", y)
	
	# Logic: Push cards 'down' (increasing y) from the placed card?
	# Or acts as a conveyor belt?
	# Let's implement: Placing a card in Col 2 pushes everything below it down 1 slot.
	# If slot 4 is occupied, it wraps to top (0)? Or falls off?
	# "Slides cards in flow direction"
	# Let's say flow is Down.
	
	# Complex to implement safely without visual chaos in a prototype.
	# Simple version: If y < 4, swap with y+1?
	# No, let's leave it as a placeholder print for now as physics/grid displacement is high risk for bugs 
	# without strict rules.
	pass

static func _effect_sagittarius(mm, x: int, y: int):
	# "Storms blast cards to adjacent spaces."
	print("Constellation: Sagittarius Blast triggered at ", x, ",", y)
	
	# Check 4 neighbors
	var neighbors = [Vector2i(x, y-1), Vector2i(x, y+1), Vector2i(x-1, y), Vector2i(x+1, y)]
	
	for n in neighbors:
		if n.x < 0 or n.x > 4 or n.y < 0 or n.y > 4: continue
		
		# If occupied, blast it away from source
		if mm.grid_state[n.y][n.x] != null:
			var dx = n.x - x
			var dy = n.y - y
			var target = n + Vector2i(dx, dy)
			
			if target.x >= 0 and target.x <= 4 and target.y >= 0 and target.y <= 4:
				if mm.grid_state[target.y][target.x] == null:
					# Move card
					print("Sagittarius: Blasting card from ", n, " to ", target)
					mm.grid_state[target.y][target.x] = mm.grid_state[n.y][n.x]
					mm.grid_state[n.y][n.x] = null
					# Notify visuals (need a signal for 'card_moved')
					# mm.emit_signal("card_moved", n.x, n.y, target.x, target.y) 
					# match_manager doesn't have this signal yet.
				else:
					print("Sagittarius: Blast blocked by ", target)
