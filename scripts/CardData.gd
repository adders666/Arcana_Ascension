class_name CardData

var suit: String # "Wands", "Cups", "Swords", "Pentacles", "Major"
var rank: String # "Ace", "2"..."10", "Page", "Knight", "Queen", "King", or Major Name
var rank_value: int # Base numeric value
var is_major: bool
var id: int # Unique ID 0-77

const SUITS = ["Wands", "Cups", "Swords", "Pentacles"]
const RANKS = ["Ace", "2", "3", "4", "5", "6", "7", "8", "9", "10", "Page", "Knight", "Queen", "King"]
const MAJORS = [
	"The Fool", "The Magician", "The High Priestess", "The Empress", "The Emperor", 
	"The Hierophant", "The Lovers", "The Chariot", "Strength", "The Hermit", 
	"Wheel of Fortune", "Justice", "The Hanged Man", "Death", "Temperance", 
	"The Devil", "The Tower", "The Star", "The Moon", "The Sun", "Judgement", "The World"
]

func _init(_suit, _rank, _val, _is_major, _id):
	suit = _suit
	rank = _rank
	rank_value = _val
	is_major = _is_major
	id = _id

func get_display_name() -> String:
	if is_major:
		return rank # Major rank is its name
	return rank + " of " + suit
