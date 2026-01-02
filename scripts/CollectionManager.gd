extends Node

# Persistent Collection
# Array of Card Objects or Dictionaries
# { "rank": "Ace", "suit": "Wands", "tier": 0, "integrity": 3 }
var collection: Array = []

func _ready():
	# Starter Deck (if empty)
	if collection.is_empty():
		_add_starter_cards()

func _add_starter_cards():
	print("Collection: Adding starter cards...")
	add_card("Ace", "Wands", 0)
	add_card("Ace", "Cups", 0)
	add_card("Ace", "Swords", 0)
	add_card("Ace", "Pentacles", 0)
	add_card("King", "Wands", 1) # One upgraded card to test damage

func add_card(rank, suit, tier=0):
	# Check for duplicates to fuse
	for card in collection:
		if card.rank == rank and card.suit == suit:
			# Duplicate found! Fuse into existing card.
			_fuse_card(card)
			return

	# New card
	collection.append({
		"rank": rank,
		"suit": suit,
		"tier": tier,
		"integrity": 3
	})
	print("Collection: Added New Card ", rank, " of ", suit, " (Tier ", tier, ")")

func _fuse_card(card):
	if card.tier < 4:
		card.tier += 1
		card.integrity = 3 # Heal on upgrade
		print("Collection: Fused Duplicate! ", card.rank, " of ", card.suit, " upgraded to Tier ", card.tier)
	else:
		print("Collection: Card at Max Tier! (Lockout / Next Rarity logic here)")

func damage_highest_tier_card():
	# Find highest tier card strictly > 0
	var candidates = []
	var max_tier = 0 # Start checking above 0
	
	for card in collection:
		if card.tier > max_tier:
			max_tier = card.tier
			candidates = [card]
		elif card.tier == max_tier and max_tier > 0:
			candidates.append(card)
			
	if candidates.is_empty():
		print("Collection: No upgraded cards to damage (Tier 0 is safe).")
		return
		
	# Pick one random victim
	var victim = candidates[randi() % candidates.size()]
	
	print("Collection: Damaging ", victim.rank, " of ", victim.suit, " (Tier ", victim.tier, ")")
	victim.integrity -= 1
	
	if victim.integrity <= 0:
		_demote_card(victim)

func _demote_card(card):
	if card.tier > 0:
		card.tier -= 1
		card.integrity = 3 
		print("Collection: Card DEMOTED to Tier ", card.tier)
	else:
		# Should not happen if we filter > 0, but safety check
		pass
