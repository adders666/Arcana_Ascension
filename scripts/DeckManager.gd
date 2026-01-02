extends Node

const CardDataScript = preload("res://scripts/CardData.gd")

var player_deck: Array = []
var ai_deck: Array = []

var player_discard: Array = []
var ai_discard: Array = []

var trump_suit: String = ""
var ace_is_high: bool = false

# Temporary storage for extracted perimeter cards
var perimeter_pool: Array = []

func _ready():
	randomize()

func initialize_decks():
	# Generate Minors for Players
	player_deck = _generate_minor_deck()
	ai_deck = _generate_minor_deck()
	
	player_discard.clear()
	ai_discard.clear()
	perimeter_pool.clear()
	
	_shuffle_deck(player_deck)
	_shuffle_deck(ai_deck)
	
	# Generate Majors (Shared Pool)
	var all_majors = _generate_major_deck()
	all_majors.shuffle()
	
	# Take top 10 for Perimeter
	for i in range(10):
		if not all_majors.is_empty():
			perimeter_pool.append(all_majors.pop_back())
			
	world_flip()

func _generate_minor_deck() -> Array:
	var new_deck = []
	var id_counter = 0
	for suit in CardDataScript.SUITS:
		for i in range(CardDataScript.RANKS.size()):
			var rank_name = CardDataScript.RANKS[i]
			var val = i + 1 
			new_deck.append(CardDataScript.new(suit, rank_name, val, false, id_counter))
			id_counter += 1
	return new_deck

func _generate_major_deck() -> Array:
	var new_deck = []
	var id_counter = 100 # Offset IDs
	for i in range(CardDataScript.MAJORS.size()):
		new_deck.append(CardDataScript.new("Major", CardDataScript.MAJORS[i], i, true, id_counter))
		id_counter += 1
	return new_deck

func _shuffle_deck(d: Array):
	d.shuffle()

func world_flip():
	trump_suit = CardDataScript.SUITS[randi() % CardDataScript.SUITS.size()]
	ace_is_high = randi() % 2 == 1 
	print("World Flip! Trump: " + trump_suit + ", Ace High: " + str(ace_is_high))

func get_card_value(card) -> int:
	if card.is_major:
		return card.rank_value 
	if card.rank == "Ace":
		return 14 if ace_is_high else 1
	return card.rank_value

func draw_card(is_player: bool = true):
	var target_deck = player_deck if is_player else ai_deck
	var target_discard = player_discard if is_player else ai_discard
	
	if target_deck.is_empty():
		if target_discard.is_empty():
			return null
		# Reshuffle
		target_deck = target_discard.duplicate()
		target_deck.shuffle()
		target_discard.clear()
		# Update reference if it was a copy (Arrays are passed by ref, but reassignment breaks it)
		if is_player: player_deck = target_deck
		else: ai_deck = target_deck
		
	return target_deck.pop_back()