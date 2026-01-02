class_name DominionSystem

# Stores the suit assigned to each row and column.
# Indices 0-4. Empty string means no suit claimed yet.
var row_suits: Array = ["", "", "", "", ""]
var col_suits: Array = ["", "", "", "", ""]

func reset():
	for i in range(5):
		row_suits[i] = ""
		col_suits[i] = ""

func get_row_suit(row_idx: int) -> String:
	return row_suits[row_idx]

func get_col_suit(col_idx: int) -> String:
	return col_suits[col_idx]

func try_claim_line(is_row: bool, index: int, suit: String) -> bool:
	# Major Arcana might not set suit? GDD says "The Claim: ... adopt the suit of that card."
	# Majors usually don't have suits like Wands/Cups. They are "Major".
	# If suit is "Major", maybe it doesn't saturate? Or saturates as Major?
	# GDD: "Rule: Players must follow the saturated suit... If they cannot, they must play a Trump or a low card to dump."
	# I'll assume only standard suits claim lines for now.
	
	if suit == "Major":
		return false
		
	if is_row:
		if row_suits[index] == "":
			row_suits[index] = suit
			return true
	else:
		if col_suits[index] == "":
			col_suits[index] = suit
			return true
	return false

func is_move_legal(card, x: int, y: int, trump_suit: String) -> bool:
	# Check Row Saturation
	var r_suit = row_suits[y]
	if r_suit != "" and card.suit != r_suit:
		# Player must follow suit.
		# Exceptions:
		# 1. Player has NO cards of that suit (Hard to check here without hand context, but let's assume UI handles that or we pass hand)
		# 2. Playing a Trump (if allowed to trump)
		# 3. Dumping (playing low card) - mechanically allowed, just bad for scoring?
		# GDD says: "If they cannot, they must play a Trump or a low card to dump."
		# This implies the MOVE IS LEGAL, but strategic context matters.
		# However, in digital card games, usually we strictly enforce "Must Follow Suit" if possible.
		# For now, I will mark it as Valid placement mechanics-wise. 
		# The restriction "If they cannot" implies a player constraint, not a board constraint.
		pass
		
	# Check Column Saturation
	var c_suit = col_suits[x]
	if c_suit != "" and card.suit != c_suit:
		pass
		
	# In this prototype phase, all placements in the correct Axis are "Legal".
	# The logic about strictly following suit is a Hand validation step (can I play this card?).
	return true
